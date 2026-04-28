import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../colors.dart';
import '../../core/locale_state.dart';
import '../../core/broadcast_store.dart';

class AdminBroadcastScreen extends StatefulWidget {
  static const route = '/admin-broadcast';
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _msgCtrl = TextEditingController();
  String _selectedType = 'info';
  String _targetAudience = 'all';
  bool _isSending = false;
  bool _sent = false;

  List<Map<String, dynamic>> _getTypes(String lang) {
    final isAr = lang == 'ar';
    final isFr = lang == 'fr';
    return [
      {'id': 'info', 'label': isAr ? 'معلومة' : (isFr ? 'Info' : 'Info'), 'icon': Icons.info_rounded, 'color': const Color(0xFF0891B2)},
      {'id': 'warning', 'label': isAr ? 'تحذير' : (isFr ? 'Attention' : 'Warning'), 'icon': Icons.warning_rounded, 'color': AppColors.warning},
      {'id': 'emergency', 'label': isAr ? 'طارئ' : (isFr ? 'Urgence' : 'Emergency'), 'icon': Icons.emergency_rounded, 'color': AppColors.error},
      {'id': 'success', 'label': isAr ? 'تحديث' : (isFr ? 'Mise à jour' : 'Update'), 'icon': Icons.check_circle_rounded, 'color': AppColors.green},
    ];
  }

  List<Map<String, dynamic>> _getAudiences(String lang) {
    final isAr = lang == 'ar';
    final isFr = lang == 'fr';
    return [
      {'id': 'all', 'label': isAr ? 'جميع المستخدمين' : (isFr ? 'Tous' : 'All Users')},
      {'id': 'vip', 'label': isAr ? 'VIP فقط' : (isFr ? 'VIP seulement' : 'VIP Only')},
      {'id': 'standard', 'label': isAr ? 'عادي' : (isFr ? 'Standard' : 'Standard')},
      {'id': 'family', 'label': isAr ? 'عائلي' : (isFr ? 'Famille' : 'Family')},
    ];
  }

  List<String> _getTemplates(String lang) {
    final isAr = lang == 'ar';
    if (isAr) {
      return [
        '🚪 البوابة أ مفتوحة الآن. يرجى التوجه إلى قسمك.',
        '⚠️ البوابة الشمالية مزدحمة جداً. استخدم البوابة الجنوبية أو الغربية.',
        '⏱️ تبدأ المباراة خلال 15 دقيقة. يرجى الجلوس في أماكنكم.',
        '🅿️ موقف السيارات B امتلأ. يتوفر موقف بديل في موقف D.',
        '🚨 طوارئ: يرجى اتباع تعليمات الموظفين والبقاء هادئاً.',
        '🍔 منطقة الطعام عند البوابة C بها طوابير أقصر الآن.',
      ];
    } else if (lang == 'fr') {
      return [
        '🚪 La Porte A est maintenant ouverte. Veuillez rejoindre votre section.',
        '⚠️ La Porte Nord est très congestionnée. Utilisez la Porte Sud ou Ouest.',
        '⏱️ Le match commence dans 15 minutes. Veuillez rejoindre vos places.',
        '🅿️ Le parking B est plein. Parking alternatif disponible au lot D.',
        '🚨 Urgence : Suivez les instructions du personnel et restez calme.',
        '🍔 La restauration près de la Porte C a moins d\'attente maintenant.',
      ];
    } else {
      return [
        '🚪 Gate A is now open. Please proceed to your section.',
        '⚠️ North Gate is highly congested. Please use South or West Gate.',
        '⏱️ Match starts in 15 minutes. Please take your seats.',
        '🅿️ Parking lot B is now full. Alternative parking available on lot D.',
        '🚨 Emergency: Please follow staff instructions and remain calm.',
        '🍔 Food Court near Gate C has shorter queues right now.',
      ];
    }
  }

  Future<void> _sendBroadcast(bool isAr) async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'أدخل نص الرسالة' : 'Enter a message'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSending = true);

    context.read<BroadcastStore>().addMessage(message: msg, type: _selectedType, audience: _targetAudience);

    try {
      await FirebaseFirestore.instance.collection('broadcasts').add({
        'message': msg,
        'type': _selectedType,
        'audience': _targetAudience,
        'sentAt': FieldValue.serverTimestamp(),
        'read': false,
      }).timeout(const Duration(seconds: 5));
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _sent = true;
      _isSending = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(isAr ? 'تم الإرسال بنجاح!' : 'Broadcast sent!', overflow: TextOverflow.ellipsis)),
        ]),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _sent = false;
      _msgCtrl.clear();
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleState>().locale.languageCode;
    final isAr = lang == 'ar';
    final types = _getTypes(lang);
    final audiences = _getAudiences(lang);
    final templates = _getTemplates(lang);
    final selectedType = types.firstWhere((t) => t['id'] == _selectedType);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isAr ? 'بث رسالة للمشجعين' : 'Broadcast Message')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel(isAr ? 'نوع الرسالة' : 'Message Type'),
            const SizedBox(height: 10),
            Row(
              children: types.map((t) {
                final isSelected = _selectedType == t['id'];
                final color = t['color'] as Color;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = t['id'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? color : color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.3)),
                      ),
                      child: Column(children: [
                        Icon(t['icon'] as IconData, size: 20, color: isSelected ? Colors.white : color),
                        const SizedBox(height: 4),
                        Text(t['label'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : color)),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _sectionLabel(isAr ? 'المستهدفون' : 'Target Audience'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: audiences.map((a) {
                final isSelected = _targetAudience == a['id'];
                return GestureDetector(
                  onTap: () => setState(() => _targetAudience = a['id'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(a['label'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textPrimary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _sectionLabel(isAr ? 'قوالب سريعة' : 'Quick Templates'),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final t = templates[i];
                  return GestureDetector(
                    onTap: () => setState(() => _msgCtrl.text = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                      child: Text(t.length > 28 ? '${t.substring(0, 28)}…' : t, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _sectionLabel(isAr ? 'نص الرسالة' : 'Message Text'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (selectedType['color'] as Color).withValues(alpha: 0.4), width: 1.5),
              ),
              child: TextField(
                controller: _msgCtrl,
                maxLines: 4,
                maxLength: 280,
                decoration: InputDecoration(hintText: isAr ? 'اكتب رسالتك هنا...' : 'Type your message here...', border: InputBorder.none, contentPadding: const EdgeInsets.all(14)),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (selectedType['color'] as Color).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (selectedType['color'] as Color).withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Icon(selectedType['icon'] as IconData, color: selectedType['color'] as Color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _msgCtrl.text.isEmpty ? (isAr ? 'معاينة الرسالة...' : 'Message preview...') : _msgCtrl.text,
                    style: TextStyle(fontSize: 13, color: _msgCtrl.text.isEmpty ? AppColors.textHint : AppColors.textPrimary),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            if (_sent)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.greenPale, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.green.withValues(alpha: 0.4))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 20),
                  const SizedBox(width: 8),
                  Flexible(child: Text(isAr ? 'تم إرسال الرسالة بنجاح! ✅' : 'Broadcast sent successfully! ✅', overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700))),
                ]),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : () => _sendBroadcast(isAr),
                  icon: _isSending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, size: 18),
                  label: Flexible(
                    child: Text(_isSending ? (isAr ? 'جاري الإرسال...' : 'Sending...') : (isAr ? 'إرسال للجميع' : 'Send Broadcast'), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: selectedType['color'] as Color),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary));
}
