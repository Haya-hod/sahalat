import 'package:flutter/material.dart';

class SeatSelectionScreen extends StatelessWidget {
  final String match;
  final String category;
  final String gate;
  final List sections;
  final Color color;

  const SeatSelectionScreen({
    super.key,
    required this.match,
    required this.category,
    required this.gate,
    required this.sections,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$category Sections')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            match,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text("Gate: $gate"),
          const SizedBox(height: 20),

          const Text(
            "Select Section",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: sections.map((sec) {
              return ChoiceChip(
                label: Text("Section $sec"),
                selected: false,
                selectedColor: color.withOpacity(.3),
                onSelected: (_) {
                  _openSeatDialog(context, sec);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _openSeatDialog(BuildContext context, String sec) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Ticket"),
        content: Text("Section: $sec\nCategory: $category\nGate: $gate"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Section $sec Reserved ✔")),
              );
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}
