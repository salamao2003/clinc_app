import 'package:supabase_flutter/supabase_flutter.dart';

// ========== ENUMS ==========

enum ReportType {
  financial('financial', 'التقارير المالية'),
  patients('patients', 'تقارير المرضى'),
  medical('medical', 'التقارير الطبية'),
  operational('operational', 'التقارير التشغيلية');

  const ReportType(this.value, this.arabicName);
  final String value;
  final String arabicName;

  static ReportType fromString(String value) {
    return ReportType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ReportType.financial,
    );
  }
}

enum ChartType {
  line('line', 'خط بياني'),
  bar('bar', 'أعمدة بيانية'),
  pie('pie', 'دائرة بيانية'),
  doughnut('doughnut', 'حلقة بيانية'),
  area('area', 'منطقة بيانية');

  const ChartType(this.value, this.arabicName);
  final String value;
  final String arabicName;

  static ChartType fromString(String value) {
    return ChartType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ChartType.line,
    );
  }
}

enum ReportStatus {
  pending('pending', 'في الانتظار'),
  generating('generating', 'يتم الإنشاء'),
  completed('completed', 'مكتمل'),
  failed('failed', 'فشل'),
  scheduled('scheduled', 'مجدول');

  const ReportStatus(this.value, this.arabicName);
  final String value;
  final String arabicName;

  static ReportStatus fromString(String value) {
    return ReportStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ReportStatus.pending,
    );
  }
}

// ========== MODELS ==========

