import 'package:flutter/material.dart';
import 'package:chilawtraders/screens/phone_view/home_phone.dart';
import 'package:chilawtraders/screens/web_view/home_web.dart';

enum DeviceType { mobile, tablet, desktop }

class ResponsiveHome extends StatelessWidget {
  const ResponsiveHome({super.key});

  /// Determine device type based on screen width
  DeviceType _getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return DeviceType.desktop;
    if (width >= 600) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  /// Check if the current platform is web
  bool _isWebPlatform() {
    // In Flutter web, we can check if we're running on web
    // This is a simple way to detect web platform
    try {
      return identical(0, 0.0) == false; // This will be true on web
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = _getDeviceType(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Debug information (can be removed in production)
    print('Screen width: $screenWidth');
    print('Device type: $deviceType');
    print('Is web platform: ${_isWebPlatform()}');

    // Decision logic for which view to show
    // Desktop (width >= 1200) or Web platform -> Web view
    // Mobile/Tablet (width < 1200) -> Mobile view
    if (deviceType == DeviceType.desktop || _isWebPlatform()) {
      return const AdminDashboardWeb();
    } else {
      return const AdminDashboardMobile();
    }
  }
}

/// Alternative responsive widget that can be used for more granular control
class AdaptiveHomeScreen extends StatelessWidget {
  const AdaptiveHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use LayoutBuilder for more precise responsive behavior
        if (constraints.maxWidth >= 1200) {
          // Desktop layout
          return const AdminDashboardWeb();
        } else if (constraints.maxWidth >= 600) {
          // Tablet layout - you can choose which view to use
          // For now, we'll use mobile view for tablets too
          return const AdminDashboardMobile();
        } else {
          // Mobile layout
          return const AdminDashboardMobile();
        }
      },
    );
  }
}

/// Responsive wrapper that can be used to wrap any widget with responsive behavior
class ResponsiveWrapper extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveWrapper({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return desktop;
        } else if (constraints.maxWidth >= 600) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Utility class for responsive breakpoints
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1200;
  
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < tablet;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tablet;
  }
}