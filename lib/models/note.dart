class Note {
  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.colorIndex = 0,
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int colorIndex;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'colorIndex': colorIndex,
  };

  factory Note.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final content = json['content'];
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];
    final colorIndex = json['colorIndex'] ?? 0;
    if (id is! String ||
        id.isEmpty ||
        title is! String ||
        title.trim().isEmpty ||
        content is! String ||
        content.trim().isEmpty ||
        createdAt is! String ||
        updatedAt is! String ||
        colorIndex is! int ||
        colorIndex < 0 ||
        colorIndex > 4) {
      throw const FormatException('Dữ liệu ghi chú không hợp lệ.');
    }
    return Note(
      id: id,
      title: title,
      content: content,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      colorIndex: colorIndex,
    );
  }
}
