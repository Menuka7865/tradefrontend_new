import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ServerServicesloging {
  /// 🔐 Login Method
  static Future<String> loging({
    required String uname,
    required String password,
  }) async {
    final url = Uri.parse("https://app.chilawtradeassociation.com/tradeApi/index.php");

    final body = jsonEncode({
      "user_code": uname,
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

      if (responseObj['status'] == true &&
          responseObj["data"] != null &&
          responseObj["data"]["user_auth"] != null) {
        final prefs = await SharedPreferences.getInstance();

        // ✅ Save token
        await prefs.setString("auth_token", responseObj["data"]["user_auth"]);

        // ✅ Save user ID (integer)
        if (responseObj["data"]["id"] != null) {
          await prefs.setInt("id", responseObj["data"]["id"]);
          print("User ID saved: ${responseObj["data"]["id"]}");
        }

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

  /// 🔓 Logout Method
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("id");
  }

  /// 🔑 Get Token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  /// 🆔 Get User ID (as integer)
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("id");
  }
}
