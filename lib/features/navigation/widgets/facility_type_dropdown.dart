import 'package:flutter/material.dart';
import '../../../domain/facility_capacity_model.dart';

/// Dropdown widget for selecting facility type.
class FacilityTypeDropdown extends StatelessWidget {
  final FacilityType? selectedType;
  final ValueChanged<FacilityType?> onChanged;

  const FacilityTypeDropdown({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.category,
            color: Color(0xFF0D47A1),
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<FacilityType>(
            value: selectedType,
            decoration: InputDecoration(
              labelText: 'Facility Type',
              labelStyle: const TextStyle(fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: FacilityType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(
                      type == FacilityType.food
                          ? Icons.restaurant
                          : Icons.wc,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(type.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
