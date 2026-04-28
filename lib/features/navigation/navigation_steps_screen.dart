import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/car_location_service.dart';
import '../../core/crowd_detection_service.dart';
import '../../core/location_service.dart';
import '../../core/ticket_payload.dart';
import '../../core/unity_navigation_bridge.dart';
import '../../domain/stadium_layout.dart';
import '../../domain/stadium_models.dart';
import '../../domain/pathfinder.dart';
import '../../domain/congestion_model.dart';
import '../../domain/facility_capacity_model.dart';
import '../../domain/facility_selector.dart';
import '../../domain/seat_navigator.dart';
import 'instruction_builder.dart';
import 'mini_stadium_map.dart';
import 'widgets/widgets.dart';
import 'crowd_scan_screen.dart';

class NavigationStepsScreen extends StatefulWidget {
  static const route = '/nav-steps';
  const NavigationStepsScreen({super.key});

  @override
  State<NavigationStepsScreen> createState() => _NavigationStepsScreenState();
}

class _NavigationStepsScreenState extends State<NavigationStepsScreen> {
  // Core state
  String _selectedStartId = 'gateA';
  DestinationOption? _selectedDestination;
  PathfindingAlgorithm _selectedAlgorithm = PathfindingAlgorithm.aStar;
  CongestionScenario _selectedScenario = CongestionScenario.allLow;

  // Seat details (for VIP/Standard sections)
  SeatDetails _seatDetails = const SeatDetails();

  // Phase 5: Results
  FacilitySelectionResult? _facilityResult;
  SeatNavigationResult? _seatResult;

  // Computed path
  List<StadiumNode> _computedPath = [];
  String? _error;

  // Resolved nodes
  StadiumNode? _startNode;
  StadiumNode? _destNode;

  // UI state
  bool _isMapExpanded = true;

  // GPS Location state
  bool _isLoadingLocation = false;
  NearestGateResult? _detectedGate;
  NearestNodeResult? _detectedNode; // Any node, not just gates
  String? _locationError;

  // Car location state
  bool _isSavingCar = false;
  bool _navigatingToCar = false;

  // Nearest facility state
  bool _isSearchingNearest = false;
  NearestNodeResult? _currentPositionNode;

  /// Avoid re-applying [ModalRoute] arguments on every [didChangeDependencies].
  bool _routeArgsConsumed = false;

  final Map<String, String> gateOptions = const {
    'Gate A': 'gateA',
    'Gate B': 'gateB',
    'Gate C': 'gateC',
    'Gate D': 'gateD',
  };

  @override
  void initState() {
    super.initState();
    StadiumLayout.buildOnce();
    CongestionModel.setScenario(_selectedScenario);
    FacilityCapacityModel.initialize();
    _detectLocation(); // Auto-detect nearest gate
    _initCrowdDetection(); // Initialize AI crowd detection
  }

  /// Initialize the CNN crowd detection model
  Future<void> _initCrowdDetection() async {
    await CrowdDetectionService.initialize();
  }

