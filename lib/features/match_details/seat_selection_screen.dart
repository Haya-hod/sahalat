import 'package:flutter/material.dart';
import '../payment/payment_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
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
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  String? _selectedSection;

  String _getPrice() {
    switch (widget.category) {
      case 'VIP':      return 'SAR 850';
      case 'Premium':  return 'SAR 450';
      case 'Family':   return 'SAR 350';
      default:         return 'SAR 250';
    }
  }

  void _confirmAndPay(BuildContext context, String sec) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Seat'),
        content: Text('Section: $sec\nCategory: ${widget.category}\nGate: ${widget.gate}\nPrice: ${_getPrice()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                PaymentScreen.route,
                arguments: {
                  'title': widget.match,
                  'section': widget.category,
                  'price': _getPrice(),
                },
              );
            },
            child: const Text('Proceed to Payment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.category} Sections')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.match,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text('Gate: ${widget.gate}'),
          const SizedBox(height: 20),
          const Text(
            'Select Section',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.sections.map((sec) {
              final isSelected = _selectedSection == sec.toString();
              return ChoiceChip(
                label: Text('Section $sec'),
                selected: isSelected,
                selectedColor: widget.color.withValues(alpha: 0.3),
                onSelected: (_) {
                  setState(() => _selectedSection = sec.toString());
                },
              );
            }).toList(),
          ),
          if (_selectedSection != null) ...[
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _confirmAndPay(context, _selectedSection!),
              icon: const Icon(Icons.payment_rounded),
              label: Text('Book Section $_selectedSection — ${_getPrice()}'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
