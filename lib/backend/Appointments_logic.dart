import 'package:supabase_flutter/supabase_flutter.dart';

class Appointment {
  final String id;
  // final String? patientId; // احذف هذا السطر
  final String? doctorId;
   final String? doctorName;
  final String patientName;
  final String phoneNumber;
  final String visitType;
  final DateTime appointmentDate;
  final String appointmentTime;
  final int durationMinutes;
  final String status;
  final String? notes;

  Appointment({
    required this.id,
    // this.patientId,
    this.doctorId,
     this.doctorName,
    required this.patientName,
    required this.phoneNumber,
    required this.visitType,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.durationMinutes,
    required this.status,
    this.notes,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      // patientId: json['patient_id'], // احذف هذا السطر
      doctorId: json['doctor_id'],
      doctorName: json['doctor_name'],
      patientName: json['patient_name'],
      phoneNumber: json['phone_number'],
      visitType: json['visit_type'],
      appointmentDate: DateTime.parse(json['appointment_date']),
      appointmentTime: json['appointment_time'],
      durationMinutes: json['duration_minutes'],
      status: json['status'],
      notes: json['notes'],
    );
  }
}

class AppointmentsLogic {
  final _supabase = Supabase.instance.client;

  Future<List<Appointment>> fetchAppointments() async {
    final response = await _supabase.from('appointments').select();
    return (response as List)
        .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<PatientLite>> fetchPatientsLite() async {
    final supabase = Supabase.instance.client;
    final response =
        await supabase.from('patients').select('id, full_name, phone_number');
    return (response as List)
        .map((json) => PatientLite.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // جلب بيانات المريض من رقم التليفون
  Future<PatientInfo?> getPatientByPhone(String phoneNumber) async {
    try {
      final response = await _supabase
          .from('patients')
          .select('id, full_name, phone_number, email')
          .eq('phone_number', phoneNumber)
          .single();

      return PatientInfo.fromJson(response);
    } catch (e) {
      print('Error getting patient by phone: $e');
      return null;
    }
  }

  // التحقق من توفر الموعد
  Future<bool> isAppointmentTimeAvailable({
    required DateTime appointmentDate,
    required String appointmentTime,
    String? excludeAppointmentId, // لاستبعاد الموعد الحالي عند التعديل
  }) async {
    try {
      var query = _supabase
          .from('appointments')
          .select('id, patient_name, status')
          .eq('appointment_date', appointmentDate.toIso8601String().split('T')[0])
          .eq('appointment_time', appointmentTime)
          .or('status.eq.Confirmed,status.eq.Pending'); // فقط المواعيد المؤكدة أو في الانتظار

      // إذا كان هناك موعد مستبعد (في حالة التعديل)
      if (excludeAppointmentId != null) {
        query = query.neq('id', excludeAppointmentId);
      }

      final response = await query;
      
      return response.isEmpty; // إرجاع true إذا كان الموعد متاح
    } catch (e) {
      print('Error checking appointment availability: $e');
      return false; // في حالة الخطأ، نعتبر أن الموعد غير متاح للأمان
    }
  }

  // جلب تفاصيل الموعد المتضارب
  Future<Map<String, dynamic>?> getConflictingAppointment({
    required DateTime appointmentDate,
    required String appointmentTime,
    String? excludeAppointmentId,
  }) async {
    try {
      var query = _supabase
          .from('appointments')
          .select('id, patient_name, status, phone_number')
          .eq('appointment_date', appointmentDate.toIso8601String().split('T')[0])
          .eq('appointment_time', appointmentTime)
          .or('status.eq.Confirmed,status.eq.Pending');

      if (excludeAppointmentId != null) {
        query = query.neq('id', excludeAppointmentId);
      }

      final response = await query;
      
      if (response.isNotEmpty) {
        return response.first;
      }
      return null;
    } catch (e) {
      print('Error getting conflicting appointment: $e');
      return null;
    }
  }

  // جلب المواعيد المشغولة في يوم معين
  Future<List<String>> getBusyTimesForDate(DateTime date) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('appointment_time')
          .eq('appointment_date', date.toIso8601String().split('T')[0])
          .or('status.eq.Confirmed,status.eq.Pending');

      return (response as List)
          .map((item) => item['appointment_time'] as String)
          .toList();
    } catch (e) {
      print('Error getting busy times: $e');
      return [];
    }
  }
}

class PatientInfo {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;

