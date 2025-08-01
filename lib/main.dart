import 'package:chilawtraders/screens/phone_view/home_phone.dart';
import 'package:chilawtraders/screens/phone_view/passwordshowing_phone.dart';
import 'package:chilawtraders/screens/web_view/create_web.dart';
import 'package:chilawtraders/screens/web_view/home_web.dart';
import 'package:chilawtraders/screens/web_view/passwordshowing.dart';
import 'package:chilawtraders/screens/web_view/loging_web.dart';
import 'package:chilawtraders/screens/responsive_home.dart';
import 'package:flutter/material.dart';
import 'package:chilawtraders/screens/phone_view/create_shope_account.dart';
import 'package:chilawtraders/screens/phone_view/login.dart';
// 🔹 ADD THIS IMPORT FOR COLLECTOR MANAGEMENT
import 'package:chilawtraders/screens/web_view/collector_management_web.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Initial screen
      home: CreateShopeAccount(),

      // ✅ Define your named routes here
      routes: {
        '/Login': (context) => const Login(),
        '/CreateShopeAccount': (context) => const CreateShopeAccount(),
        '/PasswordshowingPhone': (context) => const PasswordshowingPhone(),
        '/Passwordshowing': (context) => const Passwordshowing(),
        
        '/AdminDashboard': (context) => const ResponsiveHome(), // Responsive dashboard
        '/AdminDashboardWeb': (context) => const AdminDashboardWeb(), // Admin dashboard web
        '/AdminDashboardPhone': (context) => const AdminDashboardMobile(), // Admin dashboard phone
        '/LogingWeb': (context) => const LogingWeb(),
        
        // 🔹 ADD THIS NEW ROUTE FOR COLLECTOR MANAGEMENT
        '/CollectorManagement': (context) => const CollectorManagementWeb(),
      },
    );
  }
}