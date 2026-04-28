import 'package:flutter/material.dart';
import '../../colors.dart';
import 'package:provider/provider.dart';
import '../../core/locale_state.dart';
import '../../core/strings.dart';
import '../match_details/match_details_screen.dart';

class MatchesScreen extends StatelessWidget {
  static const route = '/matches';
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cardColors = [AppColors.cardRed, AppColors.cardYellow, AppColors.cardBlue, AppColors.cardGreen];
    final lang = context.watch<LocaleState>().locale.languageCode;
    final l = L(lang);
    final teams = ['Spain vs Brazil','Argentina vs Portugal','France vs Germany',
      'Saudi Arabia vs Japan','Morocco vs England','Italy vs Netherlands'];

    final all = List.generate(12, (i) => {
      'title': teams[i % teams.length],
      'date': 'Nov ${12 + (i % 7)}, ${18 + (i % 6)}:00',
      'venue': 'Stadium ${(i % 4) + 1}',
      'color': cardColors[i % 4],
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l.t('matches_title'))),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: all.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final m = all[i];
          return Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pushNamed(context, MatchDetailsScreen.route, arguments: m),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: m['color'] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.sports_soccer_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text('${m['date']}  •  ${m['venue']}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
