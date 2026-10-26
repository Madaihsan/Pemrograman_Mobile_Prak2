import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Menaikkan version ke 2 dan menambahkan handler onUpgrade
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // Membuat tabel awal (skema versi 2)
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        category TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');
  }

  // Menangani migrasi jika database pengguna masih versi 1
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE notes ADD COLUMN created_at TEXT NOT NULL DEFAULT ""',
      );
      await db.execute(
        'ALTER TABLE notes ADD COLUMN category TEXT NOT NULL DEFAULT "Umum"',
      );
      await db.execute(
        'ALTER TABLE notes ADD COLUMN color INTEGER NOT NULL DEFAULT 4165557', // 0xFF3F51B5
      );
    }
  }

  // CREATE: Menambah catatan baru
  Future<int> insert(Note note) async {
    final db = await instance.database;
    return await db.insert('notes', note.toMap());
  }

  // READ: Mengambil seluruh catatan
  Future<List<Note>> getAllNotes() async {
    final db = await instance.database;
    final result = await db.query('notes', orderBy: 'id DESC');
    return result.map((e) => Note.fromMap(e)).toList();
  }

  // READ (SEARCH): Mencari catatan berdasarkan kata kunci menggunakan SQL LIKE
  Future<List<Note>> searchNotes(String keyword) async {
    final db = await instance.database;
    final result = await db.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'id DESC',
    );
    return result.map((e) => Note.fromMap(e)).toList();
  }

  // UPDATE: Memperbarui catatan
  Future<int> update(Note note) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // DELETE: Menghapus catatan
  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // Tutup koneksi database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}