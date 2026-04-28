import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Seat details data class.
class SeatDetails {
  final int? row;
  final int? seat;

  const SeatDetails({this.row, this.seat});

  bool get isComplete => row != null && seat != null && row! > 0 && seat! > 0;
  bool get isEmpty => row == null && seat == null;

  SeatDetails copyWith({int? row, int? seat}) {
    return SeatDetails(
      row: row ?? this.row,
      seat: seat ?? this.seat,
    );
  }
}

/// Animated seat details input that expands when visible.
class AnimatedSeatDetails extends StatefulWidget {
  final bool isVisible;
  final String sectionName;
  final Color accentColor;
  final ValueChanged<SeatDetails> onChanged;

  const AnimatedSeatDetails({
    super.key,
    required this.isVisible,
    required this.sectionName,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  State<AnimatedSeatDetails> createState() => _AnimatedSeatDetailsState();
}

class _AnimatedSeatDetailsState extends State<AnimatedSeatDetails>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sizeAnimation;

  final _rowController = TextEditingController();
  final _seatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _sizeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (widget.isVisible) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedSeatDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
        // Clear inputs when hidden
        _rowController.clear();
        _seatController.clear();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _rowController.dispose();
    _seatController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    final row = int.tryParse(_rowController.text);
    final seat = int.tryParse(_seatController.text);
    widget.onChanged(SeatDetails(row: row, seat: seat));
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _sizeAnimation,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.accentColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.accentColor.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.event_seat_rounded,
                    size: 16,
                    color: widget.accentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Seat Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.accentColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(optional)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Row and Seat inputs
              Row(
                children: [
                  Expanded(
                    child: _buildNumberInput(
                      controller: _rowController,
                      label: 'Row',
                      hint: '1-20',
                      maxValue: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumberInput(
                      controller: _seatController,
                      label: 'Seat',
                      hint: '1-30',
                      maxValue: 30,
                    ),
                  ),
                ],
              ),
              // Helper text
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Leave empty to navigate to ${widget.sectionName} entrance',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _MaxValueFormatter(maxValue),
            ],
            onChanged: (_) => _onInputChanged(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
      ],
    );
  }
}

/// Formatter to limit input to max value
class _MaxValueFormatter extends TextInputFormatter {
  final int maxValue;

  _MaxValueFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final value = int.tryParse(newValue.text);
    if (value == null) return oldValue;

    if (value > maxValue) {
      return TextEditingValue(
        text: maxValue.toString(),
        selection: TextSelection.collapsed(offset: maxValue.toString().length),
      );
    }

    if (value < 1 && newValue.text.isNotEmpty) {
      return const TextEditingValue(
        text: '1',
        selection: TextSelection.collapsed(offset: 1),
      );
    }

    return newValue;
  }
}
