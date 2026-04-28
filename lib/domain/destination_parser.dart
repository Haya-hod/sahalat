import '../core/ticket_payload.dart';
import 'facility_capacity_model.dart';

/// Types of destinations that can be parsed from user input.
enum DestinationType {
  facility,  // Food Court, Restroom
  section,   // VIP, Standard
  seat,      // VIP Row 12 Seat 8
}

/// Result of parsing a destination string.
class ParsedDestination {
  final DestinationType type;
  final String? nodeId;
  final FacilityType? facilityType;
  final TicketPayload? ticket;
  final String displayName;

  const ParsedDestination({
    required this.type,
    this.nodeId,
    this.facilityType,
    this.ticket,
    required this.displayName,
  });

  bool get isValid => nodeId != null || facilityType != null || ticket != null;
}

/// Parses user input to determine destination type and details.
class DestinationParser {
  // Facility keyword mappings
  static const _facilityKeywords = {
    'food': FacilityType.food,
    'food court': FacilityType.food,
    'restaurant': FacilityType.food,
    'eat': FacilityType.food,
    'snack': FacilityType.food,
    'restroom': FacilityType.restroom,
    'bathroom': FacilityType.restroom,
    'toilet': FacilityType.restroom,
    'wc': FacilityType.restroom,
  };

  // Section keyword mappings
  static const _sectionKeywords = {
    'vip': 'vip',
    'vip section': 'vip',
    'standard': 'standard',
    'standard section': 'standard',
    'general': 'standard',
  };

  // Direct node ID mappings
  static const _directNodeMappings = {
    'food court': 'foodCourt',
    'food court 1': 'food1',
    'food court 2': 'food2',
    'food court 3': 'food3',
    'restroom': 'restroom',
    'restroom 1': 'wc1',
    'restroom 2': 'wc2',
    'restroom 3': 'wc3',
    'vip': 'vip',
    'vip section': 'vip',
    'standard': 'standard',
    'standard section': 'standard',
  };

  /// Parses a destination string and returns the parsed result.
  static ParsedDestination parse(String input) {
    final normalized = input.trim().toLowerCase();

    if (normalized.isEmpty) {
      return const ParsedDestination(
        type: DestinationType.facility,
        displayName: '',
      );
    }

    // Try to parse as seat format first: "VIP Row 12 Seat 8"
    final seatResult = _parseSeatFormat(normalized);
    if (seatResult != null) {
      return seatResult;
    }

    // Try direct node mapping
    if (_directNodeMappings.containsKey(normalized)) {
      final nodeId = _directNodeMappings[normalized]!;
      final type = _sectionKeywords.containsKey(normalized)
          ? DestinationType.section
          : DestinationType.facility;
      return ParsedDestination(
        type: type,
        nodeId: nodeId,
        displayName: _formatDisplayName(input),
      );
    }

    // Try section keywords
    for (final entry in _sectionKeywords.entries) {
      if (normalized.contains(entry.key)) {
        return ParsedDestination(
          type: DestinationType.section,
          nodeId: entry.value,
          displayName: _formatDisplayName(input),
        );
      }
    }

    // Try facility keywords
    for (final entry in _facilityKeywords.entries) {
      if (normalized.contains(entry.key)) {
        return ParsedDestination(
          type: DestinationType.facility,
          facilityType: entry.value,
          displayName: _formatDisplayName(input),
        );
      }
    }

    // No match found - return as-is
    return ParsedDestination(
      type: DestinationType.facility,
      displayName: input,
    );
  }

