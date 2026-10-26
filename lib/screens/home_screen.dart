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
  final TextEditingController _searchController = TextEditingController();

  List<Note> notes = [];
  List<Note> filteredNotes = [];
  String selectedFilterCategory = 'Semua';
  bool isLoading = true;

  final List<String> filterCategories = [
    'Semua',
    'Kuliah',
    'Tugas',
    'Pribadi',
    'Penting',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Memuat catatan dari SQLite
  Future<void> _loadNotes() async {
    setState(() => isLoading = true);
    final data = await db.getAllNotes();
    setState(() {
      notes = data;
      _applyFilter();
      isLoading = false;
    });
  }

  // Melakukan pencarian data dengan query SQL LIKE
  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      final data = await db.getAllNotes();
      setState(() {
        notes = data;
        _applyFilter();
      });
    } else {
      final data = await db.searchNotes(query.trim());
      setState(() {
        notes = data;
        _applyFilter();
      });
    }
  }

  // Filter kategori lokal di atas data catatan yang telah diambil
  void _applyFilter() {
    if (selectedFilterCategory == 'Semua') {
      filteredNotes = notes;
    } else {
      filteredNotes =
          notes.where((n) => n.category == selectedFilterCategory).toList();
    }
  }

  // Membuka form tambah atau edit
  void _openForm({Note? note}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteForm(note: note)),
    );
    if (result == true) {
      _loadNotes();
    }
  }

  // Peringatan Konfirmasi Hapus (Tugas 13.1)
  Future<void> _deleteNoteWithConfirmation(Note note) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Konfirmasi Hapus'),
          ],
        ),
        content: Text('Hapus catatan "${note.title}" ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await db.delete(note.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Catatan "${note.title}" berhasil dihapus'),
          backgroundColor: Colors.black87,
          duration: const Duration(seconds: 2),
        ),
      );
      _loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Catatan SQLite',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Catatan'),
      ),
      body: Column(
        children: [
          // Kolom Pencarian (Tugas 13.2)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari catatan (judul atau isi)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          // Pilihan Filter Kategori (Tugas 13.5)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: filterCategories.map((category) {
                final isSelected = selectedFilterCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedFilterCategory = category;
                        _applyFilter();
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 4),

          // Daftar Catatan
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_alt_outlined,
                              size: 72,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Catatan tidak ditemukan'
                                  : 'Belum ada catatan',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, i) {
                          final note = filteredNotes[i];
                          final noteColor = Color(note.color);

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: noteColor.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _openForm(note: note),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Baris Atas: Kategori Badge & Tombol Hapus
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Badge Kategori
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: noteColor.withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            note.category,
                                            style: TextStyle(
                                              color: noteColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        // Tombol Hapus dengan Konfirmasi (Tugas 13.1)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                            size: 22,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          tooltip: 'Hapus Catatan',
                                          onPressed: () =>
                                              _deleteNoteWithConfirmation(note),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 6),

                                    // Judul Catatan
                                    Text(
                                      note.title,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    // Isi Catatan
                                    Text(
                                      note.content,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        height: 1.3,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Tanggal Dibuat (Tugas 13.3)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          note.formattedDate,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}