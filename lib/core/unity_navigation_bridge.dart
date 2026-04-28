import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Sends navigation intents to an embedded Unity player on Android.
///
/// Requires:
/// - Unity exported as a library and merged into this app's Android project, and
/// - A GameObject named **FlutterBridge** with Unity methods `ReceiveSimplePathMessage`
///   and `ReceivePathFromFlutter` in the running Unity scene.
///
/// Without that, [sendSimplePath] returns `false` and the app keeps working in Flutter-only mode.
class UnityNavigationBridge {
  UnityNavigationBridge._();

  static const MethodChannel _channel =
      MethodChannel('com.example.sahalat/unity_nav');

  static bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Notifies Unity to run A* from [startNodeId] to [goalNodeId] and refresh the AR line.
  static Future<bool> sendSimplePath({
    required String startNodeId,
    required String goalNodeId,
  }) async {
    if (!isSupportedPlatform) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('startArNavigation', {
        'startNodeId': startNodeId,
        'goalNodeId': goalNodeId,
      });
      return ok ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('UnityNavigationBridge: ${e.message}');
      return false;
    }
  }

  /// Sends the exact path Flutter computed (node ID order) so Unity draws the same route
  /// without re-running A*. [nodeIds] must match IDs in Unity's [StadiumLayout].
  ///
  /// Unity receives JSON via `FlutterBridge.ReceivePathFromFlutter`, e.g.
  /// `["gateA","concourseMain","vip"]`.
  /// Opens the Unity AR player and passes the route so it applies on startup.
  /// Prefer this over [sendFlutterPath] / [sendSimplePath] when Unity is not already running.
  static Future<bool> openUnityWithNavigation({
    List<String>? pathNodeIds,
    String? startNodeId,
    String? goalNodeId,
  }) async {
    if (!isSupportedPlatform) return false;
    final cam = await Permission.camera.request();
    if (!cam.isGranted) {
      debugPrint(
        'UnityNavigationBridge: camera permission denied — AR needs camera access.',
      );
      return false;
    }
    String? pathJson;
    if (pathNodeIds != null && pathNodeIds.length >= 2) {
      pathJson = jsonEncode(pathNodeIds);
    }
    try {
      final ok = await _channel.invokeMethod<bool>('openUnityAr', {
        'pathJson': pathJson,
        'startNodeId': startNodeId,
        'goalNodeId': goalNodeId,
      });
      return ok ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('UnityNavigationBridge: ${e.code} ${e.message}');
      return false;
    }
  }

  static Future<bool> sendFlutterPath(List<String> nodeIds) async {
    if (!isSupportedPlatform) return false;
    if (nodeIds.length < 2) return false;
    try {
      final pathJson = jsonEncode(nodeIds);
      final ok = await _channel.invokeMethod<bool>('renderFlutterPath', {
        'pathJson': pathJson,
      });
      return ok ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('UnityNavigationBridge: ${e.message}');
      return false;
    }
  }
}
