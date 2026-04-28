import 'package:flutter/material.dart';

/// Destination types for the chip selector.
enum DestinationOption {
  vip,
  standard,
  foodCourt,
  restroom,
}

extension DestinationOptionExt on DestinationOption {
  String get label {
    switch (this) {
      case DestinationOption.vip:
        return 'VIP Section';
      case DestinationOption.standard:
        return 'Standard';
      case DestinationOption.foodCourt:
        return 'Food Court';
      case DestinationOption.restroom:
        return 'Restroom';
    }
  }

  String get shortLabel {
    switch (this) {
      case DestinationOption.vip:
        return 'VIP';
      case DestinationOption.standard:
        return 'Standard';
      case DestinationOption.foodCourt:
        return 'Food';
      case DestinationOption.restroom:
        return 'Restroom';
    }
  }

  IconData get icon {
    switch (this) {
      case DestinationOption.vip:
        return Icons.star_rounded;
      case DestinationOption.standard:
        return Icons.event_seat_rounded;
      case DestinationOption.foodCourt:
        return Icons.restaurant_rounded;
      case DestinationOption.restroom:
        return Icons.wc_rounded;
    }
  }

  String get nodeId {
    switch (this) {
      case DestinationOption.vip:
        return 'vip';
      case DestinationOption.standard:
        return 'standard';
      case DestinationOption.foodCourt:
        return 'foodCourt';
      case DestinationOption.restroom:
        return 'restroom';
    }
  }

  bool get isSeatSection {
    return this == DestinationOption.vip || this == DestinationOption.standard;
  }

  Color get accentColor {
    switch (this) {
      case DestinationOption.vip:
        return const Color(0xFFFFB300); // Amber
      case DestinationOption.standard:
        return const Color(0xFF0D47A1); // Blue
      case DestinationOption.foodCourt:
        return const Color(0xFFE65100); // Orange
      case DestinationOption.restroom:
        return const Color(0xFF00897B); // Teal
    }
  }
}

/// A chip-based destination selector for navigation.
class DestinationChipSelector extends StatelessWidget {
  final DestinationOption? selected;
  final ValueChanged<DestinationOption> onSelected;

  const DestinationChipSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            'Destination',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        // Chips in a 2x2 grid
        Row(
          children: [
            Expanded(child: _buildChip(DestinationOption.vip)),
            const SizedBox(width: 8),
            Expanded(child: _buildChip(DestinationOption.standard)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildChip(DestinationOption.foodCourt)),
            const SizedBox(width: 8),
            Expanded(child: _buildChip(DestinationOption.restroom)),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(DestinationOption option) {
    final isSelected = selected == option;
    final color = option.accentColor;

    return GestureDetector(
      onTap: () => onSelected(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              option.icon,
              size: 18,
              color: isSelected ? color : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              option.shortLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
