// lib/database/test_database.dart
import 'package:sqflite/sqflite.dart';
import 'local_database.dart';
import 'database_helper.dart';

class DatabaseTest {
  /// اختبار إنشاء قاعدة البيانات
  static Future<void> testDatabaseCreation() async {
    try {
      print('🧪 بدء اختبار قاعدة البيانات...');
      
      // 1. إنشاء قاعدة البيانات
      await LocalDatabase.database;
      print('✅ تم إنشاء قاعدة البيانات بنجاح');
      
      // 2. فحص معلومات قاعدة البيانات
      final dbInfo = await LocalDatabase.getDatabaseInfo();
      print('📊 معلومات قاعدة البيانات: $dbInfo');
      
      // 3. فحص سلامة قاعدة البيانات
      final isHealthy = await DatabaseHelper.checkDatabaseIntegrity();
      print('🏥 سلامة قاعدة البيانات: ${isHealthy ? "سليمة" : "بها مشاكل"}');
      
      // 4. الحصول على الإحصائيات
      final stats = await DatabaseHelper.getDatabaseStatistics();
      print('📈 إحصائيات قاعدة البيانات: $stats');
      
      // 5. اختبار إدراج بيانات تجريبية
      await testInsertSampleData();
      
      // 6. الحصول على الإحصائيات بعد الإدراج
      final newStats = await DatabaseHelper.getDatabaseStatistics();
      print('📈 إحصائيات جديدة: $newStats');
      
      print('🎉 تم اجتياز جميع الاختبارات بنجاح!');
      
    } catch (e) {
      print('❌ خطأ في اختبار قاعدة البيانات: $e');
    }
  }

  /// اختبار إدراج بيانات تجريبية
  static Future<void> testInsertSampleData() async {
    try {
      final db = await LocalDatabase.database;
      
      // إدراج مستخدم تجريبي
      final salt = LocalDatabase.generateSalt();
      final passwordHash = LocalDatabase.generatePasswordHash('123456', salt);
      
      await db.insert('user_profile', {
        'id': 'main_user',
        'full_name': 'د. أحمد محمد',
        'email': 'doctor@clinic.com',
        'phone': '01234567890',
        'password_hash': passwordHash,
        'salt': salt,
        'role': 'doctor',
        'created_at': DatabaseHelper.getCurrentTimestamp(),
        'updated_at': DatabaseHelper.getCurrentTimestamp(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      
      print('✅ تم إدراج بيانات المستخدم');
      
      // إدراج مريض تجريبي
      final patientId = DatabaseHelper.generateId();
      await db.insert('patients', DatabaseHelper.addTimestamp({
        'id': patientId,
        'full_name': 'محمد أحمد علي',
        'phone_number': '01111111111',
        'email': 'patient@example.com',
        'gender': 'male',
        'date_of_birth': '1990-01-01',
        'address': 'القاهرة، مصر',
        'medical_history': 'لا توجد أمراض مزمنة',
      }));
      
      print('✅ تم إدراج بيانات المريض');
      
      // إدراج موعد تجريبي
      final appointmentId = DatabaseHelper.generateId();
      await db.insert('appointments', DatabaseHelper.addTimestamp({
        'id': appointmentId,
        'patient_id': patientId,
        'doctor_name': 'د. أحمد محمد',
        'appointment_date': DateTime.now().toIso8601String().split('T')[0],
        'appointment_time': '10:00',
        'status': 'scheduled',
        'notes': 'موعد متابعة',
      }));
      
      print('✅ تم إدراج بيانات الموعد');
      
    } catch (e) {
      print('❌ خطأ في إدراج البيانات التجريبية: $e');
    }
  }

  /// اختبار تحديث البيانات
  static Future<void> testUpdateData() async {
    try {
      final db = await LocalDatabase.database;
      
      // تحديث إعدادات العيادة
      await db.update('clinic_settings', DatabaseHelper.addTimestamp({
        'clinic_name': 'عيادة د. أحمد محمد',
        'address': 'شارع الطب، القاهرة',
        'phone': '01234567890',
        'email': 'info@clinic.com',
      }, isUpdate: true), where: 'id = ?', whereArgs: ['main_clinic']);
      
      print('✅ تم تحديث إعدادات العيادة');
      
    } catch (e) {
      print('❌ خطأ في تحديث البيانات: $e');
    }
  }

  /// اختبار البحث في البيانات
  static Future<void> testSearchData() async {
    try {
      final db = await LocalDatabase.database;
      
      // البحث في المرضى
      final patients = await db.query(
        'patients',
        where: 'full_name LIKE ? OR phone_number LIKE ?',
        whereArgs: ['%محمد%', '%111%'],
      );
      
      print('🔍 نتائج البحث في المرضى: ${patients.length} مريض');
      
      // البحث في المواعيد
      final appointments = await db.query(
        'appointments',
        where: 'appointment_date = ?',
        whereArgs: [DateTime.now().toIso8601String().split('T')[0]],
      );
      
      print('🔍 مواعيد اليوم: ${appointments.length} موعد');
      
    } catch (e) {
      print('❌ خطأ في البحث: $e');
    }
  }

  /// تشغيل جميع الاختبارات
  static Future<void> runAllTests() async {
    print('🚀 بدء جميع اختبارات قاعدة البيانات...\n');
    
    await testDatabaseCreation();
    print('');
    
    await testUpdateData();
    print('');
    
    await testSearchData();
    print('');
    
    // تنظيف البيانات
    await DatabaseHelper.cleanupOldData();
    
    // ضغط قاعدة البيانات
    await DatabaseHelper.vacuumDatabase();
    
    print('🏁 انتهاء جميع الاختبارات');
  }
}
