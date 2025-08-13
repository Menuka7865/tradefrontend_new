import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:chilawtraders/screens/web_view/loging_web.dart';
import 'package:chilawtraders/serverconection/server_services_loging.dart';
import 'dart:convert';

enum DeviceType { mobile, tablet, desktop }

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _brController = TextEditingController();

  DeviceType _getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1000) return DeviceType.desktop;
    if (width >= 600) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _brController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = _getDeviceType(context);

    if (deviceType == DeviceType.desktop) {
      return const LogingWeb(); // Return desktop web login
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 1, 78, 178), Color(0xFF000428)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 70),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AnimatedTextKit(
                    animatedTexts: [
                      TyperAnimatedText(
                        'Login',
                        textStyle: const TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        speed: const Duration(milliseconds: 150),
                      ),
                    ],
                    isRepeatingAnimation: false,
                  ),
                  const SizedBox(height: 10),
                  AnimatedTextKit(
                    animatedTexts: [
                      WavyAnimatedText(
                        'Log in to your account by entering your\n username & password ',
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                    isRepeatingAnimation: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                    topRight: Radius.circular(60),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          const SizedBox(height: 40),
                          _buildLabel("User code"),
                          buildTextField(
                            label: "User Code",
                            hintText: "Enter User Code",
                            icon: Icons.verified_user_outlined,
                            controller: _shopNameController,
                            validator: _requiredValidator("User code"),
                          ),
                          const SizedBox(height: 20),
                          _buildLabel("Password"),
                          buildTextField(
                            label: "Password",
                            hintText: "Enter your password",
                            icon: Icons.password_outlined,
                            controller: _brController,
                            validator: _requiredValidator("Password"),
                          ),
                          const SizedBox(height: 30),
                          _buildSubmitButton(),
                          const SizedBox(height: 30),
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
    );
  }

  Widget _buildLabel(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );

  String? Function(String?) _requiredValidator(String fieldName) {
    return (value) =>
        (value == null || value.isEmpty) ? 'Please enter $fieldName' : null;
  }

  Widget buildTextField({
    required String label,
    required String hintText,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 1, 125, 226).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        obscureText: label.toLowerCase().contains('password'),
        decoration: InputDecoration(
          icon: Icon(icon, color: const Color.fromARGB(255, 1, 16, 95)),
          border: InputBorder.none,
          labelText: label,
          hintText: hintText,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 25, 77, 245),
                Color.fromARGB(255, 1, 23, 189),
                Color.fromARGB(255, 0, 18, 150),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Container(
            alignment: Alignment.center,
            child: const Text(
              "Login",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
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

      final stopwatch = Stopwatch()..start(); // Start timing

      final uname = _shopNameController.text.trim();
      final password = _brController.text.trim();

      try {
        final response = await ServerServicesloging.loging(
          uname: uname,
          password: password,
        );

        stopwatch.stop();
        print("⏱ Server response time: ${stopwatch.elapsedMilliseconds} ms");

        // Ensure dialog is closed before proceeding
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop(); // Close loading dialog
        }

        // Handle empty or null response
        if (response == null || response.isEmpty) {
          _showError('Server returned empty response');
          return;
        }

        try {
          // Parse the JSON response
          Map<String, dynamic> responseObj = jsonDecode(response);

          if (responseObj['status'] == true) {
            _showSuccess('Login successful!');

            // Check user type and redirect accordingly
           

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
            String errorMessage = responseObj['Message'] ?? responseObj['message'] ?? 'Login failed';
            _showError('Login failed: $errorMessage');
          }
        } on FormatException catch (e) {
          print("JSON parsing error: $e");
          print("Raw response: $response");
          
          // Fallback: if JSON parsing fails, check for simple success message
          if (response.toLowerCase().contains("success")) {
            _showSuccess('Login successful!');
            Navigator.pushReplacementNamed(context, '/HomePhone');
          } else {
            _showError('Invalid response format from server');
          }
        }
      } catch (e) {
        // Ensure dialog is closed in case of error
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop(); // Close loading dialog if still open
        }
        
        print("Login error: $e");
        _showError('Network error: Please check your connection and try again');
      }
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}