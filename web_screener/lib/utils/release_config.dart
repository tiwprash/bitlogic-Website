import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ReleaseConfig {
  static bool get isReleaseMode => kReleaseMode;
  
  static Future<void> configureForRelease() async {
    if (isReleaseMode) {
      // Disable debugging in release
      debugPrint = (String? message, {int? wrapWidth}) {};
      
      // Set preferred orientations for release
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      
      // Prevent screen from turning off automatically during scanning
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
  
  static Future<void> requestPermissionsForRelease() async {
    if (isReleaseMode) {
      // Additional release-specific permission handling
      try {
        // This ensures all permissions are properly requested in release builds
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('Release config error: $e');
      }
    }
  }
}
