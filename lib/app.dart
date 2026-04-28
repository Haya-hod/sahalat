import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'colors.dart';

// Core
import 'core/auth_state.dart';
import 'core/locale_state.dart';
import 'core/broadcast_store.dart';
import 'core/ticket_store.dart';
import 'core/user_store.dart';

// Screens
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/home/home_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/tickets/tickets_screen.dart';
import 'features/tickets/ticket_qr_screen.dart';
import 'features/tickets/ticket_transfer_screen.dart';
import 'features/matches/matches_screen.dart';
import 'features/match_details/match_details_screen.dart';
import 'features/payment/payment_screen.dart';

// Navigation
import 'features/navigation/navigation_steps_screen.dart';

// New screens from teammate
import 'features/notifications/notifications_screen.dart';
import 'features/ai/ai_recommendations_screen.dart';
import 'features/map/stadium_map_screen.dart';

// Pathfinding test screen
import 'package:sahalat/presentation/path_test_screen.dart';

// Admin screens
import 'features/admin/admin_qr_scan_screen.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'features/admin/admin_broadcast_screen.dart';

class SahalatApp extends StatelessWidget {
  const SahalatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleState()),
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => BroadcastStore()),
        ChangeNotifierProvider(create: (_) => TicketStore()),
        ChangeNotifierProvider(create: (_) => UserStore()),
      ],
      child: Consumer<LocaleState>(
        builder: (context, localeState, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "Sahalat",

            // Localization
            locale: localeState.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
              Locale('fr'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // Theme - use the new buildAppTheme
            theme: buildAppTheme(),

            // Splash
            initialRoute: SplashScreen.route,

            routes: {
              // Core
              SplashScreen.route: (_) => const SplashScreen(),
              LoginScreen.route: (_) => const LoginScreen(),
              RegisterScreen.route: (_) => const RegisterScreen(),
              HomeScreen.route: (_) => const HomeScreen(),

              // User
              ProfileScreen.route: (_) => const ProfileScreen(),
              TicketsScreen.route: (_) => const TicketsScreen(),
              TicketQrScreen.route: (_) => const TicketQrScreen(),
              TicketTransferScreen.route: (_) => const TicketTransferScreen(),
              MatchesScreen.route: (_) => const MatchesScreen(),
              MatchDetailsScreen.route: (_) => const MatchDetailsScreen(),
              PaymentScreen.route: (_) => const PaymentScreen(),

              // Navigation (GPS + A* + Crowd + Unity AR)
              NavigationStepsScreen.route: (_) => const NavigationStepsScreen(),

              // New screens from teammate
              NotificationsScreen.route: (_) => const NotificationsScreen(),
              AiRecommendationsScreen.route: (_) => const AiRecommendationsScreen(),
              StadiumMapScreen.route: (_) => const StadiumMapScreen(),

              // Pathfinding test
              '/path-test': (_) => const PathTestScreen(),

              // Admin
              AdminQrScanScreen.route: (_) => const AdminQrScanScreen(),
              AdminDashboardScreen.route: (_) => const AdminDashboardScreen(),
              AdminBroadcastScreen.route: (_) => const AdminBroadcastScreen(),
            },
          );
        },
      ),
    );
  }
}