  PatientInfo({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      id: json['id'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      email: json['email'] ?? '',
    );
  }
}

class PatientLite {
  final String id;
  final String fullName;
  final String phoneNumber;

  PatientLite({required this.id, required this.fullName, required this.phoneNumber});

  factory PatientLite.fromJson(Map<String, dynamic> json) {
    return PatientLite(
      id: json['id'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
    );
  }
}

extension AppointmentsLogicAdd on AppointmentsLogic {
  Future<void> addAppointment({
    required String phoneNumber,
    String? doctorName,
    required String visitType,
    required DateTime appointmentDate,
    required String appointmentTime,
    required int durationMinutes,
    required String status,
    String? notes,
  }) async {
    // جلب بيانات المريض من رقم التليفون
    final patient = await getPatientByPhone(phoneNumber);
    if (patient == null) {
      throw Exception('Patient not found with phone number: $phoneNumber');
    }

    // التحقق من توفر الموعد
    final isAvailable = await isAppointmentTimeAvailable(
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
    );

    if (!isAvailable) {
      // جلب تفاصيل الموعد المتضارب
      final conflictingAppointment = await getConflictingAppointment(
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
      );
      
      if (conflictingAppointment != null) {
        throw Exception('Appointment time already booked by ${conflictingAppointment['patient_name']} (${conflictingAppointment['status']})');
      } else {
        throw Exception('Appointment time is not available');
      }
    }

    await _supabase.from('appointments').insert({
      'patient_id': patient.id,
      'patient_name': patient.fullName,
      'phone_number': patient.phoneNumber,
      'doctor_name': doctorName,
      'visit_type': visitType,
      'appointment_date': appointmentDate.toIso8601String().split('T')[0],
      'appointment_time': appointmentTime,
      'duration_minutes': durationMinutes,
      'status': status,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}

extension AppointmentsLogicDelete on AppointmentsLogic {
  Future<void> deleteAppointment(String appointmentId) async {
    await _supabase.from('appointments').delete().eq('id', appointmentId);
  }
}

extension AppointmentsLogicUpdate on AppointmentsLogic {
  Future<void> updateAppointment({
    required String appointmentId,
    required String phoneNumber,
    String? doctorName,
    required String visitType,
    required DateTime appointmentDate,
    required String appointmentTime,
    required int durationMinutes,
    required String status,
    String? notes,
  }) async {
    // جلب بيانات المريض من رقم التليفون
    final patient = await getPatientByPhone(phoneNumber);
    if (patient == null) {
      throw Exception('Patient not found with phone number: $phoneNumber');
    }

    // التحقق من توفر الموعد (مع استبعاد الموعد الحالي)
    final isAvailable = await isAppointmentTimeAvailable(
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      excludeAppointmentId: appointmentId,
    );

    if (!isAvailable) {
      // جلب تفاصيل الموعد المتضارب
      final conflictingAppointment = await getConflictingAppointment(
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
        excludeAppointmentId: appointmentId,
      );
      
      if (conflictingAppointment != null) {
        throw Exception('Appointment time already booked by ${conflictingAppointment['patient_name']} (${conflictingAppointment['status']})');
      } else {
        throw Exception('Appointment time is not available');
      }
    }

    await _supabase.from('appointments').update({
      'patient_id': patient.id,
      'patient_name': patient.fullName,
      'phone_number': patient.phoneNumber,
      'doctor_name': doctorName,
      'visit_type': visitType,
      'appointment_date': appointmentDate.toIso8601String().split('T')[0],
      'appointment_time': appointmentTime,
      'duration_minutes': durationMinutes,
      'status': status,
      'notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', appointmentId);
  }
}