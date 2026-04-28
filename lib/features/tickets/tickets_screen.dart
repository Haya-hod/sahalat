import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/locale_state.dart';
import '../../core/strings.dart';
import '../../core/ticket_payload.dart';

import 'ticket_qr_screen.dart';

class TicketsScreen extends StatelessWidget {
  static const route = '/tickets';
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleState>().locale.languageCode;
    final l = L(lang);

    // ⚠️ بيانات ثابتة مؤقتًا (لين نربط Firestore)
    final tickets = [
      {'match': 'Team A vs Team B', 'seat': 'A-14', 'date': 'Nov 12, 20:30'},
      {'match': 'Team C vs Team D', 'seat': 'B-22', 'date': 'Nov 14, 18:00'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(l.t('my_tickets_title')),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final t = tickets[i];

          return Card(
            color: const Color(0xFFF0F8F2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: const Icon(Icons.confirmation_number, size: 28),
              title: Text(t['match']!),
              subtitle: Text('${t['date']} • Seat ${t['seat']}'),
              trailing: TextButton(
                onPressed: () {
                  // ✅ نرسل TicketPayload بدل Map
                  final payload = TicketPayload(
                    ticketId: null, // تذاكر ثابتة (مو من Firestore)
                    matchTitle: t['match']!,
                    matchDate: t['date']!,
                    venue: 'Stadium',
                    category: 'Standard',
                    gate: 'Gate A',
                    section: t['seat']!.split('-').first,
                    seat: t['seat']!,
                  );

                  Navigator.pushNamed(
                    context,
                    TicketQrScreen.route,
                    arguments: payload,
                  );
                },
                child: Text(
                  l.t('show_qr'),
                  style: const TextStyle(color: Color(0xFF0D47A1)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
