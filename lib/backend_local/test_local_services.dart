// lib/backend_local/test_local_services.dart
import 'auth_service_local.dart';
import 'profile_logic_local.dart';
import 'patient_service_local.dart';
import '../models/patient_model.dart';
import '../database/database_helper.dart';

class TestLocalServices {
  /// اختبار شامل للخدمات المحلية
  static Future<void> runAllTests() async {
    print('🧪 بدء اختبار الخدمات المحلية...\n');
    
    await testAuthService();
    print('');
    
    await testProfileLogic();
    print('');
    
    await testPatientService();
    print('');
    
    print('🎉 انتهاء جميع اختبارات الخدمات المحلية!');
  }

  /// اختبار نظام المصادقة
  static Future<void> testAuthService() async {
    print('🔐 اختبار نظام المصادقة...');
    
    try {
      // 1. فحص عدم وجود مستخدم
      final userExists = await AuthServiceLocal.isUserExists();
      print('👤 هل يوجد مستخدم: $userExists');
      
      // 2. إنشاء مستخدم جديد
      if (!userExists) {
        final createResult = await AuthServiceLocal.createUser(
          fullName: 'د. أحمد محمد',
          email: 'doctor@clinic.com',
          password: '123456',
          phone: '01234567890',
        );
        
        if (createResult['success']) {
          print('✅ تم إنشاء المستخدم: ${createResult['message']}');
        } else {
          print('❌ فشل إنشاء المستخدم: ${createResult['message']}');
          return;
        }
      }
      
      // 3. تسجيل الدخول
      final loginResult = await AuthServiceLocal.login(
        email: 'doctor@clinic.com',
        password: '123456',
        deviceInfo: 'Test Device',
      );
      
      if (loginResult['success']) {
        print('✅ تم تسجيل الدخول: ${loginResult['message']}');
        final sessionToken = loginResult['session_token'];
        
        // 4. التحقق من الجلسة
        final sessionCheck = await AuthServiceLocal.validateSession(sessionToken);
        if (sessionCheck['success']) {
          print('✅ الجلسة صحيحة: ${sessionCheck['user']['full_name']}');
        } else {
          print('❌ الجلسة غير صحيحة');
        }
        
        // 5. تحديث البيانات
        final updateResult = await AuthServiceLocal.updateProfile(
          sessionToken: sessionToken,
          phone: '01111111111',
        );
        
        if (updateResult['success']) {
          print('✅ تم تحديث البيانات: ${updateResult['message']}');
        }
        
      } else {
        print('❌ فشل تسجيل الدخول: ${loginResult['message']}');
      }
      
    } catch (e) {
      print('❌ خطأ في اختبار المصادقة: $e');
    }
  }

  /// اختبار منطق الملف الشخصي
  static Future<void> testProfileLogic() async {
    print('👨‍⚕️ اختبار منطق الملف الشخصي...');
    
    try {
      // 1. تحديث إعدادات العيادة
      final updateClinic = await ProfileLogicLocal.updateClinicSettings(
        clinicName: 'عيادة د. أحمد محمد',
        address: 'شارع الطب، القاهرة',
        phone: '01234567890',
        email: 'info@clinic.com',
      );
      
      if (updateClinic['success']) {
        print('✅ تم تحديث إعدادات العيادة: ${updateClinic['message']}');
      }
      
      // 2. جلب الإعدادات
      final clinicSettings = await ProfileLogicLocal.getClinicSettings();
      if (clinicSettings['success']) {
        final clinic = clinicSettings['clinic'];
        print('🏥 اسم العيادة: ${clinic['clinic_name']}');
        print('📍 العنوان: ${clinic['address']}');
      }
      
      // 3. الحصول على الإحصائيات
      final stats = await ProfileLogicLocal.getDashboardStats();
      if (stats['success']) {
        final statistics = stats['stats'];
        print('📊 إحصائيات سريعة:');
        print('   - المرضى: ${statistics['total_patients']}');
        print('   - المواعيد: ${statistics['total_appointments']}');
        print('   - الوصفات: ${statistics['total_prescriptions']}');
      }
      
      // 4. فحص حالة العيادة
      final clinicStatus = await ProfileLogicLocal.isClinicOpenNow();
      if (clinicStatus['success']) {
        print('🕐 حالة العيادة: ${clinicStatus['message']}');
      }
      
    } catch (e) {
      print('❌ خطأ في اختبار الملف الشخصي: $e');
    }
  }

