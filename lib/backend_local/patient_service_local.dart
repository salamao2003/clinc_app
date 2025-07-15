// lib/backend_local/patient_service_local.dart
import '../database/local_database.dart';
import '../database/database_helper.dart';
import '../models/patient_model.dart';

class PatientServiceLocal {
  static const String _tableName = 'patients';

  /// الحصول على جميع المرضى
  static Future<List<Patient>> getAllPatients({
    bool activeOnly = true,
    String? searchTerm,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await LocalDatabase.database;
      
      String whereClause = '';
      List<dynamic> whereArgs = [];
      
      if (activeOnly) {
        whereClause = 'is_active = ?';
        whereArgs.add(1);
      }
      
      if (searchTerm != null && searchTerm.isNotEmpty) {
        final searchPattern = DatabaseHelper.createSearchPattern(searchTerm);
        if (whereClause.isNotEmpty) {
          whereClause += ' AND ';
        }
        whereClause += '(full_name LIKE ? OR phone_number LIKE ? OR email LIKE ?)';
        whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
      }
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );

      return List.generate(maps.length, (i) {
        return Patient.fromJson(maps[i]);
      });

    } catch (e) {
      print('خطأ في جلب المرضى: $e');
      return [];
    }
  }

  /// الحصول على مريض بالـ ID
  static Future<Patient?> getPatientById(String id) async {
    try {
      final db = await LocalDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return Patient.fromJson(maps.first);
      }
      return null;

    } catch (e) {
      print('خطأ في جلب المريض: $e');
      return null;
    }
  }

  /// الحصول على مريض برقم الهاتف
  static Future<Patient?> getPatientByPhone(String phoneNumber) async {
    try {
      final db = await LocalDatabase.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'phone_number = ? AND is_active = ?',
        whereArgs: [phoneNumber, 1],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return Patient.fromJson(maps.first);
      }
      return null;

    } catch (e) {
      print('خطأ في البحث عن المريض: $e');
      return null;
    }
  }

  /// إضافة مريض جديد
  static Future<Map<String, dynamic>> addPatient(Patient patient) async {
    try {
      final db = await LocalDatabase.database;
      
      // التحقق من عدم وجود رقم الهاتف مسبقاً
      final existingPatient = await getPatientByPhone(patient.phoneNumber);
      if (existingPatient != null) {
        return {
          'success': false,
          'message': 'رقم الهاتف مسجل لمريض آخر',
          'existing_patient': existingPatient.toJson(),
        };
      }

      // إنشاء ID جديد إذا لم يكن موجود
      final patientData = patient.toJson();
      if (patientData['id'] == null || patientData['id'].isEmpty) {
        patientData['id'] = DatabaseHelper.generateId();
      }
      
      patientData['created_by'] = 'main_user';
      patientData['is_active'] = 1;
      
      final updatedData = DatabaseHelper.addTimestamp(patientData);
      
      await db.insert(_tableName, updatedData);
      
      return {
        'success': true,
        'message': 'تم إضافة المريض بنجاح',
        'patient_id': updatedData['id'],
      };

    } catch (e) {
      print('خطأ في إضافة المريض: $e');
      return {
        'success': false,
        'message': 'خطأ في إضافة المريض: ${e.toString()}',
      };
    }
  }

  /// تحديث بيانات مريض
  static Future<Map<String, dynamic>> updatePatient(Patient patient) async {
    try {
      final db = await LocalDatabase.database;
      
      // التحقق من وجود المريض
      final existingPatient = await getPatientById(patient.id);
      if (existingPatient == null) {
        return {
          'success': false,
          'message': 'المريض غير موجود',
        };
      }

      // التحقق من عدم تضارب رقم الهاتف
      final phoneCheck = await getPatientByPhone(patient.phoneNumber);
      if (phoneCheck != null && phoneCheck.id != patient.id) {
        return {
          'success': false,
          'message': 'رقم الهاتف مسجل لمريض آخر',
        };
      }

      final patientData = patient.toJson();
      patientData.remove('id'); // لا نحدث الـ ID
      patientData.remove('created_at'); // لا نحدث تاريخ الإنشاء
      patientData.remove('created_by'); // لا نحدث منشئ السجل
      
      final updatedData = DatabaseHelper.addTimestamp(patientData, isUpdate: true);
      
      final result = await db.update(
        _tableName,
        updatedData,
        where: 'id = ?',
        whereArgs: [patient.id],
      );

      if (result == 0) {
        return {
          'success': false,
          'message': 'فشل في تحديث بيانات المريض',
        };
      }

      return {
        'success': true,
        'message': 'تم تحديث بيانات المريض بنجاح',
      };

    } catch (e) {
      print('خطأ في تحديث المريض: $e');
      return {
        'success': false,
        'message': 'خطأ في التحديث: ${e.toString()}',
      };
    }
  }

  /// حذف مريض (إلغاء تفعيل)
  static Future<Map<String, dynamic>> deletePatient(String patientId) async {
    try {
      final db = await LocalDatabase.database;
      
      // التحقق من وجود المريض
      final patient = await getPatientById(patientId);
      if (patient == null) {
        return {
          'success': false,
          'message': 'المريض غير موجود',
        };
      }

      // إلغاء تفعيل بدلاً من الحذف
      final result = await db.update(
        _tableName,
        DatabaseHelper.addTimestamp({
          'is_active': 0,
        }, isUpdate: true),
        where: 'id = ?',
        whereArgs: [patientId],
      );

      if (result == 0) {
        return {
          'success': false,
          'message': 'فشل في حذف المريض',
        };
      }

      return {
        'success': true,
        'message': 'تم حذف المريض بنجاح',
      };

    } catch (e) {
      print('خطأ في حذف المريض: $e');
      return {
        'success': false,
        'message': 'خطأ في الحذف: ${e.toString()}',
      };
    }
  }

  /// استعادة مريض محذوف
  static Future<Map<String, dynamic>> restorePatient(String patientId) async {
    try {
      final db = await LocalDatabase.database;
      
      final result = await db.update(
        _tableName,
        DatabaseHelper.addTimestamp({
          'is_active': 1,
        }, isUpdate: true),
        where: 'id = ?',
        whereArgs: [patientId],
      );

      if (result == 0) {
        return {
          'success': false,
          'message': 'فشل في استعادة المريض',
        };
      }

      return {
        'success': true,
        'message': 'تم استعادة المريض بنجاح',
      };

    } catch (e) {
      print('خطأ في استعادة المريض: $e');
      return {
        'success': false,
        'message': 'خطأ في الاستعادة: ${e.toString()}',
      };
    }
  }

  /// الحصول على عدد المرضى
  static Future<int> getPatientsCount({bool activeOnly = true}) async {
    try {
      if (activeOnly) {
        return await DatabaseHelper.countRecords(_tableName, where: 'is_active = ?', whereArgs: [1]);
      } else {
        return await DatabaseHelper.countRecords(_tableName);
      }
    } catch (e) {
      print('خطأ في عد المرضى: $e');
      return 0;
    }
  }

  /// البحث في المرضى
  static Future<List<Patient>> searchPatients(String searchTerm) async {
    return await getAllPatients(searchTerm: searchTerm);
  }

  /// الحصول على المرضى الجدد خلال فترة معينة
  static Future<List<Patient>> getNewPatients({
    required DateTime fromDate,
    DateTime? toDate,
  }) async {
    try {
      final db = await LocalDatabase.database;
      
      final to = toDate ?? DateTime.now();
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'created_at >= ? AND created_at <= ? AND is_active = ?',
        whereArgs: [
          fromDate.toIso8601String(),
          to.toIso8601String(),
          1,
        ],
        orderBy: 'created_at DESC',
      );

      return List.generate(maps.length, (i) {
        return Patient.fromJson(maps[i]);
      });

    } catch (e) {
      print('خطأ في جلب المرضى الجدد: $e');
      return [];
    }
  }

  /// الحصول على إحصائيات المرضى
  static Future<Map<String, dynamic>> getPatientsStatistics() async {
    try {
      final db = await LocalDatabase.database;
      
      // إجمالي المرضى النشطين
      final totalActive = await getPatientsCount(activeOnly: true);
      
      // إجمالي المرضى (شامل المحذوفين)
      final totalAll = await getPatientsCount(activeOnly: false);
      
      // المرضى الجدد هذا الشهر
      final currentMonth = DateTime.now().toIso8601String().substring(0, 7);
      final newThisMonth = await db.query(
        _tableName,
        where: 'created_at LIKE ? AND is_active = ?',
        whereArgs: ['$currentMonth%', 1],
      );
      
      // توزيع الجنس
      final malePatients = await DatabaseHelper.countRecords(
        _tableName, 
        where: 'gender = ? AND is_active = ?', 
        whereArgs: ['male', 1]
      );
      
      final femalePatients = await DatabaseHelper.countRecords(
        _tableName,
        where: 'gender = ? AND is_active = ?',
        whereArgs: ['female', 1]
      );
      
      // المرضى مع أرقام هواتف صحيحة
      final validPhones = await db.rawQuery('''
        SELECT COUNT(*) as count FROM $_tableName 
        WHERE phone_number IS NOT NULL 
        AND LENGTH(phone_number) >= 10 
        AND is_active = 1
      ''');
      
      return {
        'total_active': totalActive,
        'total_all': totalAll,
        'new_this_month': newThisMonth.length,
        'male_patients': malePatients,
        'female_patients': femalePatients,
        'valid_phones': validPhones.first['count'] as int,
        'deleted_patients': totalAll - totalActive,
      };

    } catch (e) {
      print('خطأ في جلب إحصائيات المرضى: $e');
      return {
        'total_active': 0,
        'total_all': 0,
        'new_this_month': 0,
        'male_patients': 0,
        'female_patients': 0,
        'valid_phones': 0,
        'deleted_patients': 0,
      };
    }
  }

  /// الحصول على تاريخ المريض الطبي الكامل
  static Future<Map<String, dynamic>> getPatientMedicalHistory(String patientId) async {
    try {
      final db = await LocalDatabase.database;
      
      // بيانات المريض الأساسية
      final patient = await getPatientById(patientId);
      if (patient == null) {
        return {
          'success': false,
          'message': 'المريض غير موجود',
        };
      }

      // المواعيد
      final appointments = await db.query(
        'appointments',
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'appointment_date DESC, appointment_time DESC',
      );

      // الوصفات الطبية
      final prescriptions = await db.query(
        'prescriptions',
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'prescription_date DESC',
      );

      // الفواتير
      final invoices = await db.query(
        'invoices',
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'invoice_date DESC',
      );

      // التقارير الطبية
      final reports = await db.query(
        'reports',
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'report_date DESC',
      );

      return {
        'success': true,
        'patient': patient.toJson(),
        'appointments': appointments,
        'prescriptions': prescriptions,
        'invoices': invoices,
        'reports': reports,
      };

    } catch (e) {
      print('خطأ في جلب التاريخ الطبي: $e');
      return {
        'success': false,
        'message': 'خطأ في جلب التاريخ الطبي: ${e.toString()}',
      };
    }
  }

  /// تصدير بيانات مريض معين
  static Future<Map<String, dynamic>> exportPatientData(String patientId) async {
    try {
      final medicalHistory = await getPatientMedicalHistory(patientId);
      
      if (!medicalHistory['success']) {
        return medicalHistory;
      }

      return {
        'success': true,
        'export_data': {
          'patient_info': medicalHistory['patient'],
          'medical_history': {
            'appointments': medicalHistory['appointments'],
            'prescriptions': medicalHistory['prescriptions'],
            'invoices': medicalHistory['invoices'],
            'reports': medicalHistory['reports'],
          },
          'export_date': DatabaseHelper.getCurrentTimestamp(),
        }
      };

    } catch (e) {
      print('خطأ في تصدير بيانات المريض: $e');
      return {
        'success': false,
        'message': 'خطأ في التصدير: ${e.toString()}',
      };
    }
  }
}
