// backend/patient_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'patient_model.dart';
import 'auth_service.dart';

class PatientService {
  // Singleton pattern
  static final PatientService _instance = PatientService._internal();
  factory PatientService() => _instance;
  PatientService._internal();

  // Supabase client
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // اسم الجدول في قاعدة البيانات
  static const String _tableName = 'patients';

  /// جلب جميع المرضى
  Future<List<Patient>> getAllPatients() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      print('تم جلب ${response.length} مريض من قاعدة البيانات');
      
      return response.map((data) => Patient.fromJson(data)).toList();
    } catch (e) {
      print('خطأ في جلب المرضى: $e');
      throw Exception('فشل في جلب بيانات المرضى');
    }
  }

  /// البحث عن المرضى
  Future<List<Patient>> searchPatients(String query) async {
    try {
      if (query.isEmpty) {
        return getAllPatients();
      }

      final response = await _supabase
          .from(_tableName)
          .select('*')
          .eq('is_active', true)
          .or('full_name.ilike.%$query%,phone_number.ilike.%$query%,email.ilike.%$query%')
          .order('created_at', ascending: false);

      print('تم العثور على ${response.length} نتيجة للبحث: $query');
      
      return response.map((data) => Patient.fromJson(data)).toList();
    } catch (e) {
      print('خطأ في البحث عن المرضى: $e');
      throw Exception('فشل في البحث عن المرضى');
    }
  }

  /// جلب مريض بواسطة ID
  Future<Patient?> getPatientById(String id) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('*')
          .eq('id', id)
          .eq('is_active', true)
          .single();

      return Patient.fromJson(response);
    } catch (e) {
      print('خطأ في جلب المريض: $e');
      return null;
    }
  }

  /// إضافة مريض جديد
  Future<bool> addPatient(Patient patient) async {
    try {
      // التحقق من عدم وجود مريض بنفس البريد الإلكتروني
      if (patient.email.isNotEmpty) {
        final existingPatient = await _checkEmailExists(patient.email);
        if (existingPatient) {
          throw Exception('يوجد مريض مسجل بهذا البريد الإلكتروني');
        }
      }

      final data = patient.toJson();
      // إزالة ID لأن قاعدة البيانات ستنشئه تلقائياً
      data.remove('id');
      
      await _supabase.from(_tableName).insert(data);
      
      print('تم إضافة المريض بنجاح: ${patient.fullName}');
      return true;
    } catch (e) {
      print('خطأ في إضافة المريض: $e');
      throw Exception('فشل في إضافة المريض');
    }
  }

  /// تحديث بيانات المريض
  Future<bool> updatePatient(Patient patient) async {
    try {
      final data = patient.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();
      
      await _supabase
          .from(_tableName)
          .update(data)
          .eq('id', patient.id);

      print('تم تحديث المريض بنجاح: ${patient.fullName}');
      return true;
    } catch (e) {
      print('خطأ في تحديث المريض: $e');
      throw Exception('فشل في تحديث بيانات المريض');
    }
  }

   Future<bool> deletePatient(String id) async {
  try {
    // حذف جميع المواعيد المرتبطة بالمريض أولاً
    await _supabase
        .from('appointments')
        .delete()
        .eq('patient_id', id);
    
    print('تم حذف جميع المواعيد المرتبطة بالمريض');

    // حذف جميع الوصفات الطبية المرتبطة بالمريض
    await _supabase
        .from('prescriptions')
        .delete()
        .eq('patient_id', id);
    
    print('تم حذف جميع الوصفات الطبية المرتبطة بالمريض');

    // حذف المريض نفسه
    await _supabase
        .from(_tableName)
        .delete()
        .eq('id', id);

    print('تم حذف المريض نهائيًا من قاعدة البيانات مع جميع بياناته');
    return true;
  } catch (e) {
    print('خطأ في حذف المريض نهائيًا: $e');
    throw Exception('فشل في حذف المريض نهائيًا');
  }
}

  /// دوال منقولة من PatientsScreen

  /// تحميل المرضى (ترجع قائمتين: كل المرضى والمفلترة)
  Future<Map<String, List<Patient>>> loadPatients() async {
    try {
      final patients = await getAllPatients();
      return {
        'patients': patients,
        'filteredPatients': patients,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// البحث في قائمة محلية
  List<Patient> searchPatientsLocal(List<Patient> patients, String query) {
    if (query.isEmpty) return patients;
    final searchLower = query.toLowerCase();
    return patients.where((patient) {
      return patient.fullName.toLowerCase().contains(searchLower) ||
          patient.phoneNumber.contains(searchLower) ||
          patient.email.toLowerCase().contains(searchLower);
    }).toList();
  }

  /// حذف مريض مع تأكيد
  Future<bool> deletePatientWithConfirm(BuildContext context, Patient patient, bool isArabic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تأكيد الحذف' : 'Confirm Delete'),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من حذف المريض ${patient.fullName}؟\n\nسيتم حذف جميع البيانات المرتبطة بالمريض:\n• جميع المواعيد\n• جميع الوصفات الطبية\n\nهذا الإجراء لا يمكن التراجع عنه.'
              : 'Are you sure you want to delete patient ${patient.fullName}?\n\nAll related data will be deleted:\n• All appointments\n• All prescriptions\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isArabic ? 'حذف نهائي' : 'Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      return await deletePatient(patient.id);
    }
    return false;
  }

  /// تسجيل الخروج مع تأكيد
  Future<bool> logoutWithConfirm(BuildContext context, AuthService authService, bool isArabic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تسجيل الخروج' : 'Logout'),
        content: Text(isArabic ? 'هل أنت متأكد من تسجيل الخروج؟' : 'Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isArabic ? 'تسجيل الخروج' : 'Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authService.logout();
      return true;
    }
    return false;
  }

  /// الحصول على عدد المرضى
  Future<int> getPatientsCount() async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('id')
          .eq('is_active', true);

      return response.length;
    } catch (e) {
      print('خطأ في حساب عدد المرضى: $e');
      return 0;
    }
  }

  /// جلب المرضى حسب الجنس
  Future<List<Patient>> getPatientsByGender(String gender) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('*')
          .eq('is_active', true)
          .eq('gender', gender)
          .order('created_at', ascending: false);

      return response.map((data) => Patient.fromJson(data)).toList();
    } catch (e) {
      print('خطأ في جلب المرضى حسب الجنس: $e');
      throw Exception('فشل في جلب المرضى حسب الجنس');
    }
  }

  /// جلب المرضى الذين زاروا مؤخراً (آخر 30 يوم)
  Future<List<Patient>> getRecentPatients() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final response = await _supabase
          .from(_tableName)
          .select('*')
          .eq('is_active', true)
          .gte('last_visit_date', thirtyDaysAgo.toIso8601String())
          .order('last_visit_date', ascending: false);

      return response.map((data) => Patient.fromJson(data)).toList();
    } catch (e) {
      print('خطأ في جلب المرضى الحديثين: $e');
      throw Exception('فشل في جلب المرضى الحديثين');
    }
  }

  /// تحديث تاريخ آخر زيارة للمريض
  Future<bool> updateLastVisit(String patientId) async {
    try {
      await _supabase
          .from(_tableName)
          .update({
            'last_visit_date': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', patientId);

      print('تم تحديث تاريخ آخر زيارة للمريض');
      return true;
    } catch (e) {
      print('خطأ في تحديث تاريخ الزيارة: $e');
      throw Exception('فشل في تحديث تاريخ الزيارة');
    }
  }

  /// جلب إحصائيات المرضى
  Future<Map<String, dynamic>> getPatientsStatistics() async {
    try {
      // إجمالي المرضى
      final totalPatients = await getPatientsCount();
      
      // المرضى الذكور
      final malePatients = await getPatientsByGender('Male');
      
      // المرضى الإناث  
      final femalePatients = await getPatientsByGender('Female');
      
      // المرضى الحديثين
      final recentPatients = await getRecentPatients();

      return {
        'total_patients': totalPatients,
        'male_patients': malePatients.length,
        'female_patients': femalePatients.length,
        'recent_patients': recentPatients.length,
      };
    } catch (e) {
      print('خطأ في جلب إحصائيات المرضى: $e');
      return {
        'total_patients': 0,
        'male_patients': 0,
        'female_patients': 0,
        'recent_patients': 0,
      };
    }
  }

  /// التحقق من وجود بريد إلكتروني
  Future<bool> _checkEmailExists(String email) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('id')
          .eq('email', email)
          .eq('is_active', true);

      return response.isNotEmpty;
    } catch (e) {
      print('خطأ في التحقق من البريد الإلكتروني: $e');
      return false;
    }
  }

  /// جلب المرضى بالترقيم (Pagination)
  Future<List<Patient>> getPatientsPaginated({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final offset = (page - 1) * limit;
      
      final response = await _supabase
          .from(_tableName)
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((data) => Patient.fromJson(data)).toList();
    } catch (e) {
      print('خطأ في جلب المرضى بالترقيم: $e');
      throw Exception('فشل في جلب المرضى');
    }
  }

  /// جلب عدد البيانات المرتبطة بالمريض
  Future<Map<String, int>> getPatientRelatedDataCount(String patientId) async {
    try {
      // عدد المواعيد
      final appointmentsResponse = await _supabase
          .from('appointments')
          .select('id')
          .eq('patient_id', patientId);
      
      // عدد الوصفات الطبية
      final prescriptionsResponse = await _supabase
          .from('prescriptions')
          .select('id')
          .eq('patient_id', patientId);

      return {
        'appointments': appointmentsResponse.length,
        'prescriptions': prescriptionsResponse.length,
      };
    } catch (e) {
      print('خطأ في جلب عدد البيانات المرتبطة: $e');
      return {
        'appointments': 0,
        'prescriptions': 0,
      };
    }
  }

  /// حذف مريض مع تأكيد محسن (مع عرض عدد البيانات المرتبطة)
  Future<bool> deletePatientWithEnhancedConfirm(BuildContext context, Patient patient, bool isArabic) async {
    // جلب عدد البيانات المرتبطة أولاً
    final relatedData = await getPatientRelatedDataCount(patient.id);
    final appointmentsCount = relatedData['appointments'] ?? 0;
    final prescriptionsCount = relatedData['prescriptions'] ?? 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تأكيد الحذف' : 'Confirm Delete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                  ? 'هل أنت متأكد من حذف المريض ${patient.fullName}؟'
                  : 'Are you sure you want to delete patient ${patient.fullName}?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'سيتم حذف البيانات التالية:' : 'The following data will be deleted:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('• ${isArabic ? 'المواعيد' : 'Appointments'}: $appointmentsCount'),
            Text('• ${isArabic ? 'الوصفات الطبية' : 'Prescriptions'}: $prescriptionsCount'),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'هذا الإجراء لا يمكن التراجع عنه.' : 'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isArabic ? 'حذف نهائي' : 'Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // عرض مؤشر التحميل
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        final success = await deletePatient(patient.id);
        
        // إغلاق مؤشر التحميل
        Navigator.pop(context);
        
        return success;
      } catch (e) {
        // إغلاق مؤشر التحميل في حالة الخطأ
        Navigator.pop(context);
        rethrow;
      }
    }
    return false;
  }
}