# Modul Praktikum 2 — Penyimpanan Data Lokal dengan SQLite (Aplikasi Catatan)

**Mata Kuliah:** Pemrograman Mobile

## 1. Pendahuluan

Praktikum ini mengajarkan pembuatan aplikasi catatan yang menyimpan data langsung di perangkat, sehingga catatan tetap dapat dibuka tanpa koneksi internet.

### Persiapan lingkungan kerja

1. Flutter SDK versi stabil terbaru. Periksa instalasi menggunakan `flutter doctor` dan pastikan bagian Android tidak bermasalah.
2. Editor Visual Studio Code dengan ekstensi Flutter dan Dart, atau Android Studio.
3. Perangkat uji berupa emulator Android atau HP Android dengan USB debugging aktif.
4. Git dan akun GitHub untuk menyimpan kode serta mengumpulkan hasil praktikum.

## 2. Mengenal SQLite

SQLite adalah sistem basis data relasional (RDBMS) yang ringan dan tidak membutuhkan server terpisah. Berbeda dengan MySQL atau PostgreSQL yang berjalan di server, SQLite disimpan langsung di perangkat dalam bentuk file `.db`.

Ciri khas SQLite:

- Tidak perlu memasang server; data tersimpan secara lokal.
- Cepat dan efisien untuk data berukuran kecil hingga menengah.
- Mendukung perintah SQL seperti `SELECT`, `INSERT`, `UPDATE`, dan `DELETE`.
- Cocok untuk aplikasi *offline-first*.

SQLite sesuai untuk aplikasi yang membutuhkan penyimpanan lokal tanpa internet, memiliki data yang tidak terlalu besar (ratusan hingga ribuan baris), tidak membutuhkan sinkronisasi real-time antarpengguna, atau perlu menyimpan cache dari API. Contohnya aplikasi catatan harian, tugas kuliah, belanja dengan mode offline, dan penyimpanan preferensi pengguna.

## 3. Tujuan Pembelajaran

Mahasiswa mampu memahami konsep penyimpanan data lokal menggunakan SQLite pada Flutter dan membuat aplikasi sederhana dengan fitur CRUD (*Create, Read, Update, Delete*) menggunakan package `sqflite`.

## 4. Integrasi SQLite dalam Flutter

Flutter tidak memiliki basis data bawaan. Oleh karena itu, digunakan library eksternal `sqflite` (*SQLite for Flutter*). Library ini memungkinkan operasi basis data ditulis menggunakan Dart, dengan dukungan perintah SQL seperti `CREATE TABLE`, `INSERT`, `SELECT`, `UPDATE`, dan `DELETE`.

## 5. Struktur Direktori Proyek

```text
lib/
├── main.dart
├── db/
│   └── database_helper.dart
├── models/
│   └── note.dart
└── screens/
    ├── home_screen.dart
    └── note_form.dart
```

Struktur tersebut memisahkan logika basis data, model data, dan tampilan agar kode lebih mudah dipelihara.

## 6. Langkah 1 — Membuat Proyek dan Menambahkan Dependensi

Buat proyek Flutter dan tambahkan dependensi:

```bash
flutter create flutter_sqlite_demo
cd flutter_sqlite_demo
flutter pub add sqflite path
```

Alternatifnya, tambahkan secara manual pada `pubspec.yaml`, lalu jalankan `flutter pub get`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.3
  path: ^1.9.0
```

- `sqflite` digunakan untuk operasi basis data.
- `path` membantu menentukan lokasi file database.

## 7. Langkah 2 — Model Data (`models/note.dart`)

Model merepresentasikan satu catatan sebagai objek Dart. `toMap()` mengubah objek menjadi data berbentuk map untuk disimpan ke tabel, sedangkan `fromMap()` mengubah data dari tabel menjadi objek `Note`.

```dart
class Note {
  final int? id;
  final String title;
  final String content;

