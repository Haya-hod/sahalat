import 'package:flutter/material.dart';

class SeatPage extends StatelessWidget {
  final String match;
  final String category;
  final String section;

  const SeatPage({
    super.key,
    required this.match,
    required this.category,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final seats = List.generate(
      30,
      (i) => "Row ${i ~/ 6 + 1} - Seat ${i % 6 + 1}",
    );

    return Scaffold(
      appBar: AppBar(title: Text("$section Seats")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(match, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("Category: $category"),
          Text("Section: $section"),
          const SizedBox(height: 20),

          const Text("Select Your Seat",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: seats.map((seat) {
              return ChoiceChip(
                label: Text(seat),
                selected: false,
                onSelected: (_) => _confirmSeat(context, seat),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  void _confirmSeat(BuildContext context, String seat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Ticket"),
        content: Text("Category: $category\nSection: $section\nSeat: $seat"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Ticket Added ✔")),
              );
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}