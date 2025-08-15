import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:chilawtraders/serverconection/admin_backend_services.dart';

// DeviceType enum for responsiveness if extended in future
enum DeviceType { mobile, tablet, desktop }

DeviceType _getDeviceType(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width >= 1000) return DeviceType.desktop;
  if (width >= 600) return DeviceType.tablet;
  return DeviceType.mobile;
}

class PaymentManagementMobile extends StatefulWidget {
  const PaymentManagementMobile({super.key});

  @override
  State<PaymentManagementMobile> createState() => _PaymentManagementMobileState();
}

class _PaymentManagementMobileState extends State<PaymentManagementMobile> {
  // Payment data
  List<dynamic> allPayments = [];
  List<dynamic> filteredPayments = [];
  bool isPaymentsLoading = true;
  bool isActionLoading = false;

  // Date filtering
  DateTime? startDate;
  DateTime? endDate;
  String selectedDateFilter = 'Today';

  final List<String> dateFilterOptions = [
    'Today',
    'Yesterday',
    'This Week',
    'This Month',
    'Custom Range'
  ];

  // Search controller
  final TextEditingController searchController = TextEditingController();

  // Date formatters
  final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
  final DateFormat displayDateFormatter = DateFormat('MMM dd, yyyy');
  final DateFormat timeFormatter = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterPayments);
    _setTodayFilter();
    _validateTokenAndInitialize();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _setTodayFilter() {
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, now.day);
    endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
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

      await _loadPayments();
    } catch (e) {
      print('Token validation error: $e');
      _showErrorSnackBar('Authentication error: $e');
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    Navigator.pushReplacementNamed(context, '/Login');
  }

  Future<void> _loadPayments() async {
    try {
      setState(() {
        isPaymentsLoading = true;
      });

      final response = await AdminBackendServices.getPayments(
        startDate: startDate,
        endDate: endDate,
      );

      if (response['status'] == false &&
          (response['Message']?.toString().contains('Unauthorized') == true ||
              response['Message']?.toString().contains('Invalid token') == true)) {
        _showErrorSnackBar("Session expired. Please log in again.");
        _redirectToLogin();
        return;
      }

      if (response['status'] == true) {
        setState(() {
          var responseData = response['data'] ?? response['payments'] ?? response['Data'];
          if (responseData is List) {
            allPayments = List<dynamic>.from(responseData);
          } else if (responseData is Map && responseData.containsKey('payments')) {
            allPayments = List<dynamic>.from(responseData['payments']);
          } else {
            allPayments = List<dynamic>.from(response['Data'] ?? []);
          }
          _filterPayments();
          isPaymentsLoading = false;
        });
        _showSuccessSnackBar('Payments loaded successfully (${allPayments.length} payments)');
      } else {
        String errorMessage = response['Message'] ?? response['message'] ?? 'Failed to load payments';
        _showErrorSnackBar(errorMessage);
        setState(() {
          allPayments = [];
          filteredPayments = [];
          isPaymentsLoading = false;
        });
      }
    } catch (e) {
      print('Error loading payments: $e');
      _showErrorSnackBar('Error loading payments data: $e');
      setState(() {
        allPayments = [];
        filteredPayments = [];
        isPaymentsLoading = false;
      });
    }
  }

  void _filterPayments() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredPayments = allPayments.where((payment) {
        bool matchesSearch = query.isEmpty ||
            (payment['shop_name']?.toString().toLowerCase() ?? '').contains(query) ||
            (payment['collector_name']?.toString().toLowerCase() ?? '').contains(query) ||
            (payment['amount']?.toString().toLowerCase() ?? '').contains(query) ||
            (payment['payment_id']?.toString().toLowerCase() ?? '').contains(query);

        bool matchesDateRange = true;
        if (startDate != null && endDate != null) {
          try {
            DateTime paymentDate = DateTime.parse(payment['payment_date'] ?? payment['created_at'] ?? '');
            matchesDateRange = !paymentDate.isBefore(startDate!) && !paymentDate.isAfter(endDate!);
          } catch (e) {
            matchesDateRange = true;
          }
        }
        return matchesSearch && matchesDateRange;
      }).toList();

      filteredPayments.sort((a, b) {
        try {
          DateTime dateA = DateTime.parse(a['payment_date'] ?? a['created_at'] ?? '');
          DateTime dateB = DateTime.parse(b['payment_date'] ?? b['created_at'] ?? '');
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });
    });
  }

  Future<void> _applyDateFilter(String filter) async {
    final now = DateTime.now();

    setState(() {
      selectedDateFilter = filter;
    });

    switch (filter) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
        endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        break;
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Custom Range':
        await _selectDateRange();
        return;
    }
    await _loadPayments();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: const Color(0xFF014EB2)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
        selectedDateFilter = 'Custom Range';
      });
      await _loadPayments();
    }
  }

  Future<void> _refreshPayments() async {
    await _loadPayments();
    _showSuccessSnackBar('Payments refreshed successfully');
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'Rs. 0.00';
    try {
      double value = double.parse(amount.toString());
      return 'Rs. ${value.toStringAsFixed(2)}';
    } catch (e) {
      return 'Rs. 0.00';
    }
  }

  Color _getPaymentStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
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

  @override
  Widget build(BuildContext context) {
    final deviceType = _getDeviceType(context);

    // Simple responsive check - you can extend to use different layouts per device
    if (deviceType == DeviceType.mobile) {
      return _buildMobileLayout();
    } else {
      return _buildWebLayout();
    }
  }

  // Your web layout from original PaymentManagementWeb, unchanged
  Widget _buildWebLayout() {
    // (You can paste your original PaymentManagementWeb build implementation here)
    // For brevity not duplicated now
    return Scaffold(
      body: Row(
        children: [
          // Your sidebar and main content from your original code...
          // ...
          const Center(child: Text("Desktop layout not implemented here"))
        ],
      ),
    );
  }

  // Mobile Layout UI
  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Management'),
        backgroundColor: const Color(0xFF014EB2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isPaymentsLoading ? null : _refreshPayments,
            tooltip: 'Refresh Payments',
          )
        ],
      ),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: _refreshPayments,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedDateFilter,
                      decoration: const InputDecoration(
                        labelText: 'Date Filter',
                        border: OutlineInputBorder(),
                      ),
                      items: dateFilterOptions
                          .map((filter) => DropdownMenuItem(
                                value: filter,
                                child: Text(filter),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          _applyDateFilter(val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search payments',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              if (startDate != null && endDate != null)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.date_range, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'From: ${displayDateFormatter.format(startDate!)} To: ${displayDateFormatter.format(endDate!)}',
                        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: isPaymentsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredPayments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  allPayments.isEmpty ? Icons.receipt_long_outlined : Icons.search_off,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  allPayments.isEmpty ? 'No payments found' : 'No payments match your criteria',
                                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  allPayments.isEmpty
                                      ? 'Payments will appear here once they are made'
                                      : 'Try adjusting your search or date range',
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredPayments.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final payment = filteredPayments[index];
                              DateTime? paymentDate;
                              try {
                                paymentDate = DateTime.parse(payment['payment_date'] ?? '');
                              } catch (e) {
                                paymentDate = null;
                              }

                              final statusColor = _getPaymentStatusColor(payment['status']);

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  title: Text(
                                    payment['payment_id']?.toString() ?? 'N/A',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Amount: ${_formatCurrency(payment['amount'])}',
                                        style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
                                      ),
                                      Text('Shop: ${payment['shop_name'] ?? 'N/A'} (ID: ${payment['shop_id'] ?? 'N/A'})'),
                                      Text(
                                          'Collector: ${payment['collector_name'] ?? 'N/A'} (Phone: ${payment['collector_phone'] ?? 'N/A'})'),
                                      if (paymentDate != null)
                                        Text(
                                            'Date: ${displayDateFormatter.format(paymentDate)} ${timeFormatter.format(paymentDate)}'),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      (payment['status']?.toString() ?? 'Completed').toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              )
            ],
          ),
        ),
      ),
    );
  }

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
              child: Column(children: [
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
              ]),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.white),
              title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/AdminDashboardMobile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.white),
              title: const Text('Collectors', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/CollectorManagementMobile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.white),
              title: const Text('Payments', style: TextStyle(color: Colors.white)),
              selected: true,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/PaymentManagementMobile');
              },
            ),
            const Spacer(),
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
            )
          ],
        ),
      ),
    );
  }
}
