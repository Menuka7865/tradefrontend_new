import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:chilawtraders/serverconection/admin_backend_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CollectorManagementWeb extends StatefulWidget {
  const CollectorManagementWeb({super.key});

  @override
  State<CollectorManagementWeb> createState() => _CollectorManagementWebState();
}

class _CollectorManagementWebState extends State<CollectorManagementWeb> {
  // Dashboard statistics
  String totalCollectors = "Loading...";
  String activeCollectors = "Loading...";
  String recentlyAdded = "Loading...";
  String totalAssignments = "Loading...";

  // Collector data and search functionality
  List<Map<String, dynamic>> allCollectors = [];
  List<Map<String, dynamic>> filteredCollectors = [];
  TextEditingController searchController = TextEditingController();

  // Add collector form controllers
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  // Loading states
  bool isDashboardLoading = true;
  bool isCollectorsLoading = true;
  bool isActionLoading = false;

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
        _showErrorSnackBar(
          "No authentication token found. Please log in again.",
        );
        _redirectToLogin();
        return;
      }

      // Validate token by making a test API call
      final response = await AdminBackendServices.getDashboardStats();

      if (response['status'] == false &&
          (response['Message']?.toString().contains('Unauthorized') == true ||
              response['Message']?.toString().contains('Invalid token') ==
                  true)) {
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
    await Future.wait([_loadDashboardStats(), _loadCollectors()]);
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
              response['Message']?.toString().contains('Invalid token') ==
                  true)) {
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
          activeCollectors = allCollectors
              .where((c) => c['status'] == 'active')
              .length
              .toString();
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
        activeCollectors = allCollectors
            .where((c) => c['status'] == 'active')
            .length
            .toString();
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
              response['Message']?.toString().contains('Invalid token') ==
                  true)) {
        _showErrorSnackBar("Session expired. Please log in again.");
        _redirectToLogin();
        return;
      }

      if (response['status'] == true) {
        setState(() {
          // Handle different possible response structures
          var responseData =
              response['data'] ?? response['collectors'] ?? response['Data'];

          if (responseData is List) {
            allCollectors = List<Map<String, dynamic>>.from(responseData);
          } else if (responseData is Map &&
              responseData.containsKey('collectors')) {
            allCollectors = List<Map<String, dynamic>>.from(
              responseData['collectors'],
            );
          } else {
            // If data is directly in response
            allCollectors = List<Map<String, dynamic>>.from(
              response['Data'] ?? [],
            );
          }

          // Update total collectors count after loading
          totalCollectors = allCollectors.length.toString();

          _filterCollectors();
          isCollectorsLoading = false;
        });

        _showSuccessSnackBar(
          'Collectors loaded successfully (${allCollectors.length} collectors)',
        );

        // Reload dashboard stats after collectors are loaded
        _loadDashboardStats();
      } else {
        String errorMessage =
            response['Message'] ??
            response['message'] ??
            'Failed to load collectors';
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
    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(emailController.text.trim())) {
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

        // Reload collectors
        await _loadCollectors();
      } else {
        String errorMessage =
            response['Message'] ??
            response['message'] ??
            'Failed to add collector';
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
        return (collector['username']?.toString() ?? '').toLowerCase().contains(
              query,
            ) ||
            (collector['email']?.toString() ?? '').toLowerCase().contains(
              query,
            ) ||
            (collector['id']?.toString() ?? '').toLowerCase().contains(query);
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
                    // Admin Logo
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
                    navItem(Icons.dashboard, "Dashboard", false),
                    navItem(Icons.people, "Collectors", true),
                    // navItem(Icons.settings, "Settings", false),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
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
                          'Collector Management',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            // Connection status indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (!isDashboardLoading &&
                                        !isCollectorsLoading)
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    (!isDashboardLoading &&
                                            !isCollectorsLoading)
                                        ? Icons.wifi
                                        : Icons.sync,
                                    size: 12,
                                    color:
                                        (!isDashboardLoading &&
                                            !isCollectorsLoading)
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Refresh button
                            IconButton(
                              onPressed:
                                  (isDashboardLoading || isCollectorsLoading)
                                  ? null
                                  : _refreshDashboard,
                              icon: Icon(
                                Icons.refresh,
                                color:
                                    (isDashboardLoading || isCollectorsLoading)
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
                              "Total Collectors",
                              totalCollectors,
                              Icons.people,
                              Colors.blue.shade50,
                              Colors.blue,
                            ),
                            // adminDashboardCard(
                            //   "Active Collectors",
                            //   activeCollectors,
                            //   Icons.verified_user,
                            //   Colors.green.shade50,
                            //   Colors.green,
                            // ),
                            // adminDashboardCard(
                            //   "Recently Added",
                            //   recentlyAdded,
                            //   Icons.person_add,
                            //   Colors.orange.shade50,
                            //   Colors.orange,
                            // ),
                            // adminDashboardCard(
                            //   "Total Assignments",
                            //   totalAssignments,
                            //   Icons.assignment,
                            //   Colors.purple.shade50,
                            //   Colors.purple,
                            // ),
                          ],
                        ),

                  const SizedBox(height: 30),

                  // Add Collector Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                        Row(
                          children: [
                            // Username field
                            Expanded(
                              child: TextField(
                                controller: usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  hintText: 'Enter collector username',
                                  prefixIcon: const Icon(Icons.person),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF014EB2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Email field
                            Expanded(
                              child: TextField(
                                controller: emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'Enter collector email',
                                  prefixIcon: const Icon(Icons.email),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF014EB2),
                                    ),
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Password field
                            Expanded(
                              child: TextField(
                                controller: passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Enter collector password',
                                  prefixIcon: const Icon(Icons.lock),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF014EB2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Add button
                            ElevatedButton.icon(
                              onPressed: isActionLoading ? null : _addCollector,
                              icon: isActionLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.add),
                              label: Text(
                                isActionLoading ? 'Adding...' : 'Add Collector',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF014EB2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Collectors List Section
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
                            // Header with search
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Registered Collectors',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Row(
                                  children: [
                                    // Search Field
                                    SizedBox(
                                      width: 300,
                                      child: TextField(
                                        controller: searchController,
                                        decoration: InputDecoration(
                                          hintText:
                                              'Search collectors by username, email, or ID...',
                                          prefixIcon: const Icon(Icons.search),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF014EB2),
                                            ),
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
                              'Showing ${filteredCollectors.length} of ${allCollectors.length} collectors',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Collectors List
                            Expanded(
                              child: isCollectorsLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : filteredCollectors.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            allCollectors.isEmpty
                                                ? Icons.error_outline
                                                : Icons.search_off,
                                            size: 64,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            allCollectors.isEmpty
                                                ? 'No collectors available'
                                                : 'No collectors found',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            allCollectors.isEmpty
                                                ? 'Add your first collector using the form above'
                                                : 'Try adjusting your search criteria',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                          // if (allCollectors.isEmpty) ...[
                                          //   const SizedBox(height: 16),
                                          //   ElevatedButton.icon(
                                          //     onPressed: _refreshDashboard,
                                          //     icon: const Icon(Icons.refresh),
                                          //     label: const Text('Retry'),
                                          //     style: ElevatedButton.styleFrom(
                                          //       backgroundColor: const Color(0xFF014EB2),
                                          //       foregroundColor: Colors.white,
                                          //     ),
                                          //   ),
                                          // ],
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: filteredCollectors.length,
                                      itemBuilder: (context, index) {
                                        return collectorCard(
                                          filteredCollectors[index],
                                        );
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

  // ==================== UI WIDGETS ====================

  /// Collector Card Widget
  Widget collectorCard(Map<String, dynamic> collector) {
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
          // Profile Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF014EB2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.person, size: 30, color: Color(0xFF014EB2)),
          ),

          const SizedBox(width: 16),

          // Collector Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      collector['user_name']?.toString() ?? 'N/A',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    // const Spacer(),
                    // // Status indicator
                    // Container(
                    //   padding: const EdgeInsets.symmetric(
                    //     horizontal: 8,
                    //     vertical: 4,
                    //   ),
                    //   decoration: BoxDecoration(
                    //     color:
                    //         (collector['status']?.toString() ?? 'active') ==
                    //             'active'
                    //         ? Colors.green.shade100
                    //         : Colors.red.shade100,
                    //     borderRadius: BorderRadius.circular(12),
                    //   ),
                    //   child: Text(
                    //     (collector['status']?.toString() ?? 'active')
                    //         .toUpperCase(),
                    //     style: TextStyle(
                    //       fontSize: 10,
                    //       fontWeight: FontWeight.bold,
                    //       color:
                    //           (collector['status']?.toString() ?? 'active') ==
                    //               'active'
                    //           ? Colors.green.shade700
                    //           : Colors.red.shade700,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Email: ${collector['email']?.toString() ?? 'N/A'}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${collector['id']?.toString() ?? collector['collector_id']?.toString() ?? 'N/A'}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'Registered: ${collector['register_date']?.toString() ?? collector['created_at']?.toString() ?? collector['registration_date']?.toString() ?? 'N/A'}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                ),
              ],
            ),
          ),

          // Action buttons
          // Column(
          //   children: [
          //     IconButton(
          //       onPressed: () {
          //         // Add functionality to view collector details
          //         _showSuccessSnackBar(
          //           'Viewing details for ${collector['username'] ?? 'collector'}',
          //         );
          //       },
          //       icon: const Icon(Icons.visibility, color: Color(0xFF014EB2)),
          //       tooltip: 'View Details',
          //       constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          //       padding: const EdgeInsets.all(4),
          //     ),
          //     IconButton(
          //       onPressed: () {
          //         // Add functionality to edit collector
          //         _showSuccessSnackBar(
          //           'Editing ${collector['username'] ?? 'collector'}',
          //         );
          //       },
          //       icon: const Icon(Icons.edit, color: Colors.orange),
          //       tooltip: 'Edit Collector',
          //       constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          //       padding: const EdgeInsets.all(4),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  /// Admin Navigation Item
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
          // 🔹 UPDATED NAVIGATION LOGIC
          if (title == "Dashboard") {
            // Stay on current page or refresh
            Navigator.pushNamed(context, '/AdminDashboardWeb');
          } else if (title == "Collectors") {
            // Navigate to Collector Management
            Navigator.pushNamed(context, '/CollectorManagement');
          }
        },
      ),
    );
  }

  /// Admin Logout Button
  Widget logoutButton() {
    return Container(
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
        label: const Text("Logout", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  /// Admin Dashboard Card with Icon
  Widget adminDashboardCard(
    String title,
    String content,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
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
