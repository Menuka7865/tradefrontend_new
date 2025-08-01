import 'package:flutter/material.dart';

enum UserType { admin, user }

class NavigationHelper {
  // Determine device type
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1000) return DeviceType.desktop;
    if (width >= 600) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  // Navigate to appropriate dashboard based on user type and device
  static void navigateToDashboard(
    BuildContext context, 
    String userType, 
    {bool isWeb = false}
  ) {
    String route;
    
    if (userType.toLowerCase() == 'admin') {
      route = isWeb ? '/AdminDashboardWeb' : '/AdminDashboardPhone';
    } else {
      route = isWeb ? '/HomeWeb' : '/HomePhone';
    }
    
    Navigator.pushReplacementNamed(context, route);
  }

  // Navigate based on response and device type
  static void handleLoginNavigation(
    BuildContext context, 
    Map<String, dynamic> response
  ) {
    if (response['status'] == true) {
      final deviceType = getDeviceType(context);
      final userType = response['user_type'] ?? 'user';
      final isWeb = deviceType == DeviceType.desktop;
      
      navigateToDashboard(context, userType, isWeb: isWeb);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Welcome ${userType.toLowerCase() == 'admin' ? 'Admin' : 'User'}!'
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['Message'] ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Check if user is admin based on various criteria
  static bool isAdmin(String brNumber) {
    // Add your admin identification logic here
    final adminBRNumbers = [
      'ADMIN123',
      '000000',
      'ADMIN001',
      // Add more admin BR numbers as needed
    ];
    
    return adminBRNumbers.contains(brNumber.toUpperCase()) ||
           brNumber.toUpperCase().startsWith('ADMIN');
  }
}

enum DeviceType { mobile, tablet, desktop }