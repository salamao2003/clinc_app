import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../backend/Report_logic.dart';
import '../providers/language_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  // Dashboard Data
  Map<String, dynamic> _dashboardStats = {};
  List<Map<String, dynamic>> _revenueData = [];
  List<Map<String, dynamic>> _patientData = [];
  List<Map<String, dynamic>> _medicationData = [];
  
  // مرجع للـ LanguageProvider
  LanguageProvider? _languageProvider;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    // استمع لتغييرات اللغة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      _languageProvider?.addListener(_onLanguageChanged);
    });
  }

  @override
  void dispose() {
    _languageProvider?.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    // إعادة تحميل البيانات عند تغيير اللغة
    if (mounted) {
      _loadChartData();
    }
  }

  /// تنسيق العملة حسب اللغة
  String _formatCurrency(num amount) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isArabic = languageProvider.isArabic;
    
    String formattedNumber;
    if (amount >= 1000000) {
      formattedNumber = '${(amount / 1000000).toStringAsFixed(1)}${isArabic ? 'م' : 'M'}';
    } else if (amount >= 1000) {
      formattedNumber = '${(amount / 1000).toStringAsFixed(1)}${isArabic ? 'ك' : 'K'}';
    } else {
      formattedNumber = amount.toStringAsFixed(0);
    }
    
    return isArabic ? '$formattedNumber ج.م' : '$formattedNumber EGP';
  }

  /// تنسيق التاريخ حسب اللغة
  String _formatDate(DateTime date) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isArabic = languageProvider.isArabic;
    
    if (isArabic) {
      final months = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } else {
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // حساب الإحصائيات من البيانات الموجودة
      await _calculateStats();
      await _loadChartData();
    } catch (e) {
      _showError('فشل في تحميل البيانات: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calculateStats() async {
    try {
      final dateRange = DateRange(startDate: _startDate, endDate: _endDate);
      
      // جلب بيانات الإيرادات
      final revenueData = await ReportService.getRevenueData(dateRange: dateRange);
      double totalRevenue = 0;
      int totalInvoices = revenueData.length;
      
      for (final item in revenueData) {
        totalRevenue += (item['amount'] ?? 0).toDouble();
      }
      
      // جلب بيانات المرضى
      final patientStats = await ReportService.getPatientStats(dateRange: dateRange);
      int newPatients = patientStats.length;
      
      // حفظ الإحصائيات
      _dashboardStats = {
        'total_revenue': totalRevenue,
        'total_invoices': totalInvoices,
        'avg_revenue': totalInvoices > 0 ? totalRevenue / totalInvoices : 0,
        'new_patients': newPatients,
      };
    } catch (e) {
      print('Error calculating stats: $e');
    }
  }

  Future<void> _loadChartData() async {
    try {
      final dateRange = DateRange(startDate: _startDate, endDate: _endDate);
      
      // بيانات الإيرادات - جمع حسب الشهر
      final rawRevenueData = await ReportService.getRevenueData(dateRange: dateRange);
      final newRevenueData = _groupRevenueByMonth(rawRevenueData);
      
      // بيانات المرضى - تصنيف حسب الجنس
      final rawPatientData = await ReportService.getPatientStats(dateRange: dateRange);
      final newPatientData = _groupPatientsByGender(rawPatientData);
      
      // بيانات الأدوية
      final newMedicationData = await ReportService.getTopMedications(dateRange: dateRange, limit: 5);
      
      // تحديث البيانات مع setState فقط إذا كان الـ widget لا يزال mounted
      if (mounted) {
        setState(() {
          _revenueData = newRevenueData;
          _patientData = newPatientData;
          _medicationData = newMedicationData;
        });
      }
      
    } catch (e) {
      print('Error loading chart data: $e');
    }
  }

  /// تجميع بيانات الإيرادات حسب الشهر
  List<Map<String, dynamic>> _groupRevenueByMonth(List<Map<String, dynamic>> rawData) {
    if (rawData.isEmpty) return [];
    
    Map<String, double> monthlyRevenue = {};
    
    for (final item in rawData) {
      final invoiceDate = item['invoice_date'] ?? item['created_at'];
      if (invoiceDate != null) {
        DateTime date = DateTime.parse(invoiceDate);
        String monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0) + (item['amount'] ?? 0).toDouble();
      }
    }
    
    // تحويل إلى قائمة مرتبة
    List<String> sortedMonths = monthlyRevenue.keys.toList()..sort();
    return sortedMonths.map((month) => {
      'month': month,
      'amount': monthlyRevenue[month],
      'display': _getMonthDisplayName(month),
    }).toList();
  }

  /// تجميع المرضى حسب الجنس
  List<Map<String, dynamic>> _groupPatientsByGender(List<Map<String, dynamic>> rawData) {
    if (rawData.isEmpty) return [];
    
    // الحصول على اللغة الحالية مباشرة من الـ widget
    final isArabic = Provider.of<LanguageProvider>(context, listen: false).isArabic;
    
    Map<String, int> genderCount = {'male': 0, 'female': 0, 'other': 0};
    
    for (final patient in rawData) {
      String gender = patient['gender']?.toString().toLowerCase() ?? 'other';
      if (gender == 'm' || gender == 'male' || gender == 'ذكر') {
        genderCount['male'] = genderCount['male']! + 1;
      } else if (gender == 'f' || gender == 'female' || gender == 'أنثى') {
        genderCount['female'] = genderCount['female']! + 1;
      } else {
        genderCount['other'] = genderCount['other']! + 1;
      }
    }
    
    return [
      {
        'category': isArabic ? 'ذكور' : 'Males', 
        'count': genderCount['male'], 
        'gender': 'male'
      },
      {
        'category': isArabic ? 'إناث' : 'Females', 
        'count': genderCount['female'], 
        'gender': 'female'
      },
      if (genderCount['other']! > 0) {
        'category': isArabic ? 'غير محدد' : 'Other', 
        'count': genderCount['other'], 
        'gender': 'other'
      },
    ];
  }

  /// الحصول على اسم الشهر للعرض
  String _getMonthDisplayName(String monthKey) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isArabic = languageProvider.isArabic;
    
    final parts = monthKey.split('-');
    final year = parts[0];
    final month = int.parse(parts[1]);
    
    final monthNames = isArabic 
      ? ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
         'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']
      : ['January', 'February', 'March', 'April', 'May', 'June',
         'July', 'August', 'September', 'October', 'November', 'December'];
    
    return '${monthNames[month - 1]} $year';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isArabic = languageProvider.isArabic;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isArabic ? 'التقارير والإحصائيات' : 'Reports & Analytics',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          // زر تبديل اللغة
          IconButton(
            icon: Icon(
              isArabic ? Icons.language : Icons.language_outlined,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              languageProvider.toggleLanguage();
            },
            tooltip: isArabic ? 'English' : 'عربي',
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: isArabic ? 'تحديد الفترة' : 'Select Period',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: isArabic ? 'تحديث' : 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Selector
                  _buildPeriodSelector(isArabic),
                  const SizedBox(height: 24),
                  
                  // Stats Cards
                  _buildStatsCards(isArabic),
                  const SizedBox(height: 24),
                  
                  // Revenue Chart
                  _buildSectionTitle(isArabic ? 'الإيرادات' : 'Revenue', Icons.trending_up),
                  const SizedBox(height: 16),
                  _buildRevenueChart(),
                  const SizedBox(height: 24),
                  
                  // Patients Chart
                  _buildSectionTitle(isArabic ? 'المرضى' : 'Patients', Icons.people),
                  const SizedBox(height: 16),
                  _buildPatientsChart(),
                  const SizedBox(height: 24),
                  
                  // Top Medications
                  _buildSectionTitle(isArabic ? 'الأدوية الأكثر وصفاً' : 'Top Medications', Icons.medication),
                  const SizedBox(height: 16),
                  _buildTopMedications(isArabic),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector(bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, color: Colors.blue[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'الفترة المحددة' : 'Selected Period',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _selectDateRange,
            child: Text(isArabic ? 'تغيير' : 'Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool isArabic) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: isArabic ? 'إجمالي الإيرادات' : 'Total Revenue',
                value: _formatCurrency(_dashboardStats['total_revenue'] ?? 0),
                icon: Icons.attach_money,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: isArabic ? 'عدد الفواتير' : 'Total Invoices',
                value: (_dashboardStats['total_invoices'] ?? 0).toString(),
                icon: Icons.receipt,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: isArabic ? 'مرضى جدد' : 'New Patients',
                value: (_dashboardStats['new_patients'] ?? 0).toString(),
                icon: Icons.person_add,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue[600], size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isArabic = languageProvider.isArabic;
    
    if (_revenueData.isEmpty) {
      return _buildEmptyChart(isArabic ? 'لا توجد بيانات إيرادات' : 'No revenue data');
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان الرسم البياني
          Text(
            isArabic ? 'الإيرادات الشهرية (بالجنيه المصري)' : 'Monthly Revenue (Egyptian Pounds)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.timeline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                isArabic 
                  ? 'المحور الأفقي: الأشهر • المحور الرأسي: المبلغ (ألف جنيه)'
                  : 'X-axis: Months • Y-axis: Amount (Thousands EGP)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < _revenueData.length) {
                          final monthData = _revenueData[value.toInt()];
                          final parts = monthData['month'].split('-');
                          final month = int.parse(parts[1]);
                          
                          final monthAbbr = isArabic 
                            ? ['ين', 'فبر', 'مار', 'أبر', 'ماي', 'يون', 'يول', 'أغس', 'سبت', 'أكت', 'نوف', 'ديس'][month - 1]
                            : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
                          
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              monthAbbr,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return Container();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: 5000,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          isArabic ? '${(value / 1000).toStringAsFixed(0)}ك' : '${(value / 1000).toStringAsFixed(0)}K',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  ),
                ),
                minX: 0,
                maxX: (_revenueData.length - 1).toDouble(),
                minY: 0,
                maxY: _revenueData.isNotEmpty 
                    ? _revenueData.map((e) => (e['amount'] ?? 0).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2
                    : 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: _revenueData.asMap().entries.map((entry) {
                      final amount = (entry.value['amount'] ?? 0).toDouble();
                      return FlSpot(entry.key.toDouble(), amount);
                    }).toList(),
                    isCurved: true,
                    color: Colors.green[600],
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 5,
                            color: Colors.green[600]!,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withOpacity(0.1),
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

  Widget _buildPatientsChart() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isArabic = languageProvider.isArabic;
    
    if (_patientData.isEmpty) {
      return _buildEmptyChart(isArabic ? 'لا توجد بيانات مرضى' : 'No patient data');
    }

    // حساب العدد الإجمالي
    final totalPatients = _patientData.fold<int>(0, (sum, item) => sum + ((item['count'] ?? 0) as int));

    return Container(
      height: 350,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان الرسم البياني
          Text(
            isArabic ? 'توزيع المرضى حسب الجنس' : 'Patient Distribution by Gender',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.pie_chart, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                isArabic 
                  ? 'إجمالي المرضى: $totalPatients مريض'
                  : 'Total Patients: $totalPatients patients',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                // الرسم الدائري
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 50,
                      startDegreeOffset: -90,
                      sections: _patientData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        final count = data['count'] ?? 0;
                        final percentage = totalPatients > 0 ? (count / totalPatients * 100) : 0;
                        
                        final colors = [
                          Colors.blue[600]!,
                          Colors.pink[400]!,
                          Colors.grey[500]!,
                        ];
                        
                        return PieChartSectionData(
                          color: colors[index % colors.length],
                          value: count.toDouble(),
                          title: '${percentage.toStringAsFixed(1)}%',
                          radius: 80,
                          titleStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          badgeWidget: null,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // مفتاح الألوان
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _patientData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      final count = data['count'] ?? 0;
                      final percentage = totalPatients > 0 ? (count / totalPatients * 100) : 0;
                      
                      final colors = [
                        Colors.blue[600]!,
                        Colors.pink[400]!,
                        Colors.grey[500]!,
                      ];
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: colors[index % colors.length],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    data['category'] ?? 'غير محدد',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(right: 24),
                              child: Text(
                                isArabic 
                                  ? '$count مريض (${percentage.toStringAsFixed(1)}%)'
                                  : '$count patients (${percentage.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMedications(bool isArabic) {
    if (_medicationData.isEmpty) {
      return _buildEmptyChart(isArabic ? 'لا توجد بيانات أدوية' : 'No medication data');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _medicationData.take(5).map((medication) {
          final index = _medicationData.indexOf(medication);
          final colors = [Colors.purple, Colors.blue, Colors.green, Colors.orange, Colors.red];
          final color = colors[index % colors.length];
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    medication['drug_name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${medication['count'] ?? 0}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}