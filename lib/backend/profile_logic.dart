// backend/profile_logic.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/profile_model.dart';
import 'auth_service.dart';

class ProfileService {
  // Singleton pattern
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  // Supabase client
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // اسم الجدول في قاعدة البيانات
  static const String _tableName = 'profiles';

  /// جلب بيانات المستخدم الحالي
  Future<ProfileModel?> getCurrentUserProfile() async {
    try {
      final currentUserId = AuthService().currentUserId;
      
      if (currentUserId == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      final response = await _supabase
          .from(_tableName)
          .select('*')
          .eq('id', currentUserId)
          .single();

      print('تم جلب بيانات المستخدم بنجاح');
      return ProfileModel.fromJson(response);
      
    } on PostgrestException catch (e) {
      print('خطأ في قاعدة البيانات: ${e.message}');
      if (e.code == 'PGRST116') {
        throw Exception('لم يتم العثور على بيانات المستخدم');
      }
      throw Exception('فشل في جلب بيانات المستخدم');
    } catch (e) {
      print('خطأ في جلب بيانات المستخدم: $e');
      throw Exception('حدث خطأ أثناء جلب بيانات المستخدم');
    }
  }

  /// تحديث بيانات المستخدم
  Future<ProfileModel> updateUserProfile({
    required String fullName,
    required String phone,
    String? role,
  }) async {
    try {
      final currentUserId = AuthService().currentUserId;
      
      if (currentUserId == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // التحقق من صحة البيانات
      if (fullName.trim().isEmpty) {
        throw Exception('الاسم الكامل مطلوب');
      }
      
      if (phone.trim().isEmpty) {
        throw Exception('رقم الهاتف مطلوب');
      }

      // تحضير البيانات للتحديث
      final updateData = {
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // إضافة الدور إذا تم توفيره
      if (role != null && role.trim().isNotEmpty) {
        updateData['role'] = role.trim();
      }

      final response = await _supabase
          .from(_tableName)
          .update(updateData)
          .eq('id', currentUserId)
          .select()
          .single();

      print('تم تحديث بيانات المستخدم بنجاح');
      return ProfileModel.fromJson(response);
      
    } on PostgrestException catch (e) {
      print('خطأ في قاعدة البيانات: ${e.message}');
      throw Exception('فشل في تحديث بيانات المستخدم');
    } catch (e) {
      print('خطأ في تحديث بيانات المستخدم: $e');
      if (e.toString().contains('الاسم الكامل مطلوب') || 
          e.toString().contains('رقم الهاتف مطلوب')) {
        rethrow;
      }
      throw Exception('حدث خطأ أثناء تحديث البيانات');
    }
  }

  /// إنشاء profile جديد للمستخدم (يستخدم عند التسجيل)
  Future<ProfileModel> createUserProfile({
    required String userId,
    required String fullName,
    required String phone,
    String role = 'doctor', // القيمة الافتراضية
  }) async {
    try {
      // التحقق من صحة البيانات
      if (fullName.trim().isEmpty) {
        throw Exception('الاسم الكامل مطلوب');
      }
      
      if (phone.trim().isEmpty) {
        throw Exception('رقم الهاتف مطلوب');
      }

      final profileData = {
        'id': userId,
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'role': role.trim(),
      };

      final response = await _supabase
          .from(_tableName)
          .insert(profileData)
          .select()
          .single();

      print('تم إنشاء profile المستخدم بنجاح');
      return ProfileModel.fromJson(response);
      
    } on PostgrestException catch (e) {
      print('خطأ في قاعدة البيانات: ${e.message}');
      if (e.code == '23505') { // Unique constraint violation
        throw Exception('المستخدم موجود بالفعل');
      }
      throw Exception('فشل في إنشاء بيانات المستخدم');
    } catch (e) {
      print('خطأ في إنشاء profile المستخدم: $e');
      if (e.toString().contains('الاسم الكامل مطلوب') || 
          e.toString().contains('رقم الهاتف مطلوب')) {
        rethrow;
      }
      throw Exception('حدث خطأ أثناء إنشاء البيانات');
    }
  }

  /// التحقق من وجود profile للمستخدم
  Future<bool> doesUserProfileExist(String userId) async {
    try {
      await _supabase
          .from(_tableName)
          .select('id')
          .eq('id', userId)
          .single();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// حذف بيانات المستخدم (في حالة حذف الحساب)
  Future<void> deleteUserProfile() async {
    try {
      final currentUserId = AuthService().currentUserId;
      
      if (currentUserId == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', currentUserId);

      print('تم حذف بيانات المستخدم بنجاح');
      
    } on PostgrestException catch (e) {
      print('خطأ في قاعدة البيانات: ${e.message}');
      throw Exception('فشل في حذف بيانات المستخدم');
    } catch (e) {
      print('خطأ في حذف بيانات المستخدم: $e');
      throw Exception('حدث خطأ أثناء حذف البيانات');
    }
  }
}
