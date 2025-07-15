// lib/backend_local/appointments_logic_local.dart
import '../database/local_database.dart';
import '../database/database_helper.dart';
import '../models/patient_model.dart';

class AppointmentsLogicLocal {
  static const String _tableName = 'appointments';
  static const String _patientsTable = 'patients';

  /// الحصول على جميع المواعيد
  static Future<List<Map<String, dynamic>>> getAllAppointments({
    String? statusFilter,
    String? visitTypeFilter,
    String? doctorFilter,
    DateTime? dateFilter,
  }) async {
    try {
      final db = await LocalDatabase.database;
      
      String whereClause = '';
      List<dynamic> whereArgs = [];
      
      // إضافة فلاتر
      if (statusFilter != null && statusFilter.isNotEmpty) {
        whereClause = 'a.status = ?';
        whereArgs.add(statusFilter);
      }
      
      if (visitTypeFilter != null && visitTypeFilter.isNotEmpty) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'a.appointment_type = ?';
        whereArgs.add(visitTypeFilter);
      }
      
      if (doctorFilter != null && doctorFilter.isNotEmpty) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'a.doctor_name = ?';
        whereArgs.add(doctorFilter);
      }
      
      if (dateFilter != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'a.appointment_date = ?';
        whereArgs.add(dateFilter.toIso8601String().split('T')[0]);
      }
      
      final String query = '''
        SELECT 
          a.*,
          p.full_name as patient_name,
          p.phone_number as patient_phone
        FROM $_tableName a
        LEFT JOIN $_patientsTable p ON a.patient_id = p.id
        ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
        ORDER BY a.appointment_date DESC, a.appointment_time DESC
      ''';
      
      final appointments = await db.rawQuery(query, whereArgs);
      
