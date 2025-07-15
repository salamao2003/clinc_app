// lib/backend_local/profile_logic_local.dart
import '../database/local_database.dart';
import '../database/database_helper.dart';

class ProfileLogicLocal {
  static const String _clinicTable = 'clinic_settings';
  static const String _userTable = 'user_profile';

  /// الحصول على إعدادات العيادة
  static Future<Map<String, dynamic>> getClinicSettings() async {
    try {
      final db = await LocalDatabase.database;
      
      final settings = await db.query(
        _clinicTable,
        where: 'id = ?',
        whereArgs: ['main_clinic'],
        limit: 1,
      );

      if (settings.isEmpty) {
        return {
          'success': false,
          'message': 'إعدادات العيادة غير موجودة',
        };
      }

      final clinicData = settings.first;
      
      // تحويل working_hours من JSON string إلى Map
      Map<String, dynamic> workingHours = {};
      try {
        if (clinicData['working_hours'] != null) {
          final workingHoursStr = clinicData['working_hours'].toString();
          if (workingHoursStr.startsWith('{')) {
            // إذا كان JSON string، نحتاج parsing مناسب
            workingHours = getDefaultWorkingHours().cast<String, dynamic>();
          } else {
            workingHours = getDefaultWorkingHours().cast<String, dynamic>();
          }
        }
      } catch (e) {
        workingHours = getDefaultWorkingHours().cast<String, dynamic>();
      }

      return {
        'success': true,
        'clinic': {
          'id': clinicData['id'],
          'clinic_name': clinicData['clinic_name'],
          'address': clinicData['address'],
          'phone': clinicData['phone'],
          'email': clinicData['email'],
          'logo_path': clinicData['logo_path'],
          'working_hours': workingHours,
          'currency': clinicData['currency'],
          'language': clinicData['language'],
          'created_at': clinicData['created_at'],
          'updated_at': clinicData['updated_at'],
        }
      };

    } catch (e) {
      print('خطأ في جلب إعدادات العيادة: $e');
      return {
        'success': false,
        'message': 'خطأ في جلب الإعدادات: ${e.toString()}',
      };
    }
  }

  /// تحديث إعدادات العيادة
  static Future<Map<String, dynamic>> updateClinicSettings({
    String? clinicName,
    String? address,
    String? phone,
    String? email,
    String? logoPath,
    Map<String, String>? workingHours,
    String? currency,
    String? language,
  }) async {
    try {
      final db = await LocalDatabase.database;
      
      Map<String, dynamic> updateData = {};
      
      if (clinicName != null) {
        updateData['clinic_name'] = DatabaseHelper.sanitizeString(clinicName) ?? 'عيادة الدكتور';
      }
      if (address != null) {
        updateData['address'] = DatabaseHelper.sanitizeString(address);
      }
      if (phone != null) {
        updateData['phone'] = DatabaseHelper.sanitizeString(phone);
      }
      if (email != null) {
        updateData['email'] = DatabaseHelper.sanitizeString(email)?.toLowerCase();
      }
      if (logoPath != null) {
        updateData['logo_path'] = logoPath;
      }
      if (workingHours != null) {
        updateData['working_hours'] = workingHours.toString();
      }
      if (currency != null) {
        updateData['currency'] = currency;
      }
      if (language != null) {
        updateData['language'] = language;
      }

      if (updateData.isEmpty) {
        return {
          'success': false,
          'message': 'لا توجد بيانات للتحديث',
        };
      }

      updateData = DatabaseHelper.addTimestamp(updateData, isUpdate: true);

      final result = await db.update(
        _clinicTable,
        updateData,
        where: 'id = ?',
        whereArgs: ['main_clinic'],
      );

      if (result == 0) {
        return {
          'success': false,
          'message': 'فشل في تحديث الإعدادات',
        };
      }

      return {
        'success': true,
        'message': 'تم تحديث إعدادات العيادة بنجاح',
      };

    } catch (e) {
      print('خطأ في تحديث إعدادات العيادة: $e');
      return {
        'success': false,
        'message': 'خطأ في التحديث: ${e.toString()}',
      };
    }
  }

