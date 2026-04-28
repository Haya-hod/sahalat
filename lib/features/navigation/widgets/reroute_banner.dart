import 'package:flutter/material.dart';
import '../../../domain/facility_capacity_model.dart';
import '../../../domain/facility_selector.dart';
import '../../../domain/stadium_layout.dart';

/// Banner displayed when a facility is full and rerouting is suggested.
class RerouteBanner extends StatelessWidget {
  final FacilitySelectionResult result;
  final VoidCallback? onAcceptReroute;
  final VoidCallback? onDismiss;

  const RerouteBanner({
    super.key,
    required this.result,
    this.onAcceptReroute,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Only show if there's a warning (facility is busy or full)
    if (result.warning == null || result.warning!.isEmpty) {
      return const SizedBox.shrink();
    }

    final facility = result.facilityInfo;
    final isFull = facility?.level == CapacityLevel.high;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFull ? Colors.red.shade50 : Colors.orange.shade50,
        border: Border.all(
          color: isFull ? Colors.red.shade200 : Colors.orange.shade200,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFull ? Icons.warning_amber : Icons.info_outline,
                color: isFull ? Colors.red.shade700 : Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.warning!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        isFull ? Colors.red.shade700 : Colors.orange.shade700,
                  ),
                ),
              ),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color:
                        isFull ? Colors.red.shade400 : Colors.orange.shade400,
                  ),
                ),
            ],
          ),

          // Show best alternative
          if (isFull && result.alternatives.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildAlternativeSuggestion(context),
          ],
        ],
      ),
    );
  }

  Widget _buildAlternativeSuggestion(BuildContext context) {
    final bestAlt = result.alternatives.first;
    final altInfo = bestAlt.facilityInfo;

    if (altInfo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              altInfo.type == FacilityType.food
                  ? Icons.restaurant
                  : Icons.wc,
              color: Colors.green.shade700,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Try ${StadiumLayout.labelOf(bestAlt.nodeId)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${altInfo.loadPercent}% capacity',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (onAcceptReroute != null)
            ElevatedButton(
              onPressed: onAcceptReroute,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Go Here',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

/// Banner for nearby facilities (shown in My Seat mode).
class NearbyFacilitiesBanner extends StatelessWidget {
  final List<FacilitySelectionResult> facilities;
  final ValueChanged<String>? onFacilitySelected;

  const NearbyFacilitiesBanner({
    super.key,
    required this.facilities,
    this.onFacilitySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (facilities.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.near_me, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Nearby Facilities',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...facilities.map((result) {
            final info = result.facilityInfo;
            if (info == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: onFacilitySelected != null
                    ? () => onFacilitySelected!(result.recommendedNodeId)
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        info.type == FacilityType.food
                            ? Icons.restaurant
                            : Icons.wc,
                        size: 20,
                        color: const Color(0xFF0D47A1),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          StadiumLayout.labelOf(result.recommendedNodeId),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      _buildCapacityChip(info),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCapacityChip(FacilityInfo info) {
    Color bgColor;
    Color textColor;

    switch (info.level) {
      case CapacityLevel.low:
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case CapacityLevel.medium:
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case CapacityLevel.high:
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${info.loadPercent}%',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
