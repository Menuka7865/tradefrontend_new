import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:chilawtraders/screens/phone_view/collector_management_phone.dart';
import 'package:chilawtraders/screens/web_view/collector_management_web.dart';

enum DeviceType { mobile, tablet, desktop }

class ResponsiveCollector extends StatelessWidget {
  const ResponsiveCollector({super.key});

  /// Determine device type based on screen width
  DeviceType _getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1000) return DeviceType.desktop;
    if (width >= 600) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = _getDeviceType(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Debug information (can be removed in production)
    print('Screen width: $screenWidth');
    print('Device type: $deviceType');
    print('Is web platform: $kIsWeb');

    // FIXED DECISION LOGIC:
    // Use screen width as primary factor, not platform
    // Desktop/Large screens (width >= 1200) -> Web view
    // Mobile/Tablet (width < 1200) -> Mobile view
    if (screenWidth >= 1200) {
      return const CollectorManagementWeb();
    } else {
      return const CollectorManagementMobile();
    }
  }
}

/// Alternative responsive widget with LayoutBuilder for better responsive behavior
class AdaptiveCollectorScreen extends StatelessWidget {
  const AdaptiveCollectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use LayoutBuilder for more precise responsive behavior
        if (constraints.maxWidth >= 1200) {
          // Desktop layout
          return const CollectorManagementWeb();
        } else if (constraints.maxWidth >= 600) {
          // Tablet layout - using mobile view for tablets
          return const CollectorManagementMobile();
        } else {
          // Mobile layout
          return const CollectorManagementMobile();
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
  
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= tablet) return DeviceType.desktop;
    if (width >= mobile) return DeviceType.tablet;
    return DeviceType.mobile;
  }
}