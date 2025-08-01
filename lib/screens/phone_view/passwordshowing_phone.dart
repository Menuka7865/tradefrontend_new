import 'package:chilawtraders/screens/web_view/passwordshowing.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'dart:async';

enum DeviceType { mobile, tablet, desktop }

class PasswordshowingPhone extends StatefulWidget {
  const PasswordshowingPhone({super.key});

  @override
  State<PasswordshowingPhone> createState() => _PasswordshowingPhoneState();
}

class _PasswordshowingPhoneState extends State<PasswordshowingPhone> {
  // Determine the device type
  DeviceType _getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1000) return DeviceType.desktop;
    if (width >= 600) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  double _progress = 0.0;
  bool _navigated = false;

  final String message =
      'Your account was created successfully!\nNow log in using your default password: 123456\nPlease change your password after login in.';

  void _startProgressCountdown() {
    Timer.periodic(const Duration(milliseconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        _progress += 0.01;

        if (_progress >= 1.0 && !_navigated) {
          _progress = 1.0;
          _navigated = true;
          timer.cancel();

          // Show loading dialog for 5 seconds
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFF014EB2)),
                    ),
                    SizedBox(width: 20),
                    Text("Loading, please wait..."),
                  ],
                ),
              ),
            ),
          );

          // Wait 5 seconds then navigate
          Future.delayed(const Duration(seconds: 5), () {
            Navigator.of(context).pop(); // Close dialog
            Navigator.pushReplacementNamed(context, '/Login');
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = _getDeviceType(context);

    if (deviceType == DeviceType.desktop) {
      return const Passwordshowing(); // Return CreateWeb for desktop
    }
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF014EB2), Color(0xFF000428)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 20, left: 12, right: 12),
            child: Center(
              child: Container(
                width: screenWidth,
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          message,
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          speed: const Duration(milliseconds: 50),
                        ),
                      ],
                      totalRepeatCount: 1,
                      isRepeatingAnimation: false,
                      onFinished: () {
                        _startProgressCountdown();
                      },
                    ),
                    const SizedBox(height: 40),
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _progress >= 1.0
                            ? Colors.green
                            : const Color(0xFF014EB2),
                      ),
                      minHeight: 10,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(_progress * 100).toInt()}% loading...',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
