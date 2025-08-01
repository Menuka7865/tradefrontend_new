import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdminBackendServices {
  /// 🔹 Helper method to get token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token"); // ✅ Must match the key used when saving token
  }

  /// 🔹 Fetch Shops
  static Future<Map<String, dynamic>> getShops() async {
    final token = await _getToken();

    final url = Uri.parse("http://app.chilawtradeassociation.com/tradeApi/index.php");
    final body = jsonEncode({"type": "list_shop","loged_user_id":"52"});

    try {
      final response = await http.post(
        url,
        body: body,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print("getShops Status Code: ${response.statusCode}");
      print("getShops Body: ${response.body}");

      if (response.statusCode == 401) {
        return {"status": false, "Message": "Unauthorized - Please log in again"};
      }

      return jsonDecode(response.body);
    } catch (e) {
      print("getShops API Error: $e");
      return {"status": false, "Message": "Connection error: $e"};
    }
  }

  /// 🔹 Fetch Admin Dashboard Stats
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final token = await _getToken();

    final url = Uri.parse("http://app.chilawtradeassociation.com/tradeApi/index.php");
    final body = jsonEncode({"type": "get_dashboard_stats","loged_user_id":"52"});

    try {
      final response = await http.post(
        url,
        body: body,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print("getDashboardStats Status Code: ${response.statusCode}");
      print("getDashboardStats Body: ${response.body}");

      if (response.statusCode == 401) {
        return {"status": false, "Message": "Unauthorized - Please log in again"};
      }

      return jsonDecode(response.body);
    } catch (e) {
      print("getDashboardStats API Error: $e");
      return {"status": false, "Message": "Connection error: $e"};
    }
  }

  /// 🔹 Fetch Collectors
  static Future<Map<String, dynamic>> getCollectors() async {
    final token = await _getToken();

    final url = Uri.parse("http://app.chilawtradeassociation.com/tradeApi/index.php");
    final body = jsonEncode({
      "type": "list_collectors",
      "loged_user_id": "52"
    });

    try {
      final response = await http.post(
        url,
        body: body,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print("getCollectors Status Code: ${response.statusCode}");
      print("getCollectors Body: ${response.body}");

      if (response.statusCode == 401) {
        return {"status": false, "Message": "Unauthorized - Please log in again"};
      }

      return jsonDecode(response.body);
    } catch (e) {
      print("getCollectors API Error: $e");
      return {"status": false, "Message": "Connection error: $e"};
    }
  }

  /// 🔹 Add New Collector
  static Future<Map<String, dynamic>> addCollector({
    required String username,
    required String email,
    required String password,
  }) async {
    final token = await _getToken();

    final url = Uri.parse("http://app.chilawtradeassociation.com/tradeApi/index.php");
    final body = jsonEncode({
      "type": "add_collector",
      "loged_user_id": "52",
      "username": username,
      "email": email,
      "password": password,
    });

    try {
      final response = await http.post(
        url,
        body: body,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print("addCollector Status Code: ${response.statusCode}");
      print("addCollector Body: ${response.body}");

      if (response.statusCode == 401) {
        return {"status": false, "Message": "Unauthorized - Please log in again"};
      }

      return jsonDecode(response.body);
    } catch (e) {
      print("addCollector API Error: $e");
      return {"status": false, "Message": "Connection error: $e"};
    }
  }

  /// 🔹 Fetch Collector Statistics
  static Future<Map<String, dynamic>> getCollectorStats() async {
    final token = await _getToken();

    final url = Uri.parse("http://app.chilawtradeassociation.com/tradeApi/index.php");
    final body = jsonEncode({
      "type": "get_collector_stats",
      "loged_user_id": "52"
    });

    try {
      final response = await http.post(
        url,
        body: body,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print("getCollectorStats Status Code: ${response.statusCode}");
      print("getCollectorStats Body: ${response.body}");

      if (response.statusCode == 401) {
        return {"status": false, "Message": "Unauthorized - Please log in again"};
      }

      return jsonDecode(response.body);
    } catch (e) {
      print("getCollectorStats API Error: $e");
      return {"status": false, "Message": "Connection error: $e"};
    }
  }

  /// 🔹 Update Collector Status (Optional - for future use)
  static Future<Map<String, dynamic>> updateCollectorStatus({
    required String collectorId,
    required String status, // "active" or "inactive"
  }) async {
    final token = await _getToken();

    final url = Uri.parse("http://app.chilawtradeassociation.com/tradeApi/index.php");
    final body = jsonEncode({
      "type": "update_collector_status",
      "loged_user_id": "52",
      "collector_id": collectorId,
      "status": status,
    });

    try {
      final response = await http.post(
        url,
        body: body,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print("updateCollectorStatus Status Code: ${response.statusCode}");
      print("updateCollectorStatus Body: ${response.body}");

      if (response.statusCode == 401) {
        return {"status": false, "Message": "Unauthorized - Please log in again"};
      }

      return jsonDecode(response.body);
    } catch (e) {
      print("updateCollectorStatus API Error: $e");
      return {"status": false, "Message": "Connection error: $e"};
    }
  }

  /// 🔹 Delete Collector (Optional - for future use)
  static Future<Map<String, dynamic>> deleteCollector({
    required String collectorId,
  }) async {
    final token = await _getToken();

    final url = Uri.parse("http://app.chilawtradeassociation.com/tradeApi/index.php");
    final body = jsonEncode({
      "type": "delete_collector",
      "loged_user_id": "52",
      "collector_id": collectorId,
    });

    try {
      final response = await http.post(
        url,
        body: body,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      print("deleteCollector Status Code: ${response.statusCode}");
      print("deleteCollector Body: ${response.body}");

      if (response.statusCode == 401) {
        return {"status": false, "Message": "Unauthorized - Please log in again"};
      }

      return jsonDecode(response.body);
    } catch (e) {
      print("deleteCollector API Error: $e");
      return {"status": false, "Message": "Connection error: $e"};
    }
  }
}