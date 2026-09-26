import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;

class DBHelper {
  static Future<sql.Database> database() async {
    final dbPath = await sql.getDatabasesPath();
    return sql.openDatabase(
      path.join(dbPath, 'diagpart_inventory.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE parts(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, partNumber TEXT, brandModel TEXT, price REAL, location TEXT, imagePath TEXT, isSold INTEGER)',
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

  static Future<void> updateSoldStatus(int id, int isSold) async {
    final db = await DBHelper.database();
    await db.update(
      'parts',
      {'isSold': isSold},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> delete(int id) async {
    final db = await DBHelper.database();
    await db.delete('parts', where: 'id = ?', whereArgs: [id]);
  }
}