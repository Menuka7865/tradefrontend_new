import 'package:chilawtraders/screens/phone_view/collector_management_phone.dart';
import 'package:chilawtraders/screens/phone_view/adminpage_phone.dart';
import 'package:chilawtraders/screens/phone_view/passwordshowing_phone.dart';
import 'package:chilawtraders/screens/web_view/create_web.dart';
import 'package:chilawtraders/screens/web_view/adminpage.dart';
import 'package:chilawtraders/screens/web_view/passwordshowing.dart';
import 'package:chilawtraders/screens/web_view/loging_web.dart';
import 'package:chilawtraders/screens/responsive_home.dart';
import 'package:chilawtraders/screens/web_view/responsive_collector.dart';
import 'package:chilawtraders/screens/web_view/responsive_payments.dart'; // FIXED: Correct import path
import 'package:flutter/material.dart';
import 'package:chilawtraders/screens/phone_view/create_shope_account.dart';
import 'package:chilawtraders/screens/phone_view/login.dart';
// 🔹 Import for collector management
import 'package:chilawtraders/screens/web_view/collector_management_web.dart';
import 'package:chilawtraders/screens/web_view/payments.dart';
import 'package:chilawtraders/screens/phone_view/payments_phone.dart';

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
      home: const  Login(),

      // ✅ Define your named routes here
      routes: {
        '/Login': (context) => const Login(),
        '/CreateShopeAccount': (context) => const CreateShopeAccount(),
        '/PasswordshowingPhone': (context) => const PasswordshowingPhone(),
        '/Passwordshowing': (context) => const Passwordshowing(),
        '/LogingWeb': (context) => const LogingWeb(),
        
        // Dashboard routes
        '/AdminDashboard': (context) => const ResponsiveHome(), // Responsive dashboard
        '/AdminDashboardWeb': (context) => const AdminDashboardWeb(), // Admin dashboard web
        '/AdminDashboardMobile': (context) => const AdminDashboardMobile(), // Admin dashboard mobile
       
        
        // 🔹 Collector Management routes - FIXED
        '/CollectorManagement': (context) => const ResponsiveCollector(), // Responsive collector management
        '/CollectorManagementWeb': (context) => const CollectorManagementWeb(), // Web version
        '/CollectorManagementMobile': (context) => const CollectorManagementMobile(), // Mobile version

        //payment routes
        "/PaymentManagement": (context) => const ResponsivePayments(), // Responsive payments
        '/PaymentManagementWeb': (context) => const PaymentManagementWeb(), // Web version for
        '/PaymentManagementMobile': (context) => const PaymentManagementResponsive(), // Mobile version for payments
      },
    );
  }
}