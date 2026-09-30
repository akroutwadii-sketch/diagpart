import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;

class DBHelper {
  // فتح قاعدة البيانات أو إنشاؤها إن لم تكن موجودة
  static Future<sql.Database> database() async {
    final dbPath = await sql.getDatabasesPath();
    return sql.openDatabase(
      path.join(dbPath, 'diagpart_v2.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE parts('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'name TEXT, '
          'partNumber TEXT, '
          'price REAL, '
          'location TEXT, '
          'imagePath TEXT'
          ')',
        );
      },
      version: 1,
    );
  }

  // إضافة عنصر جديد
  static Future<void> insert(String table, Map<String, dynamic> data) async {
    final db = await DBHelper.database();
    await db.insert(
      table,
      data,
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  // جلب كافة البيانات مرتبة من الأحدث إلى الأقدم
  static Future<List<Map<String, dynamic>>> getData(String table) async {
    final db = await DBHelper.database();
    return db.query(table, orderBy: "id DESC");
  }

  // تحديث بيانات عنصر موجود
  static Future<int> update(String table, Map<String, dynamic> data) async {
    final db = await DBHelper.database();
    return await db.update(
      table,
      data,
      where: 'id = ?',
      whereArgs: [data['id']],
    );
  }

  // حذف عنصر باستخدام الـ ID
  static Future<int> delete(String table, int id) async {
    final db = await DBHelper.database();
    return await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
