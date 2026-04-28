import 'stadium_layout.dart';
import 'stadium_models.dart';
import 'pathfinder.dart';
import 'facility_selector.dart';
import 'facility_capacity_model.dart';
import '../core/ticket_payload.dart';

/// Result of seat-based navigation.
class SeatNavigationResult {
  /// Graph path to the section (AR-compatible).
  final List<StadiumNode> graphPath;

  /// The ticket/seat information.
  final TicketPayload ticket;

  /// Local directions within the section.
  final String localDirections;

  /// Section node ID.
  final String sectionNodeId;

  /// Recommended nearby facilities.
  final List<FacilitySelectionResult> nearbyFacilities;

  SeatNavigationResult({
    required this.graphPath,
    required this.ticket,
    required this.localDirections,
    required this.sectionNodeId,
    required this.nearbyFacilities,
  });

  /// Whether navigation was successful.
  bool get isValid => graphPath.isNotEmpty;

  /// Section display name.
  String get sectionName => StadiumLayout.labelOf(sectionNodeId);
}

/// Handles seat-based navigation with hierarchical routing.
///
/// Routes to section node via graph, then generates local directions
/// without adding seat nodes to the main graph.
class SeatNavigator {
  SeatNavigator._();

  /// Navigate from a starting location to a seat.
  static SeatNavigationResult navigateToSeat({
    required String startNodeId,
    required TicketPayload ticket,
    bool useCongestion = true,
  }) {
    // Ensure models are initialized
    StadiumLayout.buildOnce();
    FacilityCapacityModel.initialize();

    // Map ticket category to section node
    final sectionNodeId = ticketCategoryToNodeId(ticket.category);
    final sectionNode = StadiumLayout.nodesById[sectionNodeId];
    final startNode = StadiumLayout.nodesById[startNodeId];

    if (sectionNode == null || startNode == null) {
      return SeatNavigationResult(
        graphPath: [],
        ticket: ticket,
        localDirections: 'Unable to find route',
        sectionNodeId: sectionNodeId,
        nearbyFacilities: [],
      );
    }

    // Find path to section
    final path = Pathfinder.findPath(
      graph: StadiumLayout.graph,
      start: startNode,
      end: sectionNode,
      useCongestion: useCongestion,
    );

    // Generate local directions
    final localDirections = generateLocalDirections(ticket);

    // Get recommended facilities near this section
    final nearbyFacilities = getRecommendedFacilities(
      sectionNodeId: sectionNodeId,
      maxResults: 3,
    );

    return SeatNavigationResult(
      graphPath: path,
      ticket: ticket,
      localDirections: localDirections,
      sectionNodeId: sectionNodeId,
      nearbyFacilities: nearbyFacilities,
    );
  }

  /// Map ticket category string to graph node ID.
  static String ticketCategoryToNodeId(String category) {
    final normalized = category.toLowerCase().trim();

    switch (normalized) {
      case 'vip':
      case 'v.i.p':
      case 'v.i.p.':
        return 'vip';
      case 'standard':
      case 'std':
      case 'regular':
      case 'general':
        return 'standard';
      default:
        // Default to standard for unknown categories
        return 'standard';
    }
  }

  /// Generate human-readable local directions within the section.
  static String generateLocalDirections(TicketPayload ticket) {
    final section = ticket.section;
    final seat = ticket.seat;

    // Parse seat number if available
    final seatNum = _parseSeatNumber(seat);
    final seatSide = _determineSeatSide(seatNum);

    // Build directions
    final buffer = StringBuffer();

    if (section.isNotEmpty) {
      buffer.write('Section $section');
    }

    if (seat.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(', ');
      buffer.write('Seat $seat');
    }

    if (seatSide.isNotEmpty) {
      buffer.write(' ($seatSide)');
    }

    if (buffer.isEmpty) {
      return 'Follow signs to your seat';
    }

    return buffer.toString();
  }

  /// Parse seat number from seat string.
  static int? _parseSeatNumber(String seat) {
    // Extract numbers from seat string (e.g., "R12-S8" -> 8)
    final match = RegExp(r'(\d+)$').firstMatch(seat);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }

    // Try parsing directly
    return int.tryParse(seat);
  }

  /// Determine which side of the section based on seat number.
  static String _determineSeatSide(int? seatNum) {
    if (seatNum == null) return '';

    // Simple heuristic: odd seats on left, even on right
    // Seats 1-10 near aisle, 11-20 middle, 21+ far side
    if (seatNum <= 10) {
      return seatNum.isOdd ? 'left aisle' : 'right aisle';
    } else if (seatNum <= 20) {
      return 'center section';
    } else {
      return seatNum.isOdd ? 'far left' : 'far right';
    }
  }

  /// Get recommended facilities near a section.
  static List<FacilitySelectionResult> getRecommendedFacilities({
    required String sectionNodeId,
    int maxResults = 3,
  }) {
    final results = <FacilitySelectionResult>[];

    // Get best food facility
    final foodResult = FacilitySelector.selectBest(
      startNodeId: sectionNodeId,
      facilityType: FacilityType.food,
    );
    results.add(foodResult);

    // Get best restroom
    final restroomResult = FacilitySelector.selectBest(
      startNodeId: sectionNodeId,
      facilityType: FacilityType.restroom,
    );
    results.add(restroomResult);

    return results.take(maxResults).toList();
  }

  /// Parse a seat string like "VIP-R12-S8" into a TicketPayload.
  static TicketPayload? parseSeatString(String input) {
    if (input.isEmpty) return null;

    // Try pattern: CATEGORY-ROW-SEAT (e.g., "VIP-R12-S8")
    final pattern = RegExp(r'^([A-Za-z]+)-?R?(\d+)-?S?(\d+)$', caseSensitive: false);
    final match = pattern.firstMatch(input.trim());

    if (match != null) {
      final category = match.group(1)?.toUpperCase() ?? 'STANDARD';
      final row = match.group(2) ?? '';
      final seat = match.group(3) ?? '';

      return TicketPayload(
        matchTitle: '',
        matchDate: '',
        venue: '',
        category: category,
        gate: 'A',
        section: 'R$row',
        seat: 'S$seat',
      );
    }

    // Try simpler pattern: CATEGORY only (e.g., "VIP", "STANDARD")
    final categoryOnly = input.toUpperCase().trim();
    if (categoryOnly == 'VIP' || categoryOnly == 'STANDARD') {
      return TicketPayload(
        matchTitle: '',
        matchDate: '',
        venue: '',
        category: categoryOnly,
        gate: 'A',
        section: '',
        seat: '',
      );
    }

    return null;
  }

  /// Validate a seat string format.
  static bool isValidSeatString(String input) {
    if (input.isEmpty) return false;

    // Accept patterns like: VIP-R12-S8, STANDARD-5-22, VIP, STANDARD
    final patterns = [
      RegExp(r'^[A-Za-z]+-?\d+-?\d+$'), // Full pattern
      RegExp(r'^(VIP|STANDARD|STD)$', caseSensitive: false), // Category only
    ];

    return patterns.any((p) => p.hasMatch(input.trim()));
  }
}
