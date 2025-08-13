import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:html' as html; // For web download

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chilawtraders/serverconection/admin_backend_services.dart';

enum DeviceType { mobile, tablet, desktop }

DeviceType _getDeviceType(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width >= 1000) return DeviceType.desktop;
  if (width >= 600) return DeviceType.tablet;
  return DeviceType.mobile;
}

class AdminDashboardMobile extends StatefulWidget {
  const AdminDashboardMobile({super.key});

  @override
  State<AdminDashboardMobile> createState() => _AdminDashboardMobileState();
}

class _AdminDashboardMobileState extends State<AdminDashboardMobile> {
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

  // Users data for Send Message feature
  List<Map<String, dynamic>> allUsers = [];
  bool isUsersLoading = false;

  // Loading states
  bool isDashboardLoading = true;
  bool isShopsLoading = true;
  bool isActionLoading = false;

  // Mobile specific states
  bool isDrawerOpen = false;
  int currentIndex = 0;

  // GlobalKey for capturing QR code widget image
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

  /// Validate token before initializing dashboard
  Future<void> _validateTokenAndInitialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null || token.isEmpty) {
        _showErrorSnackBar("No authentication token found. Please log in again.");
        _redirectToLogin();
        return;
      }

      // Validate token by making a test API call using new service
      final response = await AdminBackendServices.getDashboardStats();

      if (response['status'] == false &&
          (response['Message']?.toString().contains('Unauthorized') == true ||
              response['Message']?.toString().contains('Invalid token') == true)) {
        _showErrorSnackBar("Session expired. Please log in again.");
        _redirectToLogin();
        return;
      }

      // If token is valid, initialize dashboard
      _initializeDashboard();
    } catch (e) {
      print('Token validation error: $e');
      _showErrorSnackBar('Authentication error: $e');
      _redirectToLogin();
    }
  }

  /// Redirect to login page
  void _redirectToLogin() {
    Navigator.pushReplacementNamed(context, '/Login');
  }

  /// Generate unique QR code data for each shop
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

  /// Show QR Code in a mobile-friendly dialog with save functionality
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
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'QR Code for $shopName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  key: qrKey,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 180.0,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        const SizedBox(height: 12),
                        // Show shop name below the QR code
                        Text(
                          shopName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Scan this QR code to verify shop details',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
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
                      icon: const Icon(Icons.download, size: 18),
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

  /// Save QR code image - adapted for web
  Future<void> _saveQrCode() async {
    await _saveQrCodeWeb();
  }

  /// Web download method for mobile interface
  Future<void> _saveQrCodeWeb() async {
    try {
      // Get shop name safely from currently saved shop map
      String shopName = _currentQrShop?['shop_name']?.toString() ??
                        _currentQrShop?['name']?.toString() ??
                        'unknown_shop';

      RenderRepaintBoundary boundary = qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final blob = html.Blob([pngBytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = url
        ..download = 'qr_code_${shopName}.png'  // Filename with shop name
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

  /// Initialize dashboard by loading all necessary data
  Future<void> _initializeDashboard() async {
    await Future.wait([
      _loadDashboardStats(),
      _loadShops(),
      _loadUsers(), // Load users on init
    ]);
  }

  /// Load dashboard statistics
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

  /// Load shops from API
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

  // Load users for Send Message dropdown
  Future<void> _loadUsers() async {
    try {
      setState(() {
        isUsersLoading = true;
      });

      final response = await AdminBackendServices.getUsers(); // You must have this API implemented
      if (response['status'] == true) {
        setState(() {
          allUsers = List<Map<String, dynamic>>.from(response['data']);
          isUsersLoading = false;
        });
      } else {
        _showErrorSnackBar('Failed to load users');
        setState(() {
          isUsersLoading = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading users: $e');
      setState(() {
        isUsersLoading = false;
      });
    }
  }

  /// Filter shops based on search query and selected filter
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

  /// Refresh all dashboard data
  Future<void> _refreshDashboard() async {
    setState(() {
      isDashboardLoading = true;
      isShopsLoading = true;
    });

    await _initializeDashboard();
    _showSuccessSnackBar('Dashboard refreshed successfully');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, duration: const Duration(seconds: 3)),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
    );
  }

  // Show Send Message Dialog with "All" option - Mobile optimized
  void _showSendMessageDialog() {
    String? selectedUserId;
    TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send Message',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select User',
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
                      borderSide: const BorderSide(color: Color(0xFF014EB2)),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: 'all',
                      child: Text('All'),
                    ),
                    ...allUsers
                    .where((user) => user['user_type'] == 'trader') 
                    .map((user) {
                      return DropdownMenuItem<String>(
                        value: user['id'].toString(),
                        child: Text(user['name'] ?? user['user_name'] ?? 'Unnamed User'),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    selectedUserId = value;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    hintText: 'Enter your message',
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
                      borderSide: const BorderSide(color: Color(0xFF014EB2)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (selectedUserId == null || messageController.text.trim().isEmpty) {
                          _showErrorSnackBar('Please select a user and enter a message');
                          return;
                        }

                        try {
                          Map<String, dynamic> response;
                          if (selectedUserId == 'all') {
                            // Send message to all users
                            response = await AdminBackendServices.sendMessageToAll(
                              message: messageController.text.trim(),
                            );
                          } else {
                            // Send message to single user
                            response = await AdminBackendServices.sendMessage(
                              userId: selectedUserId!,
                              message: messageController.text.trim(),
                            );
                          }

                          if (response['status'] == true) {
                            _showSuccessSnackBar("Message sent successfully");
                            Navigator.of(context).pop();
                          } else {
                            _showErrorSnackBar(response['Message'] ?? 'Failed to send message');
                          }
                        } catch (e) {
                          _showErrorSnackBar('Error sending message: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF014EB2),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Send'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF014EB2),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (!isDashboardLoading && !isShopsLoading) ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              (!isDashboardLoading && !isShopsLoading) ? Icons.wifi : Icons.sync,
              size: 16,
              color: (!isDashboardLoading && !isShopsLoading) ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
          IconButton(
            onPressed: (isDashboardLoading || isShopsLoading) ? null : _refreshDashboard,
            icon: Icon(
              Icons.refresh,
              color: (isDashboardLoading || isShopsLoading) ? Colors.grey.shade300 : Colors.white,
            ),
            tooltip: 'Refresh Dashboard',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: isUsersLoading ? null : () => _showSendMessageDialog(),
        backgroundColor: const Color(0xFF014EB2),
        child: const Icon(Icons.send, color: Colors.white),
        tooltip: 'Send Message',
      ),
    );
  }

  // === Mobile UI Widgets === //

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF014EB2), Color(0xFF000428)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 60, bottom: 20),
              child: Column(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.asset(
                        'assets/chilaw.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.admin_panel_settings, size: 40, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ADMIN PANEL',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _drawerItem(Icons.dashboard, "Dashboard", 0),
                  _drawerItem(Icons.people, "Collectors", 1),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(12)),
              child: TextButton.icon(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  Navigator.pushReplacementNamed(context, '/Login');
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("Logout", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, int index) {
    bool isSelected = currentIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: isSelected ? Colors.blue.shade700 : Colors.transparent, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        onTap: () {
          setState(() {
            currentIndex = index;
          });
          Navigator.pop(context);
          if (title == "Dashboard") {
            Navigator.pushReplacementNamed(context, '/AdminDashboardMobile');
          } else if (title == "Collectors") {
            Navigator.pushReplacementNamed(context, '/CollectorManagementMobile');
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDashboardStats(),
            const SizedBox(height: 24),
            _buildShopsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardStats() {
    if (isDashboardLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dashboard Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _mobileDashboardCard("Total Shops", totalShops, Icons.store, Colors.blue.shade50, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _mobileDashboardCard("Total Users", totalUsers, Icons.people, Colors.purple.shade50, Colors.purple)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _mobileDashboardCard("Total Payments", totalPayments, Icons.payment, Colors.green.shade50, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _mobileDashboardCard("Pending Payments", pendingPayments, Icons.pending_actions, Colors.orange.shade50, Colors.orange)),
          ],
        ),
      ],
    );
  }

  Widget _mobileDashboardCard(String title, String content, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      height: 100,
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, 2), blurRadius: 4)]),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis)),
              Icon(icon, color: iconColor, size: 20),
            ]),
            Text(content, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildShopsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, 2), blurRadius: 6, spreadRadius: 2)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Registered Shops', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search shops...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF014EB2))),
              ),
            ),
            const SizedBox(height: 12),
            Text('Showing ${filteredShops.length} of ${allShops.length} shops', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 16),
            if (isShopsLoading)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (filteredShops.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredShops.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _mobileShopCard(filteredShops[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(allShops.isEmpty ? Icons.error_outline : Icons.search_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(allShops.isEmpty ? 'No shops available' : 'No shops found', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text(
            allShops.isEmpty ? 'Check your connection or try refreshing' : 'Try adjusting your search criteria',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          if (allShops.isEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF014EB2), foregroundColor: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mobileShopCard(Map<String, dynamic> shop) {
    String qrData = _generateQRData(shop);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(shop['shop_name']?.toString() ?? shop['name']?.toString() ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _shopDetailRow('BR Number:', shop['br_registration_number']?.toString() ?? shop['br_number']?.toString() ?? 'N/A'),
          _shopDetailRow('Contact Person:', shop['contact_person']?.toString() ?? shop['owner']?.toString() ?? 'N/A'),
          _shopDetailRow('Phone:', shop['contact_teliphone']?.toString() ?? shop['phone']?.toString() ?? shop['contact_telephone']?.toString() ?? 'N/A'),
          _shopDetailRow('Address:', shop['address']?.toString() ?? 'N/A'),
          _shopDetailRow('Registered:', shop['register_date']?.toString() ?? shop['created_at']?.toString() ?? 'N/A'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showQRDialog(shop),
                icon: const Icon(Icons.qr_code, size: 16, color: Color(0xFF014EB2)),
                label: const Text('View QR', style: TextStyle(fontSize: 12, color: Color(0xFF014EB2))),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shopDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey.shade700, fontSize: 11))),
        ],
      ),
    );
  }
}