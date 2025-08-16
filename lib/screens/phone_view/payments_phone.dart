import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:chilawtraders/serverconection/admin_backend_services.dart';

// DeviceType enum for responsiveness
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
  State<PaymentManagementMobile> createState() => _PaymentManagementResponsiveState();
}

class _PaymentManagementResponsiveState extends State<PaymentManagementMobile> {
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
    'Custom Range',
  ];

  // Search controller
  final TextEditingController searchController = TextEditingController();

  // Date formatters
  final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
  final DateFormat displayDateFormatter = DateFormat('MMM dd, yyyy');
  final DateFormat timeFormatter = DateFormat('HH:mm');

  // Mobile specific states
  int currentIndex = 2; // Payments is index 2

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

  /// Validate token before initializing
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
            (payment['shop_id']?.toString().toLowerCase() ?? '').contains(query) ||
            (payment['user_id']?.toString().toLowerCase() ?? '').contains(query) ||
            (payment['payment_amount']?.toString().toLowerCase() ?? '').contains(query) ||
            (payment['id']?.toString().toLowerCase() ?? '').contains(query);

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
    final deviceType = _getDeviceType(context);
    
    if (deviceType == DeviceType.mobile) {
      await _selectCustomDateRange();
    } else {
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
  }

  Future<void> _selectCustomDateRange() async {
    DateTime? pickedStartDate = startDate;
    DateTime? pickedEndDate = endDate;

    final result = await showDialog<Map<String, DateTime>>(
      context: context,
      builder: (context) {
        final startYearController = TextEditingController(text: (pickedStartDate?.year.toString()) ?? '');
        final startMonthController = TextEditingController(text: (pickedStartDate?.month.toString()) ?? '');
        final startDayController = TextEditingController(text: (pickedStartDate?.day.toString()) ?? '');

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

  @override
  Widget build(BuildContext context) {
    final deviceType = _getDeviceType(context);

    if (deviceType == DeviceType.mobile) {
      return _buildMobileLayout();
    } else {
      return _buildWebLayout();
    }
  }

  // === MOBILE LAYOUT === //
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF014EB2),
        title: const Text(
          'Payment Management',
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
              color: !isPaymentsLoading ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              !isPaymentsLoading ? Icons.wifi : Icons.sync,
              size: 16,
              color: !isPaymentsLoading ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
          IconButton(
            onPressed: isPaymentsLoading ? null : _refreshPayments,
            icon: Icon(
              Icons.refresh,
              color: isPaymentsLoading ? Colors.grey.shade300 : Colors.white,
            ),
            tooltip: 'Refresh Payments',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildMobileBody(),
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
                  _drawerItem(Icons.payment, "Payments", 2),
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
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade700 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        onTap: () {
          setState(() {
            currentIndex = index;
          });
          Navigator.pop(context);
          if (title == "Dashboard") {
            Navigator.pushReplacementNamed(context, '/AdminDashboard');
          } else if (title == "Collectors") {
            Navigator.pushReplacementNamed(context, '/CollectorManagement');
          } else if (title == "Payments") {
            Navigator.pushReplacementNamed(context, '/PaymentManagement');
          }
        },
      ),
    );
  }

  Widget _buildMobileBody() {
    return RefreshIndicator(
      onRefresh: _refreshPayments,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPaymentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, offset: Offset(0, 2), blurRadius: 6, spreadRadius: 2),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Records',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedDateFilter,
                      isExpanded: true, 
                    decoration: InputDecoration(
                      labelText: 'Date Filter',
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    decoration: InputDecoration(
                      labelText: 'Search payments',
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            if (startDate != null && endDate != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
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
                    Expanded(
                      child: Text(
                        'From: ${displayDateFormatter.format(startDate!)} To: ${displayDateFormatter.format(endDate!)}',
                        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Showing ${filteredPayments.length} of ${allPayments.length} payments',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (isPaymentsLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filteredPayments.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredPayments.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _mobilePaymentCard(filteredPayments[index]),
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
          Icon(
            allPayments.isEmpty ? Icons.receipt_long_outlined : Icons.search_off,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            allPayments.isEmpty ? 'No payments found' : 'No payments match your criteria',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          Text(
            allPayments.isEmpty
                ? 'Payments will appear here once they are made'
                : 'Try adjusting your search or date range',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          if (allPayments.isEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshPayments,
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

  Widget _mobilePaymentCard(Map<String, dynamic> payment) {
    DateTime? paymentDate;
    try {
      paymentDate = DateTime.parse(payment['payment_date'] ?? payment['created_at'] ?? '');
    } catch (e) {
      paymentDate = null;
    }

    // final statusColor = _getPaymentStatusColor(payment['status']);

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
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF014EB2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(Icons.payment, color: Color(0xFF014EB2), size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment['id']?.toString() ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(payment['payment_amount']),
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ],
                ),
              ),
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //   decoration: BoxDecoration(
              //     color: statusColor.withOpacity(0.1),
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   child: Text(
              //     (payment['status']?.toString() ?? 'Completed').toUpperCase(),
              //     style: TextStyle(
              //       fontSize: 10,
              //       fontWeight: FontWeight.bold,
              //       color: statusColor,
              //     ),
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 8),
          // _paymentDetailRow('Shop:', payment['shop_name']?.toString() ?? 'N/A'),
          _paymentDetailRow('Shop ID:', payment['shop_id']?.toString() ?? 'N/A'),
          _paymentDetailRow('Collector:', payment['user_id']?.toString() ?? 'N/A'),
          // _paymentDetailRow('Collector Phone:', payment['collector_phone']?.toString() ?? 'N/A'),
          if (paymentDate != null)
            _paymentDetailRow(
              'Date & Time:',
              '${displayDateFormatter.format(paymentDate)} ${timeFormatter.format(paymentDate)}',
            ),
        ],
      ),
    );
  }

  Widget _paymentDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  // === WEB LAYOUT === //
  Widget _buildWebLayout() {
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
                    _navItem(Icons.dashboard, "Dashboard", false),
                    _navItem(Icons.people, "Collectors", false),
                    _navItem(Icons.payment, "Payments", true),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _logoutButton(),
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
                                                        payment['id']?.toString() ??
                                                            payment['id']?.toString() ??
                                                            'N/A',
                                                        style: const TextStyle(fontFamily: 'monospace'),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        _formatCurrency(payment['payment_amount']),
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
                                                          // Text(
                                                          //   payment['shop_id']?.toString() ?? 'Unknown Shop',
                                                          //   style: const TextStyle(fontWeight: FontWeight.w500),
                                                          // ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            'ID: ${payment['shop_id']?.toString() ?? 'N/A'}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey.shade600,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          // Text(
                                                          //   'BR: ${payment['shop_br_number']?.toString() ?? payment['br_number']?.toString() ?? 'N/A'}',
                                                          //   style: TextStyle(
                                                          //     fontSize: 11,
                                                          //     color: Colors.grey.shade500,
                                                          //   ),
                                                          // ),
                                                        ],
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          // Text(
                                                          //   payment['collector_name']?.toString() ?? 'Unknown Collector',
                                                          //   style: const TextStyle(fontWeight: FontWeight.w500),
                                                          // ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            'ID: ${payment['user_id']?.toString() ?? 'N/A'}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey.shade600,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          // Text(
                                                          //   'Phone: ${payment['collector_phone']?.toString() ?? 'N/A'}',
                                                          //   style: TextStyle(
                                                          //     fontSize: 11,
                                                          //     color: Colors.grey.shade500,
                                                          //   ),
                                                          // ),
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

  Widget _navItem(IconData icon, String title, bool isSelected) {
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

  Widget _logoutButton() {
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