import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../colors.dart';
import '../../core/auth_state.dart';
import '../../core/locale_state.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import 'admin_broadcast_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  static const route = '/admin-dashboard-v2';
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late List<GateData> gates;
  Timer? _simulationTimer;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _initGates();
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < gates.length; i++) {
          final delta = _rng.nextInt(80) - 40;
          final next = (gates[i].current + delta).clamp(0, gates[i].capacity);
          gates[i] = GateData(
            name: gates[i].name,
            current: next,
            capacity: gates[i].capacity,
            color: gates[i].color,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _initGates() {
    gates = [
      GateData(name: 'North Gate', current: 3500, capacity: 4200, color: const Color(0xFF0061FF)),
      GateData(name: 'East Gate',  current: 1900, capacity: 4200, color: AppColors.warning),
      GateData(name: 'South Gate', current: 800,  capacity: 4200, color: AppColors.success),
      GateData(name: 'West Gate',  current: 600,  capacity: 4200, color: AppColors.info),
    ];
  }

  int get _totalPeople   => gates.fold(0, (s, g) => s + g.current);
  int get _totalCapacity => gates.fold(0, (s, g) => s + g.capacity);
  double get _occupancy  => (_totalPeople / _totalCapacity) * 100;

  // Localised gate names
  String _gateName(String name, String lang) {
    if (lang == 'en') return name;
    const arNames = {
      'North Gate': 'البوابة الشمالية',
      'East Gate':  'البوابة الشرقية',
      'South Gate': 'البوابة الجنوبية',
      'West Gate':  'البوابة الغربية',
    };
    const frNames = {
      'North Gate': 'Porte Nord',
      'East Gate':  'Porte Est',
      'South Gate': 'Porte Sud',
      'West Gate':  'Porte Ouest',
    };
    return lang == 'ar' ? (arNames[name] ?? name) : (frNames[name] ?? name);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleState>().locale.languageCode;
    final isAr = lang == 'ar';
    final isFr = lang == 'fr';
    final auth = context.read<AuthState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          isAr ? 'لوحة تحكم الملعب' : (isFr ? 'Tableau de bord du stade' : 'Stadium Dashboard'),
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Tooltip(
            message: isAr ? 'بث رسالة' : (isFr ? 'Message diffusé' : 'Broadcast Message'),
            child: IconButton(
              icon: const Icon(Icons.campaign_rounded, size: 24),
              onPressed: () => Navigator.pushNamed(context, AdminBroadcastScreen.route),
            ),
          ),
          Tooltip(
            message: isAr ? 'ملفي الشخصي' : (isFr ? 'Mon profil' : 'My Profile'),
            child: IconButton(
              icon: const Icon(Icons.person_outline, size: 24),
              onPressed: () => Navigator.pushNamed(context, ProfileScreen.route),
            ),
          ),
          Tooltip(
            message: isAr ? 'تسجيل الخروج' : (isFr ? 'Déconnexion' : 'Logout'),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, size: 24),
              onPressed: () => _showLogoutDialog(context, auth, lang),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsRow(lang),
            const SizedBox(height: 24),
            _buildGatesCrowdSection(lang),
            const SizedBox(height: 24),
            _buildAlertsSection(lang),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(String lang) {
    final isAr = lang == 'ar';
    final isFr = lang == 'fr';
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: isAr ? 'إجمالي الزوار' : (isFr ? 'Total visiteurs' : 'Total Visitors'),
            value: '$_totalPeople',
            icon: Icons.groups_rounded,
            backgroundColor: const Color(0xFFEFF6FF),
            iconColor: AppColors.primary,
            borderColor: const Color(0xFFBFDBFE),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: isAr ? 'نسبة الاستيعاب' : (isFr ? 'Taux d\'occupation' : 'Capacity Usage'),
            value: '${_occupancy.toStringAsFixed(1)}%',
            icon: Icons.analytics_rounded,
            backgroundColor: AppColors.crowdMediumLight,
            iconColor: AppColors.warning,
            borderColor: AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: isAr ? 'متوسط وقت الانتظار' : (isFr ? 'Temps d\'attente' : 'Avg Wait Time'),
            value: isAr ? '٧ دقائق' : (isFr ? '7 min' : '7 min'),
            icon: Icons.schedule_rounded,
            backgroundColor: AppColors.infoLight,
            iconColor: AppColors.info,
            borderColor: AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildGatesCrowdSection(String lang) {
    final isAr = lang == 'ar';
    final isFr = lang == 'fr';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.door_front_door_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            Text(
              isAr ? 'مستوى الازدحام على البوابات' : (isFr ? 'Fréquentation des portes' : 'Gate Crowd Levels'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ]),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) => _GateBar(gateData: gates[i], lang: lang, gateName: _gateName(gates[i].name, lang)),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(String lang) {
    final isAr = lang == 'ar';
    final isFr = lang == 'fr';
    final alerts = <AlertData>[];

    for (final gate in gates) {
      final pct = (gate.current / gate.capacity) * 100;
      final localName = _gateName(gate.name, lang);
      if (pct >= 80) {
        alerts.add(AlertData(
          level: AlertLevel.high,
          title: isAr ? 'ازدحام شديد' : (isFr ? 'Forte congestion' : 'High Congestion'),
          message: isAr
              ? '$localName وصلت إلى ${pct.toStringAsFixed(0)}% من طاقتها'
              : (isFr
                  ? '$localName est à ${pct.toStringAsFixed(0)}% de sa capacité'
                  : '$localName is at ${pct.toStringAsFixed(0)}% capacity'),
          icon: Icons.warning_rounded,
          color: AppColors.error,
        ));
      } else if (pct >= 50) {
        alerts.add(AlertData(
          level: AlertLevel.medium,
          title: isAr ? 'ازدحام متوسط' : (isFr ? 'Congestion modérée' : 'Medium Congestion'),
          message: isAr
              ? 'الازدحام يتصاعد عند $localName'
              : (isFr ? 'La fréquentation augmente à $localName' : '$localName load is increasing'),
          icon: Icons.info_rounded,
          color: AppColors.warning,
        ));
      }
    }

    if (alerts.isEmpty) {
      alerts.add(AlertData(
        level: AlertLevel.ok,
        title: isAr ? 'كل الأنظمة تعمل بشكل طبيعي' : (isFr ? 'Tous les systèmes normaux' : 'All Systems Normal'),
        message: isAr
            ? 'جميع البوابات تعمل بصورة اعتيادية'
            : (isFr ? 'Toutes les portes fonctionnent normalement' : 'All gates operating normally'),
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                isAr ? 'تنبيهات النظام' : (isFr ? 'Alertes système' : 'System Alerts'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ]),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const Divider(height: 0, color: AppColors.border),
            itemBuilder: (_, i) => _AlertTile(alert: alerts[i]),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthState auth, String lang) {
    final isAr = lang == 'ar';
    final isFr = lang == 'fr';
    final nav = Navigator.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'تسجيل الخروج' : (isFr ? 'Déconnexion' : 'Logout')),
        content: Text(isAr
            ? 'هل أنت متأكد من تسجيل الخروج؟'
            : (isFr ? 'Voulez-vous vraiment vous déconnecter ?' : 'Are you sure you want to log out?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : (isFr ? 'Annuler' : 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
              nav.pushNamedAndRemoveUntil(LoginScreen.route, (r) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(isAr ? 'خروج' : (isFr ? 'Déconnecter' : 'Logout')),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color backgroundColor, iconColor, borderColor;

  const _StatCard({
    required this.title, required this.value, required this.icon,
    required this.backgroundColor, required this.iconColor, required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(color: iconColor.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: iconColor)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _GateBar extends StatelessWidget {
  final GateData gateData;
  final String lang;
  final String gateName;

  const _GateBar({required this.gateData, required this.lang, required this.gateName});

  @override
  Widget build(BuildContext context) {
    final isAr = lang == 'ar';
    final isFr = lang == 'fr';
    final occupancy = gateData.current / gateData.capacity;
    final pctStr = (occupancy * 100).toStringAsFixed(1);
    final color = AppColors.getCrowdColor(double.parse(pctStr));
    final status = AppColors.getCrowdStatus(double.parse(pctStr));

    // Localise status label
    String localStatus;
    if (status == 'High') {
      localStatus = isAr ? 'ازدحام شديد' : (isFr ? 'Forte congestion' : 'High Congestion');
    } else if (status == 'Medium') {
      localStatus = isAr ? 'ازدحام متوسط' : (isFr ? 'Congestion modérée' : 'Medium Congestion');
    } else {
      localStatus = isAr ? 'ازدحام خفيف' : (isFr ? 'Faible congestion' : 'Low Congestion');
    }

    final peopleLabel = isAr
        ? '${gateData.current} / ${gateData.capacity} شخص'
        : (isFr
            ? '${gateData.current} / ${gateData.capacity} personnes'
            : '${gateData.current} / ${gateData.capacity} people');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.location_on_rounded, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(gateName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          Text('$pctStr%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ]),
        const SizedBox(height: 8),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: occupancy,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(peopleLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(localStatus,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ),
          ],
        ),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  final AlertData alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alert.color.withValues(alpha: 0.08),
        border: Border(left: BorderSide(color: alert.color, width: 4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: alert.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(alert.icon, size: 20, color: alert.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(alert.message,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class GateData {
  String name; int current; int capacity; Color color;
  GateData({required this.name, required this.current, required this.capacity, required this.color});
}

enum AlertLevel { high, medium, ok }

class AlertData {
  final AlertLevel level;
  final String title, message;
  final IconData icon;
  final Color color;
  AlertData({required this.level, required this.title, required this.message, required this.icon, required this.color});
}
