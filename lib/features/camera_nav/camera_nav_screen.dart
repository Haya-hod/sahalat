import 'package:flutter/material.dart';
import '../navigation/navigation_steps_screen.dart';

/// Redirect to the advanced NavigationStepsScreen
class CameraNavScreen extends StatelessWidget {
  static const route = '/camera';
  const CameraNavScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Immediately redirect to the advanced navigation screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed(NavigationStepsScreen.route);
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
