import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path' as path;

class DBHelper {
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

  static Future<void> insert(String table, Map<String, dynamic> data) async {
    final db = await DBHelper.database();
    await db.insert(
      table,
      data,
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getData(String table) async {
    final db = await DBHelper.database();
    return db.query(table, orderBy: "id DESC");
  }

  static Future<int> update(String table, Map<String, dynamic> data) async {
    final db = await DBHelper.database();
    return await db.update(
      table,
      data,
      where: 'id = ?',
      whereArgs: [data['id']],
    );
  }

  static Future<int> delete(String table, int id) async {
    final db = await DBHelper.database();
    return await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
