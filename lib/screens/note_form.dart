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

  // Kategori yang tersedia
  final List<String> categories = [
    'Kuliah',
    'Tugas',
    'Pribadi',
    'Penting',
    'Lainnya',
  ];
  late String selectedCategory;

  // Palet warna catatan yang tersedia
  final List<int> colorPalette = [
    0xFF3F51B5, // Indigo
    0xFF2E7D32, // Hijau
    0xFFE65100, // Oranye
    0xFFC2185B, // Merah / Pink
    0xFF7B1FA2, // Ungu
    0xFF00796B, // Teal
  ];
  late int selectedColor;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      titleController.text = widget.note!.title;
      contentController.text = widget.note!.content;
      selectedCategory = widget.note!.category;
      selectedColor = widget.note!.color;
    } else {
      selectedCategory = categories.first;
      selectedColor = colorPalette.first;
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
      final currentTime = widget.note?.createdAt ?? DateTime.now().toIso8601String();

      final noteToSave = Note(
        id: widget.note?.id,
        title: titleController.text.trim(),
        content: contentController.text.trim(),
        createdAt: currentTime,
        category: selectedCategory,
        color: selectedColor,
      );

      try {
        if (widget.note == null) {
          await db.insert(noteToSave);
        } else {
          await db.update(noteToSave);
        }

        if (!mounted) return;
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan catatan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Catatan' : 'Tambah Catatan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Simpan',
            onPressed: _saveNote,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pilihan Kategori
              const Text(
                'Kategori Catatan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: categories.map((cat) {
                  final isSelected = selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => selectedCategory = cat);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Pilihan Warna Catatan
              const Text(
                'Label Warna',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: colorPalette.map((colorValue) {
                  final isSelected = selectedColor == colorValue;
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = colorValue),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(colorValue),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black87 : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Input Judul
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  hintText: 'Masukkan judul catatan...',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Judul tidak boleh kosong'
                        : null,
              ),
              const SizedBox(height: 16),

              // Input Isi
              TextFormField(
                controller: contentController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Isi Catatan',
                  hintText: 'Tulis isi catatan di sini...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 140),
                    child: Icon(Icons.description),
                  ),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Isi catatan tidak boleh kosong'
                        : null,
              ),
              const SizedBox(height: 24),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saveNote,
                  icon: const Icon(Icons.save),
                  label: Text(
                    isEditing ? 'Perbarui Catatan' : 'Simpan Catatan',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
