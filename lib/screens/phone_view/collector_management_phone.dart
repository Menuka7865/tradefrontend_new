import 'package:flutter/material.dart';
import 'package:chilawtraders/serverconection/admin_backend_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DeviceType { mobile, tablet, desktop }

class CollectorManagementMobile extends StatefulWidget {
  const CollectorManagementMobile({super.key});

  @override
  State createState() => _CollectorManagementMobileState();
}

// You had this method partially in the code, fix and place inside the State class if needed
DeviceType _getDeviceType(BuildContext context) {
  final width = MediaQuery.of(context).size.width;

  if (width >= 1000) return DeviceType.desktop;
  if (width >= 600) return DeviceType.tablet;
  return DeviceType.mobile;
}

class _CollectorManagementMobileState extends State<CollectorManagementMobile> {
  // Dashboard statistics
  String totalCollectors = "Loading...";
  String monthlyPayment = "Loading...";

  // Collector data and search functionality
  List<Map<String, dynamic>> allCollectors = [];
  List<Map<String, dynamic>> filteredCollectors = [];
  TextEditingController searchController = TextEditingController();

  String selectedFilter = 'All'; // if you want to later include status filtering

  // Add collector form controllers
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  // Loading states
  bool isDashboardLoading = true;
  bool isCollectorsLoading = true;
  bool isActionLoading = false;

  // UI state
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
  Future _validateTokenAndInitialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      if (token == null || token.isEmpty) {
        _showErrorSnackBar("No authentication token found. Please log in again.");
        _redirectToLogin();
        return;
      }

      // Validate token by making a test API call
      final response = await AdminBackendServices.getCollectorStats();
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
  Future _initializeDashboard() async {
    await Future.wait([
      _loadDashboardStats(),
      _loadCollectors(),
    ]);
  }

