// lib/backend_local/auth_service_local.dart
import '../database/local_database.dart';
import '../database/database_helper.dart';

class AuthServiceLocal {
  static const String _userTable = 'user_profile';
  static const String _sessionsTable = 'user_sessions';
  
  /// فحص ما إذا كان النظام تم إعداده (يوجد مستخدم)
  Future<bool> isSystemSetup() async {
    return await isUserExists();
  }
  
  /// فحص ما إذا كان هناك مستخدم مسجل بالفعل
  static Future<bool> isUserExists() async {
    try {
      final count = await DatabaseHelper.countRecords(_userTable);
      return count > 0;
    } catch (e) {
      print('خطأ في فحص وجود المستخدم: $e');
      return false;
    }
  }

  /// إنشاء حساب مستخدم جديد (للتثبيت الأول)
  static Future<Map<String, dynamic>> createUser({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? profileImage,
  }) async {
    try {
      // فحص ما إذا كان هناك مستخدم موجود بالفعل
      if (await isUserExists()) {
        return {
          'success': false,
          'message': 'يوجد مستخدم مسجل بالفعل في النظام',
        };
      }

      final db = await LocalDatabase.database;
      
      // توليد salt وtش hash لكلمة المرور
      final salt = LocalDatabase.generateSalt();
      final passwordHash = LocalDatabase.generatePasswordHash(password, salt);
      
      // بيانات المستخدم
      final userData = DatabaseHelper.addTimestamp({
        'id': 'main_user',
        'full_name': DatabaseHelper.sanitizeString(fullName),
        'email': DatabaseHelper.sanitizeString(email)?.toLowerCase(),
        'phone': DatabaseHelper.sanitizeString(phone),
        'password_hash': passwordHash,
        'salt': salt,
        'role': 'doctor',
        'is_active': 1,
        'profile_image': profileImage,
      });

      await db.insert(_userTable, userData);

      return {
        'success': true,
        'message': 'تم إنشاء الحساب بنجاح',
        'user': {
          'id': 'main_user',
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'role': 'doctor',
        }
      };

    } catch (e) {
      print('خطأ في إنشاء المستخدم: $e');
      return {
        'success': false,
        'message': 'خطأ في إنشاء الحساب: ${e.toString()}',
      };
    }
  }

