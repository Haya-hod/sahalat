import 'package:flutter/foundation.dart';

import 'ticket_models.dart';

/// In-memory store for the user's tickets.
/// Seed data is used until Firestore persistence is wired up.
class TicketStore extends ChangeNotifier {
  final List<TicketInfo> _tickets = [
    TicketInfo(
      id: '1',
      match: 'Team A vs Team B',
      seat: 'A-14',
      date: 'Nov 12, 20:30',
      category: 'Standard',
      gate: 'Gate A',
      section: 'A',
      status: TicketStatus.active,
    ),
    TicketInfo(
      id: '2',
      match: 'Team E vs Team F',
      seat: 'C-05',
      date: 'Nov 18, 19:00',
      category: 'VIP',
      gate: 'Gate C',
      section: 'C',
      status: TicketStatus.active,
    ),
    TicketInfo(
      id: '3',
      match: 'Team C vs Team D',
      seat: 'B-22',
      date: 'Nov 14, 18:00',
      category: 'Standard',
      gate: 'Gate B',
      section: 'B',
      status: TicketStatus.expired,
    ),
    TicketInfo(
      id: '4',
      match: 'Team G vs Team H',
      seat: 'D-10',
      date: 'Oct 30, 20:00',
      category: 'Standard',
      gate: 'Gate D',
      section: 'D',
      status: TicketStatus.expired,
    ),
  ];

  List<TicketInfo> get activeTickets =>
      _tickets.where((t) => t.status == TicketStatus.active).toList();

  List<TicketInfo> get expiredTickets =>
      _tickets.where((t) => t.status == TicketStatus.expired).toList();

  void addTicket({
    required String match,
    required String category,
    required String gate,
    required String section,
    required String seat,
    required String date,
  }) {
    _tickets.insert(
      0,
      TicketInfo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        match: match,
        seat: seat,
        date: date,
        category: category,
        gate: gate,
        section: section,
        status: TicketStatus.active,
      ),
    );
    notifyListeners();
  }
}