  /// Auto-check for crowd and reroute automatically (no user interaction)
  Future<void> _autoCheckCrowdAndReroute() async {
    if (_computedPath.isEmpty || _destNode == null) return;

    try {
      final recommendation = await CrowdDetectionService.checkForReroute(
        currentNodeId: _selectedStartId,
        destinationNodeId: _destNode!.id,
        currentPath: _computedPath.map((n) => n.id).toList(),
      );

      if (!mounted) return;

      // If high crowd detected, auto-reroute and show notification
      if (recommendation.shouldReroute) {
        // Show notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Crowd Detection',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        '${recommendation.reason} - Rerouting...',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        // Auto-apply alternative route
        CongestionModel.setScenario(CongestionScenario.concourseHigh);
        setState(() {
          _selectedScenario = CongestionScenario.concourseHigh;
        });

        // Recalculate path with new scenario
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && _destNode != null) {
          _computePath(_destNode!.id);

          // Show success notification
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text('Route updated to avoid crowd'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      // Silent fail - don't disturb user
      debugPrint('[CrowdDetection] Auto-check failed: $e');
    }
  }

  /// Auto-detect user's location and find nearest node (any node in stadium)
  Future<void> _detectLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Find nearest node (any node, not just gates)
      final nodeResult = await LocationService.findNearestNode();
      if (!mounted) return;

      if (nodeResult != null) {
        setState(() {
          _detectedNode = nodeResult;
          _selectedStartId = nodeResult.nodeId;
          // Also set gate result for backward compatibility
          _detectedGate = NearestGateResult(
            gateId: nodeResult.nodeId,
            gateLabel: nodeResult.nodeLabel,
            distanceMeters: nodeResult.distanceMeters,
            userLat: nodeResult.userLat,
            userLng: nodeResult.userLng,
          );
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _locationError = 'Could not get location';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Location error: $e';
        _isLoadingLocation = false;
      });
    }
  }

  /// Save current location as car parking spot
  Future<void> _saveCarLocation() async {
    setState(() => _isSavingCar = true);

    final result = await CarLocationService.saveCarLocation();

    if (!mounted) return;

    setState(() => _isSavingCar = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.success
                    ? 'Car location saved! You can navigate back anytime.'
                    : result.message,
              ),
            ),
          ],
        ),
        backgroundColor: result.success ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    if (result.success) {
      setState(() {}); // Refresh UI to show car option
    }
  }

  /// Navigate to saved car location
  void _navigateToCar() {
    if (!CarLocationService.hasCarLocation) return;

    final carGateId = CarLocationService.nearestGateId ?? 'gateA';

    setState(() {
      _navigatingToCar = true;
      _selectedDestination = null;
      _facilityResult = null;
      _seatResult = null;
    });

    // Compute path from current position to car's nearest gate
    _computePath(carGateId);

    setState(() => _navigatingToCar = false);

    // Show AR dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _computedPath.isNotEmpty) {
        _autoCheckCrowdAndReroute();
        _showArDialog();
      }
    });
  }

  /// Navigate to nearest facility from current GPS position
  Future<void> _navigateToNearestFacility(FacilityType facilityType) async {
    setState(() {
      _isSearchingNearest = true;
      _error = null;
    });

    try {
      // Get nearest facility result from GPS
      final result = await FacilitySelector.selectNearestFromGPS(
        facilityType: facilityType,
      );

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _isSearchingNearest = false;
          _error = 'Could not get your location. Please enable GPS.';
        });
        return;
      }

      // Check if user is too far from stadium (more than 100m from nearest node)
      final isTooFar = result.distanceFromUser > 100;

      // Update state with results
      setState(() {
        _isSearchingNearest = false;
        _currentPositionNode = NearestNodeResult(
          nodeId: result.startNodeId,
          nodeLabel: result.startNodeLabel,
          distanceMeters: result.distanceFromUser,
          userLat: result.userLat,
          userLng: result.userLng,
        );
        _selectedStartId = result.startNodeId;
        _facilityResult = result.facilityResult;
        _computedPath = result.path;
        _destNode = StadiumLayout.nodesById[result.recommendedFacilityId];
        _startNode = StadiumLayout.nodesById[result.startNodeId];
        _selectedDestination = facilityType == FacilityType.food
            ? DestinationOption.foodCourt
            : DestinationOption.restroom;
      });

      // Show warning if user is far from stadium
      if (isTooFar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You seem far from the stadium',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Distance: ${result.formattedDistanceToStart} - Make sure you are inside the stadium',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        // Wait a bit before showing the route notification
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
      }

      // Show notification
      final facilityLabel = StadiumLayout.labelOf(result.recommendedFacilityId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.near_me_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nearest Facility Found!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      '$facilityLabel • From ${result.startNodeLabel} (${result.formattedDistanceToStart} away)',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Auto-check crowd and show AR dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _computedPath.isNotEmpty) {
          _autoCheckCrowdAndReroute();
          _showArDialog();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearchingNearest = false;
        _error = 'Error finding nearest facility: $e';
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeArgsConsumed) return;

    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final argStartId = args['startId'] as String?;
    final argStartLabel = args['start'] as String?;
    final destLabel = args['destination'] as String?;

    final hasRelevantArgs = argStartId != null ||
        (argStartLabel != null && gateOptions.containsKey(argStartLabel)) ||
        (destLabel != null);

    if (!hasRelevantArgs) return;

    _routeArgsConsumed = true;

    if (argStartId != null) {
      _selectedStartId = argStartId;
    } else if (argStartLabel != null && gateOptions.containsKey(argStartLabel)) {
      _selectedStartId = gateOptions[argStartLabel]!;
    }

    if (destLabel != null) {
      if (gateOptions.containsKey(destLabel)) {
        final destId = gateOptions[destLabel]!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _facilityResult = null;
            _seatResult = null;
          });
          _computePath(destId);
        });
      } else {
        final option = _destinationOptionFromCameraLabel(destLabel);
        if (option != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _selectedDestination = option;
              _facilityResult = null;
              _seatResult = null;
              _seatDetails = const SeatDetails();
              _computedPath = [];
            });
            _onNavigate();
          });
        }
      }
    } else if (argStartId != null ||
        (argStartLabel != null && gateOptions.containsKey(argStartLabel))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  /// Maps labels from [CameraNavScreen] to [DestinationOption].
  DestinationOption? _destinationOptionFromCameraLabel(String label) {
    final s = label.toLowerCase();
    if (s.contains('vip')) return DestinationOption.vip;
    if (s.contains('standard')) return DestinationOption.standard;
    if (s.contains('food')) return DestinationOption.foodCourt;
    if (s.contains('restroom')) return DestinationOption.restroom;
    return null;
  }

  Future<void> _onOpenUnityAr() async {
    final goalId = _destNode?.id ??
        (_computedPath.isNotEmpty ? _computedPath.last.id : null);
    if (goalId == null) return;

    final bool opened;
    if (_computedPath.length >= 2) {
      opened = await UnityNavigationBridge.openUnityWithNavigation(
        pathNodeIds: _computedPath.map((n) => n.id).toList(),
      );
    } else {
      opened = await UnityNavigationBridge.openUnityWithNavigation(
        startNodeId: _selectedStartId,
        goalNodeId: goalId,
      );
    }

    if (!mounted) return;
    final camOk = await Permission.camera.isGranted;
    if (!mounted) return;
    final failMsg = !camOk
        ? 'Camera permission is required for AR. Allow camera for this app in system settings.'
        : 'Unity AR could not be opened. Ensure unityLibrary is in android/ and the app was rebuilt.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened
              ? 'Opening Unity AR with this route. Use the system back button to return to the app.'
              : failMsg,
        ),
      ),
    );
  }

  /// Core pathfinding
  void _computePath(String destNodeId) {
    final nodes = StadiumLayout.nodesById;
    final graph = StadiumLayout.graph;

    final startNode = nodes[_selectedStartId];
    final destNode = nodes[destNodeId];

    if (startNode == null || destNode == null) {
      setState(() {
        _computedPath = [];
        _startNode = null;
        _destNode = null;
        _error = 'Node not found';
      });
      return;
    }

    const useCongestion = true;
    final path = Pathfinder.findPath(
      graph: graph,
      start: startNode,
      end: destNode,
      algorithm: _selectedAlgorithm,
      useCongestion: useCongestion,
    );

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('DEBUG: algorithm=${_selectedAlgorithm.name.toUpperCase()}, '
        'useCongestion=$useCongestion');
    debugPrint('DEBUG: path=[${path.map((n) => n.id).join(" → ")}]');
    debugPrint('═══════════════════════════════════════════════════════');

    setState(() {
      _computedPath = path;
      _startNode = startNode;
      _destNode = destNode;
      _error = path.isEmpty ? 'No path found' : null;
    });
  }

  /// Navigate button pressed
  void _onNavigate() {
    if (_selectedDestination == null) return;

    _facilityResult = null;
    _seatResult = null;

    final dest = _selectedDestination!;

    if (dest.isSeatSection) {
      // Seat section - check if specific seat provided
      if (_seatDetails.isComplete) {
        _navigateToSeat(dest);
      } else {
        // Navigate to section entrance
        _computePath(dest.nodeId);
      }
    } else {
      // Facility - use smart recommend
      _navigateToFacility(dest);
    }

    // After calculating the path, run AI crowd detection automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _computedPath.isNotEmpty) {
        _autoCheckCrowdAndReroute();
        _showArDialog();
      }
    });
  }

  void _navigateToSeat(DestinationOption dest) {
    final ticket = TicketPayload(
      matchTitle: '',
      matchDate: '',
      venue: '',
      category: dest == DestinationOption.vip ? 'VIP' : 'Standard',
      gate: 'A',
      section: '${_seatDetails.row}',
      seat: '${_seatDetails.seat}',
    );

    final result = SeatNavigator.navigateToSeat(
      startNodeId: _selectedStartId,
      ticket: ticket,
    );

    setState(() {
      _seatResult = result;
      _computedPath = result.graphPath;
      _destNode = StadiumLayout.nodesById[result.sectionNodeId];
      _error = result.isValid ? null : 'Unable to find route';
    });
  }

  void _navigateToFacility(DestinationOption dest) {
    final facilityType = dest == DestinationOption.foodCourt
        ? FacilityType.food
        : FacilityType.restroom;

    final result = FacilitySelector.selectBest(
      startNodeId: _selectedStartId,
      facilityType: facilityType,
    );

    setState(() {
      _facilityResult = result;
      _computedPath = result.path;
      _destNode = StadiumLayout.nodesById[result.recommendedNodeId];
      _error = null;
    });
  }

  void _onStartChanged(String? newStartId) {
    if (newStartId == null || newStartId == _selectedStartId) return;
    setState(() {
      _selectedStartId = newStartId;
      _facilityResult = null;
      _seatResult = null;
      _computedPath = [];
    });
  }

  void _onDestinationChanged(DestinationOption dest) {
    setState(() {
      _selectedDestination = dest;
      _facilityResult = null;
      _seatResult = null;
      _seatDetails = const SeatDetails();
      _computedPath = [];
    });
  }

  void _onSeatDetailsChanged(SeatDetails details) {
    setState(() {
      _seatDetails = details;
    });
  }

  void _onAlgorithmChanged(PathfindingAlgorithm algo) {
    if (algo == _selectedAlgorithm) return;
    setState(() {
      _selectedAlgorithm = algo;
      _facilityResult = null;
      _seatResult = null;
    });
    if (_selectedDestination != null && _computedPath.isNotEmpty) {
      _onNavigate();
    }
  }

  void _onScenarioChanged(CongestionScenario? scenario) {
    if (scenario == null || scenario == _selectedScenario) return;
    setState(() {
      _selectedScenario = scenario;
    });
    CongestionModel.setScenario(scenario);
    FacilitySelector.invalidateCache();
    if (_selectedDestination != null && _computedPath.isNotEmpty) {
      _onNavigate();
    }
  }

  SeatMarkerInfo? _createSeatMarker() {
    if (!_seatDetails.isComplete || _selectedDestination == null) return null;
    if (!_selectedDestination!.isSeatSection) return null;

    return SeatMarkerInfo.fromTicket(
      category: _selectedDestination == DestinationOption.vip ? 'VIP' : 'Standard',
      row: _seatDetails.row!,
      seat: _seatDetails.seat!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapKey =
        '${_selectedStartId}_${_selectedDestination?.nodeId}_${_selectedAlgorithm.name}_${_selectedScenario.name}_${_computedPath.length}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Smart Navigation',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Input Card
              _buildInputCard(),

              const SizedBox(height: 10),

              // Compact Status Row
              _buildStatusRow(),

              const SizedBox(height: 10),

              // Phase 5: Capacity card
              if (_facilityResult != null) ...[
                CapacityStatusCard(result: _facilityResult!),
                const SizedBox(height: 10),
                RerouteBanner(
                  result: _facilityResult!,
                  onAcceptReroute: _facilityResult!.alternatives.isNotEmpty
                      ? () {
                          final alt = _facilityResult!.alternatives.first;
                          _computePath(alt.nodeId);
                        }
                      : null,
                ),
                const SizedBox(height: 10),
              ],

              // Seat info card
              if (_seatResult != null && _seatDetails.isComplete)
                _buildSeatInfoCard(),

              // Nearby facilities
              if (_seatResult != null &&
                  _seatResult!.nearbyFacilities.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NearbyFacilitiesBanner(
                    facilities: _seatResult!.nearbyFacilities,
                    onFacilitySelected: (nodeId) => _computePath(nodeId),
                  ),
                ),

              // Collapsible Map
              if (_computedPath.isNotEmpty) _buildCollapsibleMap(mapKey),

              const SizedBox(height: 10),

              // Error
              if (_error != null) _buildErrorCard(),

              // Steps
              if (_computedPath.isNotEmpty) ...[
                _buildStepsHeader(),
                ..._buildStepCards(),
              ] else if (_selectedDestination == null)
                _buildEmptyState(),

              // Final seat directions
              if (_seatResult != null && _computedPath.isNotEmpty)
                _buildFinalSeatDirections(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    final showSeatDetails = _selectedDestination?.isSeatSection ?? false;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Start Gate
          _buildStartGateRow(),

          const SizedBox(height: 12),

          // Destination chips
          DestinationChipSelector(
            selected: _selectedDestination,
            onSelected: _onDestinationChanged,
          ),

          // Animated seat details
          AnimatedSeatDetails(
            isVisible: showSeatDetails,
            sectionName: _selectedDestination?.label ?? '',
            accentColor: _selectedDestination?.accentColor ?? Colors.grey,
            onChanged: _onSeatDetailsChanged,
          ),

          const SizedBox(height: 14),

          // Navigate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedDestination != null ? _onNavigate : null,
              icon: const Icon(Icons.navigation_rounded, size: 18),
              label: Text(
                _getNavigateButtonText(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedDestination?.accentColor ??
                    const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ),
          if (UnityNavigationBridge.isSupportedPlatform) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _computedPath.isNotEmpty ? _onOpenUnityAr : null,
                icon: const Icon(Icons.view_in_ar_outlined, size: 18),
                label: const Text(
                  'Send route to Unity AR',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getNavigateButtonText() {
    if (_selectedDestination == null) return 'Select Destination';

    if (_selectedDestination!.isSeatSection && _seatDetails.isComplete) {
      return 'Navigate to Seat';
    }

    return 'Navigate';
  }

  Widget _buildStartGateRow() {
    final bool useMyLocation = _detectedGate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.my_location_rounded,
                color: Color(0xFF0D47A1),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Start From',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // My Location Button (Primary)
        GestureDetector(
          onTap: _isLoadingLocation ? null : _detectLocation,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: useMyLocation ? Colors.green.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: useMyLocation ? Colors.green.shade400 : Colors.blue.shade300,
                width: useMyLocation ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: useMyLocation ? Colors.green.shade100 : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isLoadingLocation
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue.shade600,
                          ),
                        )
                      : Icon(
                          Icons.gps_fixed,
                          size: 20,
                          color: useMyLocation ? Colors.green.shade700 : Colors.blue.shade700,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Current Location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: useMyLocation ? Colors.green.shade800 : Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        useMyLocation
                            ? 'Nearest: ${_detectedNode?.nodeLabel ?? _detectedGate!.gateLabel} (${_detectedNode?.formattedDistance ?? _detectedGate!.formattedDistance})'
                            : _isLoadingLocation
                                ? 'Detecting location...'
                                : 'Tap to detect nearest point',
                        style: TextStyle(
                          fontSize: 11,
                          color: useMyLocation ? Colors.green.shade600 : Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (useMyLocation)
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 22),
              ],
            ),
          ),
        ),

        // Error message
        if (_locationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.orange.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'GPS unavailable - select gate manually below',
                    style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 10),

        // Manual Gate Selection (Secondary)
        Row(
          children: [
            Text(
              'Or select gate:',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: gateOptions.entries.map((e) {
                    final isSelected = _selectedStartId == e.value && !useMyLocation;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _detectedGate = null; // Clear GPS selection
                          });
                          _onStartChanged(e.value);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            e.key,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),

        // Car location row
        const SizedBox(height: 10),
        Row(
          children: [
            // Save Car Location button
            Expanded(
              child: GestureDetector(
                onTap: _isSavingCar ? null : _saveCarLocation,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: CarLocationService.hasCarLocation
                        ? Colors.teal.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CarLocationService.hasCarLocation
                          ? Colors.teal.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isSavingCar
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.local_parking_rounded,
                              size: 16,
                              color: CarLocationService.hasCarLocation
                                  ? Colors.teal.shade600
                                  : Colors.grey.shade600,
                            ),
                      const SizedBox(width: 6),
                      Text(
                        CarLocationService.hasCarLocation
                            ? 'Car Saved ${CarLocationService.timeSinceSaved}'
                            : 'Save Car Location',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: CarLocationService.hasCarLocation
                              ? Colors.teal.shade700
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Navigate to Car button (only if car is saved)
            if (CarLocationService.hasCarLocation) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _navigateToCar,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.directions_car_rounded, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Go to Car',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatusRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildAlgorithmPill(),
          const SizedBox(width: 8),
          Container(width: 1, height: 16, color: Colors.grey.shade300),
          const SizedBox(width: 8),
          _buildCrowdPill(),
          const Spacer(),
          if (_computedPath.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_computedPath.length} steps',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlgorithmPill() {
    final isAStar = _selectedAlgorithm == PathfindingAlgorithm.aStar;
    return GestureDetector(
      onTap: () => _onAlgorithmChanged(
        isAStar ? PathfindingAlgorithm.dijkstra : PathfindingAlgorithm.aStar,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isAStar ? Colors.green.shade50 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAStar ? Colors.green.shade300 : Colors.blue.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.route_rounded,
              size: 12,
              color: isAStar ? Colors.green.shade600 : Colors.blue.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              _selectedAlgorithm.displayName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isAStar ? Colors.green.shade700 : Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrowdPill() {
    final isLow = _selectedScenario == CongestionScenario.allLow;
    return GestureDetector(
      onTap: _showCrowdDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isLow ? Colors.grey.shade100 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLow ? Colors.grey.shade300 : Colors.orange.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_rounded,
              size: 12,
              color: isLow ? Colors.grey.shade600 : Colors.orange.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              _selectedScenario.displayName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isLow ? Colors.grey.shade700 : Colors.orange.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCrowdDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crowd Scenario',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...CongestionScenario.values.map((s) {
              final selected = s == _selectedScenario;
              return ListTile(
                dense: true,
                onTap: () {
                  _onScenarioChanged(s);
                  Navigator.pop(context);
                },
                leading: Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? Colors.green : Colors.grey,
                  size: 20,
                ),
                title: Text(s.displayName, style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                  s.description,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                tileColor: selected ? Colors.green.shade50 : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Open crowd scan camera screen
  void _openCrowdScan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrowdScanScreen(
          currentPath: _computedPath.map((n) => n.id).join(' -> '),
          destination: _destNode?.id ?? '',
          onScanComplete: (shouldReroute, crowdCount) {
            if (shouldReroute && _destNode != null) {
              // Reroute to avoid crowd
              CongestionModel.setScenario(CongestionScenario.concourseHigh);
              setState(() {
                _selectedScenario = CongestionScenario.concourseHigh;
              });
              _computePath(_destNode!.id);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.alt_route_rounded, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Rerouted! Detected $crowdCount people.'),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            // Now open AR
            _onOpenUnityAr();
          },
        ),
      ),
    );
  }

  void _showArDialog() {
    final isArSupported = UnityNavigationBridge.isSupportedPlatform;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isArSupported ? Icons.view_in_ar_rounded : Icons.check_circle_rounded,
                color: const Color(0xFF0D47A1),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isArSupported ? 'Ready to Navigate' : 'Route Ready!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your route is ready with ${_computedPath.length} steps.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            // Scan Crowd Option
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.psychology_rounded, size: 20, color: Colors.purple.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scan crowd with AI camera to detect congestion before navigating.',
                      style: TextStyle(fontSize: 12, color: Colors.purple.shade900),
                    ),
                  ),
                ],
              ),
            ),
            if (isArSupported) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.view_in_ar_rounded, size: 20, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Or go directly to AR navigation.',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          // Scan Crowd Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openCrowdScan();
            },
            icon: const Icon(Icons.camera_alt_rounded, size: 18),
            label: const Text('Scan Crowd'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          if (isArSupported)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _onOpenUnityAr();
              },
              icon: const Icon(Icons.view_in_ar_rounded, size: 18),
              label: const Text('Skip to AR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleMap(String mapKey) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isMapExpanded = !_isMapExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.map_rounded, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Stadium Map',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isMapExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _isMapExpanded ? 180 : 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              child: _isMapExpanded
                  ? MiniStadiumMap(
                      key: ValueKey(mapKey),
                      startNode: _startNode,
                      destinationNode: _destNode,
                      path: _computedPath,
                      congestionScenario: _selectedScenario,
                      seatMarker: _createSeatMarker(),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatInfoCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                  'Your Seat',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                Text(
                  '${_selectedDestination?.label} - Row ${_seatDetails.row}, Seat ${_seatDetails.seat}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
              _selectedDestination?.shortLabel ?? '',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalSeatDirections() {
    if (_seatResult == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.directions, color: Colors.amber.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Final Directions',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade800,
                  ),
                ),
                Text(
                  _seatResult!.localDirections.isNotEmpty
                      ? _seatResult!.localDirections
                      : 'Follow signs to your seat',
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.touch_app_rounded, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Select a destination to get started',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(
              Icons.directions_walk_rounded,
              color: Color(0xFF0D47A1),
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Route',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0D47A1),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStepCards() {
    if (_destNode == null) return [];

    return List.generate(_computedPath.length, (i) {
      final node = _computedPath[i];
      final isFirst = i == 0;
      final isLast = i == _computedPath.length - 1;
      final nextNode = isLast ? null : _computedPath[i + 1];

      bool isNextCongested = false;
      if (nextNode != null) {
        final congestion = CongestionModel.getCongestion(node.id, nextNode.id);
        isNextCongested = congestion == CongestionLevel.high;
      }

      final instruction = InstructionBuilder.build(
        node: node,
        destination: _destNode!,
        isFirst: isFirst,
        isLast: isLast,
        next: nextNode,
      );

      return Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : 3),
        decoration: BoxDecoration(
          color: isLast ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isLast
                ? Colors.green.shade300
                : isNextCongested
                    ? Colors.orange.shade300
                    : Colors.grey.shade200,
            width: isLast ? 1.5 : 1,
          ),
        ),
        child: ListTile(
          dense: true,
          visualDensity: const VisualDensity(vertical: -3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          leading: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLast
                    ? [Colors.green.shade400, Colors.green.shade600]
                    : isFirst
                        ? [const Color(0xFF1976D2), const Color(0xFF0D47A1)]
                        : [Colors.grey.shade400, Colors.grey.shade500],
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: isLast
                  ? const Icon(Icons.flag_rounded, color: Colors.white, size: 12)
                  : isFirst
                      ? const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 12)
                      : Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
            ),
          ),
          title: Text(
            instruction,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isFirst || isLast ? FontWeight.w600 : FontWeight.w500,
              color: isLast ? Colors.green.shade700 : Colors.black87,
            ),
          ),
          subtitle: isNextCongested
              ? Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 10, color: Colors.orange.shade700),
                      const SizedBox(width: 3),
                      Text(
                        'Crowded',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : null,
          trailing: isLast
              ? Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 16)
              : null,
        ),
      );
    });
  }

}
