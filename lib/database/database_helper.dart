// lib/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'local_database.dart';

class DatabaseHelper {
  static const Uuid _uuid = Uuid();

  /// توليد ID فريد
  static String generateId() => _uuid.v4();

  /// الحصول على التاريخ والوقت الحالي كـ ISO string
  static String getCurrentTimestamp() => DateTime.now().toIso8601String();

  /// تحويل boolean إلى integer للـ SQLite
  static int boolToInt(bool value) => value ? 1 : 0;

  /// تحويل integer إلى boolean من SQLite
  static bool intToBool(int value) => value == 1;

  /// تنظيف البيانات المدخلة
  static String? sanitizeString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  /// التحقق من وجود سجل في جدول معين
  static Future<bool> recordExists(String table, String whereClause, List<dynamic> whereArgs) async {
    final db = await LocalDatabase.database;
    final result = await db.query(
      table,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// عد السجلات في جدول معين
  static Future<int> countRecords(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await LocalDatabase.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $table${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );
    return result.first['count'] as int;
  }

  /// الحصول على السجل التالي بناء على ترقيم تسلسلي
  static Future<int> getNextSequenceNumber(String table, String column) async {
    final db = await LocalDatabase.database;
    final result = await db.rawQuery(
      'SELECT MAX($column) as max_num FROM $table',
    );
    final maxNum = result.first['max_num'] as int?;
    return (maxNum ?? 0) + 1;
  }

  /// تحديث timestamp للسجل
  static Map<String, dynamic> addTimestamp(Map<String, dynamic> data, {bool isUpdate = false}) {
    final now = getCurrentTimestamp();
    
    if (!isUpdate) {
      data['created_at'] = now;
    }
    data['updated_at'] = now;
    
    return data;
  }

  /// البحث في النصوص
  static String createSearchPattern(String searchTerm) {
    return '%${searchTerm.toLowerCase()}%';
  }

  /// تنفيذ معاملة قاعدة بيانات آمنة
  static Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await LocalDatabase.database;
    return await db.transaction(action);
  }

  /// نسخ احتياطي من البيانات
  static Future<Map<String, List<Map<String, dynamic>>>> exportAllData() async {
    final db = await LocalDatabase.database;
    
    const tables = [
      'user_profile',
      'clinic_settings', 
      'patients',
      'appointments',
      'prescriptions',
      'prescription_items',
      'invoices',
      'invoice_services',
      'reports',
      'report_templates',
    ];

    Map<String, List<Map<String, dynamic>>> exportData = {};

    for (String table in tables) {
      try {
        final data = await db.query(table);
        exportData[table] = data;
      } catch (e) {
        print('خطأ في تصدير جدول $table: $e');
        exportData[table] = [];
      }
    }

    return exportData;
  }

  /// استيراد البيانات
  static Future<bool> importAllData(Map<String, List<Map<String, dynamic>>> importData) async {
    try {
      return await transaction((txn) async {
        // حذف البيانات الموجودة (ما عدا المستخدم)
        const tablesToClear = [
          'invoice_services',
          'invoices',
          'prescription_items', 
          'prescriptions',
          'appointments',
          'patients',
          'reports',
          'report_templates',
        ];

        for (String table in tablesToClear) {
          await txn.delete(table);
        }

        // إدراج البيانات المستوردة
        for (String table in importData.keys) {
          if (table != 'user_sessions') { // تجاهل جلسات المستخدم
            for (Map<String, dynamic> row in importData[table]!) {
              await txn.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }

        return true;
      });
    } catch (e) {
      print('خطأ في استيراد البيانات: $e');
      return false;
    }
  }

  /// إحصائيات قاعدة البيانات
  static Future<Map<String, int>> getDatabaseStatistics() async {
    final stats = <String, int>{};
    
    stats['patients'] = await countRecords('patients', where: 'is_active = ?', whereArgs: [1]);
    stats['appointments'] = await countRecords('appointments');
    stats['prescriptions'] = await countRecords('prescriptions');
    stats['invoices'] = await countRecords('invoices');
    stats['reports'] = await countRecords('reports');
    
    return stats;
  }

  /// تنظيف البيانات القديمة
  static Future<void> cleanupOldData({int daysToKeep = 365}) async {
    await transaction((txn) async {
      // حذف الجلسات المنتهية الصلاحية
      await txn.delete(
        'user_sessions',
        where: 'expires_at < ? OR is_active = ?',
        whereArgs: [getCurrentTimestamp(), 0],
      );
      
      // يمكن إضافة تنظيف للبيانات الأخرى حسب الحاجة
      // final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep)).toIso8601String();
      // مثل حذف المواعيد القديمة جداً أو التقارير المؤقتة
      // مثل: await txn.delete('old_logs', where: 'created_at < ?', whereArgs: [cutoffDate]);
    });
    
    print('🧹 تم تنظيف البيانات القديمة');
  }

  /// فحص سلامة قاعدة البيانات
  static Future<bool> checkDatabaseIntegrity() async {
    try {
      final db = await LocalDatabase.database;
      final result = await db.rawQuery('PRAGMA integrity_check');
      return result.first['integrity_check'] == 'ok';
    } catch (e) {
      print('خطأ في فحص سلامة قاعدة البيانات: $e');
      return false;
    }
  }

  /// ضغط قاعدة البيانات
  static Future<void> vacuumDatabase() async {
    try {
      final db = await LocalDatabase.database;
      await db.rawQuery('VACUUM');
      print('📦 تم ضغط قاعدة البيانات');
    } catch (e) {
      print('خطأ في ضغط قاعدة البيانات: $e');
    }
  }
}
