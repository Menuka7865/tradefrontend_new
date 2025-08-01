import 'dart:async';

import 'package:chilawtraders/screens/web_view/passwordshowing.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:chilawtraders/serverconection/server_services.dart';
import 'dart:convert';

class CreateWeb extends StatefulWidget {
  const CreateWeb({super.key});

  @override
  State<CreateWeb> createState() => _CreateWebState();
}

class _CreateWebState extends State<CreateWeb> {
  double _progress = 0.0;
  bool _navigated = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _shopIdController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  void _loging() {
    Navigator.pushReplacementNamed(context, '/Login');
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
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

      final stopwatch = Stopwatch()..start(); // Start timing

      final response = await ServerServices.registerShop(
        shopName: _shopNameController.text.trim(),
        brNumber: _shopIdController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        email: _emailController.text.trim(),
      );

      stopwatch.stop();
      print("⏱ Server response time: ${stopwatch.elapsedMilliseconds} ms");

      Navigator.of(context).pop(); // Close loading dialog

      try {
        Map<String, dynamic> responseObj = jsonDecode(response);

        if (responseObj['status']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shop Registered Successfully!')),
          );

          // Clear fields after success
          _shopNameController.clear();
          _shopIdController.clear();
          _contactPersonController.clear();
          _phoneController.clear();
          _addressController.clear();
          _emailController.clear();

          // Navigate to next screen
          Navigator.pushReplacementNamed(context, '/PasswordshowingPhone');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseObj['Message'] ?? "Error")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid server response")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/45.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ✅ Foreground content
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
                  // ✅ Left panel with animation
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

                  // ✅ Right panel with form
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
                                _buildField(
                                  "B.R Number",
                                  "Enter your valid BR Number",
                                  _shopIdController,
                                ),
                                _buildField(
                                  "Shop Name",
                                  "Enter Shop Name",
                                  _shopNameController,
                                ),
                                _buildField(
                                  "Contact Person",
                                  "Enter Contact Person Name",
                                  _contactPersonController,
                                ),
                                _buildField(
                                  "Telephone Number",
                                  "Enter 10-digit mobile number",
                                  _phoneController,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().length != 10) {
                                      return "Enter a valid 10-digit number";
                                    }
                                    return null;
                                  },
                                ),
                                _buildField(
                                  "Address",
                                  "Enter your address",
                                  _addressController,
                                ),
                                _buildField(
                                  "Email",
                                  "Enter your email",
                                  _emailController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return null;
                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value)) {
                                      return 'Enter valid email';
                                    }
                                    return null;
                                  },
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
                                      "SIGN UP",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 25),

                                SizedBox(
                                  width: double.infinity,
                                  height: 45,
                                  child: ElevatedButton(
                                    onPressed: _loging,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                        250,
                                        2,
                                        85,
                                        158,
                                      ),
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
        ],
      ),
    );
  }

  // Reusable input field widget
  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller, {
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
            validator:
                validator ??
                (value) {
                  if (value == null || value.isEmpty) {
                    return "This field is required";
                  }
                  return null;
                },
            keyboardType: label == "Email"
                ? TextInputType.emailAddress
                : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
