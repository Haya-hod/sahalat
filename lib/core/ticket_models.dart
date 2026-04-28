/// Represents the validity state of a ticket.
enum TicketStatus { active, expired }

/// Holds all display data for a single ticket.
class TicketInfo {
  final String id;
  final String match;
  final String seat;
  final String date;
  final String category;
  final String gate;
  final String section;
  final TicketStatus status;

  TicketInfo({
    required this.id,
    required this.match,
    required this.seat,
    required this.date,
    required this.category,
    required this.gate,
    required this.section,
    required this.status,
  });
}
