import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:chilawtraders/serverconection/admin_backend_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CollectorManagementWeb extends StatefulWidget {
  const CollectorManagementWeb({super.key});

  @override
  State createState() => _CollectorManagementWebState();
}

class _CollectorManagementWebState extends State<CollectorManagementWeb> {
  // Dashboard statistics
  String totalCollectors = "Loading...";
  String monthlyPayment = "Loading...";

  // Collector data and search functionality
  List allCollectors = [];
  List filteredCollectors = [];
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

  void _redirectToLogin() {
    Navigator.pushReplacementNamed(context, '/Login');
  }

  Future _initializeDashboard() async {
    await Future.wait([_loadDashboardStats(), _loadCollectors()]);
  }

  Future _loadDashboardStats() async {
    try {
      setState(() {
        isDashboardLoading = true;
      });

      final collectorStatsResponse = await AdminBackendServices.getCollectorStats();
      print("Collector Stats API Response: $collectorStatsResponse");

      if (collectorStatsResponse['status'] == false &&
          (collectorStatsResponse['Message']?.toString().contains('Unauthorized') == true ||
              collectorStatsResponse['Message']?.toString().contains('Invalid token') == true)) {
        _showErrorSnackBar("Session expired. Please log in again.");
        _redirectToLogin();
        return;
      }

      if (collectorStatsResponse['status'] == true && collectorStatsResponse['data'] != null) {
        final data = collectorStatsResponse['data'];
        totalCollectors = data['total_collectors']?.toString() ?? "0";
      } else {
        totalCollectors = allCollectors.length.toString();
      }

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
      monthlyPayment = payment;

      setState(() {
        isDashboardLoading = false;
      });
    } catch (e) {
      print('Error loading collector stats: $e');
      _showErrorSnackBar('Error loading dashboard data: $e');
      setState(() {
        totalCollectors = allCollectors.length.toString();
        monthlyPayment = "0";
        isDashboardLoading = false;
      });
    }
  }

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
            allCollectors = List.from(responseData);
          } else if (responseData is Map && responseData.containsKey('collectors')) {
            allCollectors = List.from(responseData['collectors']);
          } else {
            allCollectors = List.from(response['Data'] ?? []);
          }

          totalCollectors = allCollectors.length.toString();

          _filterCollectors();
          isCollectorsLoading = false;
        });
        _showSuccessSnackBar('Collectors loaded successfully (${allCollectors.length} collectors)');
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

  Future _deleteCollector(Map collector) async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Collector'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to delete this collector?'),
              const SizedBox(height: 12),
              Text(
                'Username: ${collector['user_code'] ?? collector['usercode'] ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Email: ${collector['email'] ?? 'N/A'}'),
              const SizedBox(height: 12),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        setState(() {
          isActionLoading = true;
        });

        String collectorId = (collector['id'] ?? collector['collector_id']).toString();

        final response = await AdminBackendServices.deleteCollector(collectorId: collectorId);

        print("Delete Collector API Response: $response");

        if (response['status'] == true) {
          _showSuccessSnackBar('Collector deleted successfully!');
          await _loadCollectors();
        } else {
          String errorMessage = response['Message'] ?? response['message'] ?? 'Failed to delete collector';
          _showErrorSnackBar(errorMessage);
        }
      } catch (e) {
        print('Error deleting collector: $e');
        _showErrorSnackBar('Error deleting collector: $e');
      } finally {
        setState(() {
          isActionLoading = false;
        });
      }
    }
  }

  void _filterCollectors() {
    setState(() {
      String query = searchController.text.toLowerCase();
      filteredCollectors = allCollectors.where((collector) {
        return (collector['usercode']?.toString().toLowerCase().contains(query) ?? false) ||
            (collector['email']?.toString().toLowerCase().contains(query) ?? false) ||
            (collector['id']?.toString().toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  Future _refreshDashboard() async {
    setState(() {
      isDashboardLoading = true;
      isCollectorsLoading = true;
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
                    // Refresh data from backend after update
                    await _loadDashboardStats();
                    _showSuccessSnackBar('Monthly payment updated to $newPayment');
                  } else {
                    String errorMessage = response['Message'] ?? 'Failed to update payment';
                    _showErrorSnackBar(errorMessage);
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

  void _showEditCollectorDialog(Map collector) {
    TextEditingController editUsercodeController = TextEditingController(
      text: collector['user_code'] ?? collector['usercode'] ?? '',
    );
    TextEditingController editEmailController = TextEditingController(
      text: collector['email'] ?? '',
    );
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
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: editEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: editPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password (Optional)',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
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
                    navItem(Icons.dashboard, "Dashboard", false),
                    navItem(Icons.people, "Collectors", true),
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
                        BoxShadow(color: Colors.black12, offset: Offset(0, 2), blurRadius: 6, spreadRadius: 2),
                      ],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Collector Management',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (!isDashboardLoading && !isCollectorsLoading)
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    (!isDashboardLoading && !isCollectorsLoading) ? Icons.wifi : Icons.sync,
                                    size: 12,
                                    color: (!isDashboardLoading && !isCollectorsLoading)
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: (isDashboardLoading || isCollectorsLoading) ? null : _refreshDashboard,
                              icon: Icon(
                                Icons.refresh,
                                color: (isDashboardLoading || isCollectorsLoading) ? Colors.grey : Colors.blue,
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

                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10),
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
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
                                          const Text(
                                            "Monthly payment",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.payment, color: Colors.green, size: 24),
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.orange),
                                                tooltip: 'Edit Monthly Payment',
                                                onPressed: _showEditMonthlyPaymentDialog,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Text(
                                        monthlyPayment,
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
                            ),
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
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Usercode',
                                  hintText: 'Enter collector user code',
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
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
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
                            ),
                            const SizedBox(width: 16),
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
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: isActionLoading ? null : _addCollector,
                              icon: isActionLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.add),
                              label: Text(isActionLoading ? 'Adding...' : 'Add Collector'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF014EB2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                                SizedBox(
                                  width: 300,
                                  child: TextField(
                                    controller: searchController,
                                    decoration: InputDecoration(
                                      hintText: 'Search collectors by username, email, or ID...',
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
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Showing ${filteredCollectors.length} of ${allCollectors.length} collectors',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: isCollectorsLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : filteredCollectors.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                allCollectors.isEmpty ? Icons.error_outline : Icons.search_off,
                                                size: 64,
                                                color: Colors.grey.shade400,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                allCollectors.isEmpty ? 'No collectors available' : 'No collectors found',
                                                style:
                                                    TextStyle(fontSize: 18, color: Colors.grey.shade600),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                allCollectors.isEmpty
                                                    ? 'Add your first collector using the form above'
                                                    : 'Try adjusting your search criteria',
                                                style:
                                                    TextStyle(fontSize: 14, color: Colors.grey.shade500),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: filteredCollectors.length,
                                          itemBuilder: (context, index) {
                                            return collectorCard(filteredCollectors[index]);
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

  Widget collectorCard(Map collector) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collector['user_code']?.toString() ?? collector['usercode']?.toString() ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
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
          Row(
            children: [
              IconButton(
                onPressed: isActionLoading ? null : () {
                  _showEditCollectorDialog(collector);
                },
                icon: Icon(Icons.edit, color: isActionLoading ? Colors.grey : Colors.orange),
                tooltip: 'Edit Collector',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: const EdgeInsets.all(4),
              ),
              IconButton(
                onPressed: isActionLoading ? null : () {
                  _deleteCollector(collector);
                },
                icon: Icon(Icons.delete, color: isActionLoading ? Colors.grey : Colors.red),
                tooltip: 'Delete Collector',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: const EdgeInsets.all(4),
              ),
            ],
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
        title: Text(title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        onTap: () {
          if (title == "Dashboard") {
            Navigator.pushNamed(context, '/AdminDashboardWeb');
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
            BoxShadow(color: Colors.black12, offset: Offset(1, 2), blurRadius: 4),
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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  Icon(icon, color: iconColor, size: 24),
                ],
              ),
              Text(
                content,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