  /// الحصول على بيانات الدكتور الكاملة
  static Future<Map<String, dynamic>> getDoctorProfile() async {
    try {
      final db = await LocalDatabase.database;
      
      print('🔍 البحث عن بيانات المستخدم في جدول: $_userTable');
      
      final doctors = await db.query(
        _userTable,
        where: 'id = ? AND is_active = ?',
        whereArgs: ['main_user', 1],
        limit: 1,
      );

      print('📊 عدد النتائج الموجودة: ${doctors.length}');
      
      if (doctors.isEmpty) {
        // جرب البحث بدون شرط is_active
        final allUsers = await db.query(_userTable);
        print('📊 إجمالي المستخدمين في الجدول: ${allUsers.length}');
        
        if (allUsers.isNotEmpty) {
          print('📝 أول مستخدم موجود: ${allUsers.first}');
        }
        
        return {
          'success': false,
          'message': 'بيانات الدكتور غير موجودة',
        };
      }

      final doctor = doctors.first;
      print('✅ تم العثور على البيانات: ${doctor['full_name']}');
      
      return {
        'success': true,
        'profile': {
          'id': doctor['id'],
          'full_name': doctor['full_name'],
          'email': doctor['email'],
          'phone': doctor['phone'],
          'role': doctor['role'],
          'profile_image': doctor['profile_image'],
          'created_at': doctor['created_at'],
          'updated_at': doctor['updated_at'],
          'last_login': doctor['last_login'],
        },
      };

    } catch (e) {
      print('خطأ في جلب بيانات الدكتور: $e');
      return {
        'success': false,
        'message': 'خطأ في جلب البيانات: ${e.toString()}',
      };
    }
  }

  /// تحديث بيانات الدكتور
  static Future<Map<String, dynamic>> updateDoctorProfile({
    String? fullName,
    String? phone,
    String? profileImage,
  }) async {
    try {
      final db = await LocalDatabase.database;
      
      Map<String, dynamic> updateData = {};
      
      if (fullName != null) {
        updateData['full_name'] = DatabaseHelper.sanitizeString(fullName) ?? 'الدكتور';
      }
      if (phone != null) {
        updateData['phone'] = DatabaseHelper.sanitizeString(phone);
      }
      if (profileImage != null) {
        updateData['profile_image'] = profileImage;
      }

      if (updateData.isEmpty) {
        return {
          'success': false,
          'message': 'لا توجد بيانات للتحديث',
        };
      }

      updateData = DatabaseHelper.addTimestamp(updateData, isUpdate: true);

      final result = await db.update(
        _userTable,
        updateData,
        where: 'id = ?',
        whereArgs: ['main_user'],
      );

      if (result == 0) {
        return {
          'success': false,
          'message': 'فشل في تحديث البيانات',
        };
      }

      return {
        'success': true,
        'message': 'تم تحديث بيانات الدكتور بنجاح',
      };

    } catch (e) {
      print('خطأ في تحديث بيانات الدكتور: $e');
      return {
        'success': false,
        'message': 'خطأ في التحديث: ${e.toString()}',
      };
    }
  }

  /// الحصول على الملف الشخصي الكامل (دكتور + عيادة)
  static Future<Map<String, dynamic>> getFullProfile() async {
    try {
      final doctorResult = await getDoctorProfile();
      final clinicResult = await getClinicSettings();

      if (!doctorResult['success'] && !clinicResult['success']) {
        return {
          'success': false,
          'message': 'فشل في جلب البيانات',
        };
      }

      return {
        'success': true,
        'doctor': doctorResult['success'] ? doctorResult['doctor'] : null,
        'clinic': clinicResult['success'] ? clinicResult['clinic'] : null,
      };

    } catch (e) {
      print('خطأ في جلب الملف الشخصي: $e');
      return {
        'success': false,
        'message': 'خطأ في جلب البيانات: ${e.toString()}',
      };
    }
  }

  /// إحصائيات سريعة للوحة القيادة
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final stats = await DatabaseHelper.getDatabaseStatistics();
      
      // إحصائيات إضافية
      final db = await LocalDatabase.database;
      
      // مواعيد اليوم
      final todayAppointments = await db.query(
        'appointments',
        where: 'appointment_date = ? AND status != ?',
        whereArgs: [
          DateTime.now().toIso8601String().split('T')[0],
          'cancelled'
        ],
      );

      // الإيرادات الشهرية
      final currentMonth = DateTime.now().toIso8601String().substring(0, 7); // YYYY-MM
      final monthlyInvoices = await db.rawQuery('''
        SELECT SUM(total_amount) as total, COUNT(*) as count
        FROM invoices 
        WHERE invoice_date LIKE ? AND status = ?
      ''', ['$currentMonth%', 'paid']);

      final monthlyRevenue = monthlyInvoices.first['total'] as double? ?? 0.0;
      final paidInvoicesCount = monthlyInvoices.first['count'] as int? ?? 0;

