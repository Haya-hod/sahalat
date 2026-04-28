import 'package:flutter/material.dart';

/// Navigation destination modes.
enum DestinationMode {
  facilities,
  mySeat,
}

/// Extension for mode display names.
extension DestinationModeExtension on DestinationMode {
  String get displayName {
    switch (this) {
      case DestinationMode.facilities:
        return 'Facilities';
      case DestinationMode.mySeat:
        return 'My Seat';
    }
  }

  IconData get icon {
    switch (this) {
      case DestinationMode.facilities:
        return Icons.restaurant;
      case DestinationMode.mySeat:
        return Icons.event_seat;
    }
  }
}

/// Toggle widget for switching between navigation modes.
class DestinationModeToggle extends StatelessWidget {
  final DestinationMode selectedMode;
  final ValueChanged<DestinationMode> onModeChanged;

  const DestinationModeToggle({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: DestinationMode.values.map((mode) {
          final isSelected = mode == selectedMode;
          return Expanded(
            child: GestureDetector(
              onTap: () => onModeChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0D47A1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      mode.icon,
                      size: 18,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mode.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
