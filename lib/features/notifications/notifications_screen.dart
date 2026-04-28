import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../colors.dart';
import '../../core/broadcast_store.dart';
import '../../core/locale_state.dart';

class NotificationsScreen extends StatefulWidget {
  static const route = '/notifications';
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Rebuilt whenever the active language changes.
  List<_Notif> _notifs = [];
  String _lastLang = '';
  bool _allRead = false;

  void _ensureNotifsForLang(String lang) {
    if (lang != _lastLang) {
      _lastLang = lang;
      final prevRead = {for (final n in _notifs) n.id: n.isRead};
      _notifs = _buildNotifs(lang);
      for (final n in _notifs) {
        if (prevRead[n.id] == true) n.isRead = true;
      }
    }
  }

  static List<_Notif> _buildNotifs(String lang) => [
        _Notif(
          id: 'match_reminder',
          icon: Icons.sports_soccer_rounded,
          color: AppColors.primary,
          bgColor: AppColors.surfaceAlt,
          title: lang == 'ar'
              ? 'تذكير بالمباراة'
              : (lang == 'fr' ? 'Rappel de match' : 'Match Reminder'),
          body: lang == 'ar'
              ? 'إسبانيا ضد البرازيل تبدأ خلال ساعتين! كن مستعداً.'
              : (lang == 'fr'
                  ? 'Espagne vs Brésil commence dans 2 heures !'
                  : 'Spain vs Brazil starts in 2 hours! Get ready.'),
          time: lang == 'ar' ? 'منذ ساعتين' : '2h ago',
          isRead: false,
        ),
        _Notif(
          id: 'ticket_confirmed',
          icon: Icons.confirmation_number_outlined,
          color: AppColors.green,
          bgColor: AppColors.greenPale,
          title: lang == 'ar'
              ? 'تأكيد التذكرة'
              : (lang == 'fr' ? 'Billet confirmé' : 'Ticket Confirmed'),
          body: lang == 'ar'
              ? 'تم تأكيد تذكرتك لمباراة الفريق أ ضد الفريق ب.'
              : (lang == 'fr'
                  ? 'Votre billet pour Équipe A vs Équipe B a été confirmé.'
                  : 'Your ticket for Team A vs Team B has been confirmed.'),
          time: lang == 'ar' ? 'منذ 5 ساعات' : '5h ago',
          isRead: false,
        ),
        _Notif(
          id: 'special_offer',
          icon: Icons.local_offer_outlined,
          color: AppColors.warning,
          bgColor: const Color(0xFFFFFBEB),
          title: lang == 'ar'
              ? 'عرض خاص'
              : (lang == 'fr' ? 'Offre spéciale' : 'Special Offer'),
          body: lang == 'ar'
              ? 'احصل على خصم 20% على حجزك التالي. عرض محدود!'
              : (lang == 'fr'
                  ? 'Obtenez 20% de réduction sur votre prochain billet !'
                  : 'Get 20% off on your next ticket booking. Limited time!'),
          time: lang == 'ar' ? 'منذ يومين' : '2 days ago',
          isRead: true,
        ),
      ];

  // --- Actions ---

  void _markAllRead() {
    context.read<BroadcastStore>().markAllRead();
    setState(() {
      for (final n in _notifs) {
        n.isRead = true;
      }
      _allRead = true;
    });
  }

  void _markOneRead(int index) => setState(() => _notifs[index].isRead = true);

  void _dismiss(String id) => setState(() => _notifs.removeWhere((n) => n.id == id));

  // --- Helpers ---

  IconData _typeIcon(String type) {
    switch (type) {
      case 'warning':   return Icons.warning_rounded;
      case 'emergency': return Icons.emergency_rounded;
      case 'success':   return Icons.check_circle_rounded;
      default:          return Icons.campaign_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'warning':   return AppColors.warning;
      case 'emergency': return AppColors.error;
      case 'success':   return AppColors.green;
      default:          return AppColors.primary;
    }
  }

  Color _typeBg(String type) {
    switch (type) {
      case 'warning':   return const Color(0xFFFFFBEB);
      case 'emergency': return AppColors.errorLight;
      case 'success':   return AppColors.greenPale;
      default:          return AppColors.surfaceAlt;
    }
  }

