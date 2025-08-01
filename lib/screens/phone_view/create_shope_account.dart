import 'dart:async';
import 'dart:convert';

import 'package:chilawtraders/screens/phone_view/passwordshowing_phone.dart';
import 'package:chilawtraders/screens/web_view/passwordshowing.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import 'package:chilawtraders/screens/web_view/create_web.dart';
import 'package:http/http.dart' as http;

import 'package:chilawtraders/serverconection/server_services.dart';
import 'package:chilawtraders/screens/web_view/create_web.dart';
import 'package:chilawtraders/serverconection/server_services.dart';

enum DeviceType { mobile, tablet, desktop }

class CreateShopeAccount extends StatefulWidget {
  const CreateShopeAccount({super.key});

  @override
  State<CreateShopeAccount> createState() => _CreateShopeAccountState();
}

class _CreateShopeAccountState extends State<CreateShopeAccount> {
  double _progress = 0.0;
  bool _navigated = false;
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _brController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();

  // Determine the device type
  DeviceType _getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1000) return DeviceType.desktop;
    if (width >= 600) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  void _loging() {
    Navigator.pushReplacementNamed(context, '/Login');
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = _getDeviceType(context);

    if (deviceType == DeviceType.desktop) {
      return const CreateWeb(); // Return CreateWeb for desktop
    }

    // Mobile or Tablet UI (default form)
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
                        'Create Shop',
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
                          _buildLabel("Shop Name"),
                          buildTextField(
                            label: "Shop Name",
                            hintText: "Enter Shop Name",
                            icon: Icons.store,
                            controller: _shopNameController,
                            validator: _requiredValidator("shop name"),
                          ),
                          _buildLabel("B.R Number"),
                          buildTextField(
                            label: "B.R Number",
                            hintText: "Enter your valid BR Number",
                            icon: Icons.numbers,
                            controller: _brController,
                            validator: _requiredValidator("BR number"),
                          ),
                          _buildLabel("Contact Person"),
                          buildTextField(
                            label: "Contact Person",
                            hintText: "Enter Contact Person Name",
                            icon: Icons.person,
                            controller: _contactPersonController,
                            validator: _requiredValidator("contact person"),
                          ),
                          _buildLabel("Telephone Number"),
                          buildTextField(
                            label: "Phone number",
                            hintText: "Enter your 10 digit mobile number",
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            controller: _phoneController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter phone number';
                              } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                                return 'Enter valid 10-digit number';
                              }
                              return null;
                            },
                          ),
                          _buildLabel("Address"),
                          buildTextField(
                            label: "Address",
                            hintText: "Enter your address",
                            icon: Icons.home,
                            controller: _addressController,
                            validator: _requiredValidator("address"),
                          ),
                          _buildLabel("Email"),
                          buildTextField(
                            label: "Email (Optional)",
                            hintText: "Enter your valid email",
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return 'Enter valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          _buildSubmitButton(),
                          const SizedBox(height: 30),
                          _buildloginButton(),
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
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          colors: [
            Color.fromARGB(255, 25, 77, 245),
            Color.fromARGB(255, 1, 23, 189),
            Color.fromARGB(255, 0, 18, 150),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: ElevatedButton(
        onPressed: () async {
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

            final returnrspons = await ServerServices.registerShop(
              shopName: _shopNameController.text.trim(),
              brNumber: _brController.text.trim(),
              contactPerson: _contactPersonController.text.trim(),
              phone: _phoneController.text.trim(),
              address: _addressController.text.trim(),
              email: _emailController.text.trim(),
            );

            stopwatch.stop();
            print(
              "⏱ Server response time: ${stopwatch.elapsedMilliseconds} ms",
            );

            Navigator.of(context).pop(); // Close loading dialog

            print("returnrspons" + returnrspons);
            Map<String, dynamic> responceObj = jsonDecode(returnrspons);

            if (responceObj['status']) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Shop Registered Successfully!')),
              );

              // Clear fields after success
              _shopNameController.clear();
              _brController.clear();
              _contactPersonController.clear();
              _phoneController.clear();
              _addressController.clear();
              _emailController.clear();

              Navigator.pushReplacementNamed(context, '/PasswordshowingPhone');
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(responceObj['Message'])));
            }
          }
        },

        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          "SIGNUP",
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildloginButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          colors: [
            Color.fromARGB(255, 54, 245, 25),
            Color.fromARGB(255, 1, 189, 26),
            Color.fromARGB(255, 0, 88, 2),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: ElevatedButton(
        onPressed: _loging,

        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          "Login",
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}
