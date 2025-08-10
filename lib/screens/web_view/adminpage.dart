import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:html' as html; // For web download

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

import 'package:chilawtraders/serverconection/admin_backend_services.dart';

class AdminDashboardWeb extends StatefulWidget {
  const AdminDashboardWeb({super.key});

  @override
  State<AdminDashboardWeb> createState() => _AdminDashboardWebState();
}

class _AdminDashboardWebState extends State<AdminDashboardWeb> {
  // Dashboard statistics
  String totalShops = "Loading...";
  String totalPayments = "Loading...";
  String pendingPayments = "Loading...";
  String totalUsers = "Loading...";

  // Shop data and search functionality
  List<Map<String, dynamic>> allShops = [];
  List<Map<String, dynamic>> filteredShops = [];
  TextEditingController searchController = TextEditingController();
  String selectedFilter = 'All';

  // Loading states
  bool isDashboardLoading = true;
  bool isShopsLoading = true;
  bool isActionLoading = false;

  // GlobalKey for QR code capturing
  final GlobalKey qrKey = GlobalKey();

  // Store current shop for QR saving
  Map<String, dynamic>? _currentQrShop;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterShops);
    _validateTokenAndInitialize();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _validateTokenAndInitialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null || token.isEmpty) {
        _showErrorSnackBar("No authentication token found. Please log in again.");
        _redirectToLogin();
        return;
      }

      final response = await AdminBackendServices.getDashboardStats();

      if (response['status'] == false &&
          (response['Message']?.toString().contains('Unauthorized') == true ||
              response['Message']?.toString().contains('Invalid token') == true)) {
        _showErrorSnackBar("Session expired. Please log in again.");
        _redirectToLogin();
        return;
      }

      _initializeDashboard();
    } catch (e) {
      print('Token validation error: $e');
      _showErrorSnackBar('Authentication error: $e');
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    Navigator.pushReplacementNamed(context, '/Login');
  }

  String _generateQRData(Map<String, dynamic> shop) {
    String shopId = shop['id']?.toString() ?? shop['shop_id']?.toString() ?? '';
    String shopName = shop['shop_name']?.toString() ?? shop['name']?.toString() ?? '';
    String brNumber = shop['br_registration_number']?.toString() ?? shop['br_number']?.toString() ?? '';

    Map<String, String> qrData = {
      'shop_id': shopId,
      'shop_name': shopName,
      'br_number': brNumber,
      'type': 'shop_verification',
      'generated_at': DateTime.now().toIso8601String(),
    };

    return jsonEncode(qrData);
  }

  void _showQRDialog(Map<String, dynamic> shop) {
    String qrData = _generateQRData(shop);
    String shopName = shop['shop_name']?.toString() ?? shop['name']?.toString() ?? 'Unknown Shop';

    _currentQrShop = shop; // Save for saving image on button press

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'QR Code for $shopName',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                RepaintBoundary(
                  key: qrKey,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Scan this QR code to verify shop details',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _saveQrCode();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF014EB2),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Adapted _saveQrCode for mobile and web
  Future<void> _saveQrCode() async {
    if (kIsWeb) {
      await _saveQrCodeWeb();
    } else {
      await _saveQrCodeMobile();
    }
  }

  // Web download method
  Future<void> _saveQrCodeWeb() async {
    try {
      RenderRepaintBoundary boundary = qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final blob = html.Blob([pngBytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = url
        ..download = 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png'
        ..style.display = 'none';

      html.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);

      _showSuccessSnackBar('QR code downloaded!');
    } catch (e) {
      print('Error saving QR code on web: $e');
      _showErrorSnackBar('Error saving QR code: $e');
    }
  }

  // Mobile save to gallery method
  Future<void> _saveQrCodeMobile() async {
    try {
      if (await Permission.storage.isDenied) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          _showErrorSnackBar('Storage permission denied. Cannot save QR Code.');
          return;
        }
      }

      RenderRepaintBoundary boundary = qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final result = await ImageGallerySaverPlus.saveImage(
        pngBytes,
        quality: 100,
        name: 'qr_code_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result == null || result.isEmpty) {
        _showErrorSnackBar('Failed to save QR code.');
      } else {
        _showSuccessSnackBar('QR code saved to gallery!');
      }
    } catch (e) {
      print('Error saving QR code: $e');
      _showErrorSnackBar('Error saving QR code: $e');
    }
  }

  Future<void> _initializeDashboard() async {
    await Future.wait([
      _loadDashboardStats(),
      _loadShops(),
    ]);
  }

  Future<void> _loadDashboardStats() async {
    try {
      setState(() {
        isDashboardLoading = true;
      });

      final response = await AdminBackendServices.getDashboardStats();
      print("Dashboard Stats API Response: $response");

      if (response['status'] == false &&
          (response['Message']?.toString().contains('Unauthorized') == true ||
              response['Message']?.toString().contains('Invalid token') == true)) {
        _showErrorSnackBar("Session expired. Please log in again.");
        _redirectToLogin();
        return;
      }

      if (response['status'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          totalShops = data['total_shops']?.toString() ?? "0";
          totalPayments = data['total_payments']?.toString() ?? "Rs. 0";
          pendingPayments = data['pending_payments']?.toString() ?? "Rs. 0";
          totalUsers = data['total_users']?.toString() ?? "0";
          isDashboardLoading = false;
        });
      } else {
        String errorMessage = response['Message'] ?? response['message'] ?? 'Failed to load dashboard statistics';
        _showErrorSnackBar(errorMessage);
        setState(() {
          totalShops = allShops.length.toString();
          totalPayments = "Rs. 0";
          pendingPayments = "Rs. 0";
          totalUsers = "0";
          isDashboardLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard stats: $e');
      _showErrorSnackBar('Error loading dashboard data: $e');
      setState(() {
        totalShops = allShops.length.toString();
        totalPayments = "Rs. 0";
        pendingPayments = "Rs. 0";
        totalUsers = "0";
        isDashboardLoading = false;
      });
    }
  }

  Future<void> _loadShops() async {
    try {
      setState(() {
        isShopsLoading = true;
      });

      final response = await AdminBackendServices.getShops();
      print("Shops API Response: $response");

      if (response['status'] == false &&
          (response['Message']?.toString().contains('Unauthorized') == true ||
              response['Message']?.toString().contains('Invalid token') == true)) {
        _showErrorSnackBar("Session expired. Please log in again.");
        _redirectToLogin();
        return;
      }

      if (response['status'] == true) {
        setState(() {
          var responseData = response['data'] ?? response['shops'] ?? response['Data'];

          if (responseData is List) {
            allShops = List<Map<String, dynamic>>.from(responseData);
          } else if (responseData is Map && responseData.containsKey('shops')) {
            allShops = List<Map<String, dynamic>>.from(responseData['shops']);
          } else {
            allShops = List<Map<String, dynamic>>.from(response['Data'] ?? []);
          }

          totalShops = allShops.length.toString();
          _filterShops();
          isShopsLoading = false;
        });

        _showSuccessSnackBar('Shops loaded successfully (${allShops.length} shops)');
        await _loadDashboardStats();
      } else {
        String errorMessage = response['Message'] ?? response['message'] ?? 'Failed to load shops';
        _showErrorSnackBar(errorMessage);
        setState(() {
          allShops = [];
          filteredShops = [];
          isShopsLoading = false;
        });
      }
    } catch (e) {
      print('Error loading shops: $e');
      _showErrorSnackBar('Error loading shops data: $e');
      setState(() {
        allShops = [];
        filteredShops = [];
        isShopsLoading = false;
      });
    }
  }

  void _filterShops() {
    setState(() {
      String query = searchController.text.toLowerCase();

      filteredShops = allShops.where((shop) {
        bool matchesSearch = (shop['shop_name']?.toString() ?? shop['name']?.toString() ?? '')
                .toLowerCase()
                .contains(query) ||
            (shop['br_registration_number']?.toString() ?? shop['br_number']?.toString() ?? '')
                .toLowerCase()
                .contains(query) ||
            (shop['contact_person']?.toString() ?? shop['owner']?.toString() ?? '').toLowerCase().contains(query) ||
            (shop['contact_teliphone']?.toString() ?? shop['phone']?.toString() ?? shop['contact_telephone']?.toString() ?? '')
                .toLowerCase()
                .contains(query);

        bool matchesFilter = selectedFilter == 'All' || (shop['status']?.toString() ?? 'Active') == selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      isDashboardLoading = true;
      isShopsLoading = true;
    });

    await _initializeDashboard();
    _showSuccessSnackBar('Dashboard refreshed successfully');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
    ));
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Admin Sidebar
          Container(
            width: 250,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF014EB2), Color(0xFF000428)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 80),
                    ClipOval(
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: Image.asset(
                          'assets/chilaw.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.admin_panel_settings,
                                size: 60,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'ADMIN PANEL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    navItem(Icons.dashboard, "Dashboard", true),
                    navItem(Icons.people, "Collectors", false),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: logoutButton(),
                ),
              ],
            ),
          ),

          // Main Admin Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Admin Top bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(0, 2),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (!isDashboardLoading && !isShopsLoading)
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    (!isDashboardLoading && !isShopsLoading) ? Icons.wifi : Icons.sync,
                                    size: 12,
                                    color: (!isDashboardLoading && !isShopsLoading)
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed:
                                  (isDashboardLoading || isShopsLoading) ? null : _refreshDashboard,
                              icon: Icon(
                                Icons.refresh,
                                color: (isDashboardLoading || isShopsLoading)
                                    ? Colors.grey
                                    : Colors.blue,
                              ),
                              tooltip: 'Refresh Dashboard',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Admin Stats Cards
                  isDashboardLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            adminDashboardCard(
                              "Total Shops",
                              totalShops,
                              Icons.store,
                              Colors.blue.shade50,
                              Colors.blue,
                            ),
                            adminDashboardCard(
                              "Total Payments",
                              totalPayments,
                              Icons.payment,
                              Colors.green.shade50,
                              Colors.green,
                            ),
                            adminDashboardCard(
                              "Pending Payments",
                              pendingPayments,
                              Icons.pending_actions,
                              Colors.orange.shade50,
                              Colors.orange,
                            ),
                            adminDashboardCard(
                              "Total Users",
                              totalUsers,
                              Icons.people,
                              Colors.purple.shade50,
                              Colors.purple,
                            ),
                          ],
                        ),
                  const SizedBox(height: 30),

                  // Shops Management Section
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            offset: Offset(0, 2),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with search and filter
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Registered Shops',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 300,
                                      child: TextField(
                                        controller: searchController,
                                        decoration: InputDecoration(
                                          hintText: 'Search shops by name, BR number, or owner...',
                                          prefixIcon: const Icon(Icons.search),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide:
                                                const BorderSide(color: Color(0xFF014EB2)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Results count
                            Text(
                              'Showing ${filteredShops.length} of ${allShops.length} shops',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Shops List
                            Expanded(
                              child: isShopsLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : filteredShops.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                allShops.isEmpty
                                                    ? Icons.error_outline
                                                    : Icons.search_off,
                                                size: 64,
                                                color: Colors.grey.shade400,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                allShops.isEmpty
                                                    ? 'No shops available'
                                                    : 'No shops found',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                allShops.isEmpty
                                                    ? 'Check your connection or try refreshing'
                                                    : 'Try adjusting your search criteria',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                              if (allShops.isEmpty) ...[
                                                const SizedBox(height: 16),
                                                ElevatedButton.icon(
                                                  onPressed: _refreshDashboard,
                                                  icon: const Icon(Icons.refresh),
                                                  label: const Text('Retry'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF014EB2),
                                                    foregroundColor: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: filteredShops.length,
                                          itemBuilder: (context, index) {
                                            return shopCard(filteredShops[index]);
                                          },
                                        ),
                            ),
                          ],
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

  Widget shopCard(Map<String, dynamic> shop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      shop['shop_name']?.toString() ?? shop['name']?.toString() ?? 'N/A',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _showQRDialog(shop),
                          icon: const Icon(Icons.qr_code, color: Color(0xFF014EB2)),
                          tooltip: 'View QR Code',
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: const EdgeInsets.all(4),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'BR: ${shop['br_registration_number']?.toString() ?? shop['br_number']?.toString() ?? 'N/A'} | Contact Person: ${shop['contact_person']?.toString() ?? shop['owner']?.toString() ?? 'N/A'}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Phone: ${shop['contact_teliphone']?.toString() ?? shop['phone']?.toString() ?? shop['contact_telephone']?.toString() ?? 'N/A'}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Address: ${shop['address']?.toString() ?? 'N/A'}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Registered: ${shop['register_date']?.toString() ?? shop['created_at']?.toString() ?? 'N/A'}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget navItem(IconData icon, String title, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade700 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        onTap: () {
          if (title == "Dashboard") {
            print('Already on Dashboard');
          } else if (title == "Collectors") {
            Navigator.pushNamed(context, '/CollectorManagement');
          }
        },
      ),
    );
  }

  Widget logoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton.icon(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          Navigator.pushReplacementNamed(context, '/Login');
        },
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text("Logout", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget adminDashboardCard(String title, String content, IconData icon, Color bgColor, Color iconColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        height: 120,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(1, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  Icon(icon, color: iconColor, size: 24),
                ],
              ),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
