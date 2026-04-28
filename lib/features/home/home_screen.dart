import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../colors.dart';
import '../../core/auth_state.dart';
import '../../core/locale_state.dart';
import '../../core/strings.dart';
import '../profile/profile_screen.dart';
import '../tickets/tickets_screen.dart';
import '../matches/matches_screen.dart';
import '../match_details/match_details_screen.dart';
import '../../widgets/match_card.dart';
import '../notifications/notifications_screen.dart';
import '../ai/ai_recommendations_screen.dart';
import '../map/stadium_map_screen.dart';

class HomeScreen extends StatelessWidget {
  static const route = '/home';
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final lang = context.watch<LocaleState>().locale.languageCode;
    final l = L(lang);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.t('home')),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.pushNamed(context, NotificationsScreen.route),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, ProfileScreen.route),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final nav = Navigator.of(context);
              await auth.signOut();
              nav.pushNamedAndRemoveUntil('/login', (r) => false);
            },
          ),
        ],
      ),
      body: auth.isAdmin ? const _AdminView() : _UserView(),
    );
  }
}

class _AdminView extends StatelessWidget {
  const _AdminView();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _logo(),
        const SizedBox(height: 24),
        Builder(builder: (ctx) { final lang = ctx.watch<LocaleState>().locale.languageCode; return Text(lang == 'ar' ? 'لوحة المدير' : (lang == 'fr' ? 'Tableau de bord' : 'Admin Dashboard'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)); }),
        const SizedBox(height: 16),
        Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.dashboard_customize_rounded, color: Colors.white70, size: 40),
              SizedBox(height: 10),
              Builder(builder: (ctx) { final lang = ctx.watch<LocaleState>().locale.languageCode; return Text(lang == 'ar' ? 'أدوات المدير' : (lang == 'fr' ? 'Outils Admin' : 'Admin Tools'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)); }),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserView extends StatelessWidget {
  const _UserView();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleState>().locale.languageCode;
    final l = L(lang);

    final matches = [
      {'title': 'Spain vs Brazil',       'date': 'Mar 26, 21:45', 'venue': 'Stadium 1', 'color': AppColors.cardRed},
      {'title': 'Argentina vs Portugal', 'date': 'Mar 28, 20:00', 'venue': 'Stadium 2', 'color': AppColors.cardYellow},
      {'title': 'France vs Germany',     'date': 'Apr 2, 21:00',  'venue': 'Stadium 3', 'color': AppColors.cardBlue},
      {'title': 'Saudi Arabia vs Japan', 'date': 'Apr 10, 19:30', 'venue': 'Stadium 4', 'color': AppColors.cardGreen},
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _logo(),
        const SizedBox(height: 24),

        _QuickTile(
          icon: Icons.person_outline_rounded,
          label: l.t('my_profile'),
          accentColor: AppColors.primary,
          bgColor: AppColors.surfaceAlt,
          onTap: () => Navigator.pushNamed(context, ProfileScreen.route),
        ),
        const SizedBox(height: 10),
        _QuickTile(
          icon: Icons.confirmation_number_outlined,
          label: l.t('ticket'),
          accentColor: AppColors.green,
          bgColor: AppColors.greenPale,
          onTap: () => Navigator.pushNamed(context, TicketsScreen.route),
        ),
        const SizedBox(height: 10),
        _QuickTile(
          icon: Icons.map_outlined,
          label: l.t('stadium_map'),
          accentColor: const Color(0xFF059669),
          bgColor: const Color(0xFFD1FAE5),
          onTap: () => Navigator.pushNamed(context, StadiumMapScreen.route),
        ),
        const SizedBox(height: 10),
        _QuickTile(
          icon: Icons.auto_awesome_rounded,
          label: l.t('ai_recommendations'),
          accentColor: const Color(0xFF7C3AED),
          bgColor: const Color(0xFFF3E8FF),
          onTap: () => Navigator.pushNamed(context, AiRecommendationsScreen.route),
        ),

        const SizedBox(height: 28),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l.t('matches'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, MatchesScreen.route),
              child: Text(l.t('see_all'),
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: matches.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final m = matches[i];
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, MatchDetailsScreen.route,
                  arguments: {'title': m['title'], 'date': m['date'], 'venue': m['venue']}),
                child: MatchCard(
                  title: m['title'] as String,
                  subtitle: m['date'] as String,
                  color: m['color'] as Color,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

Widget _logo() => Center(
  child: Image.asset(
    'assets/logo.png', height: 110,
    errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer, size: 70, color: AppColors.primary),
  ),
);

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon, required this.label,
    required this.accentColor, required this.bgColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ),
              Container(
                width: 4, height: 36,
                decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
