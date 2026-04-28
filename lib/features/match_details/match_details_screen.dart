import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../colors.dart';
import '../../core/locale_state.dart';
import '../../core/strings.dart';
import '../payment/payment_screen.dart';

class MatchDetailsScreen extends StatefulWidget {
  static const route = '/match-details';
  const MatchDetailsScreen({super.key});

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  String? _selectedArea;

  final List<Map<String, dynamic>> _hotspots = [
    {
      'name': 'VIP',
      'color': const Color(0xFF7C3AED),
      'bgColor': const Color(0xFFF3E8FF),
      'gate': 'Gate 1',
      'price': 'SAR 850',
      'available': 12,
      'area': const Rect.fromLTWH(140, 330, 140, 60),
    },
    {
      'name': 'Standard',
      'color': AppColors.error,
      'bgColor': AppColors.cardRed,
      'gate': 'Gate 2',
      'price': 'SAR 250',
      'available': 48,
      'area': const Rect.fromLTWH(80, 80, 260, 100),
    },
    {
      'name': 'Premium',
      'color': AppColors.primaryMid,
      'bgColor': AppColors.cardBlue,
      'gate': 'Gate 3',
      'price': 'SAR 450',
      'available': 30,
      'area': const Rect.fromLTWH(30, 200, 120, 100),
    },
    {
      'name': 'Family',
      'color': AppColors.green,
      'bgColor': AppColors.cardGreen,
      'gate': 'Gate 4',
      'price': 'SAR 350',
      'available': 22,
      'area': const Rect.fromLTWH(320, 200, 120, 100),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleState>().locale.languageCode;
    final l = L(lang);
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final title = args?['title'] ?? 'Match';
    final date = args?['date'] ?? '';
    final venue = args?['venue'] ?? '';

    final selected = _selectedArea != null
        ? _hotspots.firstWhere((h) => h['name'] == _selectedArea)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l.t('match_details'))),
      body: Column(
        children: [
          // Match info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (date.isNotEmpty) ...[
                      const Icon(Icons.access_time_rounded, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(date, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(width: 16),
                    ],
                    if (venue.isNotEmpty) ...[
                      const Icon(Icons.stadium_outlined, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(venue, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Stadium map
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double baseWidth = 420;
                const double baseHeight = 500;
                final double screenWidth = constraints.maxWidth;
                final double scaleFactor = screenWidth / baseWidth;
                final double scaledHeight = baseHeight * scaleFactor;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Map
                      SizedBox(
                        width: screenWidth,
                        height: scaledHeight,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                'assets/stadium.png',
                                fit: BoxFit.fill,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF1A5C2A),
                                  child: const Center(
                                    child: Icon(Icons.stadium, size: 80, color: Colors.white24),
                                  ),
                                ),
                              ),
                            ),
                            ..._hotspots.map((h) {
                              final Rect r = h['area'] as Rect;
                              final String name = h['name'] as String;
                              final Color color = h['color'] as Color;
                              final bool isSelected = _selectedArea == name;
                              return Positioned(
                                left: r.left * scaleFactor,
                                top: r.top * scaleFactor,
                                width: r.width * scaleFactor,
                                height: r.height * scaleFactor,
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedArea = name),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? color.withValues(alpha: 0.5)
                                          : color.withValues(alpha: 0.15),
                                      border: Border.all(
                                        color: color,
                                        width: isSelected ? 2.5 : 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isSelected ? color : color.withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),

                      // Section legend
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang == 'ar' ? 'اختر القسم' : (lang == 'fr' ? 'Choisir une section' : 'Select a Section'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSectionRow(_hotspots.sublist(0, 2)),
                            const SizedBox(height: 10),
                            _buildSectionRow(_hotspots.sublist(2, 4)),

                            if (selected != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${lang == "ar" ? "المختار" : (lang == "fr" ? "Sélectionné" : "Selected")}: ${selected['name']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: AppColors.textPrimary,
                                          )),
                                        Text(selected['price'] as String,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: selected['color'] as Color,
                                          )),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.door_sliding_outlined,
                                          size: 14, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(selected['gate'] as String,
                                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.event_seat_outlined,
                                          size: 14, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text('${selected['available']} ${lang == "ar" ? "متاح" : "available"}',
                                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 46,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            PaymentScreen.route,
                                            arguments: {
                                              'title': title,
                                              'section': selected!['name'],
                                              'price': selected['price'],
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                                        label: Text(lang == 'ar' ? 'احجز هذا القسم' : (lang == 'fr' ? 'Réserver cette section' : 'Book This Section')),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.green,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionRow(List<Map<String, dynamic>> items) {
    return Row(
      children: List.generate(items.length, (i) {
        final h = items[i];
        final name = h['name'] as String;
        final color = h['color'] as Color;
        final bgColor = h['bgColor'] as Color;
        final isSelected = _selectedArea == name;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedArea = name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i == 0 ? 5 : 0, left: i == 1 ? 5 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color : bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : color.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          h['price'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}