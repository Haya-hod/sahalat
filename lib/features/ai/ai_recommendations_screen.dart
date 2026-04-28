import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../colors.dart';
import '../../core/locale_state.dart';

class AiRecommendationsScreen extends StatefulWidget {
  static const route = '/ai-recommendations';
  const AiRecommendationsScreen({super.key});

  @override
  State<AiRecommendationsScreen> createState() =>
      _AiRecommendationsScreenState();
}

class _AiRecommendationsScreenState extends State<AiRecommendationsScreen> {
  bool _isLoading = false;
  String _response = '';
  int _selectedContextIndex = 0;
  int _selectedNeedIndex = 0;

  final Map<String, int> _crowdLevels = {
    'North Gate': 83,
    'East Gate': 45,
    'South Gate': 19,
    'West Gate': 14,
  };

  // Context options: [en, ar, fr]
  static const List<List<String>> _contextOptions = [
    ['VIP – Section A, Gate 1',     'VIP – القسم أ، البوابة 1',          'VIP – Section A, Porte 1'],
    ['Standard – Section B, Gate 2','Standard – القسم ب، البوابة 2',      'Standard – Section B, Porte 2'],
    ['Premium – Section C, Gate 3', 'Premium – القسم ج، البوابة 3',       'Premium – Section C, Porte 3'],
    ['Family – Section D, Gate 4',  'Family – القسم د، البوابة 4',        'Family – Section D, Porte 4'],
  ];

  // Need options: [en, ar, fr] + icon
  static const List<Map<String, dynamic>> _needOptions = [
    {
      'en': 'Best path to my seat',
      'ar': 'أفضل طريق لمقعدي',
      'fr': 'Meilleur chemin vers mon siège',
      'icon': Icons.directions_walk_rounded,
    },
    {
      'en': 'Nearest restroom',
      'ar': 'أقرب دورة مياه',
      'fr': 'Toilettes les plus proches',
      'icon': Icons.wc_rounded,
    },
    {
      'en': 'Nearest food court',
      'ar': 'أقرب منطقة طعام',
      'fr': 'Zone de restauration la plus proche',
      'icon': Icons.restaurant_rounded,
    },
    {
      'en': 'Avoid crowded areas',
      'ar': 'تجنب المناطق المزدحمة',
      'fr': 'Éviter les zones bondées',
      'icon': Icons.groups_rounded,
    },
    {
      'en': 'Emergency exit',
      'ar': 'مخرج الطوارئ',
      'fr': 'Sortie de secours',
      'icon': Icons.emergency_rounded,
    },
  ];

  String _contextLabel(int i, String lang) {
    final idx = lang == 'ar' ? 1 : (lang == 'fr' ? 2 : 0);
    return _contextOptions[i][idx];
  }

  String _needLabel(int i, String lang) {
    final key = lang == 'ar' ? 'ar' : (lang == 'fr' ? 'fr' : 'en');
    return _needOptions[i][key] as String;
  }

  Future<void> _getRecommendation(String lang) async {
    setState(() { _isLoading = true; _response = ''; });

    final crowdSummary = _crowdLevels.entries
        .map((e) => '${e.key}: ${e.value}%')
        .join(', ');

    final needEn = _needOptions[_selectedNeedIndex]['en'] as String;
    final prompt = '''
You are a smart stadium assistant for the Sahalat app.
User location: ${_contextOptions[_selectedContextIndex][0]}
User need: $needEn
Crowd levels: $crowdSummary
Give a short friendly recommendation (3-5 sentences). Include the best route, reason, and one practical tip.
${lang == 'ar' ? 'Respond in Arabic.' : lang == 'fr' ? 'Respond in French.' : 'Respond in English.'}
''';

    const apiKey = String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: '');

