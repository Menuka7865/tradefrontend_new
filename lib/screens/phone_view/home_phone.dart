import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:chilawtraders/screens/web_view/home_web.dart';
import 'package:chilawtraders/serverconection/admin_backend_services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DeviceType { mobile, tablet, desktop }

class AdminDashboardMobile extends StatefulWidget {
  const AdminDashboardMobile({super.key});

  @override
  State<AdminDashboardMobile> createState() => _AdminDashboardMobileState();
}

DeviceType _getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1000) return DeviceType.desktop;
    if (width >= 600) return DeviceType.tablet;
    return DeviceType.mobile;
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
  
  // Loading states
  bool isDashboardLoading = true;
  bool isShopsLoading = true;
  bool isActionLoading = false;

  // Mobile specific states
  bool isDrawerOpen = false;
  int currentIndex = 0;

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
    // Create a unique identifier combining shop details
    String shopId = shop['id']?.toString() ?? shop['shop_id']?.toString() ?? '';
    String shopName = shop['shop_name']?.toString() ?? shop['name']?.toString() ?? '';
    String brNumber = shop['br_registration_number']?.toString() ?? shop['br_number']?.toString() ?? '';
    
    // Create JSON data for QR code
    Map<String, String> qrData = {
      'shop_id': shopId,
      'shop_name': shopName,
      'br_number': brNumber,
      'type': 'shop_verification',
      'generated_at': DateTime.now().toIso8601String(),
    };
    
    return jsonEncode(qrData);
  }

  /// Show QR Code in a mobile-friendly dialog
  void _showQRDialog(Map<String, dynamic> shop) {
    String qrData = _generateQRData(shop);
    String shopName = shop['shop_name']?.toString() ?? shop['name']?.toString() ?? 'Unknown Shop';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'QR Code',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  shopName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 180.0,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Scan this QR code to verify shop details',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
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
                      onPressed: () {
                        // Here you could add functionality to save or share the QR code
                        Navigator.of(context).pop();
                        _showSuccessSnackBar('QR Code ready for $shopName');
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

  /// Initialize dashboard by loading all necessary data
  Future<void> _initializeDashboard() async {
    await Future.wait([
      _loadDashboardStats(),
      _loadShops(),
    ]);
  }

  /// Load dashboard statistics from backend - UPDATED TO USE NEW SERVICE
  Future<void> _loadDashboardStats() async {
    try {
      setState(() {
        isDashboardLoading = true;
      });

      // Use the new AdminBackendServices
      final response = await AdminBackendServices.getDashboardStats();
      
      print("Dashboard Stats API Response: $response");

      // Check for token validation issues
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
        // Handle different response structures
        String errorMessage = response['Message'] ?? response['message'] ?? 'Failed to load dashboard statistics';
        _showErrorSnackBar(errorMessage);
        
        // Set default values if API fails
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
      
      // Set default values on error
      setState(() {
        totalShops = allShops.length.toString();
        totalPayments = "Rs. 0";
        pendingPayments = "Rs. 0";
        totalUsers = "0";
        isDashboardLoading = false;
      });
    }
  }

  /// Load shops from API - UPDATED TO USE NEW SERVICE
  Future<void> _loadShops() async {
    try {
      setState(() {
        isShopsLoading = true;
      });

      // Use the new AdminBackendServices
      final response = await AdminBackendServices.getShops();
      
      print("Shops API Response: $response");

      // Check for token validation issues
      if (response['status'] == false && 
          (response['Message']?.toString().contains('Unauthorized') == true ||
           response['Message']?.toString().contains('Invalid token') == true)) {
        _showErrorSnackBar("Session expired. Please log in again.");
        _redirectToLogin();
        return;
      }
      
      if (response['status'] == true) {
        setState(() {
          // Handle different possible response structures
          var responseData = response['data'] ?? response['shops'] ?? response['Data'];
          
          if (responseData is List) {
            allShops = List<Map<String, dynamic>>.from(responseData);
          } else if (responseData is Map && responseData.containsKey('shops')) {
            allShops = List<Map<String, dynamic>>.from(responseData['shops']);
          } else {
            // If data is directly in response
            allShops = List<Map<String, dynamic>>.from(response['Data'] ?? []);
          }
          
          // Update total shops count after loading
          totalShops = allShops.length.toString();
          
          _filterShops();
          isShopsLoading = false;
        });
        
        _showSuccessSnackBar('Shops loaded successfully (${allShops.length} shops)');
        
        // Reload dashboard stats after shops are loaded to get accurate count
        _loadDashboardStats();
        
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

  /// Filter shops based on search query and selected filter - SAME AS WEB VIEW
  void _filterShops() {
    setState(() {
      String query = searchController.text.toLowerCase();
      
      filteredShops = allShops.where((shop) {
        // Handle different possible field names from API
        bool matchesSearch = (shop['shop_name']?.toString() ?? shop['name']?.toString() ?? '').toLowerCase().contains(query) ||
            (shop['br_registration_number']?.toString() ?? shop['br_number']?.toString() ?? '').toLowerCase().contains(query) ||
            (shop['contact_person']?.toString() ?? shop['owner']?.toString() ?? '').toLowerCase().contains(query) ||
            (shop['contact_teliphone']?.toString() ?? shop['phone']?.toString() ?? shop['contact_telephone']?.toString() ?? '').toLowerCase().contains(query);
        
        bool matchesFilter = selectedFilter == 'All' || 
            (shop['status']?.toString() ?? 'Active') == selectedFilter;
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  /// Refresh all dashboard data - SAME AS WEB VIEW
  Future<void> _refreshDashboard() async {
    setState(() {
      isDashboardLoading = true;
      isShopsLoading = true;
    });
    
    await _initializeDashboard();
    _showSuccessSnackBar('Dashboard refreshed successfully');
  }

  // ==================== UI HELPER METHODS ====================

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
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
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          // Connection status indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (!isDashboardLoading && !isShopsLoading) 
                  ? Colors.green.shade100 
                  : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              (!isDashboardLoading && !isShopsLoading) 
                  ? Icons.wifi 
                  : Icons.sync,
              size: 16,
              color: (!isDashboardLoading && !isShopsLoading) 
                  ? Colors.green.shade700 
                  : Colors.orange.shade700,
            ),
          ),
          // Refresh button
          IconButton(
            onPressed: (isDashboardLoading || isShopsLoading) 
                ? null 
                : _refreshDashboard,
            icon: Icon(
              Icons.refresh,
              color: (isDashboardLoading || isShopsLoading) 
                  ? Colors.grey.shade300 
                  : Colors.white,
            ),
            tooltip: 'Refresh Dashboard',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  // ==================== MOBILE UI WIDGETS ====================

  /// Mobile Navigation Drawer
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
            // Drawer Header
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
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Icon(
                              Icons.admin_panel_settings,
                              size: 40,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ADMIN PANEL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Navigation Items
            Expanded(
              child: Column(
                children: [
                  _drawerItem(Icons.dashboard, "Dashboard", 0),
                  _drawerItem(Icons.settings, "Settings", 1),
                ],
              ),
            ),
            
            // Logout Button
            Container(
              margin: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton.icon(
                onPressed: () async {
                  // Clear token and redirect to login
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  Navigator.pushReplacementNamed(context, '/Login');
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Logout", 
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Drawer Navigation Item
  Widget _drawerItem(IconData icon, String title, int index) {
    bool isSelected = currentIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
          setState(() {
            currentIndex = index;
          });
          Navigator.pop(context);
          print('Navigate to $title');
        },
      ),
    );
  }

  /// Main Body Content
  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard Stats
            _buildDashboardStats(),
            
            const SizedBox(height: 24),
            
            // Shops Section
            _buildShopsSection(),
          ],
        ),
      ),
    );
  }

  /// Dashboard Statistics Cards (Mobile Layout)
  Widget _buildDashboardStats() {
    if (isDashboardLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        // First Row
        Row(
          children: [
            Expanded(
              child: _mobileDashboardCard(
                "Total Shops",
                totalShops,
                Icons.store,
                Colors.blue.shade50,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _mobileDashboardCard(
                "Total Users",
                totalUsers,
                Icons.people,
                Colors.purple.shade50,
                Colors.purple,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Second Row
        Row(
          children: [
            Expanded(
              child: _mobileDashboardCard(
                "Total Payments",
                totalPayments,
                Icons.payment,
                Colors.green.shade50,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _mobileDashboardCard(
                "Pending Payments",
                pendingPayments,
                Icons.pending_actions,
                Colors.orange.shade50,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Mobile Dashboard Card
  Widget _mobileDashboardCard(String title, String content, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: iconColor, size: 20),
              ],
            ),
            Text(
              content,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shops Management Section (Mobile Layout)
  Widget _buildShopsSection() {
    return Container(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Registered Shops',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Search Bar
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search shops...',
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
                  borderSide: const BorderSide(color: Color(0xFF014EB2)),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Results count
            Text(
              'Showing ${filteredShops.length} of ${allShops.length} shops',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Shops List
            if (isShopsLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filteredShops.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredShops.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _mobileShopCard(filteredShops[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Empty State Widget
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            allShops.isEmpty ? Icons.error_outline : Icons.search_off,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            allShops.isEmpty ? 'No shops available' : 'No shops found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            allShops.isEmpty 
                ? 'Check your connection or try refreshing'
                : 'Try adjusting your search criteria',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
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
    );
  }

  /// Mobile Shop Card Widget with QR Code functionality - UPDATED
  Widget _mobileShopCard(Map<String, dynamic> shop) {
    String qrData = _generateQRData(shop);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Shop Name and QR Code
          Row(
            children: [
              Expanded(
                child: Text(
                  shop['shop_name']?.toString() ?? shop['name']?.toString() ?? 'N/A',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Small QR Code Preview
              // Container(
              //   width: 50,
              //   height: 50,
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(6),
              //     border: Border.all(color: Colors.grey.shade300),
              //   ),
              //   child: QrImageView(
              //     data: qrData,
              //     version: QrVersions.auto,
              //     size: 48.0,
              //     backgroundColor: Colors.white,
              //     foregroundColor: Colors.black,
              //   ),
              // ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Shop Details
          _shopDetailRow(
            'BR Number:', 
            shop['br_registration_number']?.toString() ?? shop['br_number']?.toString() ?? 'N/A'
          ),
          _shopDetailRow(
            'Contact Person:', 
            shop['contact_person']?.toString() ?? shop['owner']?.toString() ?? 'N/A'
          ),
          _shopDetailRow(
            'Phone:', 
            shop['contact_teliphone']?.toString() ?? shop['phone']?.toString() ?? shop['contact_telephone']?.toString() ?? 'N/A'
          ),
          _shopDetailRow(
            'Address:', 
            shop['address']?.toString() ?? 'N/A'
          ),
          _shopDetailRow(
            'Registered:', 
            shop['register_date']?.toString() ?? shop['created_at']?.toString() ?? 'N/A'
          ),
          
          const SizedBox(height: 8),
          
          // QR Code Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showQRDialog(shop),
                icon: const Icon(Icons.qr_code, size: 16, color: Color(0xFF014EB2)),
                label: const Text(
                  'View QR',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF014EB2),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              // TextButton.icon(
              //   onPressed: () {
              //     // Add functionality to share QR code
              //     _showSuccessSnackBar('QR Code shared for ${shop['shop_name'] ?? shop['name'] ?? 'shop'}');
              //   },
              //   icon: const Icon(Icons.share, size: 16, color: Colors.green),
              //   label: const Text(
              //     'Share',
              //     style: TextStyle(
              //       fontSize: 12,
              //       color: Colors.green,
              //     ),
              //   ),
              //   style: TextButton.styleFrom(
              //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //     minimumSize: Size.zero,
              //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  /// Shop Detail Row Helper
  Widget _shopDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}