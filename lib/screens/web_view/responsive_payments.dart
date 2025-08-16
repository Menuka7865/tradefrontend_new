import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:chilawtraders/screens/phone_view/payments_phone.dart';
import 'package:chilawtraders/screens/web_view/payments.dart';

enum DeviceType { mobile, tablet, desktop }

class ResponsivePayments extends StatelessWidget {
  const ResponsivePayments({super.key});

  /// Determine device type based on screen width
  DeviceType _getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return DeviceType.desktop;
    if (width >= 600) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get the current screen size
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final deviceType = _getDeviceType(context);
        
        // Debug information (remove in production)
        debugPrint('Screen width: $screenWidth');
        debugPrint('Device type: $deviceType');
        debugPrint('Is web platform: $kIsWeb');

        // FIXED DECISION LOGIC:
        // Use screen width as primary factor with better breakpoints
        if (screenWidth >= 1200) {
          // Desktop layout - use web view
          return const PaymentManagementWeb();
        } else {
          // Mobile/Tablet layout - use mobile responsive view
          return const PaymentManagementMobile();
        }
      },
    );
  }
}

/// Alternative responsive widget with better responsive behavior
class AdaptivePaymentScreen extends StatelessWidget {
  const AdaptivePaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use LayoutBuilder for more precise responsive behavior
        if (constraints.maxWidth >= 1200) {
          // Desktop layout
          return const PaymentManagementWeb();
        } else if (constraints.maxWidth >= 600) {
          // Tablet layout - using mobile responsive view
          return const PaymentManagementMobile();
        } else {
          // Mobile layout
          return const PaymentManagementMobile();
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
  static const double desktop = 1200;
  
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }
  
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktop) return DeviceType.desktop;
    if (width >= mobile) return DeviceType.tablet;
    return DeviceType.mobile;
  }
}