    if (apiKey.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() { _response = _demoResponse(lang); _isLoading = false; });
      return;
    }

    try {
      final res = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'claude-haiku-4-5-20251001',
          'max_tokens': 300,
          'system': 'You are a helpful stadium assistant for the Sahalat app.',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() { _response = data['content'][0]['text'].toString().trim(); });
      } else {
        setState(() { _response = _demoResponse(lang); });
      }
    } catch (_) {
      setState(() { _response = _demoResponse(lang); });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _demoResponse(String lang) {
    final need = _needOptions[_selectedNeedIndex]['en'] as String;
    if (lang == 'ar') {
      if (need.contains('seat')) {
        return 'توجّه إلى البوابة 1 عبر الممر الشمالي — نسبة الازدحام حالياً 83% لذا تحرّك بسرعة. '
            'خذ أول منعطف على اليسار بعد المدخل الرئيسي واتبع لافتات القسم أ. '
            'نصيحة: احضر قبل 15 دقيقة لتجنّب الازدحام عند بوابات الدخول.';
      } else if (need.contains('restroom')) {
        return 'أقرب دورة مياه على بُعد 40 متراً على يسارك في الطابق الأول. '
            'دورات المياه عند البوابة الجنوبية أقل ازدحاماً حالياً (19%). '
            'نصيحة: أفضل وقت للزيارة قبل بدء المباراة أو قبل نهاية الشوط الأول بخمس دقائق.';
      } else if (need.contains('food')) {
        return 'منطقة الطعام عند البوابة الجنوبية طوابيرها قصيرة الآن. '
            'امشِ عبر ممر البوابة 4 — المسافة حوالي 3 دقائق سيراً من قسمك. '
            'نصيحة: الطلب المسبق عبر التطبيق سيوفّر عليك الانتظار.';
      } else if (need.contains('crowd')) {
        return 'البوابة الجنوبية (19%) والبوابة الغربية (14%) هما الأقل ازدحاماً. '
            'تجنّب البوابة الشمالية التي وصلت إلى 83%. '
            'نصيحة: استخدم الممر الداخلي للتحرك بعيداً عن مناطق الازدحام.';
      } else {
        return 'مخارج الطوارئ موجودة في زوايا البوابات الأربع. '
            'أقرب مخرج من القسم أ هو باب الطوارئ الشمالي الشرقي على بُعد 30 متراً خلفك. '
            'نصيحة: اتبع الأسهم الخضراء على الأرض — تضيء تلقائياً في حالات الطوارئ.';
      }
    } else if (lang == 'fr') {
      if (need.contains('seat')) {
        return 'Dirigez-vous vers la Porte 1 via le couloir Nord — actuellement à 83% de capacité, dépêchez-vous. '
            'Tournez à gauche après l\'entrée principale et suivez les panneaux Section A. '
            'Conseil: arrivez 15 minutes en avance pour éviter la ruée aux tourniquets.';
      } else if (need.contains('food')) {
        return 'La zone de restauration près de la Porte Sud a peu d\'attente en ce moment. '
            'Marchez par le couloir de la Porte 4 — environ 3 minutes à pied. '
            'Conseil: pré-commandez via l\'application pour éviter la file.';
      } else {
        return 'Les toilettes les plus proches sont à 40m sur votre gauche au Niveau 1. '
            'Zone Porte Sud moins fréquentée (19%). '
            'Conseil: meilleur moment — avant le match ou 5 min avant la mi-temps.';
      }
    } else {
      if (need.contains('seat')) {
        return 'Head to Gate 1 via the North corridor — currently at 83% capacity so move quickly. '
            'Take the first left after the main entrance and follow Section A signs. '
            'Tip: Arrive 15 minutes early to avoid last-minute rush at the turnstiles.';
      } else if (need.contains('restroom')) {
        return 'The nearest restroom is 40m to your left on Level 1. '
            'South Gate area restrooms are currently less crowded (19%). '
            'Tip: Best time to visit is before the match or at half-time minus 5 minutes.';
      } else if (need.contains('food')) {
        return 'The Food Court near South Gate has short queues right now. '
            'Walk through Gate 4 corridor — about 3 minutes from your section. '
            'Tip: Pre-order via the app to skip the queue entirely.';
      } else if (need.contains('crowd')) {
        return 'South Gate (19%) and West Gate (14%) are least congested. '
            'Avoid North Gate which is at 83% capacity. '
            'Tip: Use the inner ring walkway to bypass main crowd zones.';
      } else {
        return 'Emergency exits are at all four gate corners. '
            'Your nearest exit from Section A is the North-East emergency door, 30m behind you. '
            'Tip: Follow the green floor arrows — they light up automatically in emergencies.';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleState>().locale.languageCode;
    final isAr = lang == 'ar';
    final isFr = lang == 'fr';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isAr
            ? 'توصيات الذكاء الاصطناعي'
            : (isFr ? 'Recommandations IA' : 'AI Recommendations')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white70, size: 32),
                  const SizedBox(height: 10),
                  Text(
                    isAr
                        ? 'مساعدك الذكي داخل الملعب'
                        : (isFr ? 'Votre assistant intelligent du stade' : 'Your Smart Stadium Assistant'),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAr
                        ? 'توصيات مخصصة بناءً على موقعك وحالة الازدحام'
                        : (isFr
                            ? 'Conseils personnalisés selon votre emplacement et la fréquentation'
                            : 'Personalised tips based on your location & live crowd data'),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Crowd overview
            _buildCrowdOverview(lang),
            const SizedBox(height: 24),

            // Location selector
            Text(
              isAr ? 'موقعك الحالي' : (isFr ? 'Votre emplacement' : 'Your Current Location'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedContextIndex,
                  isExpanded: true,
                  items: List.generate(
                    _contextOptions.length,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text(_contextLabel(i, lang)),
                    ),
                  ),
                  onChanged: (v) => setState(() => _selectedContextIndex = v!),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Need selector
            Text(
              isAr ? 'ماذا تحتاج؟' : (isFr ? 'Que cherchez-vous ?' : 'What do you need?'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_needOptions.length, (i) {
                final isSelected = _selectedNeedIndex == i;
                final icon = _needOptions[i]['icon'] as IconData;
                return GestureDetector(
                  onTap: () => setState(() => _selectedNeedIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          _needLabel(i, lang),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 28),

            // Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _getRecommendation(lang),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 20),
                label: Text(
                  _isLoading
                      ? (isAr ? 'جاري التحليل...' : (isFr ? 'Analyse...' : 'Analysing...'))
                      : (isAr ? 'احصل على توصية' : (isFr ? 'Obtenir une recommandation' : 'Get Recommendation')),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),

            // Response card
            if (_response.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isAr ? 'توصية الذكاء الاصطناعي' : (isFr ? 'Recommandation IA' : 'AI Recommendation'),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(_response,
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.6)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCrowdOverview(String lang) {
    final isAr = lang == 'ar';
    final isFr = lang == 'fr';
    // Localised gate names
    const gateNames = {
      'North Gate': {'ar': 'البوابة الشمالية', 'fr': 'Porte Nord'},
      'East Gate':  {'ar': 'البوابة الشرقية',  'fr': 'Porte Est'},
      'South Gate': {'ar': 'البوابة الجنوبية', 'fr': 'Porte Sud'},
      'West Gate':  {'ar': 'البوابة الغربية',  'fr': 'Porte Ouest'},
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sensors_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isAr ? 'مستوى الازدحام الحالي' : (isFr ? 'Fréquentation en direct' : 'Live Crowd Levels'),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.greenPale, borderRadius: BorderRadius.circular(6)),
                child: Row(children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(isAr ? 'مباشر' : (isFr ? 'Direct' : 'Live'),
                      style: const TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._crowdLevels.entries.map((e) {
            final pct = e.value;
            final color = AppColors.getCrowdColor(pct.toDouble());
            final displayName = isAr
                ? (gateNames[e.key]?['ar'] ?? e.key)
                : (isFr ? (gateNames[e.key]?['fr'] ?? e.key) : e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 38,
                    child: Text('$pct%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: Text(displayName,
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
