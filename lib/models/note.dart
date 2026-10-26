class Note {
  final int? id;
  final String title;
  final String content;
  final String createdAt;
  final String category;
  final int color;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.category = 'Umum',
    this.color = 0xFF3F51B5, // Default indigo
  });

  // Mengubah objek Note menjadi Map untuk disimpan ke SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt,
      'category': category,
      'color': color,
    };
  }

  // Mengubah Map dari SQLite menjadi objek Note
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      category: map['category'] as String? ?? 'Umum',
      color: map['color'] as int? ?? 0xFF3F51B5,
    );
  }

  // Format tanggal buatan sendiri yang rapi dalam bahasa Indonesia
  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute';
    } catch (_) {
      return createdAt;
    }
  }

  Note copyWith({
    int? id,
    String? title,
    String? content,
    String? createdAt,
    String? category,
    int? color,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      color: color ?? this.color,
    );
  }
}