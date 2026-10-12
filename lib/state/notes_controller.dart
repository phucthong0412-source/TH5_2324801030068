import 'package:flutter/foundation.dart';

import '../data/note_repository.dart';
import '../models/note.dart';

class NotesController extends ChangeNotifier {
  NotesController(this._repository);
  final NoteRepository _repository;
  List<Note> _notes = [];
  bool _disposed = false;
  bool isLoading = true;
  bool isSaving = false;
  String? loadError;
  List<Note> get notes => List.unmodifiable(_notes);

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    _notify();
    try {
      _notes = await _repository.loadNotes();
    } catch (_) {
      loadError = 'Không thể đọc ghi chú đã lưu. Vui lòng thử lại.';
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<void> saveNote({
    Note? original,
    required String title,
    required String content,
    required int colorIndex,
  }) async {
    if (title.trim().isEmpty || content.trim().isEmpty) {
      throw ArgumentError('Vui lòng nhập tiêu đề và nội dung.');
    }
    if (colorIndex < 0 || colorIndex > 4) {
      throw ArgumentError('Màu ghi chú không hợp lệ.');
    }
    final now = DateTime.now();
    final note = Note(
      id: original?.id ?? now.microsecondsSinceEpoch.toString(),
      title: title.trim(),
      content: content.trim(),
      createdAt: original?.createdAt ?? now,
      updatedAt: now,
      colorIndex: colorIndex,
    );
    final next = [..._notes];
    if (original == null) {
      next.insert(0, note);
    } else {
      final index = next.indexWhere((item) => item.id == original.id);
      if (index < 0) throw StateError('Không tìm thấy ghi chú.');
      next[index] = note;
    }
    await _persist(next);
  }

  Future<void> deleteNote(Note note) async {
    await _persist(_notes.where((item) => item.id != note.id).toList());
  }

  Future<void> _persist(List<Note> next) async {
    if (isLoading || loadError != null || isSaving) {
      throw StateError('Chưa thể cập nhật ghi chú.');
    }
    isSaving = true;
    _notify();
    try {
      // Chỉ cập nhật giao diện sau khi thao tác lưu thành công.
      await _repository.saveNotes(next);
      _notes = next;
    } finally {
      isSaving = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
