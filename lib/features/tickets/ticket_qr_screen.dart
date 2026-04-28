import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/ticket_payload.dart';

class TicketQrScreen extends StatelessWidget {
  static const route = '/ticket_qr';
  const TicketQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final payload =
        ModalRoute.of(context)!.settings.arguments as TicketPayload;

    // 🔥 QR يحتوي ticketId إذا موجود (أفضل للأدمن)
    // 🔁 fallback: كل بيانات التذكرة لو ما فيه ticketId
    final qrString = payload.ticketId ??
        payload.toMap().entries
            .map((e) => '${e.key}:${e.value}')
            .join('\n');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket QR'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(
              data: qrString,
              size: 240,
              backgroundColor: Colors.white,
            ),

            const SizedBox(height: 20),

            Text(
              payload.matchTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('${payload.matchDate} • ${payload.venue}'),

            const SizedBox(height: 12),

            Text('Category: ${payload.category}'),
            Text('Gate: ${payload.gate}'),
            Text('Section: ${payload.section}'),
            Text('Seat: ${payload.seat}'),

            if (payload.ticketId != null) ...[
              const SizedBox(height: 12),
              Text(
                'Ticket ID: ${payload.ticketId}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