  /// Load dashboard statistics from backend
  Future _loadDashboardStats() async {
    try {
      setState(() {
        isDashboardLoading = true;
      });

      final response = await AdminBackendServices.getCollectorStats();
      print("Collector Stats API Response: $response");

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
        });
      } else {
        setState(() {
          totalCollectors = allCollectors.length.toString();
        });
      }

      /// *** IMPORTANT FIX HERE *** ///
      /// Properly fetch monthly payment from your API response format

      final monthlyPaymentResponse = await AdminBackendServices.getmonthlypayment();
      print("Monthly Payment API Response: $monthlyPaymentResponse");

      String payment = "0";
      if (monthlyPaymentResponse['status'] == true) {
        final data = monthlyPaymentResponse['data'];
        if (data is List && data.isNotEmpty) {
          final firstItem = data[0];
          if (firstItem is Map && firstItem.containsKey('amount')) {
            payment = firstItem['amount']?.toString() ?? "0";
          }
        } else if (data is Map) {
          payment = data['amount']?.toString() ?? "0";
        }
      }
      print("Parsed monthly payment: $payment");
      setState(() {
        monthlyPayment = payment;
      });

      setState(() {
        isDashboardLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      _showErrorSnackBar('Error loading dashboard data: $e');
      setState(() {
        totalCollectors = allCollectors.length.toString();
        monthlyPayment = "0";
        isDashboardLoading = false;
      });
    }
  }

  /// Load collectors from API
  Future _loadCollectors() async {
    try {
      setState(() {
        isCollectorsLoading = true;
      });

      final response = await AdminBackendServices.getCollectors();
      print("Collectors API Response: $response");

      if (response['status'] == false &&
          (response['Message']?.toString().contains('Unauthorized') == true ||
              response['Message']?.toString().contains('Invalid token') == true)) {
        _showErrorSnackBar("Session expired. Please log in again.");
        _redirectToLogin();
        return;
      }

      if (response['status'] == true) {
        setState(() {
          var responseData = response['data'] ?? response['collectors'] ?? response['Data'];

          if (responseData is List) {
            allCollectors = List<Map<String, dynamic>>.from(responseData);
          } else if (responseData is Map && responseData.containsKey('collectors')) {
            allCollectors = List<Map<String, dynamic>>.from(responseData['collectors']);
          } else {
            allCollectors = List<Map<String, dynamic>>.from(response['Data'] ?? []);
          }

          _filterCollectors();
          isCollectorsLoading = false;
        });
        _showSuccessSnackBar('Collectors loaded successfully (${allCollectors.length} collectors)');
        // Reload dashboard stats after collectors are loaded
        await _loadDashboardStats();
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

  /// Filter collectors based on search query and selected filter
  void _filterCollectors() {
    setState(() {
      final query = searchController.text.toLowerCase();
      filteredCollectors = allCollectors.where((collector) {
        bool matchesSearch = (collector['user_code']?.toString().toLowerCase() ?? '').contains(query) ||
            (collector['email']?.toString().toLowerCase() ?? '').contains(query) ||
            (collector['id']?.toString().toLowerCase() ?? '').contains(query);
        bool matchesFilter = selectedFilter == 'All' || (collector['status']?.toString() ?? 'active') == selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  /// Refresh all dashboard data
  Future _refreshDashboard() async {
    setState(() {
      isDashboardLoading = true;
      isCollectorsLoading = true;
    });
    await _initializeDashboard();
    _showSuccessSnackBar('Dashboard refreshed successfully');
  }

  /// Add new collector
  Future _addCollector() async {
    if (usernameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text.trim())) {
      _showErrorSnackBar('Please enter a valid email address');
      return;
    }

    try {
      setState(() {
        isActionLoading = true;
      });

      final response = await AdminBackendServices.addCollector(
        usercode: usernameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      print("Add Collector API Response: $response");

      if (response['status'] == true) {
        _showSuccessSnackBar('Collector added successfully!');
        usernameController.clear();
        emailController.clear();
        passwordController.clear();

        setState(() {
          showAddForm = false;
        });

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

  /// Show success SnackBar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, duration: const Duration(seconds: 3)),
    );
  }

  /// Show error SnackBar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
    );
  }

  /// Show loading SnackBar helper
  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show Edit Monthly Payment Dialog
  void _showEditMonthlyPaymentDialog() {
    TextEditingController paymentController = TextEditingController(text: monthlyPayment);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Monthly Payment'),
          content: TextField(
            controller: paymentController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monthly Payment',
              hintText: 'Enter new monthly payment',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String newPayment = paymentController.text.trim();
                if (newPayment.isEmpty || double.tryParse(newPayment) == null) {
                  _showErrorSnackBar('Please enter a valid number');
                  return;
                }

                Navigator.of(context).pop();

                _showLoadingSnackBar('Updating payment...');

                try {
                  final response = await AdminBackendServices.updatePayment(newAmount: newPayment);

                  if (response['status'] == true) {
                    // Re-fetch dashboard stats to reflect updated payment
                    await _loadDashboardStats();
                    _showSuccessSnackBar('Monthly payment updated to $newPayment');
                  } else {
                    String error = response['Message'] ?? 'Failed to update payment';
                    _showErrorSnackBar(error);
                  }
                } catch (e) {
                  _showErrorSnackBar('Connection error. Please try again.');
                  print('Update payment error: $e');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  /// Show Edit Collector Dialog (similar to web version)
  void _showEditCollectorDialog(Map collector) {
    TextEditingController editUsercodeController = TextEditingController(text: collector['user_code'] ?? '');
    TextEditingController editEmailController = TextEditingController(text: collector['email'] ?? '');
    TextEditingController editPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool isUpdating = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Collector'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: editUsercodeController,
                      decoration: const InputDecoration(
                        labelText: 'Usercode',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: editEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: editPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password (Optional)',
                        prefixIcon: Icon(Icons.lock),
                        helperText: 'Leave empty to keep current password',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUpdating ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isUpdating
                      ? null
                      : () async {
                          String editedUsercode = editUsercodeController.text.trim();
                          String editedEmail = editEmailController.text.trim();
                          String editedPassword = editPasswordController.text.trim();

                          if (editedUsercode.isEmpty || editedEmail.isEmpty) {
                            _showErrorSnackBar('Usercode and Email cannot be empty.');
                            return;
                          }

                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(editedEmail)) {
                            _showErrorSnackBar('Enter a valid email address.');
                            return;
                          }

                          setStateDialog(() {
                            isUpdating = true;
                          });

                          bool success = await _updateCollector(
                            collectorId: (collector['id'] ?? collector['collector_id']).toString(),
                            usercode: editedUsercode,
                            email: editedEmail,
                            password: editedPassword.isEmpty ? null : editedPassword,
                          );

                          setStateDialog(() {
                            isUpdating = false;
                          });

                          if (success) {
                            Navigator.of(context).pop();
                            _showSuccessSnackBar('Collector updated successfully.');
                            await _loadCollectors();
                          }
                        },
                  child: isUpdating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Call backend API to update collector details.
  Future<bool> _updateCollector({
    required String collectorId,
    required String usercode,
    required String email,
    String? password,
  }) async {
    try {
      setState(() {
        isActionLoading = true;
      });
      final response = await AdminBackendServices.updateCollector(
        collectorId: collectorId,
        usercode: usercode,
        email: email,
        password: password,
      );
      print("Update Collector API Response: $response");
      if (response['status'] == true) {
        return true;
      } else {
        String errorMessage = response['Message'] ?? response['message'] ?? 'Update failed';
        _showErrorSnackBar(errorMessage);
        return false;
      }
    } catch (e) {
      print('Error updating collector: $e');
      _showErrorSnackBar('Error updating collector: $e');
      return false;
    } finally {
      setState(() {
        isActionLoading = false;
      });
    }
  }

  /// Delete collector with confirmation dialog
  Future _deleteCollector(Map collector) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Are you sure you want to delete collector "${collector['user_code'] ?? 'N/A'}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmDelete == true) {
      setState(() => isActionLoading = true);

      try {
        String collectorId = (collector['id'] ?? collector['collector_id']).toString();
        final response = await AdminBackendServices.deleteCollector(collectorId: collectorId);

        if (response['status'] == true) {
          _showSuccessSnackBar('Collector deleted successfully.');
          await _loadCollectors();
        } else {
          String errorMessage = response['Message'] ?? response['message'] ?? 'Failed to delete collector';
          _showErrorSnackBar(errorMessage);
        }
      } catch (e) {
        _showErrorSnackBar('Error deleting collector: $e');
      } finally {
        setState(() => isActionLoading = false);
      }
    }
  }

  /// Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Collector Management'),
        centerTitle: true,
        backgroundColor: const Color(0xFF014EB2),
      ),
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
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDashboardLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Collector Overview',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _mobileDashboardCard(
                            "Total Collectors",
                            totalCollectors,
                            Icons.people,
                            Colors.blue.shade50,
                            Colors.blue,
                            showEditButton: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _mobileDashboardCard(
                            "Monthly Payment",
                            monthlyPayment,
                            Icons.payment,
                            Colors.green.shade50,
                            Colors.green,
                            showEditButton: true,
                            onEditPressed: _showEditMonthlyPaymentDialog,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              if (showAddForm) _buildAddCollectorForm(),
              if (showAddForm) const SizedBox(height: 24),
              _buildCollectorsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileDashboardCard(
    String title,
    String content,
    IconData icon,
    Color bgColor,
    Color iconColor, {
    bool showEditButton = false,
    VoidCallback? onEditPressed,
  }) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, 2), blurRadius: 4)],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: iconColor, size: 20),
              if (showEditButton && onEditPressed != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                  tooltip: 'Edit $title',
                  onPressed: onEditPressed,
                ),
              ],
            ],
          ),
          Text(
            content,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCollectorForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Collector',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: usernameController,
            decoration: InputDecoration(
              labelText: 'Usercode',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isActionLoading ? null : _addCollector,
              icon: isActionLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
    );
  }

  Widget _buildCollectorsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Registered Collectors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search collectors...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Showing ${filteredCollectors.length} of ${allCollectors.length} collectors',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (isCollectorsLoading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
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
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(allCollectors.isEmpty ? Icons.error_outline : Icons.search_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            allCollectors.isEmpty ? 'No collectors available' : 'No collectors found',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          Text(
            allCollectors.isEmpty ? 'Add your first collector using the form above' : 'Try adjusting your search criteria',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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

  Widget _mobileCollectorCard(Map<String, dynamic> collector) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: const Color(0xFF014EB2).withOpacity(0.1), borderRadius: BorderRadius.circular(25)),
                child: const Icon(Icons.person, color: Color(0xFF014EB2), size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(collector['user_code']?.toString() ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${collector['id'] ?? collector['collector_id'] ?? 'N/A'}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _collectorDetailRow('Email:', collector['email']?.toString() ?? 'N/A'),
          _collectorDetailRow(
            'Registered:',
            collector['register_date']?.toString() ??
                collector['created_at']?.toString() ??
                collector['registration_date']?.toString() ??
                'N/A',
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showEditCollectorDialog(collector),
                icon: const Icon(Icons.edit, size: 16, color: Colors.orange),
                label: const Text('Edit', style: TextStyle(fontSize: 12, color: Colors.orange)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: isActionLoading ? null : () => _deleteCollector(collector),
                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                label: const Text('Delete', style: TextStyle(fontSize: 12, color: Colors.red)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
