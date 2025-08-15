import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:chilawtraders/serverconection/admin_backend_services.dart';

class PaymentManagementWeb extends StatefulWidget {
  const PaymentManagementWeb({super.key});

  @override
  State createState() => _PaymentManagementWebState();
}

class _PaymentManagementWebState extends State<PaymentManagementWeb> {
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

  // Search functionality
  TextEditingController searchController = TextEditingController();

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

  Future _validateTokenAndInitialize() async {
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

      _loadPayments();
    } catch (e) {
      print('Token validation error: $e');
      _showErrorSnackBar('Authentication error: $e');
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    Navigator.pushReplacementNamed(context, '/Login');
  }

  Future _loadPayments() async {
    try {
      setState(() {
        isPaymentsLoading = true;
      });

      final response = await AdminBackendServices.getPayments(
        startDate: startDate,
        endDate: endDate,
      );

      print("Payments API Response: $response");

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
    setState(() {
      String query = searchController.text.toLowerCase();
      filteredPayments = allPayments.where((payment) {
        bool matchesSearch = query.isEmpty ||
            (payment['shop_name']?.toString() ?? '').toLowerCase().contains(query) ||
            (payment['collector_name']?.toString() ?? '').toLowerCase().contains(query) ||
            (payment['amount']?.toString() ?? '').toLowerCase().contains(query) ||
            (payment['payment_id']?.toString() ?? '').toLowerCase().contains(query);

        bool matchesDateRange = true;
        if (startDate != null && endDate != null) {
          try {
            DateTime paymentDate = DateTime.parse(payment['payment_date'] ?? payment['created_at'] ?? '');
            matchesDateRange = paymentDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
                paymentDate.isBefore(endDate!.add(const Duration(days: 1)));
          } catch (e) {
            matchesDateRange = true; // Include if date parsing fails
          }
        }
        return matchesSearch && matchesDateRange;
      }).toList();

      // Sort by payment date (newest first)
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

  // Custom dialog to enter year, month, day for start and end date
  Future<void> _selectCustomDateRange() async {
    DateTime? pickedStartDate = startDate;
    DateTime? pickedEndDate = endDate;

    final result = await showDialog<Map<String, DateTime>>(
      context: context,
      builder: (context) {
        // Controllers for Start Date
        final startYearController = TextEditingController(text: (pickedStartDate?.year.toString()) ?? '');
        final startMonthController = TextEditingController(text: (pickedStartDate?.month.toString()) ?? '');
        final startDayController = TextEditingController(text: (pickedStartDate?.day.toString()) ?? '');

        // Controllers for End Date
        final endYearController = TextEditingController(text: (pickedEndDate?.year.toString()) ?? '');
        final endMonthController = TextEditingController(text: (pickedEndDate?.month.toString()) ?? '');
        final endDayController = TextEditingController(text: (pickedEndDate?.day.toString()) ?? '');

        return AlertDialog(
          title: const Text('Enter Custom Date Range'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                const Text('Start Date'),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startYearController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Year'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: startMonthController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Month'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: startDayController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Day'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('End Date'),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: endYearController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Year'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: endMonthController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Month'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: endDayController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Day'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Apply'),
              onPressed: () {
                try {
                  final startY = int.parse(startYearController.text);
                  final startM = int.parse(startMonthController.text);
                  final startD = int.parse(startDayController.text);

                  final endY = int.parse(endYearController.text);
                  final endM = int.parse(endMonthController.text);
                  final endD = int.parse(endDayController.text);

                  final start = DateTime(startY, startM, startD);
                  final end = DateTime(endY, endM, endD, 23, 59, 59);

                  if (start.isAfter(end)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Start date cannot be after end date')),
                    );
                    return;
                  }

                  Navigator.pop(context, {'start': start, 'end': end});
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid date input')),
                  );
                }
              },
            ),
          ],
        );
      },
    );

    if (result != null && result.containsKey('start') && result.containsKey('end')) {
      setState(() {
        startDate = result['start']!;
        endDate = result['end']!;
        selectedDateFilter = 'Custom Range';
      });
      _loadPayments();
    }
  }

  Future _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: startDate != null && endDate != null ? DateTimeRange(start: startDate!, end: endDate!) : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF014EB2),
                ),
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
      _loadPayments();
    }
  }

  void _applyDateFilter(String filter) {
    final now = DateTime.now();
    setState(() {
      selectedDateFilter = filter;

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
          _selectCustomDateRange();
          return;
      }
    });
    _loadPayments();
  }

  Future _refreshPayments() async {
    await _loadPayments();
    _showSuccessSnackBar('Payments refreshed successfully');
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

  @override
  Widget build(BuildContext context) {
    // The full build method remains unchanged except date filter _applyDateFilter calls.
    // Paste your existing build method here unchanged.
    // [Paste your full build method exactly as before]
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
                    navItem(Icons.people, "Collectors", false),
                    navItem(Icons.payment, "Payments", true),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: logoutButton(),
                ),
              ],
            ),
          ),
          // Main Payment Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Top bar
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
                          'Payment Management',
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
                                color: !isPaymentsLoading ? Colors.green.shade100 : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    !isPaymentsLoading ? Icons.wifi : Icons.sync,
                                    size: 12,
                                    color: !isPaymentsLoading ? Colors.green.shade700 : Colors.orange.shade700,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: isPaymentsLoading ? null : _refreshPayments,
                              icon: Icon(
                                Icons.refresh,
                                color: isPaymentsLoading ? Colors.grey : Colors.blue,
                              ),
                              tooltip: 'Refresh Payments',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Payment Management Section
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
                            // Header with filters
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Payment Records',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Row(
                                  children: [
                                    // Date Filter Dropdown
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: DropdownButton<String>(
                                        value: selectedDateFilter,
                                        underline: Container(),
                                        items: dateFilterOptions.map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            _applyDateFilter(newValue);
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Search Box
                                    SizedBox(
                                      width: 300,
                                      child: TextField(
                                        controller: searchController,
                                        decoration: InputDecoration(
                                          hintText: 'Search payments...',
                                          prefixIcon: const Icon(Icons.search),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Date range display
                            if (startDate != null && endDate != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.date_range, size: 16, color: Colors.blue.shade700),
                                    const SizedBox(width: 8),
                                    Text(
                                      'From: ${displayDateFormatter.format(startDate!)} To: ${displayDateFormatter.format(endDate!)}',
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                            // Results count
                            Text(
                              'Showing ${filteredPayments.length} of ${allPayments.length} payments',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Payments Table
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
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                allPayments.isEmpty
                                                    ? 'Payments will appear here once they are made'
                                                    : 'Try adjusting your search or date range',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: DataTable(
                                              headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                                              columns: const [
                                                DataColumn(
                                                  label: Text(
                                                    'Payment ID',
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Amount',
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Shop Details',
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Collector Details',
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Date & Time',
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Status',
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                              rows: filteredPayments.map((payment) {
                                                return DataRow(
                                                  cells: [
                                                    DataCell(
                                                      Text(
                                                        payment['payment_id']?.toString() ??
                                                            payment['id']?.toString() ??
                                                            'N/A',
                                                        style: const TextStyle(fontFamily: 'monospace'),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        _formatCurrency(payment['amount']),
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.green,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            payment['shop_name']?.toString() ?? 'Unknown Shop',
                                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            'ID: ${payment['shop_id']?.toString() ?? 'N/A'}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey.shade600,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            'BR: ${payment['shop_br_number']?.toString() ?? payment['br_number']?.toString() ?? 'N/A'}',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors.grey.shade500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            payment['collector_name']?.toString() ?? 'Unknown Collector',
                                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            'ID: ${payment['collector_id']?.toString() ?? 'N/A'}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey.shade600,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            'Phone: ${payment['collector_phone']?.toString() ?? 'N/A'}',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors.grey.shade500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            _formatPaymentDate(payment['payment_date'] ?? payment['created_at']),
                                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            _formatPaymentTime(payment['payment_date'] ?? payment['created_at']),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey.shade600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: _getPaymentStatusColor(payment['status']).withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Text(
                                                          (payment['status']?.toString() ?? 'Completed').toUpperCase(),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                            color: _getPaymentStatusColor(payment['status']),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }).toList(),
                                            ),
                                          ),
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

  String _formatPaymentDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      DateTime date = DateTime.parse(dateStr.toString());
      return displayDateFormatter.format(date);
    } catch (e) {
      return dateStr.toString();
    }
  }

  String _formatPaymentTime(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      DateTime date = DateTime.parse(dateStr.toString());
      return timeFormatter.format(date);
    } catch (e) {
      return 'N/A';
    }
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
            Navigator.pushReplacementNamed(context, '/AdminDashboard');
          } else if (title == "Payments") {
            print('Already on Payments');
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
}
