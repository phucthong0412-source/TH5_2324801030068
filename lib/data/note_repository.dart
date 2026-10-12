import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';

abstract interface class NoteRepository {
  Future<List<Note>> loadNotes();
  Future<void> saveNotes(List<Note> notes);
}

/// Lưu cả danh sách dưới dạng JSON trong một khóa SharedPreferences.
class SharedPreferencesNoteRepository implements NoteRepository {
  SharedPreferencesNoteRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();
  static const storageKey = 'personal_notes_v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<List<Note>> loadNotes() async {
    final raw = await _preferences.getString(storageKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Danh sách ghi chú không hợp lệ.');
    }
    final notes = decoded.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Ghi chú không hợp lệ.');
      }
      return Note.fromJson(item);
    }).toList();
    if (notes.map((note) => note.id).toSet().length != notes.length) {
      throw const FormatException('Mã ghi chú bị trùng.');
    }
    return notes;
  }

  @override
  Future<void> saveNotes(List<Note> notes) async {
    await _preferences.setString(
      storageKey,
      jsonEncode(notes.map((note) => note.toJson()).toList()),
    );
  }
}
