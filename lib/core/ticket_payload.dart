class TicketPayload {
  final String? ticketId; // ✅ جديد

  final String matchTitle;
  final String matchDate;
  final String venue;

  final String category;
  final String gate;
  final String section;
  final String seat;

  TicketPayload({
    this.ticketId,
    required this.matchTitle,
    required this.matchDate,
    required this.venue,
    required this.category,
    required this.gate,
    required this.section,
    required this.seat,
  });

  TicketPayload copyWith({String? ticketId}) => TicketPayload(
        ticketId: ticketId ?? this.ticketId,
        matchTitle: matchTitle,
        matchDate: matchDate,
        venue: venue,
        category: category,
        gate: gate,
        section: section,
        seat: seat,
      );

  Map<String, dynamic> toMap() => {
        'ticketId': ticketId,
        'matchTitle': matchTitle,
        'matchDate': matchDate,
        'venue': venue,
        'category': category,
        'gate': gate,
        'section': section,
        'seat': seat,
      };
}