  /// Parses seat format like "VIP Row 12 Seat 8" or "Standard R5 S10"
  static ParsedDestination? _parseSeatFormat(String normalized) {
    // Pattern: category + row + seat
    // Examples: "vip row 12 seat 8", "standard r5 s10", "vip 12-8"

    // Determine category
    String category = 'standard';
    if (normalized.contains('vip')) {
      category = 'VIP';
    } else if (normalized.contains('standard') || normalized.contains('general')) {
      category = 'Standard';
    } else {
      // No category mentioned, not a seat format
      return null;
    }

    // Extract row number
    final rowPatterns = [
      RegExp(r'row\s*(\d+)', caseSensitive: false),
      RegExp(r'r(\d+)', caseSensitive: false),
    ];

    int? row;
    for (final pattern in rowPatterns) {
      final match = pattern.firstMatch(normalized);
      if (match != null) {
        row = int.tryParse(match.group(1)!);
        break;
      }
    }

    // Extract seat number
    final seatPatterns = [
      RegExp(r'seat\s*(\d+)', caseSensitive: false),
      RegExp(r's(\d+)', caseSensitive: false),
      RegExp(r'-(\d+)$'), // For format like "12-8"
    ];

    int? seat;
    for (final pattern in seatPatterns) {
      final match = pattern.firstMatch(normalized);
      if (match != null) {
        seat = int.tryParse(match.group(1)!);
        break;
      }
    }

    // Need both row and seat for a valid seat format
    if (row == null || seat == null) {
      return null;
    }

    // Clamp values to valid range
    row = row.clamp(1, 20);
    seat = seat.clamp(1, 30);

    final ticket = TicketPayload(
      matchTitle: '',
      matchDate: '',
      venue: '',
      category: category,
      gate: 'A',
      section: '$row',
      seat: '$seat',
    );

    return ParsedDestination(
      type: DestinationType.seat,
      ticket: ticket,
      displayName: '$category Row $row Seat $seat',
    );
  }

  static String _formatDisplayName(String input) {
    // Capitalize first letter of each word
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Returns suggestions based on partial input.
  static List<DestinationSuggestion> getSuggestions(String input) {
    final normalized = input.trim().toLowerCase();
    final suggestions = <DestinationSuggestion>[];

    if (normalized.isEmpty) {
      // Return default suggestions
      return defaultSuggestions;
    }

    // Filter suggestions based on input
    for (final suggestion in allSuggestions) {
      if (suggestion.label.toLowerCase().contains(normalized) ||
          suggestion.keywords.any((k) => k.contains(normalized))) {
        suggestions.add(suggestion);
      }
    }

    return suggestions.take(6).toList();
  }

  /// Default quick suggestions.
  static const defaultSuggestions = [
    DestinationSuggestion(
      label: 'Food Court',
      icon: '🍔',
      value: 'Food Court',
      keywords: ['food', 'eat', 'restaurant'],
    ),
    DestinationSuggestion(
      label: 'Restroom',
      icon: '🚻',
      value: 'Restroom',
      keywords: ['wc', 'bathroom', 'toilet'],
    ),
    DestinationSuggestion(
      label: 'VIP Section',
      icon: '⭐',
      value: 'VIP',
      keywords: ['vip', 'premium'],
    ),
    DestinationSuggestion(
      label: 'Standard',
      icon: '🎫',
      value: 'Standard',
      keywords: ['standard', 'general'],
    ),
  ];

  static const allSuggestions = [
    ...defaultSuggestions,
    DestinationSuggestion(
      label: 'Food Court 1',
      icon: '🍔',
      value: 'Food Court 1',
      keywords: ['food1'],
    ),
    DestinationSuggestion(
      label: 'Food Court 2',
      icon: '🍕',
      value: 'Food Court 2',
      keywords: ['food2'],
    ),
    DestinationSuggestion(
      label: 'Food Court 3',
      icon: '🌭',
      value: 'Food Court 3',
      keywords: ['food3'],
    ),
    DestinationSuggestion(
      label: 'Restroom 1',
      icon: '🚻',
      value: 'Restroom 1',
      keywords: ['wc1'],
    ),
    DestinationSuggestion(
      label: 'Restroom 2',
      icon: '🚻',
      value: 'Restroom 2',
      keywords: ['wc2'],
    ),
    DestinationSuggestion(
      label: 'Restroom 3',
      icon: '🚻',
      value: 'Restroom 3',
      keywords: ['wc3'],
    ),
  ];
}

/// A destination suggestion for quick selection.
class DestinationSuggestion {
  final String label;
  final String icon;
  final String value;
  final List<String> keywords;

  const DestinationSuggestion({
    required this.label,
    required this.icon,
    required this.value,
    this.keywords = const [],
  });
}
