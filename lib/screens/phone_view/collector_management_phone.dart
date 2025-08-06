import 'package:flutter/material.dart';
import 'package:chilawtraders/serverconection/admin_backend_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DeviceType { mobile, tablet, desktop }

class CollectorManagementMobile extends StatefulWidget {
  const CollectorManagementMobile({super.key});

  @override
  State<CollectorManagementMobile> createState() => _CollectorManagementMobileState();
}

DeviceType _getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1000) return DeviceType.desktop;
    if (width >= 600) return DeviceType.tablet;
    return DeviceType.mobile;
  }

class _CollectorManagementMobileState extends State<CollectorManagementMobile> {
  // Dashboard statistics
  String totalCollectors = "Loading...";
  String activeCollectors = "Loading...";
  String recentlyAdded = "Loading...";
  String totalAssignments = "Loading...";

  // Collector data and search functionality
  List<Map<String, dynamic>> allCollectors = [];
  List<Map<String, dynamic>> filteredCollectors = [];
  TextEditingController searchController = TextEditingController();
  String selectedFilter = 'All';
  
  // Add collector form controllers
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  
  // Loading states
  bool isDashboardLoading = true;
  bool isCollectorsLoading = true;
  bool isActionLoading = false;

  // Mobile specific states
  bool isDrawerOpen = false;
  int currentIndex = 1; // Collectors tab selected
  bool showAddForm = false;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterCollectors);
    _validateTokenAndInitialize();
  }

  @override
  void dispose() {
    searchController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
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

      // Validate token by making a test API call
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

  /// Initialize dashboard by loading all necessary data
  Future<void> _initializeDashboard() async {
    await Future.wait([
      _loadDashboardStats(),
      _loadCollectors(),
    ]);
  }

  /// Load dashboard statistics from backend
  Future<void> _loadDashboardStats() async {
    try {
      setState(() {
        isDashboardLoading = true;
      });

      // Use AdminBackendServices to get collector stats
      final response = await AdminBackendServices.getCollectorStats();
      
      print("Collector Stats API Response: $response");

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
          totalCollectors = data['total_collectors']?.toString() ?? "0";
          activeCollectors = data['active_collectors']?.toString() ?? "0";
          recentlyAdded = data['recently_added']?.toString() ?? "0";
          totalAssignments = data['total_assignments']?.toString() ?? "0";
          isDashboardLoading = false;
        });
      } else {
        // Handle different response structures or set default values
        setState(() {
          totalCollectors = allCollectors.length.toString();
          activeCollectors = allCollectors.where((c) => c['status'] == 'active').length.toString();
          recentlyAdded = "0";
          totalAssignments = "0";
          isDashboardLoading = false;
        });
      }
    } catch (e) {
      print('Error loading collector stats: $e');
      _showErrorSnackBar('Error loading dashboard data: $e');
      
      // Set default values on error
      setState(() {
        totalCollectors = allCollectors.length.toString();
        activeCollectors = allCollectors.where((c) => c['status'] == 'active').length.toString();
        recentlyAdded = "0";
        totalAssignments = "0";
        isDashboardLoading = false;
      });
    }
  }

  /// Load collectors from API
  Future<void> _loadCollectors() async {
    try {
      setState(() {
        isCollectorsLoading = true;
      });

      // Use AdminBackendServices to get collectors
      final response = await AdminBackendServices.getCollectors();
      
      print("Collectors API Response: $response");

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
          var responseData = response['data'] ?? response['collectors'] ?? response['Data'];
          
          if (responseData is List) {
            allCollectors = List<Map<String, dynamic>>.from(responseData);
          } else if (responseData is Map && responseData.containsKey('collectors')) {
            allCollectors = List<Map<String, dynamic>>.from(responseData['collectors']);
          } else {
            // If data is directly in response
            allCollectors = List<Map<String, dynamic>>.from(response['Data'] ?? []);
          }
          
          // Update total collectors count after loading
          totalCollectors = allCollectors.length.toString();
          
          _filterCollectors();
          isCollectorsLoading = false;
        });
        
        _showSuccessSnackBar('Collectors loaded successfully (${allCollectors.length} collectors)');
        
        // Reload dashboard stats after collectors are loaded
        _loadDashboardStats();
        
      } else {
        String errorMessage = response['Message'] ?? response['message'] ?? 'Failed to load collectors';
        _showErrorSnackBar(errorMessage);
        setState(() {
          allCollectors = [];
          filteredCollectors = [];
          isCollectorsLoading = false;
        });
      }
    } catch (e) {
      print('Error loading collectors: $e');
      _showErrorSnackBar('Error loading collectors data: $e');
      setState(() {
        allCollectors = [];
        filteredCollectors = [];
        isCollectorsLoading = false;
      });
    }
  }

  /// Add new collector
  Future<void> _addCollector() async {
    if (usernameController.text.trim().isEmpty || 
        emailController.text.trim().isEmpty || 
        passwordController.text.trim().isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    // Basic email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text.trim())) {
      _showErrorSnackBar('Please enter a valid email address');
      return;
    }

    try {
      setState(() {
        isActionLoading = true;
      });

      final response = await AdminBackendServices.addCollector(
        username: usernameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      print("Add Collector API Response: $response");

      if (response['status'] == true) {
        _showSuccessSnackBar('Collector added successfully!');
        
        // Clear form
        usernameController.clear();
        emailController.clear();
        passwordController.clear();
        
        // Hide form
        setState(() {
          showAddForm = false;
        });
        
        // Reload collectors
        await _loadCollectors();
        
      } else {
        String errorMessage = response['Message'] ?? response['message'] ?? 'Failed to add collector';
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      print('Error adding collector: $e');
      _showErrorSnackBar('Error adding collector: $e');
    } finally {
      setState(() {
        isActionLoading = false;
      });
    }
  }

  /// Filter collectors based on search query
  void _filterCollectors() {
    setState(() {
      String query = searchController.text.toLowerCase();
      
      filteredCollectors = allCollectors.where((collector) {
        bool matchesSearch = (collector['username']?.toString() ?? '').toLowerCase().contains(query) ||
            (collector['email']?.toString() ?? '').toLowerCase().contains(query) ||
            (collector['id']?.toString() ?? '').toLowerCase().contains(query);
        
        bool matchesFilter = selectedFilter == 'All' || 
            (collector['status']?.toString() ?? 'active') == selectedFilter;
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  /// Refresh all dashboard data
  Future<void> _refreshDashboard() async {
    setState(() {
      isDashboardLoading = true;
      isCollectorsLoading = true;
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
          'Collector Management',
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
              color: (!isDashboardLoading && !isCollectorsLoading) 
                  ? Colors.green.shade100 
                  : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              (!isDashboardLoading && !isCollectorsLoading) 
                  ? Icons.wifi 
                  : Icons.sync,
              size: 16,
              color: (!isDashboardLoading && !isCollectorsLoading) 
                  ? Colors.green.shade700 
                  : Colors.orange.shade700,
            ),
          ),
          // Refresh button
          IconButton(
            onPressed: (isDashboardLoading || isCollectorsLoading) 
                ? null 
                : _refreshDashboard,
            icon: Icon(
              Icons.refresh,
              color: (isDashboardLoading || isCollectorsLoading) 
                  ? Colors.grey.shade300 
                  : Colors.white,
            ),
            tooltip: 'Refresh Dashboard',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            showAddForm = !showAddForm;
          });
        },
        backgroundColor: const Color(0xFF014EB2),
        child: Icon(
          showAddForm ? Icons.close : Icons.add,
          color: Colors.white,
        ),
        tooltip: showAddForm ? 'Close Form' : 'Add Collector',
      ),
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
                  _drawerItem(Icons.people, "Collectors", 1),
                  
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
          
          // Navigation logic
          if (title == "Dashboard") {
            Navigator.pushReplacementNamed(context, '/AdminDashboardMobile');
          } else if (title == "Collectors") {
             Navigator.pushReplacementNamed(context, '/CollectorManagementMobile');
          } 
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
            
            // Add Collector Form (if shown)
            if (showAddForm) ...[
              _buildAddCollectorForm(),
              const SizedBox(height: 24),
            ],
            
            // Collectors Section
            _buildCollectorsSection(),
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
          'Collector Overview',
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
                "Total Collectors",
                totalCollectors,
                Icons.people,
                Colors.blue.shade50,
                Colors.blue,
              ),
            ),
        //     const SizedBox(width: 12),
        //     Expanded(
        //       child: _mobileDashboardCard(
        //         "Active Collectors",
        //         activeCollectors,
        //         Icons.verified_user,
        //         Colors.green.shade50,
        //         Colors.green,
        //       ),
        //     ),
        //   ],
        // ),
        
        // const SizedBox(height: 12),
        
        // // Second Row
        // Row(
        //   children: [
        //     Expanded(
        //       child: _mobileDashboardCard(
        //         "Recently Added",
        //         recentlyAdded,
        //         Icons.person_add,
        //         Colors.orange.shade50,
        //         Colors.orange,
        //       ),
        //     ),
        //     const SizedBox(width: 12),
        //     Expanded(
        //       child: _mobileDashboardCard(
        //         "Assignments",
        //         totalAssignments,
        //         Icons.assignment,
        //         Colors.purple.shade50,
        //         Colors.purple,
        //       ),
        //     ),
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

  /// Add Collector Form (Mobile Layout)
  Widget _buildAddCollectorForm() {
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
            const Text(
              'Add New Collector',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Username field
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Enter collector username',
                prefixIcon: const Icon(Icons.person),
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
            
            // Email field
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter collector email',
                prefixIcon: const Icon(Icons.email),
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
              keyboardType: TextInputType.emailAddress,
            ),
            
            const SizedBox(height: 12),
            
            // Password field
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter collector password',
                prefixIcon: const Icon(Icons.lock),
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
            
            const SizedBox(height: 16),
            
            // Add button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isActionLoading ? null : _addCollector,
                icon: isActionLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(isActionLoading ? 'Adding...' : 'Add Collector'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF014EB2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Collectors Management Section (Mobile Layout)
  Widget _buildCollectorsSection() {
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
              'Registered Collectors',
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
                hintText: 'Search collectors...',
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
              'Showing ${filteredCollectors.length} of ${allCollectors.length} collectors',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Collectors List
            if (isCollectorsLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filteredCollectors.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredCollectors.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _mobileCollectorCard(filteredCollectors[index]);
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
            allCollectors.isEmpty ? Icons.error_outline : Icons.search_off,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            allCollectors.isEmpty ? 'No collectors available' : 'No collectors found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            allCollectors.isEmpty 
                ? 'Add your first collector using the form above'
                : 'Try adjusting your search criteria',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          if (allCollectors.isEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  showAddForm = true;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Collector'),
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

  /// Mobile Collector Card Widget
  Widget _mobileCollectorCard(Map<String, dynamic> collector) {
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
          // Header Row with Collector Info and Status
          Row(
            children: [
              // Profile Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF014EB2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.person,
                  size: 25,
                  color: Color(0xFF014EB2),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Collector Name and Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collector['user_name']?.toString() ?? 'N/A',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${collector['id']?.toString() ?? collector['collector_id']?.toString() ?? 'N/A'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status Badge
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //   decoration: BoxDecoration(
              //     color: (collector['status']?.toString() ?? 'active') == 'active' 
              //         ? Colors.green.shade100 
              //         : Colors.red.shade100,
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   child: Text(
              //     (collector['status']?.toString() ?? 'active').toUpperCase(),
              //     style: TextStyle(
              //       fontSize: 10,
              //       fontWeight: FontWeight.bold,
              //       color: (collector['status']?.toString() ?? 'active') == 'active' 
              //           ? Colors.green.shade700 
              //           : Colors.red.shade700,
              //     ),
              //   ),
              // ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Collector Details
          _collectorDetailRow(
            'Email:', 
            collector['email']?.toString() ?? 'N/A'
          ),
          _collectorDetailRow(
            'Registered:', 
            collector['register_date']?.toString() ?? collector['created_at']?.toString() ?? collector['registration_date']?.toString() ?? 'N/A'
          ),
          
          const SizedBox(height: 8),
          
          // Action Buttons Row
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.end,
          //   children: [
          //     TextButton.icon(
          //       onPressed: () {
          //         // Add functionality to view collector details
          //         _showSuccessSnackBar('Viewing details for ${collector['username'] ?? 'collector'}');
          //       },
          //       icon: const Icon(Icons.visibility, size: 16, color: Color(0xFF014EB2)),
          //       label: const Text(
          //         'View',
          //         style: TextStyle(
          //           fontSize: 12,
          //           color: Color(0xFF014EB2),
          //         ),
          //       ),
          //       style: TextButton.styleFrom(
          //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //         minimumSize: Size.zero,
          //         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          //       ),
          //     ),
          //     const SizedBox(width: 8),
          //     TextButton.icon(
          //       onPressed: () {
          //         // Add functionality to edit collector
          //         _showSuccessSnackBar('Editing ${collector['username'] ?? 'collector'}');
          //       },
          //       icon: const Icon(Icons.edit, size: 16, color: Colors.orange),
          //       label: const Text(
          //         'Edit',
          //         style: TextStyle(
          //           fontSize: 12,
          //           color: Colors.orange,
          //         ),
          //       ),
          //       style: TextButton.styleFrom(
          //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //         minimumSize: Size.zero,
          //         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  /// Collector Detail Row Helper
  Widget _collectorDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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