// backend/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Supabase client
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Current user info
  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  
  // Get current user email
  String? get currentUserEmail => currentUser?.email;
  
  // Get current user ID
  String? get currentUserId => currentUser?.id;

  /// تسجيل الدخول
  Future<bool> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        print('تم تسجيل الدخول بنجاح: ${response.user!.email}');
        return true;
      }
      
      return false;
    } on AuthException catch (e) {
      print('خطأ في تسجيل الدخول: ${e.message}');
      throw Exception(_getArabicErrorMessage(e.message));
    } catch (e) {
      print('خطأ عام في تسجيل الدخول: $e');
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  /// إنشاء حساب جديد
  Future<bool> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      // إنشاء المستخدم في Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'phone': phone.trim(),
        },
      );

      if (response.user != null) {
        print('تم إنشاء الحساب بنجاح: ${response.user!.email}');
        
        // إضافة بيانات إضافية للملف الشخصي
        await _createUserProfile(
          userId: response.user!.id,
          fullName: fullName.trim(),
          phone: phone.trim(),
        );
        
        return true;
      }
      
      return false;
    } on AuthException catch (e) {
      print('خطأ في إنشاء الحساب: ${e.message}');
      throw Exception(_getArabicErrorMessage(e.message));
    } catch (e) {
      print('خطأ عام في إنشاء الحساب: $e');
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  /// إنشاء ملف شخصي للمستخدم
  Future<void> _createUserProfile({
    required String userId,
    required String fullName,
    required String phone,
  }) async {
    try {
      await _supabase.from('profiles').insert({
        'id': userId,
        'full_name': fullName,
        'phone': phone,
        'role': 'user',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      print('تم إنشاء الملف الشخصي بنجاح');
    } catch (e) {
      print('خطأ في إنشاء الملف الشخصي: $e');
      // لا نرمي خطأ هنا لأن المستخدم تم إنشاؤه بنجاح
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      print('تم تسجيل الخروج بنجاح');
    } catch (e) {
      print('خطأ في تسجيل الخروج: $e');
      throw Exception('حدث خطأ أثناء تسجيل الخروج');
    }
  }

  /// التحقق من حالة المصادقة
  Future<bool> isAuthenticated() async {
    return currentUser != null;
  }

  /// الحصول على الملف الشخصي للمستخدم
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser == null) return null;

      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', currentUser!.id)
          .single();

      return response;
    } catch (e) {
      print('خطأ في جلب الملف الشخصي: $e');
      
      // إرجاع بيانات أساسية من Auth إذا لم يوجد profile
      return {
        'id': currentUser?.id,
        'full_name': currentUser?.userMetadata?['full_name'] ?? 'مستخدم',
        'email': currentUser?.email,
        'phone': currentUser?.userMetadata?['phone'] ?? '',
        'role': 'user',
      };
    }
  }

  /// إعادة تعيين كلمة المرور
  Future<bool> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
      return true;
    } on AuthException catch (e) {
      print('خطأ في إعادة تعيين كلمة المرور: ${e.message}');
      throw Exception(_getArabicErrorMessage(e.message));
    } catch (e) {
      print('خطأ عام في إعادة تعيين كلمة المرور: $e');
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  /// تحديث كلمة المرور
  Future<bool> changePassword({
    required String newPassword,
  }) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return true;
    } on AuthException catch (e) {
      print('خطأ في تحديث كلمة المرور: ${e.message}');
      throw Exception(_getArabicErrorMessage(e.message));
    } catch (e) {
      print('خطأ عام في تحديث كلمة المرور: $e');
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  /// تحديث الملف الشخصي
  Future<bool> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // تحديث البيانات في جدول profiles
      await _supabase.from('profiles').update({
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentUser!.id);

      // تحديث البيانات في Auth metadata
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': fullName.trim(),
            'phone': phone.trim(),
          },
        ),
      );

      return true;
    } catch (e) {
      print('خطأ في تحديث الملف الشخصي: $e');
      throw Exception('حدث خطأ في تحديث البيانات');
    }
  }

  /// التحقق من صحة البريد الإلكتروني
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// التحقق من قوة كلمة المرور
  bool isValidPassword(String password) {
    // على الأقل 8 أحرف مع حرف كبير وصغير ورقم
    if (password.length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    if (!RegExp(r'[a-z]').hasMatch(password)) return false;
    if (!RegExp(r'\d').hasMatch(password)) return false;
    return true;
  }

  /// الاستماع لتغييرات حالة المصادقة
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// ترجمة رسائل الخطأ للعربية
  String _getArabicErrorMessage(String? errorMessage) {
    if (errorMessage == null) return 'حدث خطأ غير معروف';
    
    final message = errorMessage.toLowerCase();
    
    if (message.contains('invalid login credentials') || 
        message.contains('invalid email or password')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
    
    if (message.contains('user already registered') ||
        message.contains('email already exists')) {
      return 'هذا البريد الإلكتروني مسجل مسبقاً';
    }
    
    if (message.contains('password should be at least')) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    
    if (message.contains('invalid email')) {
      return 'البريد الإلكتروني غير صالح';
    }
    
    if (message.contains('email not confirmed')) {
      return 'يرجى تأكيد البريد الإلكتروني أولاً';
    }
    
    if (message.contains('too many requests')) {
      return 'محاولات كثيرة جداً، حاول مرة أخرى لاحقاً';
    }
    
    if (message.contains('network')) {
      return 'خطأ في الاتصال بالشبكة';
    }
    
    return 'حدث خطأ: $errorMessage';
  }

  /// التحقق من توفر البريد الإلكتروني
  Future<bool> emailExists(String email) async {
    try {
      // لا توجد طريقة مباشرة في Supabase للتحقق من وجود البريد
      // سنعتمد على رسالة الخطأ عند المحاولة
      return false;
    } catch (e) {
      print('خطأ في التحقق من البريد الإلكتروني: $e');
      return false;
    }
  }
}