      // المرضى الجدد هذا الشهر
      final newPatients = await db.query(
        'patients',
        where: 'created_at LIKE ? AND is_active = ?',
        whereArgs: ['$currentMonth%', 1],
      );

      return {
        'success': true,
        'stats': {
          'total_patients': stats['patients'] ?? 0,
          'total_appointments': stats['appointments'] ?? 0,
          'total_prescriptions': stats['prescriptions'] ?? 0,
          'total_invoices': stats['invoices'] ?? 0,
          'total_reports': stats['reports'] ?? 0,
          'today_appointments': todayAppointments.length,
          'monthly_revenue': monthlyRevenue,
          'paid_invoices_this_month': paidInvoicesCount,
          'new_patients_this_month': newPatients.length,
        }
      };

    } catch (e) {
      print('خطأ في جلب الإحصائيات: $e');
      return {
        'success': false,
        'message': 'خطأ في جلب الإحصائيات: ${e.toString()}',
        'stats': {
          'total_patients': 0,
          'total_appointments': 0,
          'total_prescriptions': 0,
          'total_invoices': 0,
          'total_reports': 0,
          'today_appointments': 0,
          'monthly_revenue': 0.0,
          'paid_invoices_this_month': 0,
          'new_patients_this_month': 0,
        }
      };
    }
  }

  /// إعداد ساعات العمل الافتراضية
  static Map<String, String> getDefaultWorkingHours() {
    return {
      "saturday": "9:00-17:00",
      "sunday": "9:00-17:00",
      "monday": "9:00-17:00", 
      "tuesday": "9:00-17:00",
      "wednesday": "9:00-17:00",
      "thursday": "9:00-17:00",
      "friday": "closed"
    };
  }

  /// فحص ما إذا كانت العيادة مفتوحة الآن
  static Future<Map<String, dynamic>> isClinicOpenNow() async {
    try {
      final clinicResult = await getClinicSettings();
      if (!clinicResult['success']) {
        return {
          'success': false,
          'message': 'لا يمكن جلب إعدادات العيادة',
        };
      }

      final clinic = clinicResult['clinic'];
      final workingHours = clinic['working_hours'] as Map<String, dynamic>;
      
      final now = DateTime.now();
      final currentDay = _getDayName(now.weekday);
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      if (!workingHours.containsKey(currentDay)) {
        return {
          'success': true,
          'is_open': false,
          'message': 'لا توجد ساعات عمل محددة لهذا اليوم',
        };
      }

      final daySchedule = workingHours[currentDay] as String;
      
      if (daySchedule.toLowerCase() == 'closed') {
        return {
          'success': true,
          'is_open': false,
          'message': 'العيادة مغلقة اليوم',
        };
      }

      // تحليل ساعات العمل (مثال: "9:00-17:00")
      final times = daySchedule.split('-');
      if (times.length != 2) {
        return {
          'success': true,
          'is_open': false,
          'message': 'تنسيق ساعات العمل غير صحيح',
        };
      }

      final openTime = times[0].trim();
      final closeTime = times[1].trim();
      
      final isOpen = _isTimeBetween(currentTime, openTime, closeTime);
      
      return {
        'success': true,
        'is_open': isOpen,
        'message': isOpen ? 'العيادة مفتوحة الآن' : 'العيادة مغلقة الآن',
        'open_time': openTime,
        'close_time': closeTime,
        'current_time': currentTime,
      };

    } catch (e) {
      print('خطأ في فحص حالة العيادة: $e');
      return {
        'success': false,
        'message': 'خطأ في فحص الحالة: ${e.toString()}',
      };
    }
  }

  /// مساعد للحصول على اسم اليوم
  static String _getDayName(int weekday) {
    const days = {
      1: 'monday',
      2: 'tuesday', 
      3: 'wednesday',
      4: 'thursday',
      5: 'friday',
      6: 'saturday',
      7: 'sunday',
    };
    return days[weekday] ?? 'sunday';
  }

  /// مساعد للتحقق من وقوع الوقت بين وقتين
  static bool _isTimeBetween(String currentTime, String startTime, String endTime) {
    try {
      final current = _timeToMinutes(currentTime);
      final start = _timeToMinutes(startTime);
      final end = _timeToMinutes(endTime);
      
      return current >= start && current <= end;
    } catch (e) {
      return false;
    }
  }

  /// تحويل الوقت إلى دقائق للمقارنة
  static int _timeToMinutes(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }
}
