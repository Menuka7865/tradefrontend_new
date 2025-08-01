import 'package:chilawtraders/screens/phone_view/passwordshowing_phone.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'dart:async';

class Passwordshowing extends StatefulWidget {
  const Passwordshowing({super.key});

  @override
  State<Passwordshowing> createState() => _PasswordshowingState();
}

class _PasswordshowingState extends State<Passwordshowing> {
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
                borderRadius: BorderRadius.circular(16),
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
          Future.delayed(const Duration(seconds: 0), () {
            Navigator.of(context).pop(); // Close dialog
            Navigator.pushReplacementNamed(context, '/Login');
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/45.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Foreground
          Center(
            child: Container(
              width: 900,
              height: 600,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left side
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF014EB2), Color(0xFF000428)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipOval(
                            child: SizedBox(
                              width: 120,
                              height: 120,
                              child: Image.asset(
                                'assets/chilaw.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AnimatedTextKit(
                            animatedTexts: [
                              WavyAnimatedText(
                                'Chilaw Trade Association',
                                textStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                                speed: Duration(milliseconds: 100),
                              ),
                            ],
                            totalRepeatCount: 1,
                            pause: Duration(milliseconds: 1000),
                            displayFullTextOnTap: true,
                            stopPauseOnTap: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right side
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedTextKit(
                            animatedTexts: [
                              TypewriterAnimatedText(
                                message,
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                                speed: Duration(milliseconds: 50),
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
