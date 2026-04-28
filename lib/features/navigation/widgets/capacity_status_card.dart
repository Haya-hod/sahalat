import 'package:flutter/material.dart';
import '../../../domain/facility_capacity_model.dart';
import '../../../domain/facility_selector.dart';
import '../../../domain/stadium_layout.dart';

/// Card displaying facility capacity status with visual indicators.
class CapacityStatusCard extends StatelessWidget {
  final FacilitySelectionResult result;
  final VoidCallback? onSelectAlternative;

  const CapacityStatusCard({
    super.key,
    required this.result,
    this.onSelectAlternative,
  });

  @override
  Widget build(BuildContext context) {
    final facility = result.facilityInfo;
    if (facility == null) return const SizedBox.shrink();

    final loadPercent = facility.loadPercent;
    final level = facility.level;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(level),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with facility name and status badge
          Row(
            children: [
              Icon(
                facility.type == FacilityType.food
                    ? Icons.restaurant
                    : Icons.wc,
                color: const Color(0xFF0D47A1),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      StadiumLayout.labelOf(facility.nodeId),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Recommended',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(level),
            ],
          ),
          const SizedBox(height: 16),

          // Capacity bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Capacity',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${facility.statusText} ($loadPercent%)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getTextColor(level),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: loadPercent / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          _getBarColor(level),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Score breakdown
          Row(
            children: [
              _buildScoreChip('Route', result.routeCost, Icons.route),
              const SizedBox(width: 8),
              _buildScoreChip(
                  'Capacity', result.capacityPenalty, Icons.people),
              const SizedBox(width: 8),
              _buildScoreChip('Total', result.totalScore, Icons.calculate),
            ],
          ),

          // Alternatives
          if (result.alternatives.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Alternatives:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            ...result.alternatives.take(2).map((alt) {
              final altInfo = alt.facilityInfo;
              if (altInfo == null) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: _getBarColor(altInfo.level),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        StadiumLayout.labelOf(alt.nodeId),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      '${altInfo.loadPercent}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getTextColor(altInfo.level),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (altInfo.level == CapacityLevel.high) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.warning_amber,
                        size: 14,
                        color: Colors.orange,
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(CapacityLevel level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getBadgeColor(level),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        level.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _getTextColor(level),
        ),
      ),
    );
  }

  Widget _buildScoreChip(String label, int value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBorderColor(CapacityLevel level) {
    switch (level) {
      case CapacityLevel.low:
        return Colors.green.shade300;
      case CapacityLevel.medium:
        return Colors.orange.shade300;
      case CapacityLevel.high:
        return Colors.red.shade300;
    }
  }

  Color _getBarColor(CapacityLevel level) {
    switch (level) {
      case CapacityLevel.low:
        return Colors.green;
      case CapacityLevel.medium:
        return Colors.orange;
      case CapacityLevel.high:
        return Colors.red;
    }
  }

  Color _getBadgeColor(CapacityLevel level) {
    switch (level) {
      case CapacityLevel.low:
        return Colors.green.shade100;
      case CapacityLevel.medium:
        return Colors.orange.shade100;
      case CapacityLevel.high:
        return Colors.red.shade100;
    }
  }

  Color _getTextColor(CapacityLevel level) {
    switch (level) {
      case CapacityLevel.low:
        return Colors.green.shade800;
      case CapacityLevel.medium:
        return Colors.orange.shade800;
      case CapacityLevel.high:
        return Colors.red.shade800;
    }
  }
}
