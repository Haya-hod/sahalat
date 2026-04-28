import 'package:flutter/material.dart';
import '../../../domain/destination_parser.dart';

/// Unified destination input field with suggestion chips.
/// Supports facilities, sections, and seat format parsing.
class UnifiedDestinationInput extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<ParsedDestination> onDestinationChanged;
  final VoidCallback? onNavigate;

  const UnifiedDestinationInput({
    super.key,
    this.initialValue,
    required this.onDestinationChanged,
    this.onNavigate,
  });

  @override
  State<UnifiedDestinationInput> createState() => _UnifiedDestinationInputState();
}

class _UnifiedDestinationInputState extends State<UnifiedDestinationInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  List<DestinationSuggestion> _suggestions = [];
  ParsedDestination? _currentDestination;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _suggestions = DestinationParser.defaultSuggestions;

    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _parseInput(widget.initialValue!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  void _onInputChanged(String value) {
    _parseInput(value);
    _updateSuggestions(value);
  }

  void _parseInput(String value) {
    final result = DestinationParser.parse(value);
    setState(() {
      _currentDestination = result;
    });
    if (result.isValid) {
      widget.onDestinationChanged(result);
    }
  }

  void _updateSuggestions(String value) {
    setState(() {
      _suggestions = DestinationParser.getSuggestions(value);
    });
  }

  void _selectSuggestion(DestinationSuggestion suggestion) {
    _controller.text = suggestion.value;
    _parseInput(suggestion.value);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main input field
        _buildInputField(),

        const SizedBox(height: 10),

        // Quick suggestion chips
        _buildSuggestionChips(),

        // Seat format hint (shown when typing seat-like input)
        if (_currentDestination?.type == DestinationType.seat)
          _buildSeatPreview(),
      ],
    );
  }

  Widget _buildInputField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasFocus ? const Color(0xFF0D47A1) : Colors.grey.shade300,
          width: _hasFocus ? 2 : 1,
        ),
        boxShadow: _hasFocus
            ? [
                BoxShadow(
                  color: const Color(0xFF0D47A1).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              _getDestinationIcon(),
              color: const Color(0xFF0D47A1),
              size: 22,
            ),
          ),

          // Text field
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onInputChanged,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Where to? (e.g., Food Court, VIP Row 5 Seat 12)',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => widget.onNavigate?.call(),
            ),
          ),

          // Clear button
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close, color: Colors.grey.shade400, size: 20),
              onPressed: () {
                _controller.clear();
                _onInputChanged('');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _suggestions.map((suggestion) {
        final isSelected = _controller.text.toLowerCase() == suggestion.value.toLowerCase();
        return GestureDetector(
          onTap: () => _selectSuggestion(suggestion),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF0D47A1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF0D47A1)
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  suggestion.icon,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Text(
                  suggestion.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeatPreview() {
    final ticket = _currentDestination?.ticket;
    if (ticket == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.event_seat, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seat Detected',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${ticket.category} Section - Row ${ticket.section}, Seat ${ticket.seat}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              ticket.category,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDestinationIcon() {
    switch (_currentDestination?.type) {
      case DestinationType.facility:
        return Icons.place_rounded;
      case DestinationType.section:
        return Icons.stadium_rounded;
      case DestinationType.seat:
        return Icons.event_seat_rounded;
      default:
        return Icons.search_rounded;
    }
  }
}
