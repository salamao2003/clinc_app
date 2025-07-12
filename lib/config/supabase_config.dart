// lib/config/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // ⚠️ استبدل القيم دي بالقيم الحقيقية من Supabase Dashboard
  static const String supabaseUrl = 'https://ibfgpgkirquaycmkilnf.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImliZmdwZ2tpcnF1YXljbWtpbG5mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE2NTA3OTcsImV4cCI6MjA2NzIyNjc5N30.teJZzt6P8GJzmheFxBe9Qtl2wLO733oip3TEDa0T-cQ';
  
  static SupabaseClient get client => Supabase.instance.client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true, // لوضع التطوير فقط
    );
  }
}