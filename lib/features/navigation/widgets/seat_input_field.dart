import 'package:flutter/material.dart';
import '../../../core/ticket_payload.dart';

/// Widget for entering seat information.
/// Supports both text input and dropdown mode.
class SeatInputField extends StatefulWidget {
  final ValueChanged<TicketPayload?> onSeatChanged;
  final TicketPayload? initialTicket;

  const SeatInputField({
    super.key,
    required this.onSeatChanged,
    this.initialTicket,
  });

  @override
  State<SeatInputField> createState() => _SeatInputFieldState();
}

class _SeatInputFieldState extends State<SeatInputField> {
  String _selectedCategory = 'VIP';
  final TextEditingController _rowController = TextEditingController();
  final TextEditingController _seatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialTicket != null) {
      _selectedCategory = widget.initialTicket!.category;
      // Extract row number from section (e.g., "R12" -> "12")
      final rowMatch = RegExp(r'\d+').firstMatch(widget.initialTicket!.section);
      if (rowMatch != null) {
        _rowController.text = rowMatch.group(0) ?? '';
      }
      // Extract seat number from seat (e.g., "S8" -> "8")
      final seatMatch = RegExp(r'\d+').firstMatch(widget.initialTicket!.seat);
      if (seatMatch != null) {
        _seatController.text = seatMatch.group(0) ?? '';
      }
    }
  }

  @override
  void dispose() {
    _rowController.dispose();
    _seatController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final row = _rowController.text.trim();
    final seat = _seatController.text.trim();

    if (row.isEmpty && seat.isEmpty) {
      // At least category is selected
      widget.onSeatChanged(TicketPayload(
        matchTitle: '',
        matchDate: '',
        venue: '',
        category: _selectedCategory,
        gate: 'A',
        section: '',
        seat: '',
      ));
      return;
    }

    widget.onSeatChanged(TicketPayload(
      matchTitle: '',
      matchDate: '',
      venue: '',
      category: _selectedCategory,
      gate: 'A',
      section: row.isNotEmpty ? 'R$row' : '',
      seat: seat.isNotEmpty ? 'S$seat' : '',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category dropdown
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.confirmation_number,
                color: Color(0xFF0D47A1),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Ticket Category',
                  labelStyle: const TextStyle(fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'VIP',
                    child: Row(
                      children: [
                        Icon(Icons.star, size: 18, color: Colors.amber),
                        SizedBox(width: 8),
                        Text('VIP Section'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'STANDARD',
                    child: Row(
                      children: [
                        Icon(Icons.event_seat, size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Standard Section'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                    _notifyChange();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row and Seat inputs
        Row(
          children: [
            // Row input
            Expanded(
              child: TextFormField(
                controller: _rowController,
                decoration: InputDecoration(
                  labelText: 'Row',
                  hintText: 'e.g., 12',
                  labelStyle: const TextStyle(fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                  prefixIcon: const Icon(Icons.table_rows, size: 18),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _notifyChange(),
              ),
            ),
            const SizedBox(width: 12),

            // Seat input
            Expanded(
              child: TextFormField(
                controller: _seatController,
                decoration: InputDecoration(
                  labelText: 'Seat',
                  hintText: 'e.g., 8',
                  labelStyle: const TextStyle(fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                  prefixIcon: const Icon(Icons.event_seat, size: 18),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _notifyChange(),
              ),
            ),
          ],
        ),

        // Preview
        if (_rowController.text.isNotEmpty || _seatController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your seat: $_selectedCategory Section, '
                      '${_rowController.text.isNotEmpty ? "Row ${_rowController.text}" : ""}'
                      '${_rowController.text.isNotEmpty && _seatController.text.isNotEmpty ? ", " : ""}'
                      '${_seatController.text.isNotEmpty ? "Seat ${_seatController.text}" : ""}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