  /// تسجيل الدخول
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? deviceInfo,
  }) async {
    try {
      final db = await LocalDatabase.database;
      
      // البحث عن المستخدم
      final users = await db.query(
        _userTable,
        where: 'email = ? AND is_active = ?',
        whereArgs: [email.toLowerCase(), 1],
        limit: 1,
      );

      if (users.isEmpty) {
        return {
          'success': false,
          'message': 'البريد الإلكتروني غير مسجل',
        };
      }

      final user = users.first;
      final storedHash = user['password_hash'] as String;
      final salt = user['salt'] as String;

      // التحقق من كلمة المرور
      if (!LocalDatabase.verifyPassword(password, storedHash, salt)) {
        return {
          'success': false,
          'message': 'كلمة المرور غير صحيحة',
        };
      }

      // إنشاء جلسة جديدة
      final sessionToken = DatabaseHelper.generateId();
      final expiresAt = DateTime.now().add(Duration(days: 30)).toIso8601String();
      
      await db.insert(_sessionsTable, {
        'id': DatabaseHelper.generateId(),
        'user_id': 'main_user',
        'session_token': sessionToken,
        'expires_at': expiresAt,
        'created_at': DatabaseHelper.getCurrentTimestamp(),
        'device_info': deviceInfo ?? 'Unknown Device',
        'is_active': 1,
      });

      // تحديث آخر دخول
      await db.update(
        _userTable,
        DatabaseHelper.addTimestamp({
          'last_login': DatabaseHelper.getCurrentTimestamp(),
        }, isUpdate: true),
        where: 'id = ?',
        whereArgs: ['main_user'],
      );

      return {
        'success': true,
        'message': 'تم تسجيل الدخول بنجاح',
        'user': {
          'id': user['id'],
          'full_name': user['full_name'],
          'email': user['email'],
          'phone': user['phone'],
          'role': user['role'],
          'profile_image': user['profile_image'],
        },
        'session_token': sessionToken,
        'expires_at': expiresAt,
      };

    } catch (e) {
      print('خطأ في تسجيل الدخول: $e');
      return {
        'success': false,
        'message': 'خطأ في تسجيل الدخول: ${e.toString()}',
      };
    }
  }

  /// تسجيل الخروج
  static Future<Map<String, dynamic>> logout(String sessionToken) async {
    try {
      final db = await LocalDatabase.database;
      
      // إلغاء تفعيل الجلسة
      await db.update(
        _sessionsTable,
        {'is_active': 0, 'updated_at': DatabaseHelper.getCurrentTimestamp()},
        where: 'session_token = ?',
        whereArgs: [sessionToken],
      );

      return {
        'success': true,
        'message': 'تم تسجيل الخروج بنجاح',
      };

    } catch (e) {
      print('خطأ في تسجيل الخروج: $e');
      return {
        'success': false,
        'message': 'خطأ في تسجيل الخروج: ${e.toString()}',
      };
    }
  }

  /// التحقق من صحة الجلسة
  static Future<Map<String, dynamic>> validateSession(String sessionToken) async {
    try {
      final db = await LocalDatabase.database;
      
      final sessions = await db.rawQuery('''
        SELECT s.*, u.full_name, u.email, u.phone, u.role, u.profile_image
        FROM $_sessionsTable s
        JOIN $_userTable u ON s.user_id = u.id
        WHERE s.session_token = ? AND s.is_active = 1 AND s.expires_at > ?
      ''', [sessionToken, DatabaseHelper.getCurrentTimestamp()]);

      if (sessions.isEmpty) {
        return {
          'success': false,
          'message': 'الجلسة منتهية الصلاحية أو غير صحيحة',
        };
      }

      final session = sessions.first;
      
      return {
        'success': true,
        'user': {
          'id': session['user_id'],
          'full_name': session['full_name'],
          'email': session['email'],
          'phone': session['phone'],
          'role': session['role'],
          'profile_image': session['profile_image'],
        },
        'session': {
          'token': session['session_token'],
          'expires_at': session['expires_at'],
        }
      };

    } catch (e) {
      print('خطأ في التحقق من الجلسة: $e');
      return {
        'success': false,
        'message': 'خطأ في التحقق من الجلسة: ${e.toString()}',
      };
    }
  }

  /// تغيير كلمة المرور
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String sessionToken,
  }) async {
    try {
      // التحقق من الجلسة أولاً
      final sessionResult = await validateSession(sessionToken);
      if (!sessionResult['success']) {
        return sessionResult;
      }

      final db = await LocalDatabase.database;
      
      // الحصول على بيانات المستخدم الحالية
      final users = await db.query(
        _userTable,
        where: 'id = ?',
        whereArgs: ['main_user'],
        limit: 1,
      );

      if (users.isEmpty) {
        return {
          'success': false,
          'message': 'المستخدم غير موجود',
        };
      }

      final user = users.first;
      final storedHash = user['password_hash'] as String;
      final salt = user['salt'] as String;

      // التحقق من كلمة المرور الحالية
      if (!LocalDatabase.verifyPassword(currentPassword, storedHash, salt)) {
        return {
          'success': false,
          'message': 'كلمة المرور الحالية غير صحيحة',
        };
      }

      // توليد hash جديد لكلمة المرور الجديدة
      final newSalt = LocalDatabase.generateSalt();
      final newPasswordHash = LocalDatabase.generatePasswordHash(newPassword, newSalt);

      // تحديث كلمة المرور
      await db.update(
        _userTable,
        DatabaseHelper.addTimestamp({
          'password_hash': newPasswordHash,
          'salt': newSalt,
        }, isUpdate: true),
        where: 'id = ?',
        whereArgs: ['main_user'],
      );

      // إلغاء جميع الجلسات الأخرى (عدا الجلسة الحالية)
      await db.update(
        _sessionsTable,
        {'is_active': 0, 'updated_at': DatabaseHelper.getCurrentTimestamp()},
        where: 'user_id = ? AND session_token != ?',
        whereArgs: ['main_user', sessionToken],
      );

      return {
        'success': true,
        'message': 'تم تغيير كلمة المرور بنجاح',
      };

    } catch (e) {
      print('خطأ في تغيير كلمة المرور: $e');
      return {
        'success': false,
        'message': 'خطأ في تغيير كلمة المرور: ${e.toString()}',
      };
    }
  }

  /// تحديث بيانات المستخدم
  static Future<Map<String, dynamic>> updateProfile({
    required String sessionToken,
    String? fullName,
    String? phone,
    String? profileImage,
  }) async {
    try {
      // التحقق من الجلسة أولاً
      final sessionResult = await validateSession(sessionToken);
      if (!sessionResult['success']) {
        return sessionResult;
      }

      final db = await LocalDatabase.database;
      
      Map<String, dynamic> updateData = {};
      
      if (fullName != null) {
        updateData['full_name'] = DatabaseHelper.sanitizeString(fullName);
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

      await db.update(
        _userTable,
        updateData,
        where: 'id = ?',
        whereArgs: ['main_user'],
      );

      return {
        'success': true,
        'message': 'تم تحديث البيانات بنجاح',
      };

    } catch (e) {
      print('خطأ في تحديث البيانات: $e');
      return {
        'success': false,
        'message': 'خطأ في تحديث البيانات: ${e.toString()}',
      };
    }
  }

  /// الحصول على بيانات المستخدم
  static Future<Map<String, dynamic>> getUserProfile(String sessionToken) async {
    try {
      final sessionResult = await validateSession(sessionToken);
      if (!sessionResult['success']) {
        return sessionResult;
      }

      return {
        'success': true,
        'user': sessionResult['user'],
      };

    } catch (e) {
      print('خطأ في جلب بيانات المستخدم: $e');
      return {
        'success': false,
        'message': 'خطأ في جلب البيانات: ${e.toString()}',
      };
    }
  }

  /// إعادة تعيين النظام (حذف جميع البيانات)
  static Future<Map<String, dynamic>> resetSystem() async {
    try {
      await LocalDatabase.deleteDatabase();
      
      return {
        'success': true,
        'message': 'تم إعادة تعيين النظام بنجاح',
      };

    } catch (e) {
      print('خطأ في إعادة تعيين النظام: $e');
      return {
        'success': false,
        'message': 'خطأ في إعادة التعيين: ${e.toString()}',
      };
    }
  }

  /// الحصول على جميع الجلسات النشطة
  static Future<List<Map<String, dynamic>>> getActiveSessions() async {
    try {
      final db = await LocalDatabase.database;
      
      final sessions = await db.query(
        _sessionsTable,
        where: 'user_id = ? AND is_active = 1 AND expires_at > ?',
        whereArgs: ['main_user', DatabaseHelper.getCurrentTimestamp()],
        orderBy: 'created_at DESC',
      );

      return sessions;

    } catch (e) {
      print('خطأ في جلب الجلسات: $e');
      return [];
    }
  }

  /// إلغاء جلسة معينة
  static Future<bool> revokeSession(String sessionToken) async {
    try {
      final db = await LocalDatabase.database;
      
      await db.update(
        _sessionsTable,
        {'is_active': 0, 'updated_at': DatabaseHelper.getCurrentTimestamp()},
        where: 'session_token = ?',
        whereArgs: [sessionToken],
      );

      return true;

    } catch (e) {
      print('خطأ في إلغاء الجلسة: $e');
      return false;
    }
  }
}
