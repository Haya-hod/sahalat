import '../../domain/stadium_models.dart';
import '../../domain/stadium_layout.dart';

/// Builds human-friendly navigation instructions based on context.
///
/// This class generates dynamic, destination-aware direction text for each
/// step in the navigation path. Instructions vary based on:
/// - Node type (gate, concourse, section, poi)
/// - Position in path (first, middle, last)
/// - The selected destination
/// - The next node in the path (for directional context)
class InstructionBuilder {
  InstructionBuilder._();

  /// Builds a context-aware instruction for a navigation step.
  ///
  /// Parameters:
  /// - [node]: The current node in the path
  /// - [destination]: The final destination node
  /// - [isFirst]: Whether this is the starting point
  /// - [isLast]: Whether this is the final destination
  /// - [next]: Optional next node (for directional hints)
  static String build({
    required StadiumNode node,
    required StadiumNode destination,
    required bool isFirst,
    required bool isLast,
    StadiumNode? next,
  }) {
    final label = _getNodeLabel(node.id);
    final destLabel = _getNodeLabel(destination.id);

    // Final destination - arrival message
    if (isLast) {
      return _buildArrivalMessage(node, destLabel);
    }

    // Starting point
    if (isFirst) {
      return _buildStartMessage(node, label, next);
    }

    // Middle steps
    return _buildMiddleMessage(node, label, destination, next);
  }

  /// Builds the arrival message for the final destination.
  static String _buildArrivalMessage(StadiumNode node, String destLabel) {
    switch (node.type) {
      case NodeType.section:
        if (node.id == 'vip') {
          return 'Welcome to the VIP Section!';
        }
        return 'You\'ve arrived at the $destLabel!';
      case NodeType.poi:
        if (node.id == 'restroom' || node.id.startsWith('wc')) {
          return 'You\'ve arrived at the $destLabel.';
        }
        if (node.id == 'foodCourt' || node.id.startsWith('food')) {
          return 'Welcome to the $destLabel!';
        }
        return 'You\'ve arrived at $destLabel.';
      default:
        return 'You\'ve arrived at $destLabel.';
    }
  }

  /// Builds the starting message.
  static String _buildStartMessage(
      StadiumNode node, String label, StadiumNode? next) {
    String direction = '';
    if (next != null) {
      final nextLabel = _getNodeLabel(next.id);
      // Check if heading to ring walkway
      if (_isRingNode(next.id)) {
        direction = ' and head to the ring walkway';
      } else {
        direction = ' and head towards $nextLabel';
      }
    }

    switch (node.type) {
      case NodeType.gate:
        return 'Start at $label$direction.';
      default:
        return 'Begin at $label$direction.';
    }
  }

  /// Builds instruction for middle steps.
  static String _buildMiddleMessage(
    StadiumNode node,
    String label,
    StadiumNode destination,
    StadiumNode? next,
  ) {
    final destLabel = _getNodeLabel(destination.id);

    // Handle ring walkway nodes
    if (_isRingNode(node.id)) {
      final direction = _getRingDirection(node.id);
      if (next != null && _isRingNode(next.id)) {
        // Moving along the ring
        final nextDir = _getRingDirection(next.id);
        return 'Follow ring walkway $direction towards $nextDir.';
      } else if (next != null) {
        // Exiting ring to destination
        return 'Exit ring walkway $direction towards $destLabel.';
      }
      return 'Continue along ring walkway $direction.';
    }

    switch (node.type) {
      case NodeType.concourse:
        if (next != null && _isRingNode(next.id)) {
          return 'From Main Concourse, head to ring walkway.';
        }
        return 'Walk through the Main Concourse towards $destLabel.';

      case NodeType.section:
        return 'Continue past the $label.';

      case NodeType.poi:
        return 'Pass by the $label.';

      case NodeType.gate:
        return 'Continue past $label.';
    }
  }

  /// Checks if a node ID is a ring walkway node.
  static bool _isRingNode(String id) {
    return id == 'ringN' || id == 'ringE' || id == 'ringS' || id == 'ringW';
  }

  /// Gets a direction description for a ring node.
  static String _getRingDirection(String id) {
    switch (id) {
      case 'ringN':
        return '(North)';
      case 'ringE':
        return '(East)';
      case 'ringS':
        return '(South)';
      case 'ringW':
        return '(West)';
      default:
        return '';
    }
  }

  /// Converts node ID to human-readable label.
  static String _getNodeLabel(String id) {
    // Use StadiumLayout.labelOf if available, with fallback
    final label = StadiumLayout.labelOf(id);
    if (label != id) return label;

    // Fallback mappings
    switch (id) {
      case 'gateA':
        return 'Gate A';
      case 'gateB':
        return 'Gate B';
      case 'gateC':
        return 'Gate C';
      case 'gateD':
        return 'Gate D';
      case 'concourseMain':
        return 'Main Concourse';
      case 'ringN':
        return 'North Ring';
      case 'ringE':
        return 'East Ring';
      case 'ringS':
        return 'South Ring';
      case 'ringW':
        return 'West Ring';
      case 'vip':
        return 'VIP Section';
      case 'standard':
        return 'Standard Section';
      case 'restroom':
        return 'Restrooms';
      case 'foodCourt':
        return 'Food Court';
      // Phase 5 facilities
      case 'food1':
        return 'Food Court 1';
      case 'food2':
        return 'Food Court 2';
      case 'food3':
        return 'Food Court 3';
      case 'wc1':
        return 'Restroom 1';
      case 'wc2':
        return 'Restroom 2';
      case 'wc3':
        return 'Restroom 3';
      default:
        return id;
    }
  }

  /// Gets an icon for the node type (for use in UI).
  static String getEmoji(StadiumNode node, bool isFirst, bool isLast) {
    if (isLast) return '🏁';
    if (isFirst) return '🚪';

    // Ring nodes
    if (_isRingNode(node.id)) return '🔄';

    switch (node.type) {
      case NodeType.gate:
        return '🚪';
      case NodeType.concourse:
        return '🚶';
      case NodeType.section:
        return '🎫';
      case NodeType.poi:
        return '📍';
    }
  }
}