      return appointments.map((appointment) {
        return {
          'appointmentId': appointment['id'],
          'patientName': appointment['patient_name'] ?? 'غير محدد',
          'phoneNumber': appointment['patient_phone'] ?? '',
          'doctorName': appointment['doctor_name'] ?? '',
          'visitType': appointment['appointment_type'] ?? '',
          'date': appointment['appointment_date'],
          'time': appointment['appointment_time'],
          'duration': appointment['duration_minutes'],
          'status': appointment['status'],
          'notes': appointment['notes'] ?? '',
        };
      }).toList();

    } catch (e) {
      print('خطأ في جلب المواعيد: $e');
      return [];
    }
  }

  /// إضافة موعد جديد
  static Future<Map<String, dynamic>> addAppointment({
    required String phoneNumber,
    String? doctorName,
    required String visitType,
    required DateTime appointmentDate,
    required String appointmentTime,
    int durationMinutes = 30,
    String status = 'Pending',
    String? notes,
  }) async {
    try {
      final db = await LocalDatabase.database;
      
      // البحث عن المريض برقم الهاتف
      final patients = await db.query(
        _patientsTable,
        where: 'phone_number = ? AND is_active = ?',
        whereArgs: [phoneNumber, 1],
        limit: 1,
      );
      
      if (patients.isEmpty) {
        return {
          'success': false,
          'message': 'Patient not found with phone number: $phoneNumber',
        };
      }
      
      final patient = patients.first;
      final patientId = patient['id'];
      
      // التحقق من تضارب المواعيد
      final dateStr = appointmentDate.toIso8601String().split('T')[0];
      final conflictCheck = await _checkTimeConflict(dateStr, appointmentTime, null);
      
      if (!conflictCheck['available']) {
        return {
          'success': false,
          'message': 'Appointment time already booked by ${conflictCheck['patient_name']} (${conflictCheck['status']})',
        };
      }
      
      // إنشاء ID جديد للموعد
      final appointmentId = DatabaseHelper.generateId();
      
      final appointmentData = {
        'id': appointmentId,
        'patient_id': patientId,
        'doctor_name': doctorName,
        'appointment_type': visitType,
        'appointment_date': dateStr,
        'appointment_time': appointmentTime,
        'duration_minutes': durationMinutes,
        'status': status.toLowerCase(), // تحويل إلى أحرف صغيرة
        'notes': notes,
        'created_by': 'main_user',
      };
      
      final finalData = DatabaseHelper.addTimestamp(appointmentData);
      
      await db.insert(_tableName, finalData);
      
      return {
        'success': true,
        'message': 'تم إضافة الموعد بنجاح',
        'appointment_id': appointmentId,
      };

    } catch (e) {
      print('خطأ في إضافة الموعد: $e');
      return {
        'success': false,
        'message': 'خطأ في إضافة الموعد: ${e.toString()}',
      };
    }
  }

  /// تحديث موعد موجود
  static Future<Map<String, dynamic>> updateAppointment({
    required String appointmentId,
    required String phoneNumber,
    String? doctorName,
    required String visitType,
    required DateTime appointmentDate,
    required String appointmentTime,
    int durationMinutes = 30,
    String status = 'Pending',
    String? notes,
  }) async {
    try {
      final db = await LocalDatabase.database;
      
      // التحقق من وجود الموعد
      final existingAppointments = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [appointmentId],
        limit: 1,
      );
      
      if (existingAppointments.isEmpty) {
        return {
          'success': false,
          'message': 'الموعد غير موجود',
        };
      }
      
      // البحث عن المريض برقم الهاتف
      final patients = await db.query(
        _patientsTable,
        where: 'phone_number = ? AND is_active = ?',
        whereArgs: [phoneNumber, 1],
        limit: 1,
      );
      
      if (patients.isEmpty) {
        return {
          'success': false,
          'message': 'Patient not found with phone number: $phoneNumber',
        };
      }
      
      final patient = patients.first;
      final patientId = patient['id'];
      
      // التحقق من تضارب المواعيد (استثناء الموعد الحالي)
      final dateStr = appointmentDate.toIso8601String().split('T')[0];
      final conflictCheck = await _checkTimeConflict(dateStr, appointmentTime, appointmentId);
      
      if (!conflictCheck['available']) {
        return {
          'success': false,
          'message': 'Appointment time already booked by ${conflictCheck['patient_name']} (${conflictCheck['status']})',
        };
      }
      
      final updateData = {
        'patient_id': patientId,
        'doctor_name': doctorName,
        'appointment_type': visitType,
        'appointment_date': dateStr,
        'appointment_time': appointmentTime,
        'duration_minutes': durationMinutes,
        'status': status.toLowerCase(), // تحويل إلى أحرف صغيرة
        'notes': notes,
      };
      
      final finalData = DatabaseHelper.addTimestamp(updateData, isUpdate: true);
      
      final result = await db.update(
        _tableName,
        finalData,
        where: 'id = ?',
        whereArgs: [appointmentId],
      );
      
      if (result == 0) {
        return {
          'success': false,
          'message': 'فشل في تحديث الموعد',
        };
      }
      
      return {
        'success': true,
        'message': 'تم تحديث الموعد بنجاح',
      };

    } catch (e) {
      print('خطأ في تحديث الموعد: $e');
      return {
        'success': false,
        'message': 'خطأ في التحديث: ${e.toString()}',
      };
    }
  }

  /// حذف موعد
  static Future<Map<String, dynamic>> deleteAppointment(String appointmentId) async {
    try {
      final db = await LocalDatabase.database;
      
      final result = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [appointmentId],
      );
      
      if (result == 0) {
        return {
          'success': false,
          'message': 'الموعد غير موجود',
        };
      }
      
      return {
        'success': true,
        'message': 'تم حذف الموعد بنجاح',
      };

    } catch (e) {
      print('خطأ في حذف الموعد: $e');
      return {
        'success': false,
        'message': 'خطأ في الحذف: ${e.toString()}',
      };
    }
  }

  /// البحث عن مريض برقم الهاتف
  static Future<Patient?> getPatientByPhone(String phoneNumber) async {
    try {
      final db = await LocalDatabase.database;
      
      final patients = await db.query(
        _patientsTable,
        where: 'phone_number = ? AND is_active = ?',
        whereArgs: [phoneNumber, 1],
        limit: 1,
      );
      
      if (patients.isNotEmpty) {
        return Patient.fromJson(patients.first);
      }
      return null;

    } catch (e) {
      print('خطأ في البحث عن المريض: $e');
      return null;
    }
  }

  /// الحصول على الأوقات المحجوزة في تاريخ محدد
  static Future<List<String>> getBusyTimesForDate(DateTime date) async {
    try {
      final db = await LocalDatabase.database;
      
      final dateStr = date.toIso8601String().split('T')[0];
      
      final appointments = await db.query(
        _tableName,
        columns: ['appointment_time'],
        where: 'appointment_date = ? AND status IN (?, ?)',
        whereArgs: [dateStr, 'scheduled', 'completed'],
      );
      
      return appointments.map((app) => app['appointment_time'].toString()).toList();

    } catch (e) {
      print('خطأ في جلب الأوقات المحجوزة: $e');
      return [];
    }
  }

  /// الحصول على إحصائيات المواعيد
  static Future<Map<String, dynamic>> getAppointmentsStatistics() async {
    try {
      // إجمالي المواعيد
      final totalAppointments = await DatabaseHelper.countRecords(_tableName);
      
      // مواعيد اليوم
      final today = DateTime.now().toIso8601String().split('T')[0];
      final todayAppointments = await DatabaseHelper.countRecords(
        _tableName,
        where: 'appointment_date = ?',
        whereArgs: [today],
      );
      
      // المواعيد المؤكدة/مجدولة
      final scheduledAppointments = await DatabaseHelper.countRecords(
        _tableName,
        where: 'status = ?',
        whereArgs: ['scheduled'],
      );
      
      // المواعيد المكتملة
      final completedAppointments = await DatabaseHelper.countRecords(
        _tableName,
        where: 'status = ?',
        whereArgs: ['completed'],
      );
      
      // المواعيد الملغية
      final cancelledAppointments = await DatabaseHelper.countRecords(
        _tableName,
        where: 'status = ?',
        whereArgs: ['cancelled'],
      );
      
      // المواعيد التي لم يحضرها المريض
      final noShowAppointments = await DatabaseHelper.countRecords(
        _tableName,
        where: 'status = ?',
        whereArgs: ['no_show'],
      );
      
      return {
        'total_appointments': totalAppointments,
        'today_appointments': todayAppointments,
        'scheduled_appointments': scheduledAppointments,
        'completed_appointments': completedAppointments,
        'cancelled_appointments': cancelledAppointments,
        'no_show_appointments': noShowAppointments,
      };

    } catch (e) {
      print('خطأ في جلب إحصائيات المواعيد: $e');
      return {
        'total_appointments': 0,
        'today_appointments': 0,
        'scheduled_appointments': 0,
        'completed_appointments': 0,
        'cancelled_appointments': 0,
        'no_show_appointments': 0,
      };
    }
  }

  /// التحقق من تضارب الأوقات
  static Future<Map<String, dynamic>> _checkTimeConflict(String date, String time, String? excludeAppointmentId) async {
    try {
      final db = await LocalDatabase.database;
      
      String whereClause = 'a.appointment_date = ? AND a.appointment_time = ? AND a.status IN (?, ?)';
      List<dynamic> whereArgs = [date, time, 'scheduled', 'completed'];
      
      if (excludeAppointmentId != null) {
        whereClause += ' AND a.id != ?';
        whereArgs.add(excludeAppointmentId);
      }
      
      final conflictingAppointments = await db.rawQuery('''
        SELECT a.*, p.full_name as patient_name
        FROM $_tableName a
        LEFT JOIN $_patientsTable p ON a.patient_id = p.id
        WHERE $whereClause
        LIMIT 1
      ''', whereArgs);
      
      if (conflictingAppointments.isNotEmpty) {
        final conflict = conflictingAppointments.first;
        return {
          'available': false,
          'patient_name': conflict['patient_name'] ?? 'غير محدد',
          'status': conflict['status'],
        };
      }
      
      return {'available': true};

    } catch (e) {
      print('خطأ في فحص تضارب الأوقات: $e');
      return {'available': true}; // في حالة الخطأ، السماح بالحجز
    }
  }

  /// الحصول على قائمة الأطباء الفريدة
  static Future<List<String>> getUniqueDoctors() async {
    try {
      final db = await LocalDatabase.database;
      
      final doctors = await db.rawQuery('''
        SELECT DISTINCT doctor_name 
        FROM $_tableName 
        WHERE doctor_name IS NOT NULL AND doctor_name != ''
        ORDER BY doctor_name
      ''');
      
      return doctors.map((doc) => doc['doctor_name'].toString()).toList();

    } catch (e) {
      print('خطأ في جلب قائمة الأطباء: $e');
      return [];
    }
  }

  /// الحصول على أنواع الزيارات الفريدة
  static Future<List<String>> getUniqueVisitTypes() async {
    try {
      final db = await LocalDatabase.database;
      
      final visitTypes = await db.rawQuery('''
        SELECT DISTINCT appointment_type 
        FROM $_tableName 
        WHERE appointment_type IS NOT NULL AND appointment_type != ''
        ORDER BY appointment_type
      ''');
      
      return visitTypes.map((vt) => vt['appointment_type'].toString()).toList();

    } catch (e) {
      print('خطأ في جلب أنواع الزيارات: $e');
      return ['consultation', 'follow_up', 'check_up', 'emergency']; // قيم افتراضية
    }
  }
}
