import 'dart:convert';
import 'package:http/http.dart' as http;

class ServerServices {
  static registerShop({
    required String shopName,
    required String brNumber,
    required String contactPerson,
    required String phone,
    required String address,
    required String email,
  }) async {
    final url = Uri.parse(
      'https://app.chilawtradeassociation.com/tradeApi/index.php',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "type": "register",
        "shop_name": shopName,
        "br_registration_number": brNumber,
        "contact_person": contactPerson,
        "contact_teliphone": phone,
        "address": address,
        "email": email,
      }),
    );

    // DEBUG response:
    print("Response Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    return response.body;

    //if (response.statusCode == 200) {
    //final data = jsonDecode(response.body);
    //   if (data['success'] == true) {
    //     return true;
    //   }
    // }
    // return false;
  }
}