  Note({
    this.id,
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
    );
  }
}
```

## 8. Langkah 3 — Database Helper (`db/database_helper.dart`)

Kelas `DatabaseHelper` mengatur proses simpan, baca, ubah, dan hapus data. Pola *singleton* memastikan penggunaan satu instance helper dan satu referensi koneksi database.

```dart
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
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL
      )
    ''');
  }

  Future<int> insert(Note note) async {
    final db = await instance.database;
    return await db.insert('notes', note.toMap());
  }

  Future<List<Note>> getAllNotes() async {
    final db = await instance.database;
    final result = await db.query('notes', orderBy: 'id DESC');
    return result.map((e) => Note.fromMap(e)).toList();
  }

  Future<int> update(Note note) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
```

### Penjelasan operasi CRUD

| Operasi | Fungsi | Penjelasan |
|---|---|---|
| Create | `insert(Note note)` | Menambahkan catatan baru ke tabel `notes`. |
| Read | `getAllNotes()` | Mengambil semua catatan dan mengurutkannya berdasarkan `id` secara menurun. |
| Update | `update(Note note)` | Memperbarui catatan berdasarkan `id`. |
| Delete | `delete(int id)` | Menghapus catatan berdasarkan `id`. |

Pada `update()` dan `delete()`, parameter `whereArgs` digunakan bersama kondisi `?` agar nilai ID diberikan sebagai argumen, bukan digabungkan langsung ke string SQL.

### Struktur tabel awal

| Kolom | Tipe | Ketentuan |
|---|---|---|
| `id` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` |
| `title` | `TEXT` | `NOT NULL` |
| `content` | `TEXT` | `NOT NULL` |

## 9. Langkah 4 — Halaman Daftar Catatan (`screens/home_screen.dart`)

Halaman utama menampilkan daftar catatan, membuka formulir tambah/edit, dan menghapus catatan.

```dart
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/note.dart';
import 'note_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = DatabaseHelper.instance;
  List<Note> notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final data = await db.getAllNotes();
    setState(() => notes = data);
  }

  void _openForm({Note? note}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteForm(note: note)),
    );
    if (result == true) {
      _loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catatan SQLite')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: notes.isEmpty
          ? const Center(child: Text('Belum ada catatan.'))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, i) {
                final note = notes[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(
                      note.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _openForm(note: note),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.redAccent,
                      ),
                      onPressed: () async {
                        await db.delete(note.id!);
                        _loadNotes();
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
```

Ketika halaman dibuka, `initState()` memanggil `_loadNotes()` untuk mengambil data dari SQLite. Pengguna dapat menekan tombol tambah untuk membuat catatan atau mengetuk catatan yang sudah ada untuk mengeditnya. Setelah formulir mengembalikan nilai `true`, daftar dimuat ulang.

Pada kode awal modul, penghapusan langsung dilakukan ketika ikon hapus ditekan. Tugas praktikum meminta penambahan dialog konfirmasi sebelum penghapusan.

## 10. Langkah 5 — Form Tambah/Edit Catatan (`screens/note_form.dart`)

Formulir yang sama digunakan untuk menambah maupun mengedit catatan. Jika `note` bernilai `null`, formulir berada dalam mode tambah. Jika sebuah catatan diberikan, kolom formulir diisi dengan data yang sudah ada.

```dart
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/note.dart';

class NoteForm extends StatefulWidget {
  final Note? note;

  const NoteForm({super.key, this.note});

  @override
  State<NoteForm> createState() => _NoteFormState();
}

class _NoteFormState extends State<NoteForm> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      titleController.text = widget.note!.title;
      contentController.text = widget.note!.content;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_formKey.currentState!.validate()) {
      final db = DatabaseHelper.instance;
      final newNote = Note(
        id: widget.note?.id,
        title: titleController.text.trim(),
        content: contentController.text.trim(),
      );

      if (widget.note == null) {
        await db.insert(newNote);
      } else {
        await db.update(newNote);
      }

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.note == null ? 'Tambah Catatan' : 'Edit Catatan',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty
                        ? 'Judul tidak boleh kosong'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Isi Catatan',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty
                        ? 'Isi catatan tidak boleh kosong'
                        : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saveNote,
                icon: const Icon(Icons.save),
                label: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Poin penting:

- `TextEditingController` mengelola isi kolom formulir.
- `GlobalKey<FormState>` digunakan untuk menjalankan validasi.
- `trim()` menghapus spasi di awal dan akhir input sebelum disimpan.
- `dispose()` melepaskan controller ketika halaman tidak lagi digunakan.
- `Navigator.pop(context, true)` mengembalikan tanda bahwa data telah disimpan atau diperbarui.

## 11. Langkah 6 — Entry Point (`main.dart`)

File `main.dart` menjalankan aplikasi dan menetapkan `HomeScreen` sebagai halaman awal.

```dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Catatan SQLite',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
```

## 12. Menjalankan Aplikasi dan Hasil Akhir

Jalankan aplikasi menggunakan:

```bash
flutter run
```

Aplikasi menampilkan daftar catatan. Pengguna dapat:

- Menambah catatan.
- Mengedit catatan dengan mengetuk item.
- Menghapus catatan melalui ikon tempat sampah.
- Menyimpan catatan secara lokal di file `notes.db`.

Data tetap tersimpan setelah aplikasi ditutup karena disimpan dalam database lokal perangkat.

## 13. Tugas Praktikum 2

Kembangkan aplikasi catatan dengan fitur berikut.

### 13.1 Konfirmasi hapus

Tampilkan `AlertDialog` dengan pesan **“Hapus catatan ini?”** sebelum catatan benar-benar dihapus.

### 13.2 Pencarian catatan

Tambahkan kolom pencarian pada halaman utama. Gunakan query SQL `LIKE`, misalnya:

```dart
db.query(
  'notes',
  where: 'title LIKE ?',
  whereArgs: ['%$keyword%'],
);
```

Contoh tersebut mencari kata kunci pada kolom `title`. Pencarian dapat dikembangkan sesuai kebutuhan, tetapi contoh pada modul menggunakan judul catatan.

### 13.3 Tanggal dibuat

Tambahkan kolom `created_at` pada tabel `notes` dan tampilkan tanggal pada setiap catatan.

Petunjuk modul:

- Naikkan versi database menjadi `2`.
- Tambahkan `onUpgrade` yang menjalankan `ALTER TABLE`.
- Sebagai alternatif yang disebutkan dalam modul, hapus aplikasi dari perangkat lalu pasang kembali. Perhatikan bahwa cara ini dapat menghilangkan data lokal yang tersimpan.

### 13.4 Perbaikan tampilan

Rapikan tema aplikasi, termasuk warna, kartu, dan ikon agar konsisten.

### 13.5 Nilai tambahan

Tambahkan fitur kategori atau warna catatan yang juga tersimpan di SQLite.

## 14. Laporan Praktikum 2

Laporan dikumpulkan melalui e-learning dan mencakup:

1. Judul dan tujuan praktikum.
2. Deskripsi aplikasi.
3. Penjelasan kode utama, khususnya fungsi CRUD pada `DatabaseHelper` dan perubahan struktur tabel.
4. Screenshot aplikasi yang memperlihatkan daftar, tambah, edit, hapus, dan pencarian.
5. Video demonstrasi singkat.
6. Link repository GitHub yang bersifat publik.
7. Kesimpulan.

## 15. Ringkasan Alur Aplikasi

```text
Pengguna
   |
   v
HomeScreen
   |-- Memuat catatan ---------> DatabaseHelper
   |                                |
   |                                v
   |                           SQLite (notes.db)
   |
   |-- Tambah/Edit ------------> NoteForm
   |                                |
   |                                v
   |                           DatabaseHelper
   |
   |-- Hapus ------------------> DatabaseHelper
   |
   v
Daftar catatan diperbarui
```

## 16. Kesimpulan

Praktikum ini memperkenalkan penyimpanan data lokal menggunakan SQLite pada aplikasi Flutter. Model `Note` merepresentasikan data, `DatabaseHelper` menangani operasi database, `HomeScreen` menampilkan daftar catatan, dan `NoteForm` menangani input serta pengeditan. Tugas pengembangan berfokus pada konfirmasi penghapusan, pencarian, tanggal pembuatan, perbaikan tampilan, serta kategori atau warna catatan.
