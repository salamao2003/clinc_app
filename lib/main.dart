// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'config/supabase_config.dart';
import 'screens/splash_screen.dart';
import 'providers/language_provider.dart';
import 'database/local_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة Supabase (مؤقت)
  await SupabaseConfig.initialize();
  
  // حذف قاعدة البيانات لحل مشكلة الجدول (مؤقتاً)
  try {
    await LocalDatabase.deleteDatabase();
    print('✅ تم حذف قاعدة البيانات القديمة');
  } catch (e) {
    print('🔄 قاعدة البيانات غير موجودة أو تم حذفها بالفعل');
  }
  
  runApp(const ClinicManagementApp());
}

class ClinicManagementApp extends StatelessWidget {
  const ClinicManagementApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LanguageProvider(),
      child: MaterialApp(
        title: 'نظام إدارة العيادة',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF2196F3),
          fontFamily: 'Roboto',
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        // يبدأ بـ Splash Screen
         home: const SplashScreen(),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
        ],
      ),
    );
  }
}