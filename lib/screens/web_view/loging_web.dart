import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:chilawtraders/serverconection/server_services_loging.dart';

class LogingWeb extends StatefulWidget {
  const LogingWeb({super.key});

  @override
  State<LogingWeb> createState() => _LogingWebState();
}

class _LogingWebState extends State<LogingWeb> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController(); // Fixed: Changed from _shopIdController
  final TextEditingController _brNumberController = TextEditingController(); // Fixed: Changed from _shopNameController

  

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Padding(
            padding: EdgeInsets.all(24.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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

      final stopwatch = Stopwatch()..start();

      final uname = _brNumberController.text.trim();
      final password = _passwordController.text.trim();

      try {
        final returnResponse = await ServerServicesloging.loging(
          uname: uname,
          password: password,
        );
        
        stopwatch.stop();
        print("⏱ Server response time: ${stopwatch.elapsedMilliseconds} ms");
        print("Response: $returnResponse");

        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Handle different response formats
        Map<String, dynamic> responseObj;
        
        try {
          // Try to parse as JSON first
          responseObj = jsonDecode(returnResponse);
        } catch (jsonError) {
          print("JSON parsing error: $jsonError");
          
          // Fallback: Create response object based on string content
          if (returnResponse.toLowerCase().contains("success") || 
              returnResponse.toLowerCase().contains("login successful")) {
            responseObj = {
              'status': true,
              'Message': 'Login Successful!',
              // 'user_type': _determineUserType(uname), // Determine locally
            };
          } else {
            responseObj = {
              'status': false,
              'Message': returnResponse.isNotEmpty ? returnResponse : 'Login Failed',
              'user_type': 'user',
            };
          }
        }

        // Handle successful login
        if (responseObj['status'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login Successful!'),
                backgroundColor: Colors.green,
              ),
            );
          }

          // Clear form
          _brNumberController.clear();
          _passwordController.clear();

         
          if (mounted) {
            
              // Check if admin route exists, fallback to user route if not
              try {
                Navigator.pushReplacementNamed(context, '/AdminDashboard');
              } catch (e) {
                print("Admin route not found, redirecting to user dashboard: $e");
                Navigator.pushReplacementNamed(context, '/HomeWeb');
              }
           
          }
        } else {
          // Handle login failure
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseObj['Message'] ?? 'Login Failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print("Login error: $e");
        
        // Close loading dialog if still open
        if (mounted) {
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _brNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: 900,
          height: 600,
          decoration: BoxDecoration(
            color: Colors.white,
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
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 120,
                                decoration: const BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.business,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            'Chilaw Trade Association',
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                            speed: const Duration(milliseconds: 100),
                          ),
                        ],
                        totalRepeatCount: 1,
                        pause: const Duration(milliseconds: 1000),
                        displayFullTextOnTap: true,
                        stopPauseOnTap: true,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF014EB2),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Please sign in to your Admin account',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 32),
                            _buildField(
                              "User Code",
                              "Enter your User Code",
                              _brNumberController,
                              icon: Icons.verified_user_outlined,
                            ),
                            _buildField(
                              "Password",
                              "Enter your Password",
                              _passwordController,
                              icon: Icons.password_outlined,
                            ),
                            const SizedBox(height: 25),
                            SizedBox(
                              width: double.infinity,
                              height: 45,
                              child: ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF004e92),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller, {
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            obscureText: label.toLowerCase().contains("password"),
            validator: validator ?? (value) {
              if (value == null || value.isEmpty) {
                return "This field is required";
              }
              return null;
            },
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: icon != null ? Icon(icon) : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF014EB2)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}