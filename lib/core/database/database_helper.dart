import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'unilife.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tablo: Dersler
    await db.execute('''
      CREATE TABLE courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        instructor TEXT,
        room_name TEXT,
        color_code TEXT,
        target_grade REAL DEFAULT 0
      )
    ''');

    // 2. Tablo: Ders Programı
    await db.execute('''
      CREATE TABLE schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL,
        day_of_week INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE CASCADE
      )
    ''');

    // 3. Tablo: Görevler (Ödev & Sınav)
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        due_date INTEGER NOT NULL,
        is_completed INTEGER DEFAULT 0,
        reminder_time INTEGER,
        FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE CASCADE
      )
    ''');

    // 4. Tablo: Notlar
    await db.execute('''
      CREATE TABLE grades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        score REAL DEFAULT 0,
        weight REAL DEFAULT 0,
        FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE CASCADE
      )
    ''');

    // 5. Tablo: Çalışma İstatistikleri
    await db.execute('''
      CREATE TABLE study_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER,
        date_timestamp INTEGER NOT NULL,
        duration_minutes INTEGER NOT NULL,
        FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE SET NULL
      )
    ''');

    // 6. Tablo: Bütçe (Cüzdan) - TEK VE DOĞRU HALİ
    // (Profil ekranındaki koda uygun olan yapı budur)
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        amount REAL,
        is_expense INTEGER, -- 1 ise Gider, 0 ise Gelir
        date TEXT
      )
    ''');
  }

  // --- CRUD METODLARI ---
  Future<int> insert(String table, Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows(String table) async {
    Database db = await database;
    return await db.query(table);
  }

  Future<int> update(String table, Map<String, dynamic> row) async {
    Database db = await database;
    int id = row['id'];
    return await db.update(table, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    Database db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
  
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    Database db = await database;
    return await db.rawQuery(sql, arguments);
  }
}