import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/locale_state.dart';
import '../../core/strings.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../colors.dart';
import '../../core/ticket_payload.dart';

class TicketQrScreen extends StatelessWidget {
  static const route = '/ticket_qr';
  const TicketQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final payload =
        ModalRoute.of(context)?.settings.arguments as TicketPayload?;
    if (payload == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No ticket data')),
      );
    }
    final lang = context.watch<LocaleState>().locale.languageCode;
    final isAr = lang == 'ar';
    final isFr = lang == 'fr';

    final qrString = payload.ticketId ??
        payload.toMap().entries.map((e) => '${e.key}:${e.value}').join('\n');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(L(context.watch<LocaleState>().locale.languageCode).t('my_ticket'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.sports_soccer_rounded, color: Colors.white70, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    payload.matchTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${payload.matchDate}  •  ${payload.venue}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                  ),
                ],
              ),
            ),

            // QR section
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: qrString,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAr ? 'امسح عند المدخل' : (isFr ? 'Scanner à l\'entrée' : 'Scan at the entrance'),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Tear line
            _TearLine(),

            // Details section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _DetailChip(label: isAr ? 'الفئة'    : (isFr ? 'Catégorie' : 'Category'), value: payload.category, icon: Icons.category_outlined),
                      const SizedBox(width: 12),
                      _DetailChip(label: isAr ? 'البوابة'  : (isFr ? 'Porte'     : 'Gate'),     value: payload.gate,     icon: Icons.door_sliding_outlined),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _DetailChip(label: isAr ? 'القسم'    : (isFr ? 'Section'   : 'Section'), value: payload.section, icon: Icons.grid_view_outlined),
                      const SizedBox(width: 12),
                      _DetailChip(label: isAr ? 'المقعد'   : (isFr ? 'Siège'     : 'Seat'),    value: payload.seat,     icon: Icons.event_seat_outlined),
                    ],
                  ),

                  if (payload.ticketId != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'ID: ${payload.ticketId}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Valid badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.greenPale,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_outlined, color: AppColors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'تذكرة صالحة' : (isFr ? 'Billet valide' : 'Valid Ticket'),
                    style: const TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TearLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Row(
        children: [
          Transform.translate(
            offset: const Offset(-14, 0),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (_, c) => Row(
                children: List.generate(
                  (c.maxWidth / 8).floor(),
                  (_) => Expanded(
                    child: Container(height: 1, color: AppColors.border),
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(14, 0),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _DetailChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint,
                      fontWeight: FontWeight.w500)),
                Text(value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
