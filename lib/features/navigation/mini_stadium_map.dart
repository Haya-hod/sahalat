import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../domain/stadium_models.dart';
import '../../domain/congestion_model.dart';

/// Information about a seat marker to display on the map.
///
/// Used for seat navigation mode to show the user's exact seat location
/// with a pulsing highlight effect.
class SeatMarkerInfo {
  /// The section where the seat is located ('vip' or 'standard')
  final String section;

  /// Row number (1-based, used for radial positioning)
  final int row;

  /// Seat number within the row (1-based, used for angular positioning)
  final int seat;

  /// Total rows in the section (for normalization)
  final int totalRows;

  /// Total seats per row (for normalization)
  final int seatsPerRow;

  const SeatMarkerInfo({
    required this.section,
    required this.row,
    required this.seat,
    this.totalRows = 20,
    this.seatsPerRow = 30,
  });

  /// Creates a SeatMarkerInfo from ticket category and seat details.
  factory SeatMarkerInfo.fromTicket({
    required String category,
    required int row,
    required int seat,
  }) {
    return SeatMarkerInfo(
      section: category.toLowerCase() == 'vip' ? 'vip' : 'standard',
      row: row,
      seat: seat,
    );
  }

  /// Computes the normalized position (0-1 range) for this seat on the map.
  ///
  /// The position is calculated based on:
  /// - Section: VIP is in the north (top), Standard is in the south (bottom)
  /// - Row: Maps to radial distance from section center
  /// - Seat: Maps to angular position within the section arc
  Offset computeNormalizedPosition() {
    // Section centers (normalized coordinates)
    const vipCenter = Offset(0.5, 0.34);
    const standardCenter = Offset(0.5, 0.66);

    final isVip = section == 'vip';
    final sectionCenter = isVip ? vipCenter : standardCenter;

    // Calculate radial offset based on row (inner rows closer to field)
    // Row 1 is closest to field, higher rows are further out
    final rowFraction = (row - 1) / (totalRows - 1).clamp(1, 100);
    final radialOffset = 0.02 + rowFraction * 0.12; // 0.02 to 0.14 range

    // Calculate angular offset based on seat number
    // Seats are distributed in a 120-degree arc (π/3 radians each side)
    final seatFraction = (seat - 1) / (seatsPerRow - 1).clamp(1, 100);
    final angularRange = math.pi / 3; // 60 degrees each side
    final angle = (seatFraction - 0.5) * angularRange * 2;

    // Direction: VIP faces down (south), Standard faces up (north)
    final baseAngle = isVip ? math.pi / 2 : -math.pi / 2;
    final finalAngle = baseAngle + angle;

    // Compute final position
    return Offset(
      sectionCenter.dx + radialOffset * math.cos(finalAngle),
      sectionCenter.dy + radialOffset * math.sin(finalAngle),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SeatMarkerInfo &&
        other.section == section &&
        other.row == row &&
        other.seat == seat;
  }

  @override
  int get hashCode => Object.hash(section, row, seat);
}

/// Realistic 2D stadium visualization with seating tiers, ring walkway,
/// congestion display, animated path rendering, and seat marker highlighting.
///
/// Features:
/// - Cubic Bezier curves for smooth paths around the field
/// - Animated moving dashes along the navigation path
/// - Pulsing seat marker with radar-ping effect
/// - Optional section highlighting
/// - Congestion-aware coloring
/// - Premium visual effects (glow, gradients)
class MiniStadiumMap extends StatefulWidget {
  final StadiumNode? startNode;
  final StadiumNode? destinationNode;
  final List<StadiumNode> path;
  final CongestionScenario congestionScenario;

  /// Optional seat marker to display with pulsing highlight.
  /// When set, shows the user's exact seat location with an animated effect.
  final SeatMarkerInfo? seatMarker;

  /// Whether to subtly highlight the entire section containing the seat.
  final bool highlightSection;

  const MiniStadiumMap({
    super.key,
    this.startNode,
    this.destinationNode,
    this.path = const [],
    this.congestionScenario = CongestionScenario.allLow,
    this.seatMarker,
    this.highlightSection = true,
  });

