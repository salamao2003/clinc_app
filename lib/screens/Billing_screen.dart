import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../backend/Billing_logic.dart';
import '../widgets/app_sidebar.dart';
import 'print_invoice_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({Key? key}) : super(key: key);

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  // ألوان ثابتة
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color backgroundColor = Color(0xFFF8FAFC);

  final BillingLogic _logic = BillingLogic();
  List<Invoice> _invoices = [];
  List<Invoice> _filteredInvoices = [];
  bool _loading = true;
  bool _isArabic = false;
  
  final TextEditingController _searchController = TextEditingController();
  
  // Filter variables
  String? _selectedPaymentStatus;
  DateTime? _fromDate;
  DateTime? _toDate;

  // Statistics
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
    _fetchStatistics();
    _searchController.addListener(() {
      _filterInvoices(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInvoices() async {
    setState(() => _loading = true);
    try {
      _invoices = await _logic.fetchInvoices();
      _filteredInvoices = _invoices;
      _applyFilters();
    } catch (e) {
      _showErrorSnackBar('خطأ في جلب الفواتير: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _fetchStatistics() async {
    try {
      _statistics = await _logic.getInvoiceStatistics();
      setState(() {});
    } catch (e) {
      print('Error fetching statistics: $e');
    }
  }

  void _filterInvoices(String query) {
    setState(() {
      _filteredInvoices = _invoices.where((invoice) {
        // Text search filter
        bool matchesSearch = true;
        if (query.isNotEmpty) {
          final patientName = invoice.patientName.toLowerCase();
          final phoneNumber = invoice.phoneNumber.toLowerCase();
          final doctorName = invoice.doctorName.toLowerCase();
          final searchQuery = query.toLowerCase();
          matchesSearch = patientName.contains(searchQuery) || 
                         phoneNumber.contains(searchQuery) ||
                         doctorName.contains(searchQuery);
        }
        
        // Payment status filter
        bool matchesStatus = _selectedPaymentStatus == null || 
                           invoice.paymentStatus == _selectedPaymentStatus;
        
        // Date range filter
        bool matchesDateRange = true;
        if (_fromDate != null) {
          matchesDateRange = invoice.invoiceDate.isAfter(_fromDate!) ||
                           invoice.invoiceDate.isAtSameMomentAs(_fromDate!);
        }
        if (_toDate != null && matchesDateRange) {
          matchesDateRange = invoice.invoiceDate.isBefore(_toDate!.add(const Duration(days: 1)));
        }
        
        return matchesSearch && matchesStatus && matchesDateRange;
      }).toList();
    });
  }

  void _applyFilters() {
    _filterInvoices(_searchController.text);
  }

  void _clearFilters() {
    setState(() {
      _selectedPaymentStatus = null;
      _fromDate = null;
      _toDate = null;
      _searchController.clear();
    });
    _filterInvoices('');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Row(
          children: [
            // Sidebar
            AppSidebar(
              parentContext: context,
              selectedPage: 'billing',
              isArabic: _isArabic,
            ),
            // Main Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isArabic ? 'إدارة الفواتير' : 'Billing Management',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 21, 118, 255),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isArabic 
                                  ? 'إدارة وتتبع جميع الفواتير والمدفوعات' 
                                  : 'Manage and track all invoices and payments',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showInvoiceDialog(),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: Text(
                            _isArabic ? 'إضافة فاتورة جديدة' : 'Add New Invoice',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Language Toggle Button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.language,
                                size: 16,
                                color: _isArabic ? Colors.grey : primaryBlue,
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isArabic = false;
                                  });
                                },
                                child: Text(
                                  'English',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: !_isArabic ? primaryBlue : Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 1,
                                height: 16,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isArabic = true;
                                  });
                                },
                                child: Text(
                                  'عربي',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _isArabic ? primaryBlue : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Statistics Cards
                  if (_statistics.isNotEmpty) _buildStatisticsCards(),
                  
                  // Search and Filters
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: _isArabic 
                                ? 'البحث باسم المريض، رقم التليفون، أو اسم الدكتور...'
                                : 'Search by patient name, phone number, or doctor name...',
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                              suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Color(0xFF9CA3AF)),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterInvoices('');
                                    },
                                  )
                                : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Filters Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // Payment Status Filter
                              _buildFilterDropdown(
                                title: _isArabic ? 'حالة الدفع' : 'Payment Status',
                                value: _selectedPaymentStatus,
                                items: ['Paid', 'Unpaid', 'Partially Paid'],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPaymentStatus = value;
                                  });
                                  _applyFilters();
                                },
                                getDisplayText: (status) {
                                  if (_isArabic) {
                                    switch (status) {
                                      case 'Paid': return 'مدفوع';
                                      case 'Unpaid': return 'غير مدفوع';
                                      case 'Partially Paid': return 'مدفوع جزئياً';
                                      default: return status;
                                    }
                                  }
                                  return status;
                                },
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Date Range Filters
                              _buildDateRangePicker(),
                              
                              const SizedBox(width: 16),
                              
                              // Clear Filters Button
                              TextButton.icon(
                                onPressed: _clearFilters,
                                icon: const Icon(Icons.clear_all, size: 16),
                                label: Text(_isArabic ? 'مسح الفلاتر' : 'Clear Filters'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey[600],
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Invoices Table
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 24, right: 8, bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredInvoices.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isNotEmpty
                                      ? (_isArabic ? 'لا توجد نتائج للبحث' : 'No search results found')
                                      : (_isArabic ? 'لا توجد فواتير' : 'No invoices found'),
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isArabic ? 'جرب البحث بكلمات مختلفة' : 'Try searching with different terms',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 20,
                                headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
                                columns: [
                                  DataColumn(label: Text(_isArabic ? 'اسم المريض' : 'Patient Name')),
                                  DataColumn(label: Text(_isArabic ? 'رقم التليفون' : 'Phone Number')),
                                  DataColumn(label: Text(_isArabic ? 'اسم الدكتور' : 'Doctor Name')),
                                  DataColumn(label: Text(_isArabic ? 'الخدمة الطبية' : 'Medical Service')),
                                  DataColumn(label: Text(_isArabic ? 'المبلغ' : 'Amount')),
                                  DataColumn(label: Text(_isArabic ? 'التاريخ' : 'Date')),
                                  DataColumn(label: Text(_isArabic ? 'حالة الدفع' : 'Payment Status')),
                                  DataColumn(label: Text(_isArabic ? 'ملاحظات' : 'Notes')),
                                  DataColumn(label: Text(_isArabic ? 'الإجراءات' : 'Actions')),
                                ],
                                rows: _filteredInvoices.map((invoice) {
                                  return _buildInvoiceRow(invoice);
                                }).toList(),
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: _isArabic ? 'إجمالي الفواتير' : 'Total Invoices',
              value: _statistics['totalInvoices']?.toString() ?? '0',
              icon: Icons.receipt_long,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: _isArabic ? 'إجمالي المبلغ' : 'Total Amount',
              value: '${_statistics['totalAmount']?.toStringAsFixed(2) ?? '0'} LE',
              icon: Icons.attach_money,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: _isArabic ? 'المبلغ المدفوع' : 'Paid Amount',
              value: '${_statistics['paidAmount']?.toStringAsFixed(2) ?? '0'} LE',
              icon: Icons.check_circle,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              title: _isArabic ? 'المبلغ المستحق' : 'Outstanding Amount',
              value: '${_statistics['unpaidAmount']?.toStringAsFixed(2) ?? '0'} LE',
              icon: Icons.pending,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildInvoiceRow(Invoice invoice) {
    return DataRow(
      cells: [
        DataCell(Text(invoice.patientName)),
        DataCell(Text(invoice.phoneNumber)),
        DataCell(Text(invoice.doctorName.isEmpty ? (_isArabic ? 'غير محدد' : 'Not specified') : invoice.doctorName)),
        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (invoice.services.isNotEmpty)
                  ...invoice.services.take(2).map((service) => 
                    Text(
                      '${service.serviceName} (${service.quantity}x)',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ).toList()
                else
                  Text(_isArabic ? 'لا توجد خدمات' : 'No services'),
                if (invoice.services.length > 2)
                  Text(
                    _isArabic 
                      ? '+${invoice.services.length - 2} خدمات أخرى'
                      : '+${invoice.services.length - 2} more services',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ),
        DataCell(Text('${invoice.totalAmount.toStringAsFixed(2)} LE')),
        DataCell(Text(
          "${invoice.invoiceDate.toLocal().toString().split(' ')[0]}"
        )),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(invoice.paymentStatus).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _isArabic
                ? _getStatusTextArabic(invoice.paymentStatus)
                : invoice.paymentStatus,
              style: TextStyle(
                color: _getStatusColor(invoice.paymentStatus),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              invoice.notes?.isEmpty == true || invoice.notes == null 
                ? (_isArabic ? 'لا توجد' : 'No notes') 
                : invoice.notes!,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    _printInvoice(invoice);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.print, color: Colors.green, size: 16),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    _showInvoiceDialog(isEdit: true, invoice: invoice);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.edit, color: Color(0xFF2196F3), size: 16),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showDeleteConfirmation(invoice.id),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.delete, color: Colors.red, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid': return Colors.green;
      case 'Unpaid': return Colors.red;
      case 'Partially Paid': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getStatusTextArabic(String status) {
    switch (status) {
      case 'Paid': return 'مدفوع';
      case 'Unpaid': return 'غير مدفوع';
      case 'Partially Paid': return 'مدفوع جزئياً';
      default: return status;
    }
  }

  Widget _buildFilterDropdown({
    required String title,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String Function(String) getDisplayText,
  }) {
    return Row(
      children: [
        Text(
          title + ':',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: value != null ? primaryBlue.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: value != null ? primaryBlue.withOpacity(0.3) : Colors.grey.shade300,
            ),
          ),
          child: DropdownButton<String>(
            hint: Text(
              _isArabic ? 'الكل' : 'All',
              style: TextStyle(
                fontSize: 12,
                color: value != null ? primaryBlue : Colors.grey[600],
                fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            value: value,
            underline: const SizedBox(),
            icon: Icon(
              Icons.arrow_drop_down,
              color: value != null ? primaryBlue : Colors.grey[600],
              size: 16,
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(
                  _isArabic ? 'الكل' : 'All',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              ...items.map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(
                  getDisplayText(item),
                  style: const TextStyle(fontSize: 12),
                ),
              )),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangePicker() {
    return Row(
      children: [
        Text(
          (_isArabic ? 'التاريخ:' : 'Date:'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (_fromDate != null || _toDate != null) ? primaryBlue.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (_fromDate != null || _toDate != null) ? primaryBlue.withOpacity(0.3) : Colors.grey.shade300,
            ),
          ),
          child: TextButton(
            onPressed: () async {
              final DateTimeRange? range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDateRange: _fromDate != null && _toDate != null
                  ? DateTimeRange(start: _fromDate!, end: _toDate!)
                  : null,
              );
              
              if (range != null) {
                setState(() {
                  _fromDate = range.start;
                  _toDate = range.end;
                });
                _applyFilters();
              }
            },
            child: Text(
              (_fromDate != null && _toDate != null)
                ? '${_fromDate!.toString().split(' ')[0]} - ${_toDate!.toString().split(' ')[0]}'
                : (_isArabic ? 'اختر التاريخ' : 'Select Date'),
              style: TextStyle(
                fontSize: 12,
                color: (_fromDate != null || _toDate != null) ? primaryBlue : Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDeleteConfirmation(String invoiceId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_isArabic ? 'تأكيد الحذف' : 'Confirm Delete'),
          content: Text(_isArabic ? 'هل أنت متأكد من حذف هذه الفاتورة؟' : 'Are you sure you want to delete this invoice?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _logic.deleteInvoice(invoiceId);
                  _showSuccessSnackBar(_isArabic ? 'تم حذف الفاتورة بنجاح' : 'Invoice deleted successfully');
                  _fetchInvoices();
                  _fetchStatistics();
                } catch (e) {
                  _showErrorSnackBar('خطأ في حذف الفاتورة: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(_isArabic ? 'حذف' : 'Delete',style:TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showInvoiceDialog({bool isEdit = false, Invoice? invoice}) async {
    final phoneController = TextEditingController(text: invoice?.phoneNumber ?? '');
    final doctorController = TextEditingController(text: invoice?.doctorName ?? '');
    final notesController = TextEditingController(text: invoice?.notes ?? '');
    
    DateTime selectedDate = invoice?.invoiceDate ?? DateTime.now();
    String selectedPaymentStatus = invoice?.paymentStatus ?? 'Unpaid';
    String? selectedPaymentMethod = invoice?.paymentMethod;
    
    String patientName = invoice?.patientName ?? '';
    bool isLoadingPatient = false;

    // Services list - initialize with existing services or one empty service
    List<Map<String, dynamic>> services = [];
    if (isEdit && invoice != null && invoice.services.isNotEmpty) {
      services = invoice.services.map((service) => {
        'serviceName': service.serviceName,
        'quantity': service.quantity,
        'unitPrice': service.unitPrice,
        'totalPrice': service.totalPrice,
      }).toList();
    } else {
      services.add({
        'serviceName': '',
        'quantity': 1,
        'unitPrice': 0.0,
        'totalPrice': 0.0,
      });
    }

    // Controllers for services
    List<List<TextEditingController>> serviceControllers = [];
    
    void _updateServiceControllers() {
      // Dispose old controllers
      for (var controllers in serviceControllers) {
        for (var controller in controllers) {
          controller.dispose();
        }
      }
      
      // Create new controllers
      serviceControllers = services.map((service) => [
        TextEditingController(text: service['serviceName']),
        TextEditingController(text: service['quantity'].toString()),
        TextEditingController(text: service['unitPrice'].toString()),
      ]).toList();
    }
    
    _updateServiceControllers();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEdit
                  ? (_isArabic ? 'تعديل فاتورة' : 'Edit Invoice')
                  : (_isArabic ? 'إضافة فاتورة جديدة' : 'Add New Invoice'),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Phone Number Field
                      TextField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          labelText: _isArabic ? 'رقم التليفون *' : 'Phone Number *',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) async {
                          if (value.length >= 10) {
                            setDialogState(() {
                              isLoadingPatient = true;
                            });
                            
                            try {
                              final patientInfo = await _logic.getPatientAndDoctorInfo(value);
                              if (patientInfo != null) {
                                final patient = patientInfo['patient'] as PatientInfo;
                                final doctorName = patientInfo['doctorName'] as String;
                                
                                setDialogState(() {
                                  patientName = patient.fullName;
                                  if (doctorName.isNotEmpty) {
                                    doctorController.text = doctorName;
                                  }
                                });
                              } else {
                                setDialogState(() {
                                  patientName = '';
                                });
                              }
                            } catch (e) {
                              print('Error fetching patient info: $e');
                            }
                            
                            setDialogState(() {
                              isLoadingPatient = false;
                            });
                          }
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Patient Name Display
                      if (patientName.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_isArabic ? 'المريض:' : 'Patient:'} $patientName',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      
                      if (isLoadingPatient)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Doctor Name Field
                      TextField(
                        controller: doctorController,
                        decoration: InputDecoration(
                          labelText: _isArabic ? 'اسم الدكتور' : 'Doctor Name',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Medical Services Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _isArabic ? 'الخدمات الطبية *' : 'Medical Services *',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setDialogState(() {
                                      services.add({
                                        'serviceName': '',
                                        'quantity': 1,
                                        'unitPrice': 0.0,
                                        'totalPrice': 0.0,
                                      });
                                      _updateServiceControllers();
                                    });
                                  },
                                  icon: const Icon(Icons.add, size: 18),
                                  label: Text(_isArabic ? 'إضافة خدمة' : 'Add Service'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...services.asMap().entries.map((entry) {
                              final index = entry.key;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${_isArabic ? 'خدمة' : 'Service'} ${index + 1}',
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        const Spacer(),
                                        if (services.length > 1)
                                          IconButton(
                                            onPressed: () {
                                              setDialogState(() {
                                                services.removeAt(index);
                                                _updateServiceControllers();
                                              });
                                            },
                                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: serviceControllers[index][0],
                                      decoration: InputDecoration(
                                        labelText: _isArabic ? 'اسم الخدمة *' : 'Service Name *',
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      onChanged: (value) {
                                        services[index]['serviceName'] = value;
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: TextField(
                                            controller: serviceControllers[index][1],
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: _isArabic ? 'الكمية *' : 'Quantity *',
                                              border: const OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                            onChanged: (value) {
                                              final quantity = int.tryParse(value) ?? 1;
                                              services[index]['quantity'] = quantity;
                                              final unitPrice = services[index]['unitPrice'] as double;
                                              final total = quantity * unitPrice;
                                              services[index]['totalPrice'] = total;
                                              setDialogState(() {});
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 3,
                                          child: TextField(
                                            controller: serviceControllers[index][2],
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: _isArabic ? 'سعر الوحدة *' : 'Unit Price *',
                                              border: const OutlineInputBorder(),
                                              isDense: true,
                                              suffixText: 'LE',
                                            ),
                                            onChanged: (value) {
                                              final unitPrice = double.tryParse(value) ?? 0.0;
                                              services[index]['unitPrice'] = unitPrice;
                                              final quantity = services[index]['quantity'] as int;
                                              final total = quantity * unitPrice;
                                              services[index]['totalPrice'] = total;
                                              setDialogState(() {});
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 3,
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                            ),
                                            child: Text(
                                              '${_isArabic ? 'المجموع:' : 'Total:'} ${services[index]['totalPrice'].toStringAsFixed(2)} LE',
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const Divider(),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _isArabic ? 'المجموع الكلي:' : 'Grand Total:',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${services.fold(0.0, (sum, service) => sum + (service['totalPrice'] as double)).toStringAsFixed(2)} LE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Date Picker
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setDialogState(() {
                              selectedDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: _isArabic ? 'التاريخ *' : 'Date *',
                            border: const OutlineInputBorder(),
                          ),
                          child: Text(
                            selectedDate.toString().split(' ')[0],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Payment Status Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedPaymentStatus,
                        decoration: InputDecoration(
                          labelText: _isArabic ? 'حالة الدفع *' : 'Payment Status *',
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(value: 'Paid', child: Text(_isArabic ? 'مدفوع' : 'Paid')),
                          DropdownMenuItem(value: 'Unpaid', child: Text(_isArabic ? 'غير مدفوع' : 'Unpaid')),
                          DropdownMenuItem(value: 'Partially Paid', child: Text(_isArabic ? 'مدفوع جزئياً' : 'Partially Paid')),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedPaymentStatus = value!;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Payment Method Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedPaymentMethod,
                        decoration: InputDecoration(
                          labelText: _isArabic ? 'طريقة الدفع' : 'Payment Method',
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(value: null, child: Text(_isArabic ? 'اختر الطريقة' : 'Select method')),
                          DropdownMenuItem(value: 'Cash', child: Text(_isArabic ? 'نقداً' : 'Cash')),
                          DropdownMenuItem(value: 'Card', child: Text(_isArabic ? 'بطاقة' : 'Card')),
                          DropdownMenuItem(value: 'Bank Transfer', child: Text(_isArabic ? 'حوالة بنكية' : 'Bank Transfer')),
                          DropdownMenuItem(value: 'Insurance', child: Text(_isArabic ? 'تأمين' : 'Insurance')),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedPaymentMethod = value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Notes Field
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: _isArabic ? 'ملاحظات (اختياري)' : 'Notes (Optional)',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(_isArabic ? 'إلغاء' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validation
                    if (phoneController.text.isEmpty ||
                        patientName.isEmpty) {
                      _showErrorSnackBar(_isArabic ? 'يرجى ملء جميع الحقول المطلوبة' : 'Please fill all required fields');
                      return;
                    }

                    // Validate services
                    bool hasValidServices = false;
                    List<InvoiceService> validServices = [];
                    
                    for (int i = 0; i < services.length; i++) {
                      final serviceName = serviceControllers[i][0].text.trim();
                      final quantity = int.tryParse(serviceControllers[i][1].text) ?? 0;
                      final unitPrice = double.tryParse(serviceControllers[i][2].text) ?? 0.0;
                      
                      if (serviceName.isNotEmpty && quantity > 0 && unitPrice > 0) {
                        hasValidServices = true;
                        validServices.add(InvoiceService(
                          id: '', // Will be set by database
                          invoiceId: isEdit ? invoice!.id : '',
                          serviceName: serviceName,
                          quantity: quantity,
                          unitPrice: unitPrice,
                          totalPrice: quantity * unitPrice,
                        ));
                      }
                    }
                    
                    if (!hasValidServices) {
                      _showErrorSnackBar(_isArabic ? 'يرجى إضافة خدمة واحدة صحيحة على الأقل' : 'Please add at least one valid service');
                      return;
                    }

                    try {
                      if (isEdit && invoice != null) {
                        await _logic.updateInvoice(
                          invoiceId: invoice.id,
                          phoneNumber: phoneController.text,
                          doctorName: doctorController.text,
                          services: validServices,
                          invoiceDate: selectedDate,
                          paymentStatus: selectedPaymentStatus,
                          paymentMethod: selectedPaymentMethod,
                          notes: notesController.text.isEmpty ? null : notesController.text,
                        );
                        _showSuccessSnackBar(_isArabic ? 'تم تحديث الفاتورة بنجاح' : 'Invoice updated successfully');
                      } else {
                        await _logic.addInvoice(
                          phoneNumber: phoneController.text,
                          doctorName: doctorController.text,
                          services: validServices,
                          invoiceDate: selectedDate,
                          paymentStatus: selectedPaymentStatus,
                          paymentMethod: selectedPaymentMethod,
                          notes: notesController.text.isEmpty ? null : notesController.text,
                        );
                        _showSuccessSnackBar(_isArabic ? 'تم إضافة الفاتورة بنجاح' : 'Invoice added successfully');
                      }
                      
                      // Dispose controllers
                      for (var controllers in serviceControllers) {
                        for (var controller in controllers) {
                          controller.dispose();
                        }
                      }
                      
                      Navigator.of(context).pop();
                      _fetchInvoices();
                      _fetchStatistics();
                    } catch (e) {
                      _showErrorSnackBar('خطأ: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
                  child: Text(
                    isEdit 
                      ? (_isArabic ? 'تحديث' : 'Update')
                      : (_isArabic ? 'إضافة' : 'Add'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _printInvoice(Invoice invoice) async {
    try {
      // التأكد من أن السياق ما زال متاحاً
      if (!mounted) return;
      
      // تأخير صغير للتأكد من اكتمال الـ layout
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      // عرض نافذة حوار للاختيار بين المعاينة والطباعة المباشرة
      await PrintInvoiceService.showPrintDialog(invoice, _isArabic, context);
    } catch (e) {
      print('Error in _printInvoice: $e');
      if (mounted) {
        _showErrorSnackBar(_isArabic ? 'خطأ في طباعة الفاتورة' : 'Error printing invoice');
      }
    }
  }
}