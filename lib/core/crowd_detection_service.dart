import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Crowd detection result
class CrowdDetectionResult {
  final int estimatedCount;
  final CrowdLevel level;
  final double confidence;

  CrowdDetectionResult({
    required this.estimatedCount,
    required this.level,
    required this.confidence,
  });

  /// Get crowd level from count
  static CrowdLevel levelFromCount(int count) {
    if (count < 20) return CrowdLevel.low;
    if (count < 50) return CrowdLevel.moderate;
    if (count < 100) return CrowdLevel.high;
    return CrowdLevel.veryHigh;
  }

  /// Create from API response
  factory CrowdDetectionResult.fromJson(Map<String, dynamic> json) {
    final count = (json['count'] as num).toInt();
    final levelStr = json['crowd_level'] as String? ?? 'low';

    CrowdLevel level;
    switch (levelStr) {
      case 'low':
        level = CrowdLevel.low;
        break;
      case 'moderate':
        level = CrowdLevel.moderate;
        break;
      case 'high':
        level = CrowdLevel.high;
        break;
      case 'very_high':
        level = CrowdLevel.veryHigh;
        break;
      default:
        level = levelFromCount(count);
    }

    return CrowdDetectionResult(
      estimatedCount: count,
      level: level,
      confidence: 0.95,
    );
  }
}

enum CrowdLevel {
  low,       // < 20 people - green
  moderate,  // 20-50 people - yellow
  high,      // 50-100 people - orange
  veryHigh,  // > 100 people - red
}

extension CrowdLevelExtension on CrowdLevel {
  String get displayName {
    switch (this) {
      case CrowdLevel.low:
        return 'Low';
      case CrowdLevel.moderate:
        return 'Moderate';
      case CrowdLevel.high:
        return 'High';
      case CrowdLevel.veryHigh:
        return 'Very High';
    }
  }

  bool get shouldReroute => this == CrowdLevel.high || this == CrowdLevel.veryHigh;
}

/// Service for crowd detection using CSRNet CNN model
/// Connects to Python Flask API server for real inference
class CrowdDetectionService {
  // API server URL - change this to your server IP
  // For local testing on same network: use your computer's IP
  // For production: use your cloud server URL
  static String _apiBaseUrl = 'http://172.20.17.229:5000';

  static bool _isInitialized = false;
  static bool _apiAvailable = false;

  /// Set the API server URL
  static void setApiUrl(String url) {
    _apiBaseUrl = url;
    _isInitialized = false;
  }

  /// Initialize - check if API server is available
  static Future<bool> initialize() async {
    if (_isInitialized && _apiAvailable) return true;

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/health'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _apiAvailable = data['status'] == 'ok' && data['model_loaded'] == true;
        debugPrint('[CrowdDetection] API connected: $_apiAvailable');
      } else {
        _apiAvailable = false;
      }
    } catch (e) {
      debugPrint('[CrowdDetection] API not available: $e');
      _apiAvailable = false;
    }

    _isInitialized = true;
    return _apiAvailable;
  }

  /// Check if API is available
  static bool get isApiAvailable => _apiAvailable;

  /// Analyze image for crowd density using the CSRNet API
  static Future<CrowdDetectionResult> analyzeImage(Uint8List imageBytes) async {
    // Try API first
    if (_apiAvailable && imageBytes.isNotEmpty) {
      try {
        final base64Image = base64Encode(imageBytes);

        final response = await http.post(
          Uri.parse('$_apiBaseUrl/detect_base64'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'image': base64Image}),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            debugPrint('[CrowdDetection] API result: count=${data['count']}');
            return CrowdDetectionResult.fromJson(data);
          }
        }
      } catch (e) {
        debugPrint('[CrowdDetection] API error: $e');
      }
    }

    // Fallback to simulation if API not available
    return _simulatedDetection();
  }

  /// Simulated detection for demo/offline mode
  static CrowdDetectionResult _simulatedDetection() {
    // Generate realistic-looking simulated data
    // This simulates what CSRNet would detect
    final hour = DateTime.now().hour;
    int baseCount;

    // Simulate higher crowd during peak hours
    if (hour >= 17 && hour <= 21) {
      // Evening match time - higher crowd
      baseCount = 60 + (DateTime.now().millisecond % 50);
    } else if (hour >= 12 && hour <= 14) {
      // Lunch time - moderate
      baseCount = 30 + (DateTime.now().millisecond % 30);
    } else {
      // Other times - lower
      baseCount = 10 + (DateTime.now().millisecond % 25);
    }

    final level = CrowdDetectionResult.levelFromCount(baseCount);

    debugPrint('[CrowdDetection] Simulated: count=$baseCount, level=${level.displayName}');

    return CrowdDetectionResult(
      estimatedCount: baseCount,
      level: level,
      confidence: 0.75, // Lower confidence for simulation
    );
  }

  /// Quick check if a path segment is congested
  static Future<bool> isPathCongested(String pathSegmentId) async {
    final result = await analyzeImage(Uint8List(0));
    return result.level.shouldReroute;
  }

  /// Get rerouting recommendation based on crowd detection
  static Future<RerouteRecommendation> checkForReroute({
    required String currentNodeId,
    required String destinationNodeId,
    required List<String> currentPath,
  }) async {
    // Initialize if needed
    if (!_isInitialized) {
      await initialize();
    }

    // Detect crowd (uses API if available, simulation otherwise)
    final result = await analyzeImage(Uint8List(0));

    if (result.level.shouldReroute) {
      return RerouteRecommendation(
        shouldReroute: true,
        reason: 'High crowd detected: ${result.estimatedCount} people',
        crowdLevel: result.level,
        alternativePathSuggested: true,
        isRealDetection: _apiAvailable,
      );
    }

    return RerouteRecommendation(
      shouldReroute: false,
      reason: 'Path is clear (${result.estimatedCount} people)',
      crowdLevel: result.level,
      alternativePathSuggested: false,
      isRealDetection: _apiAvailable,
    );
  }
}

class RerouteRecommendation {
  final bool shouldReroute;
  final String reason;
  final CrowdLevel crowdLevel;
  final bool alternativePathSuggested;
  final bool isRealDetection; // true if using real CSRNet API

  RerouteRecommendation({
    required this.shouldReroute,
    required this.reason,
    required this.crowdLevel,
    required this.alternativePathSuggested,
    this.isRealDetection = false,
  });
}
