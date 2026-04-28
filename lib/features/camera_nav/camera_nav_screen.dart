import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/navigation_steps_screen.dart';
import '../navigation/crowd_scan_screen.dart';
import '../../core/locale_state.dart';
import '../../core/strings.dart';
import '../../colors.dart';

class CameraNavScreen extends StatefulWidget {
  static const route = '/camera';
  const CameraNavScreen({super.key});

  @override
  State<CameraNavScreen> createState() => _CameraNavScreenState();
}

class _CameraNavScreenState extends State<CameraNavScreen> {
  CameraController? _controller;
  Future<void>? _init;

  double? savedLat;
  double? savedLng;

  String _selectedGate = 'Gate A';

  @override
  void initState() {
    super.initState();
    _init = _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) return;

      final cam = cams.first;
      _controller = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (_) {
      // Camera initialisation failed; the UI falls back to the no-camera view.
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _openCrowdScan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrowdScanScreen(
          currentPath: _selectedGate,
          destination: 'Stadium',
          onScanComplete: (shouldReroute, crowdCount) {
            if (shouldReroute) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('High crowd detected: $crowdCount people. Consider alternative route.'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 4),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Path is clear: $crowdCount people detected.'),
                  backgroundColor: AppColors.green,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleState>().locale.languageCode;
    final l = L(lang);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.t('nav_camera')),
        actions: [
          // AI Crowd Scan button in app bar
          IconButton(
            onPressed: () => _openCrowdScan(context),
            icon: const Icon(Icons.psychology_rounded),
            tooltip: 'AI Crowd Detection',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCrowdScan(context),
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.psychology_rounded, color: Colors.white),
        label: const Text('AI Scan', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder(
        future: _init,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!(_controller?.value.isInitialized ?? false)) {
            return _buildFallbackUI(context, l);
          }

          return Stack(
            children: [
              CameraPreview(_controller!),

              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(child: _buildSaveCarBtn(l)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildDestinationBtn(context, l)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFallbackUI(BuildContext context, L l) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_outlined, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            l.t('camera_not_available'),
            style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 40),
          _buildSaveCarBtn(l),
          const SizedBox(height: 20),
          _buildDestinationBtn(context, l),
        ],
      ),
    );
  }

  Widget _buildSaveCarBtn(L l) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: () {
        savedLat = 24.7156;
        savedLng = 46.6773;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${l.t('saved_car_success')}$savedLat, $savedLng"),
            backgroundColor: AppColors.green,
          ),
        );
      },
      icon: const Icon(Icons.directions_car, size: 22),
      label: Text(
        l.t('save_car_location'),
        style: const TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDestinationBtn(BuildContext context, L l) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: () => _showDestinationSheet(context, l),
      icon: const Icon(Icons.place, size: 22),
      label: Text(
        l.t('where_to_go'),
        style: const TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showDestinationSheet(BuildContext context, L l) {
    final destinations = [
      'Gate A',
      'Gate B',
      'Gate C',
      'Gate D',
      'VIP Section',
      'Standard Section',
      'Food Court',
      'Restrooms',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final size = MediaQuery.of(context).size;
        final height = size.height * 0.55;

        return Container(
          height: height,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.t('choose_destination'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  itemCount: destinations.length,
                  itemBuilder: (_, i) {
                    return ListTile(
                      leading: const Icon(Icons.navigation, color: AppColors.primary),
                      title: Text(destinations[i]),
                      onTap: () {
                        Navigator.pop(context);

                        Navigator.pushNamed(
                          context,
                          NavigationStepsScreen.route,
                          arguments: {
                            'start': _selectedGate,
                            'destination': destinations[i],
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.t('close')),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
