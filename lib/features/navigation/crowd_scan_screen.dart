import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../core/crowd_detection_service.dart';

/// Screen for scanning crowd using camera and CSRNet AI
class CrowdScanScreen extends StatefulWidget {
  final String currentPath;
  final String destination;
  final Function(bool shouldReroute, int crowdCount) onScanComplete;

  const CrowdScanScreen({
    super.key,
    required this.currentPath,
    required this.destination,
    required this.onScanComplete,
  });

  @override
  State<CrowdScanScreen> createState() => _CrowdScanScreenState();
}

class _CrowdScanScreenState extends State<CrowdScanScreen> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isScanning = false;
  CrowdDetectionResult? _result;
  String? _error;

  // Live Mode
  bool _isLiveMode = false;
  Timer? _liveTimer;
  int _scanCount = 0;
  static const _liveScanInterval = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera available');
        return;
      }

      // Use back camera
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      setState(() => _error = 'Camera error: $e');
    }
  }

  Future<void> _scanCrowd() async {
    if (_cameraController == null || !_isInitialized || _isScanning) return;

    setState(() {
      _isScanning = true;
      if (!_isLiveMode) {
        _result = null;
      }
      _error = null;
    });

    try {
      // Capture image
      final XFile imageFile = await _cameraController!.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Send to CSRNet API
      final result = await CrowdDetectionService.analyzeImage(imageBytes);

      if (mounted) {
        setState(() {
          _result = result;
          _isScanning = false;
          _scanCount++;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Scan failed: $e';
          _isScanning = false;
        });
      }
    }
  }

  void _toggleLiveMode() {
    setState(() {
      _isLiveMode = !_isLiveMode;
      _scanCount = 0;
    });

    if (_isLiveMode) {
      _startLiveScanning();
    } else {
      _stopLiveScanning();
    }
  }

  void _startLiveScanning() {
    // Do initial scan
    _scanCrowd();

    // Set up periodic scanning
    _liveTimer = Timer.periodic(_liveScanInterval, (_) {
      if (mounted && _isLiveMode && !_isScanning) {
        _scanCrowd();
      }
    });
  }

  void _stopLiveScanning() {
    _liveTimer?.cancel();
    _liveTimer = null;
  }

  void _confirmAndContinue() {
    final shouldReroute = _result?.level.shouldReroute ?? false;
    final count = _result?.estimatedCount ?? 0;
    widget.onScanComplete(shouldReroute, count);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _stopLiveScanning();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('AI Crowd Detection'),
            if (_isLiveMode) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // Live Mode Toggle
          IconButton(
            onPressed: _isInitialized ? _toggleLiveMode : null,
            icon: Icon(
              _isLiveMode ? Icons.stop_circle_rounded : Icons.play_circle_rounded,
              color: _isLiveMode ? Colors.red : Colors.white,
            ),
            tooltip: _isLiveMode ? 'Stop Live Mode' : 'Start Live Mode',
          ),
          if (_result != null)
            TextButton(
              onPressed: _confirmAndContinue,
              child: const Text('Continue', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Camera Preview
          Expanded(
            flex: 3,
            child: _buildCameraPreview(),
          ),

          // Results Panel
          Expanded(
            flex: 2,
            child: _buildResultsPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    if (!_isInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Camera preview
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CameraPreview(_cameraController!),
        ),

        // Scanning overlay
        if (_isScanning)
          Container(
            color: _isLiveMode ? Colors.black26 : Colors.black54,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: _isLiveMode ? Colors.red : Colors.white,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isLiveMode ? 'Live scanning...' : 'Analyzing crowd...',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Using CSRNet AI',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),

        // Live mode corner indicator
        if (_isLiveMode && !_isScanning)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Grid overlay
        if (!_isScanning)
          CustomPaint(
            size: Size.infinite,
            painter: _GridPainter(),
          ),
      ],
    );
  }

  Widget _buildResultsPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          if (_result == null && !_isScanning) ...[
            // Instructions
            Icon(Icons.camera_alt_rounded, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            const Text(
              'Point camera at the crowd',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'CSRNet AI will count people and detect congestion',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const Spacer(),

            // Buttons Row
            Row(
              children: [
                // Live Mode button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isInitialized ? _toggleLiveMode : null,
                    icon: Icon(_isLiveMode ? Icons.stop : Icons.stream),
                    label: Text(_isLiveMode ? 'Stop Live' : 'Live Mode'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _isLiveMode ? Colors.red : Colors.purple,
                      side: BorderSide(color: _isLiveMode ? Colors.red : Colors.purple),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Single Scan button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _scanCrowd,
                    icon: const Icon(Icons.psychology_rounded),
                    label: const Text('Scan Crowd'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (_result != null) ...[
            // Live mode indicator
            if (_isLiveMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LIVE - Auto-scanning every 3 sec',
                      style: TextStyle(color: Colors.red.shade300, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($_scanCount scans)',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                    ),
                  ],
                ),
              ),
            // Results
            _buildResultCard(),
            const Spacer(),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLiveMode ? _toggleLiveMode : _scanCrowd,
                    icon: Icon(_isLiveMode ? Icons.stop : Icons.refresh),
                    label: Text(_isLiveMode ? 'Stop' : 'Rescan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _isLiveMode ? Colors.red : Colors.white,
                      side: BorderSide(color: _isLiveMode ? Colors.red : Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _confirmAndContinue,
                    icon: Icon(_result!.level.shouldReroute
                        ? Icons.alt_route_rounded
                        : Icons.arrow_forward_rounded),
                    label: Text(_result!.level.shouldReroute
                        ? 'Reroute & Continue'
                        : 'Continue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _result!.level.shouldReroute
                          ? Colors.orange
                          : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _result!;
    final color = _getColorForLevel(result.level);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconForLevel(result.level),
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${result.estimatedCount} People Detected',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            result.level.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (CrowdDetectionService.isApiAvailable)
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade400, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'CSRNet AI',
                                style: TextStyle(color: Colors.green.shade400, fontSize: 11),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey.shade400, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Simulation',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (result.level.shouldReroute) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'High congestion detected! Alternative route recommended.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getColorForLevel(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low:
        return Colors.green;
      case CrowdLevel.moderate:
        return Colors.yellow.shade700;
      case CrowdLevel.high:
        return Colors.orange;
      case CrowdLevel.veryHigh:
        return Colors.red;
    }
  }

  IconData _getIconForLevel(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low:
        return Icons.check_circle_rounded;
      case CrowdLevel.moderate:
        return Icons.people_rounded;
      case CrowdLevel.high:
        return Icons.warning_rounded;
      case CrowdLevel.veryHigh:
        return Icons.dangerous_rounded;
    }
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;

    // Vertical lines
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(2 * size.width / 3, 0),
      Offset(2 * size.width / 3, size.height),
      paint,
    );

    // Horizontal lines
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, 2 * size.height / 3),
      Offset(size.width, 2 * size.height / 3),
      paint,
    );

    // Corner brackets
    final bracketPaint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const bracketSize = 40.0;
    const margin = 20.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(margin, margin + bracketSize)
        ..lineTo(margin, margin)
        ..lineTo(margin + bracketSize, margin),
      bracketPaint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - margin - bracketSize, margin)
        ..lineTo(size.width - margin, margin)
        ..lineTo(size.width - margin, margin + bracketSize),
      bracketPaint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(margin, size.height - margin - bracketSize)
        ..lineTo(margin, size.height - margin)
        ..lineTo(margin + bracketSize, size.height - margin),
      bracketPaint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - margin - bracketSize, size.height - margin)
        ..lineTo(size.width - margin, size.height - margin)
        ..lineTo(size.width - margin, size.height - margin - bracketSize),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