  /// اختبار خدمة المرضى
  static Future<void> testPatientService() async {
    print('🏥 اختبار خدمة المرضى...');
    
    try {
      // 1. إضافة مريض تجريبي
      final testPatient = Patient(
        id: DatabaseHelper.generateId(),
        fullName: 'محمد أحمد علي',
        gender: 'male',
        phoneNumber: '01111111111',
        email: 'patient@example.com',
        dateOfBirth: DateTime(1990, 1, 1),
        address: 'القاهرة، مصر',
        emergencyContact: 'فاطمة أحمد',
        emergencyPhone: '01222222222',
        medicalHistory: 'لا توجد أمراض مزمنة',
        allergies: 'لا توجد حساسية',
        bloodType: 'O+',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final addResult = await PatientServiceLocal.addPatient(testPatient);
      if (addResult['success']) {
        print('✅ تم إضافة المريض: ${addResult['message']}');
        final patientId = addResult['patient_id'];
        
        // 2. البحث عن المريض
        final foundPatient = await PatientServiceLocal.getPatientById(patientId);
        if (foundPatient != null) {
          print('👤 تم العثور على المريض: ${foundPatient.displayName}');
          print('📅 العمر: ${foundPatient.age} سنة');
          print('☎️ الهاتف: ${foundPatient.phoneNumber}');
        }
        
        // 3. تحديث بيانات المريض
        final updatedPatient = foundPatient!.copyWith(
          notes: 'مريض متعاون جداً',
          updatedAt: DateTime.now(),
        );
        
        final updateResult = await PatientServiceLocal.updatePatient(updatedPatient);
        if (updateResult['success']) {
          print('✅ تم تحديث المريض: ${updateResult['message']}');
        }
        
        // 4. البحث في المرضى
        final searchResults = await PatientServiceLocal.searchPatients('محمد');
        print('🔍 نتائج البحث: ${searchResults.length} مريض');
        
        // 5. الحصول على إحصائيات المرضى
        final patientStats = await PatientServiceLocal.getPatientsStatistics();
        print('📈 إحصائيات المرضى:');
        print('   - إجمالي المرضى النشطين: ${patientStats['total_active']}');
        print('   - المرضى الذكور: ${patientStats['male_patients']}');
        print('   - المرضى الإناث: ${patientStats['female_patients']}');
        
      } else {
        print('❌ فشل إضافة المريض: ${addResult['message']}');
      }
      
      // 6. عد المرضى
      final patientsCount = await PatientServiceLocal.getPatientsCount();
      print('👥 إجمالي المرضى: $patientsCount');
      
    } catch (e) {
      print('❌ خطأ في اختبار المرضى: $e');
    }
  }

  /// اختبار إضافة بيانات تجريبية أكثر
  static Future<void> addSampleData() async {
    print('📝 إضافة بيانات تجريبية...');
    
    try {
      // إضافة عدة مرضى
      final samplePatients = [
        {
          'name': 'فاطمة محمد',
          'gender': 'female',
          'phone': '01222222222',
          'email': 'fatma@example.com',
          'birth': DateTime(1985, 6, 15),
        },
        {
          'name': 'أحمد علي',
          'gender': 'male', 
          'phone': '01333333333',
          'email': 'ahmed@example.com',
          'birth': DateTime(1992, 3, 20),
        },
        {
          'name': 'نورا حسن',
          'gender': 'female',
          'phone': '01444444444',
          'email': 'nora@example.com',
          'birth': DateTime(1988, 12, 10),
        },
      ];

      for (var patientData in samplePatients) {
        final patient = Patient(
          id: DatabaseHelper.generateId(),
          fullName: patientData['name'] as String,
          gender: patientData['gender'] as String,
          phoneNumber: patientData['phone'] as String,
          email: patientData['email'] as String,
          dateOfBirth: patientData['birth'] as DateTime,
          address: 'القاهرة، مصر',
          emergencyContact: 'جهة اتصال الطوارئ',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final result = await PatientServiceLocal.addPatient(patient);
        if (result['success']) {
          print('✅ تم إضافة ${patient.fullName}');
        }
      }
      
      // إحصائيات محدثة
      final finalStats = await PatientServiceLocal.getPatientsStatistics();
      print('📊 إحصائيات نهائية:');
      print('   - إجمالي المرضى: ${finalStats['total_active']}');
      print('   - الذكور: ${finalStats['male_patients']}');
      print('   - الإناث: ${finalStats['female_patients']}');
      
    } catch (e) {
      print('❌ خطأ في إضافة البيانات التجريبية: $e');
    }
  }
}
