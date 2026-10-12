import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:th5_2324801030068/data/note_repository.dart';
import 'package:th5_2324801030068/state/notes_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  test(
    'CRUD survives fresh repositories with Vietnamese text and creation date',
    () async {
      final first = NotesController(SharedPreferencesNoteRepository());
      addTearDown(first.dispose);
      await first.load();
      expect(first.notes, isEmpty);
      await first.saveNote(
        title: '  Ý tưởng hôm nay  ',
        content: 'Dòng đầu\nDòng hai: tiếng Việt ✨',
        colorIndex: 3,
      );
      final original = first.notes.single;

      final reopened = NotesController(SharedPreferencesNoteRepository());
      addTearDown(reopened.dispose);
      await reopened.load();
      expect(reopened.notes.single.title, 'Ý tưởng hôm nay');
      expect(reopened.notes.single.content, 'Dòng đầu\nDòng hai: tiếng Việt ✨');
      expect(reopened.notes.single.colorIndex, 3);
      await reopened.saveNote(
        original: reopened.notes.single,
        title: 'Tiêu đề mới',
        content: 'Nội dung cập nhật',
        colorIndex: 1,
      );

      final afterEdit = await SharedPreferencesNoteRepository().loadNotes();
      expect(afterEdit.single.id, original.id);
      expect(afterEdit.single.createdAt, original.createdAt);
      expect(afterEdit.single.title, 'Tiêu đề mới');
      expect(afterEdit.single.colorIndex, 1);
      await reopened.deleteNote(reopened.notes.single);
      expect(await SharedPreferencesNoteRepository().loadNotes(), isEmpty);
    },
  );

  test(
    'Corrupt storage blocks writes without erasing the original value',
    () async {
      final preferences = SharedPreferencesAsync();
      const badData = '{broken json';
      await preferences.setString(
        SharedPreferencesNoteRepository.storageKey,
        badData,
      );
      final controller = NotesController(SharedPreferencesNoteRepository());
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.loadError, isNotNull);
      await expectLater(
        controller.saveNote(title: 'Test', content: 'Test', colorIndex: 0),
        throwsStateError,
      );
      expect(
        await preferences.getString(SharedPreferencesNoteRepository.storageKey),
        badData,
      );
    },
  );

  test('Whitespace-only notes are rejected before writing', () async {
    final controller = NotesController(SharedPreferencesNoteRepository());
    addTearDown(controller.dispose);
    await controller.load();
    await expectLater(
      controller.saveNote(title: '   ', content: '\n', colorIndex: 0),
      throwsArgumentError,
    );
    expect(await SharedPreferencesNoteRepository().loadNotes(), isEmpty);
  });
}