  String _timeAgo(DateTime dt, String lang) {
    final d = DateTime.now().difference(dt);
    if (lang == 'ar') {
      if (d.inSeconds < 60)  return 'الآن';
      if (d.inMinutes < 60)  return 'منذ ${d.inMinutes} دقيقة';
      if (d.inHours < 24)    return 'منذ ${d.inHours} ساعة';
      return 'منذ ${d.inDays} يوم';
    } else if (lang == 'fr') {
      if (d.inSeconds < 60)  return 'À l\'instant';
      if (d.inMinutes < 60)  return 'Il y a ${d.inMinutes} min';
      if (d.inHours < 24)    return 'Il y a ${d.inHours}h';
      return 'Il y a ${d.inDays}j';
    } else {
      if (d.inSeconds < 60)  return 'Just now';
      if (d.inMinutes < 60)  return '${d.inMinutes}m ago';
      if (d.inHours < 24)    return '${d.inHours}h ago';
      return '${d.inDays}d ago';
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleState>().locale.languageCode;
    _ensureNotifsForLang(lang);
    final broadcast = context.watch<BroadcastStore>();
    final msgs = broadcast.messages;
    final hasUnread = !_allRead &&
        (_notifs.any((n) => !n.isRead) || broadcast.unreadCount > 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          lang == 'ar' ? 'الإشعارات' : (lang == 'fr' ? 'Notifications' : 'Notifications'),
        ),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                lang == 'ar'
                    ? 'تعليم الكل مقروء'
                    : (lang == 'fr' ? 'Tout marquer lu' : 'Mark all read'),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
        ],
      ),
      body: (msgs.isEmpty && _notifs.isEmpty)
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('No notifications',
                      style: TextStyle(color: AppColors.textHint, fontSize: 16)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (msgs.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        lang == 'ar' ? 'من إدارة الملعب' : 'From Stadium Admin',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  ...List.generate(msgs.length, (i) {
                    final m = msgs[i];
                    final color = _typeColor(m.type);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => broadcast.markRead(i),
                        child: _NotifCard(
                          isRead: m.isRead,
                          borderColor: m.isRead ? AppColors.border : color.withValues(alpha: 0.4),
                          borderWidth: m.isRead ? 1.0 : 1.5,
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                                color: _typeBg(m.type),
                                borderRadius: BorderRadius.circular(12)),
                            child: Icon(_typeIcon(m.type), color: color, size: 22),
                          ),
                          title: lang == 'ar' ? 'إعلان الملعب' : (lang == 'fr' ? 'Annonce du stade' : 'Stadium Announcement'),
                          body: m.message,
                          time: _timeAgo(m.sentAt, lang),
                        ),
                      ),
                    );
                  }),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Divider(color: AppColors.border),
                  ),
                ],
                ...List.generate(_notifs.length, (i) {
                  final n = _notifs[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: ValueKey(n.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _dismiss(n.id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                      ),
                      child: GestureDetector(
                        onTap: () => _markOneRead(i),
                        child: _NotifCard(
                          isRead: n.isRead,
                          borderColor: n.isRead
                              ? AppColors.border
                              : AppColors.primary.withValues(alpha: 0.2),
                          borderWidth: 1.0,
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                                color: n.bgColor, borderRadius: BorderRadius.circular(12)),
                            child: Icon(n.icon, color: n.color, size: 22),
                          ),
                          title: n.title,
                          body: n.body,
                          time: n.time,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared card widget
// ---------------------------------------------------------------------------

class _NotifCard extends StatelessWidget {
  final bool isRead;
  final Color borderColor;
  final double borderWidth;
  final Widget leading;
  final String title;
  final String body;
  final String time;

  const _NotifCard({
    required this.isRead,
    required this.borderColor,
    required this.borderWidth,
    required this.leading,
    required this.title,
    required this.body,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRead ? AppColors.surface : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (!isRead)
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                    ),
                ]),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                const SizedBox(height: 6),
                Text(time,
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class _Notif {
  final String id;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;
  final String body;
  final String time;
  bool isRead;

  _Notif({
    required this.id,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
  });
}