  @override
  State<MiniStadiumMap> createState() => _MiniStadiumMapState();
}

class _MiniStadiumMapState extends State<MiniStadiumMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Animation controller for moving dash effect and seat pulse
    // Duration controls speed: lower = faster movement
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Start animation if there's a path or seat marker
    if (_shouldAnimate()) {
      _animationController.repeat();
    }
  }

  bool _shouldAnimate() {
    return widget.path.length >= 2 || widget.seatMarker != null;
  }

  @override
  void didUpdateWidget(MiniStadiumMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if animation state needs to change
    final pathChanged = !_pathEquals(oldWidget.path, widget.path);
    final seatChanged = oldWidget.seatMarker != widget.seatMarker;

    if (pathChanged || seatChanged) {
      if (_shouldAnimate()) {
        if (!_animationController.isAnimating) {
          _animationController.repeat();
        }
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  bool _pathEquals(List<StadiumNode> a, List<StadiumNode> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Stadium painter with animation
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(double.infinity, 260),
                  painter: _RealisticStadiumPainter(
                    startNode: widget.startNode,
                    destinationNode: widget.destinationNode,
                    path: widget.path,
                    congestionScenario: widget.congestionScenario,
                    animationValue: _animationController.value,
                    seatMarker: widget.seatMarker,
                    highlightSection: widget.highlightSection,
                  ),
                );
              },
            ),
            // Title badge
            Positioned(
              top: 8,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stadium, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      widget.seatMarker != null ? 'Your Seat' : 'Stadium Layout',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Legend
            Positioned(
              bottom: 8,
              left: 12,
              right: 12,
              child: _buildLegend(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: [
          _LegendItem(
            color: Colors.green.shade400,
            label: 'Start',
            isCircle: true,
          ),
          _LegendItem(
            color: Colors.red.shade400,
            label: 'Dest',
            isCircle: true,
          ),
          _LegendItem(
            color: Colors.cyan.shade300,
            label: 'Path',
            isCircle: false,
          ),
          if (widget.seatMarker != null)
            _LegendItem(
              color: Colors.amber.shade400,
              label: 'Seat',
              isCircle: true,
              isPulsing: true,
            ),
          _LegendItem(
            color: Colors.orange.shade400,
            label: 'Congested',
            isCircle: false,
            isDashed: true,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isCircle;
  final bool isDashed;
  final bool isPulsing;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isCircle = true,
    this.isDashed = false,
    this.isPulsing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isCircle)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: isPulsing
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
          )
        else
          Container(
            width: 16,
            height: 3,
            decoration: BoxDecoration(
              color: isDashed ? Colors.transparent : color,
              border: isDashed ? Border.all(color: color, width: 1) : null,
              borderRadius: BorderRadius.circular(2),
            ),
            child: isDashed
                ? CustomPaint(
                    painter: _DashedLinePainter(color: color),
                  )
                : null,
          ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Colors.white70),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 2.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Represents a visual path segment for the Display Path system.
/// Can be either a straight segment or an ellipse arc segment.
class _DisplaySegment {
  final Offset start;
  final Offset end;
  final String fromId;
  final String toId;
  final bool isArc;
  final bool isCongested;

  const _DisplaySegment({
    required this.start,
    required this.end,
    required this.fromId,
    required this.toId,
    required this.isArc,
    required this.isCongested,
  });
}

class _RealisticStadiumPainter extends CustomPainter {
  final StadiumNode? startNode;
  final StadiumNode? destinationNode;
  final List<StadiumNode> path;
  final CongestionScenario congestionScenario;
  final double animationValue;
  final SeatMarkerInfo? seatMarker;
  final bool highlightSection;

  // Animation constants
  static const double _dashLength = 8.0;
  static const double _gapLength = 6.0;
  static const double _dashCycleLength = _dashLength + _gapLength;

  // Seat pulse constants
  static const double _pulseBaseRadius = 6.0;
  static const double _pulseMaxRadius = 20.0;
  static const int _pulseRingCount = 3;

  _RealisticStadiumPainter({
    this.startNode,
    this.destinationNode,
    this.path = const [],
    this.congestionScenario = CongestionScenario.allLow,
    this.animationValue = 0.0,
    this.seatMarker,
    this.highlightSection = true,
  });

  // Updated node positions including ring walkway
  static final Map<String, Offset> _nodePositions = {
    // Gates - outer perimeter (cardinal directions)
    'gateA': const Offset(0.06, 0.5), // West
    'gateB': const Offset(0.5, 0.94), // South
    'gateC': const Offset(0.94, 0.5), // East
    'gateD': const Offset(0.5, 0.06), // North

    // Ring Walkway - outer concourse loop
    'ringN': const Offset(0.5, 0.18), // North ring
    'ringE': const Offset(0.82, 0.5), // East ring
    'ringS': const Offset(0.5, 0.82), // South ring
    'ringW': const Offset(0.18, 0.5), // West ring

    // Facilities - between ring and center
    'restroom': const Offset(0.28, 0.38), // NW area
    'foodCourt': const Offset(0.72, 0.38), // NE area

    // Concourse - center hub
    'concourseMain': const Offset(0.5, 0.5),

    // Seating sections - inner area
    'vip': const Offset(0.5, 0.34), // North side VIP
    'standard': const Offset(0.5, 0.66), // South side standard

    // Phase 5: Multiple Facilities (distributed around stadium)
    'food1': const Offset(0.40, 0.22), // Near North ring
    'food2': const Offset(0.78, 0.42), // Near East ring
    'food3': const Offset(0.50, 0.78), // Near South ring
    'wc1': const Offset(0.22, 0.42), // Near West ring
    'wc2': const Offset(0.62, 0.22), // Between North/East
    'wc3': const Offset(0.35, 0.78), // Near South/West
  };

  // Define edge connections for drawing
  static const List<(String, String)> _allEdges = [
    // Gates to Ring
    ('gateA', 'ringW'),
    ('gateB', 'ringS'),
    ('gateC', 'ringE'),
    ('gateD', 'ringN'),
    // Gates to Concourse (direct paths)
    ('gateA', 'concourseMain'),
    ('gateB', 'concourseMain'),
    ('gateC', 'concourseMain'),
    ('gateD', 'concourseMain'),
    // Ring loop
    ('ringN', 'ringE'),
    ('ringE', 'ringS'),
    ('ringS', 'ringW'),
    ('ringW', 'ringN'),
    // Ring to Concourse
    ('ringN', 'concourseMain'),
    ('ringE', 'concourseMain'),
    ('ringS', 'concourseMain'),
    ('ringW', 'concourseMain'),
    // Concourse to destinations
    ('concourseMain', 'vip'),
    ('concourseMain', 'standard'),
    ('concourseMain', 'restroom'),
    ('concourseMain', 'foodCourt'),
    // Ring to destinations
    ('ringN', 'vip'),
    ('ringS', 'standard'),
    ('ringW', 'restroom'),
    ('ringE', 'foodCourt'),
    // Phase 5: Multiple Facilities edges
    ('food1', 'ringN'),
    ('food1', 'ringW'),
    ('food1', 'concourseMain'),
    ('food2', 'ringE'),
    ('food2', 'concourseMain'),
    ('food3', 'ringS'),
    ('food3', 'concourseMain'),
    ('wc1', 'ringW'),
    ('wc1', 'concourseMain'),
    ('wc2', 'ringN'),
    ('wc2', 'ringE'),
    ('wc3', 'ringS'),
    ('wc3', 'ringW'),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw stadium layers from outside to inside
    _drawOuterWall(canvas, size, center);
    _drawRingWalkway(canvas, size, center);

    // Draw section highlight (subtle) if seat marker is set
    if (seatMarker != null && highlightSection) {
      _drawSectionHighlight(canvas, size, center, seatMarker!.section);
    }

    _drawSeatingTiers(canvas, size, center);
    _drawCenterField(canvas, size, center);

    // Draw graph edges (with congestion highlighting)
    _drawGraphEdges(canvas, size);

    // Draw path with animation
    if (path.length >= 2) {
      _drawPath(canvas, size);
    }

    // Draw all nodes
    _drawAllNodes(canvas, size);

    // Draw seat marker with pulsing effect (on top of everything)
    if (seatMarker != null) {
      _drawSeatMarker(canvas, size);
    }
  }

  /// Draws a subtle highlight over the section containing the seat
  void _drawSectionHighlight(
      Canvas canvas, Size size, Offset center, String section) {
    final isVip = section == 'vip';

    // Section arc parameters
    final radiusX = size.width * (isVip ? 0.20 : 0.30);
    final radiusY = size.height * (isVip ? 0.18 : 0.28);
    final sectionCenter = isVip
        ? Offset(size.width * 0.5, size.height * 0.34)
        : Offset(size.width * 0.5, size.height * 0.66);

    // Pulsing opacity based on animation
    final pulseOpacity = 0.08 + 0.04 * math.sin(animationValue * 2 * math.pi);

    final highlightPaint = Paint()
      ..color = Colors.amber.withValues(alpha: pulseOpacity)
      ..style = PaintingStyle.fill;

    // Draw elliptical highlight
    final rect = Rect.fromCenter(
      center: sectionCenter,
      width: radiusX * 2.2,
      height: radiusY * 2.2,
    );
    canvas.drawOval(rect, highlightPaint);

    // Draw a subtle border
    final borderPaint = Paint()
      ..color = Colors.amber.withValues(alpha: pulseOpacity * 2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(rect, borderPaint);
  }

  /// Draws the pulsing seat marker with radar-ping effect
  void _drawSeatMarker(Canvas canvas, Size size) {
    if (seatMarker == null) return;

    // Compute seat position
    final normalizedPos = seatMarker!.computeNormalizedPosition();
    final seatPos = Offset(
      normalizedPos.dx * size.width,
      normalizedPos.dy * size.height,
    );

    // Draw pulsing concentric rings (radar ping effect)
    for (int i = 0; i < _pulseRingCount; i++) {
      // Stagger the rings with phase offset
      final phase = (animationValue + i / _pulseRingCount) % 1.0;

      // Calculate radius: starts at base, expands to max
      final radius =
          _pulseBaseRadius + phase * (_pulseMaxRadius - _pulseBaseRadius);

      // Calculate opacity: fades out as ring expands
      // Use smooth easing for natural feel
      final easedPhase = _easeOutCubic(phase);
      final opacity = (1.0 - easedPhase) * 0.6;

      if (opacity > 0.01) {
        final ringPaint = Paint()
          ..color = Colors.amber.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 - phase * 1.0; // Thinner as it expands

        canvas.drawCircle(seatPos, radius, ringPaint);
      }
    }

    // Draw solid glow underneath the marker
    final glowPaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(seatPos, _pulseBaseRadius + 4, glowPaint);

    // Draw the solid seat marker dot
    final markerPaint = Paint()
      ..color = Colors.amber.shade400
      ..style = PaintingStyle.fill;
    canvas.drawCircle(seatPos, _pulseBaseRadius, markerPaint);

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(seatPos, _pulseBaseRadius, borderPaint);

    // Draw seat icon (small chair symbol or just initials)
    _drawText(canvas, seatPos, '🪑', 8, Colors.white);
  }

  /// Easing function for smooth pulse animation
  double _easeOutCubic(double t) {
    return 1.0 - math.pow(1.0 - t, 3).toDouble();
  }

  void _drawOuterWall(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..color = const Color(0xFF3d3d5c)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromCenter(
      center: center,
      width: size.width * 0.94,
      height: size.height * 0.92,
    );
    canvas.drawOval(rect, paint);
  }

  void _drawRingWalkway(Canvas canvas, Size size, Offset center) {
    // Draw the ring walkway as a translucent band
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromCenter(
      center: center,
      width: size.width * 0.68,
      height: size.height * 0.66,
    );
    canvas.drawOval(rect, paint);

    // Inner edge of ring
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final innerRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.58,
      height: size.height * 0.56,
    );
    canvas.drawOval(innerRect, innerPaint);
  }

  void _drawSeatingTiers(Canvas canvas, Size size, Offset center) {
    // Outer tier (ring area, more subtle)
    _drawSeatingRing(
      canvas,
      center,
      radiusX: size.width * 0.40,
      radiusY: size.height * 0.38,
      seatCount: 80,
      color: const Color(0xFF4a9eff).withValues(alpha: 0.5),
      gapAngles: [0, math.pi / 2, math.pi, 3 * math.pi / 2],
    );

    // Middle tier
    _drawSeatingRing(
      canvas,
      center,
      radiusX: size.width * 0.30,
      radiusY: size.height * 0.28,
      seatCount: 60,
      color: const Color(0xFF7c3aed).withValues(alpha: 0.6),
      gapAngles: [0, math.pi / 2, math.pi, 3 * math.pi / 2],
    );

    // Inner tier (VIP)
    _drawSeatingRing(
      canvas,
      center,
      radiusX: size.width * 0.20,
      radiusY: size.height * 0.18,
      seatCount: 40,
      color: const Color(0xFFfbbf24).withValues(alpha: 0.6),
      gapAngles: [0, math.pi],
    );
  }

  void _drawSeatingRing(
    Canvas canvas,
    Offset center, {
    required double radiusX,
    required double radiusY,
    required int seatCount,
    required Color color,
    List<double> gapAngles = const [],
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const gapSize = 0.18;

    for (int i = 0; i < seatCount; i++) {
      final angle = (2 * math.pi * i) / seatCount;

      bool inGap = false;
      for (final gapAngle in gapAngles) {
        if ((angle - gapAngle).abs() < gapSize ||
            (angle - gapAngle + 2 * math.pi).abs() < gapSize ||
            (angle - gapAngle - 2 * math.pi).abs() < gapSize) {
          inGap = true;
          break;
        }
      }
      if (inGap) continue;

      final x = center.dx + radiusX * math.cos(angle);
      final y = center.dy + radiusY * math.sin(angle);

      canvas.drawCircle(Offset(x, y), 2.0, paint);
    }
  }

  void _drawCenterField(Canvas canvas, Size size, Offset center) {
    final fieldRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: center, width: size.width * 0.24, height: size.height * 0.14),
      const Radius.circular(6),
    );

    final fieldPaint = Paint()
      ..color = const Color(0xFF22c55e).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(fieldRect, fieldPaint);

    final outlinePaint = Paint()
      ..color = const Color(0xFF22c55e).withValues(alpha: 0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(fieldRect, outlinePaint);

    canvas.drawCircle(center, 8, outlinePaint);

    _drawText(canvas, center, 'FIELD', 7, Colors.white30);
  }

  void _drawGraphEdges(Canvas canvas, Size size) {
    for (final edge in _allEdges) {
      final fromPos = _nodePositions[edge.$1];
      final toPos = _nodePositions[edge.$2];
      if (fromPos == null || toPos == null) continue;

      final from = Offset(fromPos.dx * size.width, fromPos.dy * size.height);
      final to = Offset(toPos.dx * size.width, toPos.dy * size.height);

      // Check congestion
      final congestion = CongestionModel.getCongestion(edge.$1, edge.$2);
      final isCongested = congestion == CongestionLevel.high;

      final paint = Paint()
        ..color = isCongested
            ? Colors.orange.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = isCongested ? 2.5 : 1.5
        ..style = PaintingStyle.stroke;

      if (isCongested) {
        // Draw dashed line for congested edges
        _drawStaticDashedLine(canvas, from, to, paint);
      } else {
        canvas.drawLine(from, to, paint);
      }
    }
  }

  void _drawStaticDashedLine(
      Canvas canvas, Offset from, Offset to, Paint paint) {
    const dashLength = 5.0;
    const gapLength = 4.0;

    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final unitX = dx / distance;
    final unitY = dy / distance;

    double currentDistance = 0;
    bool draw = true;

    while (currentDistance < distance) {
      final segmentLength = draw ? dashLength : gapLength;
      final endDistance =
          (currentDistance + segmentLength).clamp(0.0, distance);

      if (draw) {
        canvas.drawLine(
          Offset(from.dx + unitX * currentDistance,
              from.dy + unitY * currentDistance),
          Offset(from.dx + unitX * endDistance, from.dy + unitY * endDistance),
          paint,
        );
      }

      currentDistance = endDistance;
      draw = !draw;
    }
  }

  void _drawPath(Canvas canvas, Size size) {
    // === DISPLAY PATH SYSTEM ===
    // Build a visual-only path that removes concourseMain from the middle
    // and connects adjacent nodes with ellipse arcs along the ring walkway.

    final displaySegments = _buildDisplaySegments(size);
    if (displaySegments.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw each display segment
    for (final segment in displaySegments) {
      if (segment.isArc) {
        // Draw ellipse arc along ring walkway
        _drawEllipseArcSegment(
          canvas,
          segment.start,
          segment.end,
          center,
          size,
          segment.isCongested,
        );
      } else {
        _drawAnimatedStraightSegment(
          canvas,
          segment.start,
          segment.end,
          center,
          size,
          segment.isCongested,
        );
      }
    }
  }

  /// Represents a visual path segment (straight or arc)
  List<_DisplaySegment> _buildDisplaySegments(Size size) {
    final segments = <_DisplaySegment>[];

    // Filter out concourseMain from the middle of the path
    // Keep it only if it's the start or end destination
    final displayNodes = <String>[];
    final displayPoints = <Offset>[];

    for (int i = 0; i < path.length; i++) {
      final node = path[i];
      final nodeId = node.id;

      // Skip concourseMain if it's in the MIDDLE of the path (not start/end)
      if (nodeId == 'concourseMain' && i > 0 && i < path.length - 1) {
        continue; // Remove from display path
      }

      final pos = _nodePositions[nodeId];
      if (pos == null) continue;

      displayNodes.add(nodeId);
      displayPoints.add(Offset(pos.dx * size.width, pos.dy * size.height));
    }

    if (displayPoints.length < 2) return segments;

    final center = Offset(size.width / 2, size.height / 2);
    final fieldHalfWidth = size.width * 0.14;
    final fieldHalfHeight = size.height * 0.10;

    // Build segments
    for (int i = 0; i < displayPoints.length - 1; i++) {
      final start = displayPoints[i];
      final end = displayPoints[i + 1];
      final fromId = displayNodes[i];
      final toId = displayNodes[i + 1];

      // Check congestion for this segment (check original edges)
      final congestion = CongestionModel.getCongestion(fromId, toId);
      final isCongested = congestion == CongestionLevel.high;

      // Determine if we need an arc:
      // 1. If the original path had concourseMain between these nodes
      // 2. If the straight line would cross the field
      final needsArc = _shouldUseArc(
        start, end, fromId, toId, center, fieldHalfWidth, fieldHalfHeight,
      );

      segments.add(_DisplaySegment(
        start: start,
        end: end,
        fromId: fromId,
        toId: toId,
        isArc: needsArc,
        isCongested: isCongested,
      ));
    }

    return segments;
  }

  /// Direct graph “spurs” from the ring to a POI/section (short edges in [StadiumLayout]).
  /// These must not use the ring-walkway ellipse arc: that arc follows the *whole* oval and
  /// visually sweeps through other cardinal ring nodes (e.g. past North) even when the logical
  /// path is only ringW→food1 — users read that as a wrong route / overshoot past F1.
  static bool _isRingSpurEdge(String a, String b) {
    bool isRing(String id) => id.startsWith('ring');
    bool isSpurTarget(String id) {
      if (id.startsWith('food') || id.startsWith('wc')) return true;
      return id == 'restroom' ||
          id == 'foodCourt' ||
          id == 'vip' ||
          id == 'standard';
    }

    return (isRing(a) && isSpurTarget(b)) || (isSpurTarget(a) && isRing(b));
  }

  /// Determines if a segment should use an arc (vs straight line)
  bool _shouldUseArc(
    Offset start,
    Offset end,
    String fromId,
    String toId,
    Offset center,
    double fieldHalfWidth,
    double fieldHalfHeight,
  ) {
    if (_isRingSpurEdge(fromId, toId)) {
      return false;
    }

    // Check if original path had concourseMain between these nodes
    bool hadConcourseInBetween = false;
    for (int i = 0; i < path.length - 1; i++) {
      if (path[i].id == fromId) {
        // Look ahead to find toId
        for (int j = i + 1; j < path.length; j++) {
          if (path[j].id == toId) {
            // Check if any node between i and j is concourseMain
            for (int k = i + 1; k < j; k++) {
              if (path[k].id == 'concourseMain') {
                hadConcourseInBetween = true;
                break;
              }
            }
            break;
          }
        }
        break;
      }
    }

    if (hadConcourseInBetween) return true;

    return _segmentCrossesField(
        start, end, center, fieldHalfWidth, fieldHalfHeight);
  }

  /// True if the segment [start]–[end] intersects the field rectangle (not only midpoint).
  bool _segmentCrossesField(Offset start, Offset end, Offset center,
      double halfW, double halfH) {
    final r = Rect.fromLTRB(
      center.dx - halfW,
      center.dy - halfH,
      center.dx + halfW,
      center.dy + halfH,
    );
    if (r.contains(start) || r.contains(end)) return true;
    final corners = <Offset>[
      r.topLeft,
      r.topRight,
      r.bottomRight,
      r.bottomLeft,
    ];
    for (var i = 0; i < 4; i++) {
      if (_segmentsIntersect2D(start, end, corners[i], corners[(i + 1) % 4])) {
        return true;
      }
    }
    return false;
  }

  double _cross2D(Offset o, Offset a, Offset b) {
    return (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
  }

  bool _segmentsIntersect2D(Offset p1, Offset p2, Offset p3, Offset p4) {
    final d1 = _cross2D(p1, p2, p3);
    final d2 = _cross2D(p1, p2, p4);
    final d3 = _cross2D(p3, p4, p1);
    final d4 = _cross2D(p3, p4, p2);
    if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
      return true;
    }
    const eps = 1e-9;
    if (d1.abs() < eps && _onSegment(p1, p3, p2)) return true;
    if (d2.abs() < eps && _onSegment(p1, p4, p2)) return true;
    if (d3.abs() < eps && _onSegment(p3, p1, p4)) return true;
    if (d4.abs() < eps && _onSegment(p3, p2, p4)) return true;
    return false;
  }

  bool _onSegment(Offset a, Offset b, Offset c) {
    return b.dx <= math.max(a.dx, c.dx) + 1e-9 &&
        b.dx + 1e-9 >= math.min(a.dx, c.dx) &&
        b.dy <= math.max(a.dy, c.dy) + 1e-9 &&
        b.dy + 1e-9 >= math.min(a.dy, c.dy);
  }

  /// Draws a PURE ellipse arc along the ring walkway between two nodes.
  ///
  /// This replaces concourseMain routing with a visual arc that follows
  /// the stadium's ring walkway ellipse exactly - no blending or detours.
  ///
  /// The path consists of:
  /// 1. Short entry segment from start node to ring
  /// 2. Pure ellipse arc along the ring
  /// 3. Short exit segment from ring to end node
  void _drawEllipseArcSegment(
    Canvas canvas,
    Offset start,
    Offset end,
    Offset center,
    Size size,
    bool isCongested,
  ) {
    // Ring walkway ellipse dimensions (matches _drawRingWalkway)
    final ringRadiusX = size.width * 0.34;  // Half of 0.68
    final ringRadiusY = size.height * 0.33; // Half of 0.66

    // Calculate angles from center to start and end points
    final startAngle = math.atan2(start.dy - center.dy, start.dx - center.dx);
    final endAngle = math.atan2(end.dy - center.dy, end.dx - center.dx);

    // Points on the ring ellipse (where arc starts and ends)
    final ringStartX = center.dx + ringRadiusX * math.cos(startAngle);
    final ringStartY = center.dy + ringRadiusY * math.sin(startAngle);
    final ringStart = Offset(ringStartX, ringStartY);

    // Calculate angular difference - choose the SHORTER arc direction
    var angleDiff = endAngle - startAngle;
    // Normalize to [-pi, pi] to get shortest arc
    while (angleDiff > math.pi) {
      angleDiff -= 2 * math.pi;
    }
    while (angleDiff < -math.pi) {
      angleDiff += 2 * math.pi;
    }

    // Build the complete path
    final arcPath = Path();
    arcPath.moveTo(start.dx, start.dy);

    // Entry segment: from start node to ring (short connector)
    arcPath.lineTo(ringStart.dx, ringStart.dy);

    // Pure ellipse arc along the ring
    const arcSegments = 36;
    for (int i = 1; i <= arcSegments; i++) {
      final t = i / arcSegments;
      final currentAngle = startAngle + angleDiff * t;

      // Point DIRECTLY on the ring ellipse
      final arcX = center.dx + ringRadiusX * math.cos(currentAngle);
      final arcY = center.dy + ringRadiusY * math.sin(currentAngle);
      arcPath.lineTo(arcX, arcY);
    }

    // Exit segment: from ring to end node
    arcPath.lineTo(end.dx, end.dy);

    // Draw glow effect (static, underneath)
    final glowPaint = Paint()
      ..color =
          (isCongested ? Colors.orange : Colors.cyan).withValues(alpha: 0.2)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(arcPath, glowPaint);

    // Draw animated dashed path on top
    _drawAnimatedDashedPath(canvas, arcPath, isCongested);

    // Draw direction arrow at arc midpoint (on the ring itself)
    final midAngle = startAngle + angleDiff * 0.5;
    final midPoint = Offset(
      center.dx + ringRadiusX * math.cos(midAngle),
      center.dy + ringRadiusY * math.sin(midAngle),
    );

    // Tangent direction at midpoint (perpendicular to radius, along arc)
    final tangentAngle = midAngle + (angleDiff > 0 ? math.pi / 2 : -math.pi / 2);

    _drawArrow(
      canvas,
      midPoint,
      tangentAngle,
      isCongested ? Colors.orange.shade200 : Colors.cyan.shade200,
    );
  }

  /// Smooth quadratic segment (bulge away from field center) + animated dashes.
  void _drawAnimatedStraightSegment(
    Canvas canvas,
    Offset start,
    Offset end,
    Offset stadiumCenter,
    Size size,
    bool isCongested,
  ) {
    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1.0) return;

    final nx = -dy / len;
    final ny = dx / len;
    final toCx = mid.dx - stadiumCenter.dx;
    final toCy = mid.dy - stadiumCenter.dy;
    final dotOut = nx * toCx + ny * toCy;
    final sign = dotOut >= 0 ? 1.0 : -1.0;
    final bulge = math.min(len * 0.22, size.shortestSide * 0.065);
    final cx = mid.dx + sign * nx * bulge;
    final cy = mid.dy + sign * ny * bulge;

    final linePath = Path();
    linePath.moveTo(start.dx, start.dy);
    linePath.quadraticBezierTo(cx, cy, end.dx, end.dy);

    final glowPaint = Paint()
      ..color =
          (isCongested ? Colors.orange : Colors.cyan).withValues(alpha: 0.2)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(linePath, glowPaint);

    _drawAnimatedDashedPath(canvas, linePath, isCongested);

    final tArrow = 0.5;
    final ax = (1 - tArrow) * (1 - tArrow) * start.dx +
        2 * (1 - tArrow) * tArrow * cx +
        tArrow * tArrow * end.dx;
    final ay = (1 - tArrow) * (1 - tArrow) * start.dy +
        2 * (1 - tArrow) * tArrow * cy +
        tArrow * tArrow * end.dy;
    final tx = 2 *
        ((1 - tArrow) * (cx - start.dx) + tArrow * (end.dx - cx));
    final ty = 2 *
        ((1 - tArrow) * (cy - start.dy) + tArrow * (end.dy - cy));
    final angle = math.atan2(ty, tx);
    _drawArrow(
      canvas,
      Offset(ax, ay),
      angle,
      isCongested ? Colors.orange.shade200 : Colors.cyan.shade200,
    );
  }

  /// Draws animated moving dashes along any path (straight or curved)
  void _drawAnimatedDashedPath(Canvas canvas, Path path, bool isCongested) {
    final color = isCongested ? Colors.orange.shade300 : Colors.cyan.shade300;

    // Calculate dash offset based on animation value
    final dashOffset = animationValue * _dashCycleLength;

    // Create dash effect with animated offset
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Use path metrics to draw dashes along the curve
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      final pathLength = metric.length;
      var distance = -dashOffset;

      while (distance < pathLength) {
        final dashStart = distance.clamp(0.0, pathLength);
        final dashEnd = (distance + _dashLength).clamp(0.0, pathLength);

        if (dashEnd > dashStart && distance + _dashLength > 0) {
          final extractedPath = metric.extractPath(dashStart, dashEnd);
          canvas.drawPath(extractedPath, paint);
        }

        distance += _dashCycleLength;
      }
    }

    // Draw a subtle solid line underneath for continuity
    final solidPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, solidPaint);
  }

  void _drawArrow(Canvas canvas, Offset position, double angle, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const arrowSize = 8.0;
    const arrowAngle = 0.5;

    final arrowPath = Path();
    arrowPath.moveTo(
      position.dx - arrowSize * math.cos(angle - arrowAngle),
      position.dy - arrowSize * math.sin(angle - arrowAngle),
    );
    arrowPath.lineTo(position.dx, position.dy);
    arrowPath.lineTo(
      position.dx - arrowSize * math.cos(angle + arrowAngle),
      position.dy - arrowSize * math.sin(angle + arrowAngle),
    );

    canvas.drawPath(arrowPath, paint);
  }

  void _drawAllNodes(Canvas canvas, Size size) {
    for (final entry in _nodePositions.entries) {
      final nodeId = entry.key;
      final pos =
          Offset(entry.value.dx * size.width, entry.value.dy * size.height);

      final isStart = startNode?.id == nodeId;
      final isDestination = destinationNode?.id == nodeId;
      final isOnPath = path.any((n) => n.id == nodeId);

      _drawNode(canvas, pos, nodeId, isStart, isDestination, isOnPath);
    }
  }

  void _drawNode(Canvas canvas, Offset pos, String nodeId, bool isStart,
      bool isDestination, bool isOnPath) {
    Color bgColor;
    double radius;
    String label;

    // Determine style based on node state
    if (isStart) {
      bgColor = Colors.green.shade500;
      radius = 14;
    } else if (isDestination) {
      bgColor = Colors.red.shade500;
      radius = 16;
    } else if (isOnPath) {
      bgColor = Colors.cyan.shade400;
      radius = 10;
    } else {
      bgColor = Colors.grey.shade600;
      radius = 7;
    }

    // Node labels
    switch (nodeId) {
      case 'gateA':
        label = 'A';
      case 'gateB':
        label = 'B';
      case 'gateC':
        label = 'C';
      case 'gateD':
        label = 'D';
      case 'ringN':
        label = 'N';
      case 'ringE':
        label = 'E';
      case 'ringS':
        label = 'S';
      case 'ringW':
        label = 'W';
      case 'restroom':
        label = 'WC';
      case 'foodCourt':
        label = 'F';
      case 'vip':
        label = 'VIP';
      case 'standard':
        label = 'STD';
      case 'concourseMain':
        label = 'C';
      // Phase 5 facilities
      case 'food1':
        label = 'F1';
      case 'food2':
        label = 'F2';
      case 'food3':
        label = 'F3';
      case 'wc1':
        label = 'R1';
      case 'wc2':
        label = 'R2';
      case 'wc3':
        label = 'R3';
      default:
        label = '?';
    }

    // Ring nodes get different styling
    final isRingNode = nodeId.startsWith('ring');
    if (isRingNode && !isOnPath && !isStart && !isDestination) {
      bgColor = const Color(0xFF5a5a7a);
      radius = 9;
    }

    // Glow for path nodes
    if (isStart || isDestination || isOnPath) {
      final glowPaint = Paint()
        ..color = bgColor.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(pos, radius + 4, glowPaint);
    }

    // Node background
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, radius, bgPaint);

    // Node border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(pos, radius, borderPaint);

    // Label
    double fontSize = (isStart || isDestination) ? 9 : 6;
    if (nodeId == 'vip' || nodeId == 'standard') fontSize = 5;
    if (isRingNode && !isOnPath) fontSize = 6;

    _drawText(canvas, pos, label, fontSize, Colors.white);
  }

  void _drawText(
      Canvas canvas, Offset pos, String text, double fontSize, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      pos - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _RealisticStadiumPainter oldDelegate) {
    // Repaint on animation value change for smooth animation
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.startNode?.id != startNode?.id ||
        oldDelegate.destinationNode?.id != destinationNode?.id ||
        oldDelegate.path.length != path.length ||
        oldDelegate.congestionScenario != congestionScenario ||
        oldDelegate.seatMarker != seatMarker ||
        oldDelegate.highlightSection != highlightSection ||
        !_pathEquals(oldDelegate.path, path);
  }

  bool _pathEquals(List<StadiumNode> a, List<StadiumNode> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
}
