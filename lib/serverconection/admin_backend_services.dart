import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

final String baseUrl = "https://app.chilawtradeassociation.com/tradeApi/index.php";

class AdminBackendServices {
  /// 🔹 Helper method to get token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token"); // ✅ Must match the key used when saving token
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("id");
  }

  /// 🔹 Fetch Shops
  static Future<Map<String, dynamic>> getShops() async {
    final token = await _getToken();
    final id = await getUserId();

    final url = Uri.parse(baseUrl);
    final body = jsonEncode({"type": "list_shop","loged_user_id":  id?.toString() ?? ""});

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
    final id = await getUserId();

    final url = Uri.parse(baseUrl);
    final body = jsonEncode({"type": "get_dashboard_stats","loged_user_id":id?.toString() ?? "",});

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
    final id = await getUserId();

    final url = Uri.parse(baseUrl);
    final body = jsonEncode({
      "type": "list_collectors",
      "loged_user_id": id?.toString() ?? "",
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
    final id = await getUserId();

    final url = Uri.parse(baseUrl);
    final body = jsonEncode({
      "type": "add_collector",
      "loged_user_id": id?.toString() ?? "",
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
    final id = await getUserId();

    final url = Uri.parse(baseUrl);
    final body = jsonEncode({
      "type": "get_collector_stats",
      "loged_user_id": id?.toString() ?? "",
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
  final id = await getUserId();

  final url = Uri.parse(baseUrl);
  final body = jsonEncode({
    "type": "delete_collector",
    "loged_user_id": id?.toString() ?? "",
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
  final id = await getUserId();

  final url = Uri.parse(baseUrl);
  
  // Build the request body with correct parameter names
  Map<String, dynamic> requestBody = {
    "type": "update_collector",
    "loged_user_id": id?.toString() ?? "",
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
  final id = await getUserId();

  final url = Uri.parse(baseUrl);
  
  // Build the request body with correct parameter names
  Map<String, dynamic> requestBody = {
    "type": "update_monthly_payment",
    "loged_user_id": id?.toString() ?? "",
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
    final id = await getUserId();

    final url = Uri.parse(baseUrl);
    final body = jsonEncode({
      "type": "show_monthly_payment",
      "loged_user_id": id?.toString() ?? ""
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
    final id = await getUserId();

    final url = Uri.parse(baseUrl);
    final body = jsonEncode({"type": "list_users","loged_user_id": id?.toString() ?? ""});

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
    final id = await getUserId();

    final url = Uri.parse(baseUrl);
    final body = jsonEncode({
      "type": "send_to_single_trader",
      "loged_user_id": id?.toString() ?? "",
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
    final id = await getUserId();

    final url = Uri.parse(baseUrl);
    final body = jsonEncode({
      "type": "send_to_all_traders",
      "loged_user_id": id?.toString() ?? "",
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
static Future<Map<String, dynamic>> getPayments({
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    String? status,
    int? page,
    int? perPage,
  }) async {
    final token = await _getToken();
    final id = await getUserId();
    
    final url = Uri.parse(baseUrl);
    
    // Prepare request body
    Map<String, dynamic> requestBody = {
      "type": "list_all_payments",
      "loged_user_id": id?.toString() ?? "",
    };

    // Add optional parameters
    if (startDate != null) {
      requestBody["start_date"] = startDate.toIso8601String();
    }
    if (endDate != null) {
      requestBody["end_date"] = endDate.toIso8601String();
    }
    if (search != null && search.isNotEmpty) {
      requestBody["search"] = search;
    }
    if (status != null && status.isNotEmpty) {
      requestBody["status"] = status;
    }
    if (page != null) {
      requestBody["page"] = page;
    }
    if (perPage != null) {
      requestBody["per_page"] = perPage;
    }

    final body = jsonEncode(requestBody);

    try {
      print("getPayments URL: $url");
      print("getPayments Request Body: $body");

      final response = await http.post(
        url,
        body: body,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - Please check your internet connection');
        },
      );

      print("getPayments Status Code: ${response.statusCode}");
      print("getPayments Response Body: ${response.body}");

      // Handle different HTTP status codes
      if (response.statusCode == 401) {
        return {
          "status": false, 
          "Message": "Unauthorized - Invalid token. Please log in again"
        };
      }

      if (response.statusCode == 403) {
        return {
          "status": false, 
          "Message": "Access forbidden - Insufficient permissions"
        };
      }

      if (response.statusCode == 404) {
        return {
          "status": false, 
          "Message": "API endpoint not found"
        };
      }

      if (response.statusCode == 500) {
        return {
          "status": false, 
          "Message": "Server error - Please try again later"
        };
      }

      // Try to decode the response
      try {
        final decodedResponse = jsonDecode(response.body);
        
        // Handle successful response
        if (response.statusCode == 200) {
          return decodedResponse;
        } else {
          // Handle other status codes with decoded response
          return {
            "status": false,
            "Message": decodedResponse['message'] ?? 
                      decodedResponse['Message'] ?? 
                      "Request failed with status: ${response.statusCode}"
          };
        }
      } catch (jsonError) {
        print("JSON decode error: $jsonError");
        return {
          "status": false,
          "Message": "Invalid response format from server"
        };
      }

    } catch (e) {
      print("getPayments API Error: $e");
      
      // Handle specific error types
      String errorMessage;
      if (e.toString().contains('timeout')) {
        errorMessage = "Request timeout - Please check your internet connection";
      } else if (e.toString().contains('SocketException')) {
        errorMessage = "Network error - Please check your internet connection";
      } else if (e.toString().contains('HandshakeException')) {
        errorMessage = "SSL connection error - Please try again";
      } else {
        errorMessage = "Connection error: ${e.toString()}";
      }
      
      return {
        "status": false, 
        "Message": errorMessage
      };
    }
  }



}