class ReportTemplate {
  final String id;
  final String name;
  final ReportType reportType;
  final String description;
  final String queryTemplate;
  final Map<String, dynamic>? defaultFilters;
  final ChartConfig? chartConfig;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReportTemplate({
    required this.id,
    required this.name,
    required this.reportType,
    required this.description,
    required this.queryTemplate,
    this.defaultFilters,
    this.chartConfig,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReportTemplate.fromJson(Map<String, dynamic> json) {
    return ReportTemplate(
      id: json['id'],
      name: json['name'],
      reportType: ReportType.fromString(json['report_type']),
      description: json['description'] ?? '',
      queryTemplate: json['query_template'],
      defaultFilters: json['default_filters'],
      chartConfig: json['chart_config'] != null 
          ? ChartConfig.fromJson(json['chart_config']) 
          : null,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'report_type': reportType.value,
      'description': description,
      'query_template': queryTemplate,
      'default_filters': defaultFilters,
      'chart_config': chartConfig?.toJson(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Report {
  final String id;
  final ReportType reportType;
  final String title;
  final String? description;
  final Map<String, dynamic>? filters;
  final String? generatedBy;
  final DateTime generatedAt;
  final ReportData? data;
  final bool isScheduled;
  final String? scheduleFrequency;
  final bool isFavorite;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Report({
    required this.id,
    required this.reportType,
    required this.title,
    this.description,
    this.filters,
    this.generatedBy,
    required this.generatedAt,
    this.data,
    this.isScheduled = false,
    this.scheduleFrequency,
    this.isFavorite = false,
    this.status = ReportStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      reportType: ReportType.fromString(json['report_type']),
      title: json['title'],
      description: json['description'],
      filters: json['filters'],
      generatedBy: json['generated_by'],
      generatedAt: DateTime.parse(json['generated_at']),
      data: json['data'] != null ? ReportData.fromJson(json['data']) : null,
      isScheduled: json['is_scheduled'] ?? false,
      scheduleFrequency: json['schedule_frequency'],
      isFavorite: json['is_favorite'] ?? false,
      status: ReportStatus.fromString(json['status'] ?? 'pending'),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_type': reportType.value,
      'title': title,
      'description': description,
      'filters': filters,
      'generated_by': generatedBy,
      'generated_at': generatedAt.toIso8601String(),
      'data': data?.toJson(),
      'is_scheduled': isScheduled,
      'schedule_frequency': scheduleFrequency,
      'is_favorite': isFavorite,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ReportData {
  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> summary;
  final ChartData? chartData;
  final DateTime lastUpdated;

  ReportData({
    required this.rows,
    required this.summary,
    this.chartData,
    required this.lastUpdated,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      rows: List<Map<String, dynamic>>.from(json['rows'] ?? []),
      summary: json['summary'] ?? {},
      chartData: json['chart_data'] != null 
          ? ChartData.fromJson(json['chart_data']) 
          : null,
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rows': rows,
      'summary': summary,
      'chart_data': chartData?.toJson(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

class ChartConfig {
  final ChartType type;
  final String? xAxis;
  final String? yAxis;
  final String? labelField;
  final String? valueField;
  final String? title;
  final Map<String, dynamic>? options;

  ChartConfig({
    required this.type,
    this.xAxis,
    this.yAxis,
    this.labelField,
    this.valueField,
    this.title,
    this.options,
  });

  factory ChartConfig.fromJson(Map<String, dynamic> json) {
    return ChartConfig(
      type: ChartType.fromString(json['type']),
      xAxis: json['xAxis'],
      yAxis: json['yAxis'],
      labelField: json['labelField'],
      valueField: json['valueField'],
      title: json['title'],
      options: json['options'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'xAxis': xAxis,
      'yAxis': yAxis,
      'labelField': labelField,
      'valueField': valueField,
      'title': title,
      'options': options,
    };
  }
}

class ChartData {
  final List<Map<String, dynamic>> datasets;
  final List<String> labels;
  final Map<String, dynamic>? options;

  ChartData({
    required this.datasets,
    required this.labels,
    this.options,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      datasets: List<Map<String, dynamic>>.from(json['datasets'] ?? []),
      labels: List<String>.from(json['labels'] ?? []),
      options: json['options'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'datasets': datasets,
      'labels': labels,
      'options': options,
    };
  }
}

// ========== DATE RANGE HELPER ==========

class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  DateRange({
    required this.startDate,
    required this.endDate,
  });

  factory DateRange.today() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return DateRange(startDate: startOfDay, endDate: endOfDay);
  }

  factory DateRange.thisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return DateRange(
      startDate: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      endDate: endOfWeek,
    );
  }

  factory DateRange.thisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return DateRange(startDate: startOfMonth, endDate: endOfMonth);
  }

  factory DateRange.thisYear() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);
    return DateRange(startDate: startOfYear, endDate: endOfYear);
  }

  factory DateRange.custom(DateTime start, DateTime end) {
    return DateRange(startDate: start, endDate: end);
  }

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'DateRange(${startDate.toString().split(' ')[0]} - ${endDate.toString().split(' ')[0]})';
  }
}

// ========== REPORT SERVICE ==========

class ReportService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ========== TEMPLATE OPERATIONS ==========

  /// جلب جميع قوالب التقارير
  static Future<List<ReportTemplate>> getReportTemplates({ReportType? type}) async {
    try {
      var query = _supabase.from('report_templates').select();
      
      if (type != null) {
        query = query.eq('report_type', type.value);
      }
      
      final response = await query.eq('is_active', true).order('name');
      
      return (response as List)
          .map((json) => ReportTemplate.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('فشل في جلب قوالب التقارير: $e');
    }
  }

  /// إنشاء قالب تقرير جديد
  static Future<ReportTemplate> createReportTemplate(ReportTemplate template) async {
    try {
      final response = await _supabase
          .from('report_templates')
          .insert(template.toJson())
          .select()
          .single();
      
      return ReportTemplate.fromJson(response);
    } catch (e) {
      throw Exception('فشل في إنشاء قالب التقرير: $e');
    }
  }

  // ========== REPORT OPERATIONS ==========

  /// جلب جميع التقارير
  static Future<List<Report>> getReports({
    ReportType? type,
    bool? isFavorite,
    int? limit,
  }) async {
    try {
      dynamic query = _supabase.from('reports').select();
      
      if (type != null) {
        query = query.eq('report_type', type.value);
      }
      
      if (isFavorite != null) {
        query = query.eq('is_favorite', isFavorite);
      }
      
      query = query.order('generated_at', ascending: false);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final response = await query;
      
      return (response as List)
          .map((json) => Report.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('فشل في جلب التقارير: $e');
    }
  }

  /// إنشاء تقرير جديد
  static Future<Report> createReport({
    required ReportType reportType,
    required String title,
    String? description,
    Map<String, dynamic>? filters,
    bool isScheduled = false,
    String? scheduleFrequency,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      final reportData = {
        'report_type': reportType.value,
        'title': title,
        'description': description,
        'filters': filters,
        'generated_by': userId,
        'generated_at': DateTime.now().toIso8601String(),
        'is_scheduled': isScheduled,
        'schedule_frequency': scheduleFrequency,
        'status': ReportStatus.pending.value,
      };
      
      final response = await _supabase
          .from('reports')
          .insert(reportData)
          .select()
          .single();
      
      return Report.fromJson(response);
    } catch (e) {
      throw Exception('فشل في إنشاء التقرير: $e');
    }
  }

  /// تحديث بيانات التقرير
  static Future<Report> updateReportData({
    required String reportId,
    required ReportData data,
    ReportStatus? status,
  }) async {
    try {
      final updateData = {
        'data': data.toJson(),
        'status': (status ?? ReportStatus.completed).value,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final response = await _supabase
          .from('reports')
          .update(updateData)
          .eq('id', reportId)
          .select()
          .single();
      
      return Report.fromJson(response);
    } catch (e) {
      throw Exception('فشل في تحديث بيانات التقرير: $e');
    }
  }

  /// تحديث حالة المفضلة للتقرير
  static Future<void> toggleFavorite(String reportId, bool isFavorite) async {
    try {
      await _supabase
          .from('reports')
          .update({'is_favorite': isFavorite})
          .eq('id', reportId);
    } catch (e) {
      throw Exception('فشل في تحديث المفضلة: $e');
    }
  }

  /// حذف تقرير
  static Future<void> deleteReport(String reportId) async {
    try {
      await _supabase
          .from('reports')
          .delete()
          .eq('id', reportId);
    } catch (e) {
      throw Exception('فشل في حذف التقرير: $e');
    }
  }

  // ========== DATA GENERATION ==========

  /// تنفيذ استعلام مخصص للتقرير
  static Future<List<Map<String, dynamic>>> executeQuery({
    required String query,
    List<dynamic>? parameters,
  }) async {
    try {
      // استعلام مخصص باستخدام RPC
      final response = await _supabase.rpc('execute_report_query', 
        params: {
          'query_text': query,
          'params': parameters ?? [],
        }
      );
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('فشل في تنفيذ الاستعلام: $e');
    }
  }

  /// جلب بيانات الإيرادات
  static Future<List<Map<String, dynamic>>> getRevenueData({
    required DateRange dateRange,
    String groupBy = 'day', // day, week, month
  }) async {
    try {
      final response = await _supabase
          .from('invoices')
          .select('amount, invoice_date, created_at')
          .gte('invoice_date', dateRange.startDate.toIso8601String().split('T')[0])
          .lte('invoice_date', dateRange.endDate.toIso8601String().split('T')[0])
          .order('invoice_date');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching revenue data: $e');
      return [];
    }
  }

  /// جلب إحصائيات المرضى
  static Future<List<Map<String, dynamic>>> getPatientStats({
    required DateRange dateRange,
  }) async {
    try {
      final response = await _supabase
          .from('patients')
          .select('id, gender, date_of_birth, created_at')
          .gte('created_at', dateRange.startDate.toIso8601String())
          .lte('created_at', dateRange.endDate.toIso8601String())
          .order('created_at');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('فشل في جلب إحصائيات المرضى: $e');
    }
  }

  /// جلب بيانات الأدوية الأكثر وصفاً
  static Future<List<Map<String, dynamic>>> getTopMedications({
    required DateRange dateRange,
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from('prescription_items')
          .select('drug_name')
          .gte('created_at', dateRange.startDate.toIso8601String())
          .lte('created_at', dateRange.endDate.toIso8601String());
      
      // تجميع البيانات في Flutter
      final drugCounts = <String, int>{};
      for (final item in response) {
        final drugName = item['drug_name'] as String;
        drugCounts[drugName] = (drugCounts[drugName] ?? 0) + 1;
      }
      
      final sortedDrugs = drugCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return sortedDrugs.take(limit).map((entry) => {
        'drug_name': entry.key,
        'count': entry.value,
      }).toList();
    } catch (e) {
      throw Exception('فشل في جلب بيانات الأدوية: $e');
    }
  }

  /// جلب إحصائيات المواعيد
  static Future<List<Map<String, dynamic>>> getAppointmentStats({
    required DateRange dateRange,
  }) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('status, appointment_date, created_at')
          .gte('appointment_date', dateRange.startDate.toIso8601String().split('T')[0])
          .lte('appointment_date', dateRange.endDate.toIso8601String().split('T')[0])
          .order('appointment_date');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('فشل في جلب إحصائيات المواعيد: $e');
    }
  }
}

// ========== REPORT GENERATORS ==========

abstract class ReportGenerator {
  Future<ReportData> generate({
    required DateRange dateRange,
    Map<String, dynamic>? filters,
  });
}

class FinancialReportGenerator implements ReportGenerator {
  @override
  Future<ReportData> generate({
    required DateRange dateRange,
    Map<String, dynamic>? filters,
  }) async {
    try {
      // جلب بيانات الإيرادات
      final revenueData = await ReportService.getRevenueData(dateRange: dateRange);
      
      // حساب الملخص
      double totalRevenue = 0;
      int totalInvoices = 0;
      
      for (final row in revenueData) {
        totalRevenue += (row['total_revenue'] ?? 0).toDouble();
        totalInvoices += ((row['invoice_count'] ?? 0) as num).toInt();
      }
      
      final avgRevenue = totalInvoices > 0 ? totalRevenue / totalInvoices : 0;
      
      final summary = {
        'total_revenue': totalRevenue,
        'total_invoices': totalInvoices,
        'avg_revenue': avgRevenue,
        'period': dateRange.toString(),
      };
      
      // إعداد بيانات الرسم البياني
      final chartData = ChartData(
        datasets: [{
          'label': 'الإيرادات',
          'data': revenueData.map((row) => row['total_revenue']).toList(),
          'backgroundColor': 'rgba(54, 162, 235, 0.2)',
          'borderColor': 'rgba(54, 162, 235, 1)',
        }],
        labels: revenueData.map((row) => row['period'].toString()).toList(),
      );
      
      return ReportData(
        rows: revenueData,
        summary: summary,
        chartData: chartData,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('فشل في إنشاء التقرير المالي: $e');
    }
  }
}

class PatientReportGenerator implements ReportGenerator {
  @override
  Future<ReportData> generate({
    required DateRange dateRange,
    Map<String, dynamic>? filters,
  }) async {
    try {
      // جلب بيانات المرضى
      final patientData = await ReportService.getPatientStats(dateRange: dateRange);
      
      // تحليل البيانات
      int totalPatients = patientData.length;
      int maleCount = 0;
      int femaleCount = 0;
      Map<String, int> ageGroups = {
        '0-18': 0,
        '19-35': 0,
        '36-50': 0,
        '51+': 0,
      };
      
      for (final patient in patientData) {
        // تحليل الجنس
        final gender = patient['gender'];
        if (gender == 'male') maleCount++;
        if (gender == 'female') femaleCount++;
        
        // تحليل العمر
        if (patient['date_of_birth'] != null) {
          final birthDate = DateTime.parse(patient['date_of_birth']);
          final age = DateTime.now().difference(birthDate).inDays ~/ 365;
          
          if (age <= 18) ageGroups['0-18'] = ageGroups['0-18']! + 1;
          else if (age <= 35) ageGroups['19-35'] = ageGroups['19-35']! + 1;
          else if (age <= 50) ageGroups['36-50'] = ageGroups['36-50']! + 1;
          else ageGroups['51+'] = ageGroups['51+']! + 1;
        }
      }
      
      final summary = {
        'total_patients': totalPatients,
        'male_count': maleCount,
        'female_count': femaleCount,
        'age_groups': ageGroups,
        'period': dateRange.toString(),
      };
      
      // إعداد بيانات الرسم البياني للجنس
      final genderChartData = ChartData(
        datasets: [{
          'data': [maleCount, femaleCount],
          'backgroundColor': ['#36A2EB', '#FF6384'],
        }],
        labels: ['ذكور', 'إناث'],
      );
      
      return ReportData(
        rows: patientData,
        summary: summary,
        chartData: genderChartData,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('فشل في إنشاء تقرير المرضى: $e');
    }
  }
}

class MedicalReportGenerator implements ReportGenerator {
  @override
  Future<ReportData> generate({
    required DateRange dateRange,
    Map<String, dynamic>? filters,
  }) async {
    try {
      // جلب بيانات الأدوية الأكثر وصفاً
      final medicationData = await ReportService.getTopMedications(
        dateRange: dateRange,
        limit: filters?['limit'] ?? 10,
      );
      
      // حساب الملخص
      int totalPrescriptions = medicationData.fold(
        0, (sum, item) => sum + (item['count'] as int)
      );
      
      final summary = {
        'total_prescriptions': totalPrescriptions,
        'unique_medications': medicationData.length,
        'top_medication': medicationData.isNotEmpty ? medicationData.first['drug_name'] : null,
        'period': dateRange.toString(),
      };
      
      // إعداد بيانات الرسم البياني
      final chartData = ChartData(
        datasets: [{
          'data': medicationData.map((item) => item['count']).toList(),
          'backgroundColor': [
            '#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0', '#9966FF',
            '#FF9F40', '#FF6384', '#C9CBCF', '#4BC0C0', '#FF6384'
          ],
        }],
        labels: medicationData.map((item) => item['drug_name'].toString()).toList(),
      );
      
      return ReportData(
        rows: medicationData,
        summary: summary,
        chartData: chartData,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('فشل في إنشاء التقرير الطبي: $e');
    }
  }
}

class OperationalReportGenerator implements ReportGenerator {
  @override
  Future<ReportData> generate({
    required DateRange dateRange,
    Map<String, dynamic>? filters,
  }) async {
    try {
      // جلب بيانات المواعيد
      final appointmentData = await ReportService.getAppointmentStats(dateRange: dateRange);
      
      // تحليل البيانات
      Map<String, int> statusCounts = {
        'completed': 0,
        'pending': 0,
        'cancelled': 0,
      };
      
      int totalAppointments = appointmentData.length;
      
      for (final appointment in appointmentData) {
        final status = appointment['status'];
        // تحويل حالات قاعدة البيانات إلى تصنيفات داخلية
        String mappedStatus;
        switch (status?.toLowerCase()) {
          case 'confirmed':
          case 'completed':
            mappedStatus = 'completed';
            break;
          case 'pending':
          case 'scheduled':
            mappedStatus = 'pending';
            break;
          case 'cancelled':
          case 'canceled':
            mappedStatus = 'cancelled';
            break;
          default:
            mappedStatus = 'pending'; // افتراضي
        }
        
        if (statusCounts.containsKey(mappedStatus)) {
          statusCounts[mappedStatus] = statusCounts[mappedStatus]! + 1;
        }
      }
      
      // حساب معدلات الأداء
      double completionRate = totalAppointments > 0 
          ? (statusCounts['completed']! / totalAppointments) * 100 
          : 0;
      double cancellationRate = totalAppointments > 0 
          ? (statusCounts['cancelled']! / totalAppointments) * 100 
          : 0;
      
      final summary = {
        'total_appointments': totalAppointments,
        'completed': statusCounts['completed'],
        'pending': statusCounts['pending'],
        'cancelled': statusCounts['cancelled'],
        'completion_rate': completionRate,
        'cancellation_rate': cancellationRate,
        'period': dateRange.toString(),
      };
      
      // إعداد بيانات الرسم البياني
      final chartData = ChartData(
        datasets: [{
          'data': statusCounts.values.toList(),
          'backgroundColor': ['#4BC0C0', '#FFCE56', '#FF6384'],
        }],
        labels: ['مكتملة', 'في الانتظار', 'ملغية'],
      );
      
      return ReportData(
        rows: appointmentData,
        summary: summary,
        chartData: chartData,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('فشل في إنشاء التقرير التشغيلي: $e');
    }
  }
}

// ========== REPORT MANAGER ==========

class ReportManager {
  static final Map<ReportType, ReportGenerator> _generators = {
    ReportType.financial: FinancialReportGenerator(),
    ReportType.patients: PatientReportGenerator(),
    ReportType.medical: MedicalReportGenerator(),
    ReportType.operational: OperationalReportGenerator(),
  };

  /// إنشاء تقرير جديد
  static Future<Report> generateReport({
    required ReportType type,
    required String title,
    required DateRange dateRange,
    String? description,
    Map<String, dynamic>? filters,
  }) async {
    try {
      // إنشاء التقرير في قاعدة البيانات
      final report = await ReportService.createReport(
        reportType: type,
        title: title,
        description: description,
        filters: {
          ...?filters,
          'date_range': dateRange.toJson(),
        },
      );

      // تحديث حالة التقرير إلى "يتم الإنشاء"
      await ReportService.updateReportData(
        reportId: report.id,
        data: ReportData(
          rows: [],
          summary: {},
          lastUpdated: DateTime.now(),
        ),
        status: ReportStatus.generating,
      );

      // إنشاء البيانات
      final generator = _generators[type];
      if (generator == null) {
        throw Exception('نوع التقرير غير مدعوم: ${type.arabicName}');
      }

      final reportData = await generator.generate(
        dateRange: dateRange,
        filters: filters,
      );

      // حفظ النتائج
      final completedReport = await ReportService.updateReportData(
        reportId: report.id,
        data: reportData,
        status: ReportStatus.completed,
      );

      return completedReport;
    } catch (e) {
      throw Exception('فشل في إنشاء التقرير: $e');
    }
  }

  /// جلب مولد التقرير حسب النوع
  static ReportGenerator? getGenerator(ReportType type) {
    return _generators[type];
  }

  /// إنشاء تقرير سريع بدون حفظ
  static Future<ReportData> generateQuickReport({
    required ReportType type,
    required DateRange dateRange,
    Map<String, dynamic>? filters,
  }) async {
    final generator = _generators[type];
    if (generator == null) {
      throw Exception('نوع التقرير غير مدعوم: ${type.arabicName}');
    }

    return await generator.generate(
      dateRange: dateRange,
      filters: filters,
    );
  }
}

// ========== UTILITY FUNCTIONS ==========

class ReportUtils {
  /// تنسيق الأرقام للعرض
  static String formatNumber(num number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}م';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}ك';
    } else {
      return number.toStringAsFixed(0);
    }
  }

  /// تنسيق العملة
  static String formatCurrency(num amount, {String currency = 'ج.م'}) {
    return '${formatNumber(amount)} $currency';
  }

  /// تنسيق النسب المئوية
  static String formatPercentage(num percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// تنسيق التاريخ للعرض
  static String formatDate(DateTime date) {
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// حساب معدل النمو
  static double calculateGrowthRate(num current, num previous) {
    if (previous == 0) return 0;
    return ((current - previous) / previous) * 100;
  }

  /// حساب المتوسط
  static double calculateAverage(List<num> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// حساب الوسيط
  static double calculateMedian(List<num> values) {
    if (values.isEmpty) return 0;
    
    final sorted = List<num>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    
    if (sorted.length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    } else {
      return sorted[middle].toDouble();
    }
  }

  /// تحويل البيانات إلى CSV
  static String convertToCSV(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';
    
    final headers = data.first.keys.toList();
    final csvContent = StringBuffer();
    
    // إضافة العناوين
    csvContent.writeln(headers.join(','));
    
    // إضافة البيانات
    for (final row in data) {
      final values = headers.map((header) => row[header]?.toString() ?? '').toList();
      csvContent.writeln(values.join(','));
    }
    
    return csvContent.toString();
  }

  /// إنشاء ألوان عشوائية للرسوم البيانية
  static List<String> generateChartColors(int count) {
    final baseColors = [
      '#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0', '#9966FF',
      '#FF9F40', '#FF6384', '#C9CBCF', '#4BC0C0', '#FF6384'
    ];
    
    final colors = <String>[];
    for (int i = 0; i < count; i++) {
      colors.add(baseColors[i % baseColors.length]);
    }
    
    return colors;
  }

  /// التحقق من صحة فترة التاريخ
  static bool isValidDateRange(DateRange range) {
    return range.startDate.isBefore(range.endDate) || 
           range.startDate.isAtSameMomentAs(range.endDate);
  }

  /// حساب عدد الأيام في فترة
  static int getDaysInRange(DateRange range) {
    return range.endDate.difference(range.startDate).inDays + 1;
  }

  /// تحديد نوع التجميع المناسب حسب فترة التاريخ
  static String getOptimalGroupBy(DateRange range) {
    final days = getDaysInRange(range);
    
    if (days <= 7) return 'day';
    if (days <= 31) return 'day';
    if (days <= 365) return 'week';
    return 'month';
  }
}

// ========== EXPORT FUNCTIONS ==========

class ReportExporter {
  /// تصدير التقرير كـ JSON
  static Map<String, dynamic> exportAsJson(Report report) {
    return {
      'report': report.toJson(),
      'exported_at': DateTime.now().toIso8601String(),
      'exported_by': Supabase.instance.client.auth.currentUser?.id,
    };
  }

  /// تصدير البيانات كـ CSV
  static String exportAsCSV(ReportData data) {
    return ReportUtils.convertToCSV(data.rows);
  }

  /// إنشاء ملخص التقرير للطباعة
  static Map<String, dynamic> createPrintSummary(Report report) {
    return {
      'title': report.title,
      'type': report.reportType.arabicName,
      'generated_at': ReportUtils.formatDate(report.generatedAt),
      'summary': report.data?.summary ?? {},
      'total_records': report.data?.rows.length ?? 0,
    };
  }
}