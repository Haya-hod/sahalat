import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../colors.dart';
import '../../core/locale_state.dart';
import '../../core/strings.dart';
import '../../core/ticket_models.dart';
import '../../core/ticket_payload.dart';
import '../../core/ticket_store.dart';
import 'ticket_qr_screen.dart';
import 'ticket_transfer_screen.dart';

class TicketsScreen extends StatefulWidget {
  static const route = '/tickets-v2';

  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleState>().locale.languageCode;
    final l = L(lang);

    final store = context.watch<TicketStore>();
    final activeTickets = store.activeTickets;
    final expiredTickets = store.expiredTickets;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          l.t('my_tickets_title'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // Tab Bar
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                // Tab 1: Active Tickets
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18),
                      const SizedBox(width: 6),
                      Text(lang == 'ar' ? 'نشطة' : (lang == 'fr' ? 'Actifs' : 'Active')),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          activeTickets.length.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Tab 2: Expired Tickets
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history, size: 18),
                      const SizedBox(width: 6),
                      Text(lang == 'ar' ? 'منتهية' : (lang == 'fr' ? 'Expirés' : 'Expired')),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textHint.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          expiredTickets.length.toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Active Tickets Tab
                _buildTicketsList(
                  tickets: activeTickets,
                  emptyMessage: lang == 'ar' ? 'لا توجد تذاكر نشطة' : (lang == 'fr' ? 'Aucun billet actif' : 'No active tickets'),
                  onQrTap: (ticket) {
                    _navigateToQR(context, ticket);
                  },
                ),

                // Expired Tickets Tab
                _buildTicketsList(
                  tickets: expiredTickets,
                  emptyMessage: lang == 'ar' ? 'لا توجد تذاكر منتهية' : (lang == 'fr' ? 'Aucun billet expiré' : 'No expired tickets'),
                  onQrTap: (ticket) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(lang == 'ar' ? 'انتهت صلاحية هذه التذكرة' : (lang == 'fr' ? 'Ce billet a expiré' : 'This ticket has expired')),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsList({
    required List<TicketInfo> tickets,
    required String emptyMessage,
    required Function(TicketInfo) onQrTap,
  }) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_activity_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, index) {
        final ticket = tickets[index];
        return _TicketCard(
          ticket: ticket,
          onQrTap: () => onQrTap(ticket),
        );
      },
    );
  }

  void _navigateToQR(BuildContext context, TicketInfo ticket) {
    Navigator.pushNamed(
      context,
      TicketQrScreen.route,
      arguments: TicketPayload(
        ticketId: ticket.id,
        matchTitle: ticket.match,
        matchDate: ticket.date,
        venue: 'Stadium',
        category: ticket.category,
        gate: ticket.gate,
        section: ticket.section,
        seat: ticket.seat,
      ),
    );
  }
}


class _TicketCard extends StatelessWidget {
  final TicketInfo ticket;
  final VoidCallback onQrTap;

  const _TicketCard({
    required this.ticket,
    required this.onQrTap,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleState>().locale.languageCode;
    final isActive = ticket.status == TicketStatus.active;
    
    final backgroundColor = isActive 
        ? AppColors.cardSuccessBg 
        : AppColors.cardErrorBg;
    
    final borderColor = isActive 
        ? AppColors.cardSuccessBorder 
        : AppColors.cardErrorBorder;
    
    final headerColor = isActive 
        ? AppColors.successGradient 
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD1D5DB), Color(0xFF9CA3AF)],
          );
    
    final statusLabel = isActive
        ? (lang == 'ar' ? '✓ صالحة' : (lang == 'fr' ? '✓ Valide' : '✓ Valid'))
        : (lang == 'ar' ? '✗ منتهية' : (lang == 'fr' ? '✗ Expirée' : '✗ Expired'));
    final statusColor = isActive ? AppColors.success : AppColors.textHint;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isActive 
                ? AppColors.success.withValues(alpha: 0.08) 
                : AppColors.textHint.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: headerColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(17),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.sports_soccer_rounded,
                    size: 22,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.match,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ticket.category,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            color: backgroundColor,
            child: Row(
              children: [
                Transform.translate(
                  offset: const Offset(-13, 0),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: borderColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (_, c) => Row(
                      children: List.generate(
                        (c.maxWidth / 8).floor(),
                        (_) => Expanded(
                          child: Container(
                            height: 1.5,
                            color: borderColor,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(13, 0),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: borderColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _DetailChip(
                      icon: Icons.event_seat_outlined,
                      label: lang == 'ar' ? 'المقعد' : (lang == 'fr' ? 'Siège' : 'Seat'),
                      value: ticket.seat,
                      color: isActive ? AppColors.success : AppColors.textHint,
                    ),
                    const SizedBox(width: 12),
                    _DetailChip(
                      icon: Icons.access_time_rounded,
                      label: lang == 'ar' ? 'التاريخ' : (lang == 'fr' ? 'Date' : 'Date'),
                      value: ticket.date,
                      color: isActive ? AppColors.primary : AppColors.textHint,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    _DetailChip(
                      icon: Icons.location_on_rounded,
                      label: lang == 'ar' ? 'البوابة' : (lang == 'fr' ? 'Porte' : 'Gate'),
                      value: ticket.gate,
                      color: isActive ? AppColors.info : AppColors.textHint,
                    ),
                    const SizedBox(width: 12),
                    _DetailChip(
                      icon: Icons.layers_rounded,
                      label: lang == 'ar' ? 'القسم' : (lang == 'fr' ? 'Section' : 'Section'),
                      value: ticket.section,
                      color: isActive ? AppColors.warning : AppColors.textHint,
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (isActive)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onQrTap,
                      icon: const Icon(Icons.qr_code_rounded, size: 18),
                      label: Text(lang == 'ar' ? 'عرض QR' : (lang == 'fr' ? 'QR Code' : 'Show QR')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(lang == 'ar' ? 'تم الأرشفة' : (lang == 'fr' ? 'Billet archivé' : 'Ticket archived')),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.archive_outlined, size: 18),
                      label: Text(lang == 'ar' ? 'أرشيف' : (lang == 'fr' ? 'Archiver' : 'Archive')),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.textHint,
                          width: 1.5,
                        ),
                        foregroundColor: AppColors.textHint,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                if (isActive)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/ticket-transfer',
                          arguments: TicketPayload(
                            ticketId: ticket.id,
                            matchTitle: ticket.match,
                            matchDate: ticket.date,
                            venue: 'Stadium',
                            category: ticket.category,
                            gate: ticket.gate,
                            section: ticket.section,
                            seat: ticket.seat,
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(lang == 'ar' ? 'تحويل' : (lang == 'fr' ? 'Transférer' : 'Transfer')),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: Text(lang == 'ar' ? 'تفاصيل' : (lang == 'fr' ? 'Détails' : 'Details')),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border, width: 1.5),
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



