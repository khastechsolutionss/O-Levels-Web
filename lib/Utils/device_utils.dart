import 'package:flutter/material.dart';

/// Utility class for device type detection.
/// Uses [shortestSide] which is more reliable than width alone
/// because it remains consistent in both portrait and landscape orientations.
class DeviceUtils {
  DeviceUtils._(); // Prevent instantiation

  /// Returns true if the device is a tablet (shortestSide >= 600dp).
  static bool isTablet(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600;
  }

  /// Returns true if the device is a phone (shortestSide < 600dp).
  static bool isPhone(BuildContext context) => !isTablet(context);
}
