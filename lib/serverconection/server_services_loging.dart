import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ServerServicesloging {
  /// 🔹 Login Method
  static Future<String> loging({
    required String uname,
    required String password,
  }) async {
    final url = Uri.parse(
      "http://app.chilawtradeassociation.com/tradeApi/index.php",
    );

    final body = jsonEncode({
      "user_name": uname,
      "password": password,
      "type": "login",
    });

    try {
      final response = await http.post(
        url,
        body: body,
        headers: {'Content-Type': 'application/json'},
      );

      print("Login Response Status Code: ${response.statusCode}");
      print("Login Response Body: ${response.body}");

      final Map<String, dynamic> responseObj = jsonDecode(response.body);

      // ✅ Check if login is successful and token exists
      if (responseObj['status'] == true &&
          responseObj["data"] != null &&
          responseObj["data"]["user_auth"] != null) {
        final prefs = await SharedPreferences.getInstance();

        // ✅ Save user_auth as token
        await prefs.setString("auth_token", responseObj["data"]["user_auth"]);

        print("Token saved: ${responseObj["data"]["user_auth"]}");
      } else {
        print("Login failed: ${responseObj['Message']}");
      }

      return response.body;
    } catch (e) {
      print("Login API Error: $e");
      return jsonEncode({
        "status": false,
        "Message": "Connection error: $e",
        "user_type": "user"
      });
    }
  }

  /// 🔹 Logout Method
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
  }

  /// 🔹 Get Token Method
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  /// 🔹 Determine User Type (Fallback)
  static String determineUserType(String brNumber) {
    if (brNumber.toUpperCase().startsWith('ADMIN') ||
        brNumber == '000000' ||
        brNumber == 'ADMIN123') {
      return 'admin';
    }
    return 'user';
  }

  /// 🔹 Login and Return Response with User Type
  static Future<Map<String, dynamic>> loginWithUserType({
    required String uname,
    required String password,
  }) async {
    try {
      final response = await loging(uname: uname, password: password);
      Map<String, dynamic> responseObj = jsonDecode(response);

      // ✅ If API does not return user_type, determine it locally
      if (!responseObj.containsKey('user_type') ||
          responseObj['user_type'] == null) {
        responseObj['user_type'] = determineUserType(uname);
      }

      return responseObj;
    } catch (e) {
      return {
        "status": false,
        "Message": "Login failed: $e",
        "user_type": "user"
      };
    }
  }
}
