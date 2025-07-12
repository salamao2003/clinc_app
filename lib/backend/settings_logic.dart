import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/clinic_settings.dart';

class SettingsService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // جلب إعدادات العيادة للمستخدم الحالي
  static Future<ClinicSettings?> getClinicSettings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('clinic_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) return null;
      
      return ClinicSettings.fromJson(response);
    } catch (e) {
      print('Error getting clinic settings: $e');
      return null;
    }
  }

  // حفظ أو تحديث إعدادات العيادة
  static Future<bool> saveClinicSettings(ClinicSettings settings) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // التحقق من وجود إعدادات سابقة
      final existing = await getClinicSettings();
      
      if (existing == null) {
        // إنشاء إعدادات جديدة
        await _supabase
            .from('clinic_settings')
            .insert({
              ...settings.toJson(),
              'user_id': user.id,
            });
        
        return true;
      } else {
        // تحديث الإعدادات الموجودة
        await _supabase
            .from('clinic_settings')
            .update(settings.toJson())
            .eq('user_id', user.id)
            .eq('id', existing.id);
        
        return true;
      }
    } catch (e) {
      print('Error saving clinic settings: $e');
      return false;
    }
  }

  // رفع شعار العيادة
  static Future<String?> uploadClinicLogo(File imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // قراءة وضغط الصورة
      final bytes = await imageFile.readAsBytes();
      final compressedBytes = await _compressImage(bytes);
      
      // إنشاء اسم ملف فريد
      final fileName = '${user.id}_logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // رفع الصورة
      await _supabase.storage
          .from('clinic-logos')
          .uploadBinary(fileName, compressedBytes);

      // الحصول على رابط الصورة العام
      final imageUrl = _supabase.storage
          .from('clinic-logos')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      print('Error uploading logo: $e');
      return null;
    }
  }

  // حذف شعار العيادة
  static Future<bool> deleteClinicLogo(String logoUrl) async {
    try {
      if (logoUrl.isEmpty) return true;

      // استخراج اسم الملف من URL
      final uri = Uri.parse(logoUrl);
      final fileName = uri.pathSegments.last;

      await _supabase.storage
          .from('clinic-logos')
          .remove([fileName]);

      return true;
    } catch (e) {
      print('Error deleting logo: $e');
      return false;
    }
  }

  // ضغط الصورة
  static Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;

      // تقليل الحجم إذا كان أكبر من 800x600
      img.Image resized = image;
      if (image.width > 800 || image.height > 600) {
        resized = img.copyResize(image, 
          width: image.width > image.height ? 800 : null,
          height: image.height > image.width ? 600 : null,
        );
      }

      // ضغط الجودة إلى 85%
      final compressedBytes = img.encodeJpg(resized, quality: 85);
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      print('Error compressing image: $e');
      return bytes;
    }
  }

  // تغيير كلمة المرور
  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // التحقق من كلمة المرور الحالية
      final signInResponse = await _supabase.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );

      if (signInResponse.user == null) {
        throw Exception('Current password is incorrect');
      }

      // تغيير كلمة المرور
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return response.user != null;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  // التحقق من صحة كلمة المرور
  static bool isPasswordValid(String password) {
    // على الأقل 8 أحرف، يحتوي على حرف وعدد
    return password.length >= 8 && 
           RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(password);
  }

  // إنشاء إعدادات افتراضية للمستخدم الجديد
  static Future<bool> createDefaultSettings(String clinicName) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final defaultSettings = ClinicSettings(
        id: '',
        userId: user.id,
        clinicName: clinicName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await saveClinicSettings(defaultSettings);
    } catch (e) {
      print('Error creating default settings: $e');
      return false;
    }
  }

  // التحقق من وجود إعدادات للمستخدم
  static Future<bool> hasClinicSettings() async {
    final settings = await getClinicSettings();
    return settings != null;
  }
}
