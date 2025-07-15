// lib/database/local_database.dart
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

class LocalDatabase {
  static Database? _database;
  static const String dbName = 'clinic_app.db';
  static const int dbVersion = 1;

  /// تهيئة قاعدة البيانات للـ Desktop platforms
  static void _initializeFfi() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  // Singleton pattern للـ database
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _initializeFfi(); // تهيئة FFI للـ Desktop
    _database = await _initDatabase();
    return _database!;
  }

  /// إنشاء قاعدة البيانات وتهيئتها
  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), dbName);
    
    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  /// إنشاء الجداول عند إنشاء قاعدة البيانات لأول مرة
  static Future<void> _onCreate(Database db, int version) async {
    await _createUserTables(db);
    await _createClinicTables(db);
    await _createIndexes(db);
    await _insertDefaultData(db);
    
    print('✅ تم إنشاء قاعدة البيانات المحلية بنجاح - الإصدار $version');
  }

  /// تحديث قاعدة البيانات عند وجود إصدار أحدث
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 تحديث قاعدة البيانات من الإصدار $oldVersion إلى $newVersion');
    
    // مثال للتحديثات المستقبلية
    if (oldVersion < 2) {
      // إضافة جداول جديدة أو تعديل موجودة
      // await db.execute('ALTER TABLE patients ADD COLUMN blood_type TEXT');
    }
    
    if (oldVersion < 3) {
      // تحديثات أخرى
    }
  }

  /// تنفيذ عند فتح قاعدة البيانات
  static Future<void> _onOpen(Database db) async {
    // تفعيل Foreign Keys
    await db.execute('PRAGMA foreign_keys = ON');
    print('🔓 تم فتح قاعدة البيانات المحلية');
  }

  /// إنشاء جداول المستخدمين والمصادقة
  static Future<void> _createUserTables(Database db) async {
    // جدول المستخدم الرئيسي (Single User)
    await db.execute('''
      CREATE TABLE user_profile (
        id TEXT PRIMARY KEY DEFAULT 'main_user',
        full_name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        role TEXT DEFAULT 'doctor',
        is_active INTEGER DEFAULT 1,
        profile_image TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_login TEXT
      )
    ''');

    // جدول جلسات المستخدم
    await db.execute('''
      CREATE TABLE user_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT DEFAULT 'main_user',
        session_token TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        device_info TEXT,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES user_profile (id) ON DELETE CASCADE
      )
    ''');

    // جدول إعدادات العيادة
    await db.execute('''
      CREATE TABLE clinic_settings (
        id TEXT PRIMARY KEY DEFAULT 'main_clinic',
        clinic_name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        email TEXT,
        logo_path TEXT,
        working_hours TEXT,
        currency TEXT DEFAULT 'EGP',
        language TEXT DEFAULT 'ar',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// إنشاء جداول البيانات الرئيسية للعيادة
  static Future<void> _createClinicTables(Database db) async {
    // جدول المرضى
    await db.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        phone_number TEXT UNIQUE NOT NULL,
        email TEXT,
        gender TEXT CHECK (gender IN ('male', 'female')),
        date_of_birth TEXT,
        address TEXT,
        emergency_contact TEXT,
        emergency_phone TEXT,
        medical_history TEXT,
        allergies TEXT,
        blood_type TEXT,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        created_by TEXT DEFAULT 'main_user',
        FOREIGN KEY (created_by) REFERENCES user_profile (id)
      )
    ''');

    // جدول المواعيد
    await db.execute('''
      CREATE TABLE appointments (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        doctor_name TEXT,
        appointment_date TEXT NOT NULL,
        appointment_time TEXT NOT NULL,
        duration_minutes INTEGER DEFAULT 30,
        status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'cancelled', 'no_show')),
        appointment_type TEXT DEFAULT 'consultation',
        notes TEXT,
        symptoms TEXT,
        diagnosis TEXT,
        treatment_plan TEXT,
        follow_up_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        created_by TEXT DEFAULT 'main_user',
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES user_profile (id)
      )
    ''');

    // جدول الوصفات الطبية
    await db.execute('''
      CREATE TABLE prescriptions (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        appointment_id TEXT,
        prescription_date TEXT NOT NULL,
        diagnosis TEXT,
        notes TEXT,
        follow_up_instructions TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        created_by TEXT DEFAULT 'main_user',
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE,
        FOREIGN KEY (appointment_id) REFERENCES appointments (id) ON DELETE SET NULL,
        FOREIGN KEY (created_by) REFERENCES user_profile (id)
      )
    ''');

    // جدول أدوية الوصفة
    await db.execute('''
      CREATE TABLE prescription_items (
        id TEXT PRIMARY KEY,
        prescription_id TEXT NOT NULL,
        medication_name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        frequency TEXT NOT NULL,
        duration TEXT NOT NULL,
        instructions TEXT,
        quantity INTEGER,
        price REAL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (prescription_id) REFERENCES prescriptions (id) ON DELETE CASCADE
      )
    ''');

    // جدول الفواتير
    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        appointment_id TEXT,
        invoice_number TEXT UNIQUE NOT NULL,
        invoice_date TEXT NOT NULL,
        due_date TEXT,
        subtotal REAL NOT NULL DEFAULT 0.0,
        tax_amount REAL DEFAULT 0.0,
        discount_amount REAL DEFAULT 0.0,
        total_amount REAL NOT NULL DEFAULT 0.0,
        paid_amount REAL DEFAULT 0.0,
        status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'partially_paid', 'overdue', 'cancelled')),
        payment_method TEXT,
        payment_date TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        created_by TEXT DEFAULT 'main_user',
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE,
        FOREIGN KEY (appointment_id) REFERENCES appointments (id) ON DELETE SET NULL,
        FOREIGN KEY (created_by) REFERENCES user_profile (id)
      )
    ''');

    // جدول خدمات الفاتورة
    await db.execute('''
      CREATE TABLE invoice_services (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        service_name TEXT NOT NULL,
        description TEXT,
        quantity INTEGER DEFAULT 1,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // جدول التقارير
    await db.execute('''
      CREATE TABLE reports (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        appointment_id TEXT,
        report_type TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        report_date TEXT NOT NULL,
        attachments TEXT, -- JSON array of file paths
        is_template INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        created_by TEXT DEFAULT 'main_user',
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE,
        FOREIGN KEY (appointment_id) REFERENCES appointments (id) ON DELETE SET NULL,
        FOREIGN KEY (created_by) REFERENCES user_profile (id)
      )
    ''');

    // جدول قوالب التقارير
    await db.execute('''
      CREATE TABLE report_templates (
        id TEXT PRIMARY KEY,
        template_name TEXT NOT NULL,
        template_type TEXT NOT NULL,
        content TEXT NOT NULL,
        variables TEXT, -- JSON array of template variables
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        created_by TEXT DEFAULT 'main_user',
        FOREIGN KEY (created_by) REFERENCES user_profile (id)
      )
    ''');
  }

  /// إنشاء الفهارس لتحسين الأداء
  static Future<void> _createIndexes(Database db) async {
    // فهارس لجدول المرضى
    await db.execute('CREATE INDEX idx_patients_phone ON patients (phone_number)');
    await db.execute('CREATE INDEX idx_patients_name ON patients (full_name)');
    await db.execute('CREATE INDEX idx_patients_active ON patients (is_active)');
    
    // فهارس لجدول المواعيد
    await db.execute('CREATE INDEX idx_appointments_date ON appointments (appointment_date)');
    await db.execute('CREATE INDEX idx_appointments_patient ON appointments (patient_id)');
    await db.execute('CREATE INDEX idx_appointments_status ON appointments (status)');
    
    // فهارس لجدول الوصفات
    await db.execute('CREATE INDEX idx_prescriptions_patient ON prescriptions (patient_id)');
    await db.execute('CREATE INDEX idx_prescriptions_date ON prescriptions (prescription_date)');
    
    // فهارس لجدول الفواتير
    await db.execute('CREATE INDEX idx_invoices_patient ON invoices (patient_id)');
    await db.execute('CREATE INDEX idx_invoices_date ON invoices (invoice_date)');
    await db.execute('CREATE INDEX idx_invoices_status ON invoices (status)');
    
    print('📊 تم إنشاء الفهارس بنجاح');
  }

  /// إدراج البيانات الافتراضية
  static Future<void> _insertDefaultData(Database db) async {
    // إعدادات العيادة الافتراضية
    await db.insert('clinic_settings', {
      'id': 'main_clinic',
      'clinic_name': 'عيادة الدكتور',
      'address': '',
      'phone': '',
      'email': '',
      'working_hours': '{"saturday": "9:00-17:00", "sunday": "9:00-17:00", "monday": "9:00-17:00", "tuesday": "9:00-17:00", "wednesday": "9:00-17:00", "thursday": "9:00-17:00", "friday": "closed"}',
      'currency': 'EGP',
      'language': 'ar',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // قوالب تقارير افتراضية
    await _insertDefaultReportTemplates(db);
    
    print('📝 تم إدراج البيانات الافتراضية');
  }

  /// إدراج قوالب التقارير الافتراضية
  static Future<void> _insertDefaultReportTemplates(Database db) async {
    final templates = [
      {
        'id': 'consultation_report',
        'template_name': 'تقرير كشف طبي',
        'template_type': 'consultation',
        'content': '''
تقرير كشف طبي

اسم المريض: {{patient_name}}
التاريخ: {{report_date}}
العمر: {{patient_age}}

الشكوى الرئيسية:
{{chief_complaint}}

الفحص السريري:
{{clinical_examination}}

التشخيص:
{{diagnosis}}

العلاج الموصى به:
{{treatment_plan}}

ملاحظات:
{{notes}}

التوقيع: {{doctor_name}}
        ''',
        'variables': '["patient_name", "report_date", "patient_age", "chief_complaint", "clinical_examination", "diagnosis", "treatment_plan", "notes", "doctor_name"]',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'prescription_report',
        'template_name': 'روشتة طبية',
        'template_type': 'prescription',
        'content': '''
روشتة طبية

اسم المريض: {{patient_name}}
التاريخ: {{prescription_date}}
رقم الروشتة: {{prescription_number}}

الأدوية الموصوفة:
{{medications_list}}

تعليمات المريض:
{{patient_instructions}}

التوقيع: {{doctor_name}}
العيادة: {{clinic_name}}
        ''',
        'variables': '["patient_name", "prescription_date", "prescription_number", "medications_list", "patient_instructions", "doctor_name", "clinic_name"]',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }
    ];

    for (var template in templates) {
      await db.insert('report_templates', template);
    }
  }

  /// توليد hash آمن لكلمة المرور
  static String generatePasswordHash(String password, String salt) {
    var bytes = utf8.encode(password + salt);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// توليد salt عشوائي
  static String generateSalt() {
    final random = Random.secure();
    var bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }

  /// التحقق من كلمة المرور
  static bool verifyPassword(String password, String hash, String salt) {
    return generatePasswordHash(password, salt) == hash;
  }

  /// إغلاق قاعدة البيانات
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('🔒 تم إغلاق قاعدة البيانات');
    }
  }

  /// حذف قاعدة البيانات (للاختبار أو إعادة التعيين)
  static Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), dbName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
    print('🗑️ تم حذف قاعدة البيانات');
  }

  /// الحصول على معلومات قاعدة البيانات
  static Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;
    final version = await db.getVersion();
    final path = db.path;
    
    return {
      'version': version,
      'path': path,
      'isOpen': db.isOpen,
    };
  }
}
