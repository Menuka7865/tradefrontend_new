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
    final body = jsonEncode({"type": "list_shop","loged_user_id": "52"});

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
    required String usercode,
    required String email,
    required String password,
  }) async {
    final token = await _getToken();

    final url = Uri.parse("http://app.chilawtradeassociation.com/tradeApi/index.php");
    final body = jsonEncode({
      "type": "add_collector",
      "loged_user_id": "52",
      "user_code": usercode,
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

  
  // Corrected Delete Collector Function
static Future<Map<String, dynamic>> deleteCollector({
  required String collectorId,
}) async {
  final token = await _getToken();

  final url = Uri.parse("http://app.chilawtradeassociation.com/tradeApi/index.php");
  final body = jsonEncode({
    "type": "delete_collector",
    "loged_user_id": "52",
    "user_id": collectorId,  
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

// Corrected Update Collector Function
static Future<Map<String, dynamic>> updateCollector({
  required String collectorId,
  required String usercode,
  required String email,
  String? password,
}) async {
  final token = await _getToken();

  final url = Uri.parse("http://app.chilawtradeassociation.com/tradeApi/index.php");
  
  // Build the request body with correct parameter names
  Map<String, dynamic> requestBody = {
    "type": "update_collector",
    "loged_user_id": "52",
    "user_id": collectorId,        
    "user_name": usercode,         
    "email": email,
  };

  // Only include password if it's provided and not empty
  if (password != null && password.isNotEmpty) {
    requestBody["password"] = password;
  }

  final body = jsonEncode(requestBody);

  try {
    final response = await http.post(
      url,
      body: body,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    print("updateCollector Status Code: ${response.statusCode}");
    print("updateCollector Body: ${response.body}");

    if (response.statusCode == 401) {
      return {"status": false, "Message": "Unauthorized - Please log in again"};
    }

    return jsonDecode(response.body);
  } catch (e) {
    print("updateCollector API Error: $e");
    return {"status": false, "Message": "Connection error: $e"};
  }
}

//Update monthly payment
static Future<Map<String, dynamic>> updatePayment({
  required String newAmount,
  
}) async {
  final token = await _getToken();

  final url = Uri.parse("http://app.chilawtradeassociation.com/tradeApi/index.php");
  
  // Build the request body with correct parameter names
  Map<String, dynamic> requestBody = {
    "type": "update_monthly_payment",
    "loged_user_id": "52",
    "new_amount": newAmount,
  };



  final body = jsonEncode(requestBody);

  try {
    final response = await http.post(
      url,
      body: body,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    print("updatePayment Status Code: ${response.statusCode}");
    print("updatePayment Body: ${response.body}");

    if (response.statusCode == 401) {
      return {"status": false, "Message": "Unauthorized - Please log in again"};
    }

    return jsonDecode(response.body);
  } catch (e) {
    print("updateCollector API Error: $e");
    return {"status": false, "Message": "Connection error: $e"};
  }
}

//Get Monthly Payment
static Future<Map<String, dynamic>> getmonthlypayment() async {
    final token = await _getToken();

    final url = Uri.parse("http://app.chilawtradeassociation.com/tradeApi/index.php");
    final body = jsonEncode({
      "type": "show_monthly_payment",
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

      print("Getpayment Status Code: ${response.statusCode}");
      print("Getpayment Body: ${response.body}");

      if (response.statusCode == 401) {
        return {"status": false, "Message": "Unauthorized - Please log in again"};
      }

      return jsonDecode(response.body);
    } catch (e) {
      print("getCollectorStats API Error: $e");
      return {"status": false, "Message": "Connection error: $e"};
    }
  }

  //get users
  static Future<Map<String, dynamic>> getUsers() async {
    final token = await _getToken();

    final url = Uri.parse("http://app.chilawtradeassociation.com/tradeApi/index.php");
    final body = jsonEncode({"type": "list_users","loged_user_id": "52"});

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

  //send message to a single user
  static Future<Map<String, dynamic>> sendMessage({
    required String userId,
    required String message,
  }) async {
    final token = await _getToken();

    final url = Uri.parse("http://app.chilawtradeassociation.com/tradeApi/index.php");
    final body = jsonEncode({
      "type": "send_to_single_trader",
      "loged_user_id": "52",
      "trader_id": userId,
      "message": message,
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

      print("sendMessage Status Code: ${response.statusCode}");
      print("sendMessage Body: ${response.body}");

      if (response.statusCode == 401) {
        return {"status": false, "Message": "Unauthorized - Please log in again"};
      }

      return jsonDecode(response.body);
    } catch (e) {
      print("sendMessage API Error: $e");
      return {"status": false, "Message": "Connection error: $e"};
    }
  }

  //send message to all users
  static Future<Map<String, dynamic>> sendMessageToAll({
    required String message,
  }) async {
    final token = await _getToken();

    final url = Uri.parse("http://app.chilawtradeassociation.com/tradeApi/index.php");
    final body = jsonEncode({
      "type": "send_to_all_traders",
      "loged_user_id": "52",
      "message": message,
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

      print("sendMessageToAll Status Code: ${response.statusCode}");
      print("sendMessageToAll Body: ${response.body}");

      if (response.statusCode == 401) {
        return {"status": false, "Message": "Unauthorized - Please log in again"};
      }

      return jsonDecode(response.body);
    } catch (e) {
      print("sendMessageToAll API Error: $e");
      return {"status": false, "Message": "Connection error: $e"};
    }
  }



}


