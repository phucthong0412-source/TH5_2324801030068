import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:th5_2324801030068/data/note_repository.dart';
import 'package:th5_2324801030068/main.dart';
import 'package:th5_2324801030068/models/note.dart';
import 'package:th5_2324801030068/widgets/note_card.dart';

class MemoryRepository implements NoteRepository {
  MemoryRepository([List<Note>? notes]) : stored = notes ?? [];
  List<Note> stored;
  bool failSave = false;
  bool failLoad = false;

  @override
  Future<List<Note>> loadNotes() async {
    if (failLoad) throw Exception('Read failed');
    return [...stored];
  }

  @override
  Future<void> saveNotes(List<Note> notes) async {
    if (failSave) throw Exception('Write failed');
    stored = [...notes];
  }
}

Note sampleNote() => Note(
  id: 'sample',
  title: 'Kế hoạch học tập',
  content: 'Hoàn thành bài Flutter và ôn tập SQLite.',
  createdAt: DateTime(2026, 1, 15, 8, 30),
  updatedAt: DateTime(2026, 1, 15, 8, 30),
);

Future<void> openApp(WidgetTester tester, MemoryRepository repository) async {
  await tester.pumpWidget(MyApp(repository: repository));
  await tester.pumpAndSettle();
}

Future<void> pressSave(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const ValueKey('save-note')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('save-note')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Create, edit, and reopen a saved note', (tester) async {
    final repository = MemoryRepository();
    await openApp(tester, repository);
    expect(find.text('Ý tưởng đầu tiên bắt đầu ở đây'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-note')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-title')),
      'Bài thực hành 5',
    );
    await tester.enterText(
      find.byKey(const ValueKey('note-content')),
      'Xây dựng ứng dụng ghi chú cá nhân.',
    );
    await pressSave(tester);
    expect(find.text('Ghi chú của bạn'), findsOneWidget);
    expect(repository.stored.single.title, 'Bài thực hành 5');
    final createdAt = repository.stored.single.createdAt;

    await tester.tap(find.text('Bài thực hành 5'));
    await tester.pumpAndSettle();
    expect(find.text('Chỉnh sửa ghi chú'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('note-title')),
      'Đã hoàn thành bài 5',
    );
    await tester.enterText(
      find.byKey(const ValueKey('note-content')),
      'Đã kiểm tra thêm, sửa và xóa.',
    );
    await pressSave(tester);
    expect(find.text('Đã hoàn thành bài 5'), findsOneWidget);
    expect(repository.stored.single.createdAt, createdAt);
    expect(repository.stored.single.content, 'Đã kiểm tra thêm, sửa và xóa.');

    await tester.pumpWidget(const SizedBox.shrink());
    await openApp(tester, repository);
    expect(find.text('Đã hoàn thành bài 5'), findsOneWidget);
  });

  testWidgets('Reject empty title and content', (tester) async {
    final repository = MemoryRepository();
    await openApp(tester, repository);
    await tester.tap(find.byKey(const ValueKey('add-note')));
    await tester.pumpAndSettle();
    await pressSave(tester);
    expect(find.text('Vui lòng nhập tiêu đề.'), findsOneWidget);
    expect(find.text('Vui lòng nhập nội dung.'), findsOneWidget);
    expect(repository.stored, isEmpty);
    expect(find.text('Ghi chú mới'), findsOneWidget);
  });

  testWidgets('Long press exposes delete, cancel keeps the note', (
    tester,
  ) async {
    final repository = MemoryRepository([sampleNote()]);
    await openApp(tester, repository);
    await tester.longPress(find.text('Kế hoạch học tập'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Xóa ghi chú'));
    await tester.pumpAndSettle();
    expect(find.text('Xóa ghi chú này?'), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(repository.stored, hasLength(1));
    expect(find.text('Kế hoạch học tập'), findsOneWidget);

    await tester.longPress(find.text('Kế hoạch học tập'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Xóa ghi chú'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pumpAndSettle();
    expect(repository.stored, isEmpty);
    expect(find.byType(NoteCard), findsNothing);
  });

  testWidgets('Swipe requests confirmation before deleting', (tester) async {
    final repository = MemoryRepository([sampleNote()]);
    await openApp(tester, repository);
    await tester.drag(find.byType(NoteCard), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Xóa ghi chú này?'), findsOneWidget);
    expect(repository.stored, hasLength(1));
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pumpAndSettle();
    expect(repository.stored, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Search matches content and clearing restores the list', (
    tester,
  ) async {
    await openApp(tester, MemoryRepository([sampleNote()]));
    await tester.enterText(
      find.byKey(const ValueKey('search-notes')),
      'sqlite',
    );
    await tester.pumpAndSettle();
    expect(find.byType(NoteCard), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('search-notes')),
      'không có',
    );
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy ghi chú'), findsOneWidget);
    await tester.tap(find.byTooltip('Xóa tìm kiếm'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteCard), findsOneWidget);
  });

  testWidgets('Unsaved changes require confirmation when leaving', (
    tester,
  ) async {
    final repository = MemoryRepository();
    await openApp(tester, repository);
    await tester.tap(find.byKey(const ValueKey('add-note')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-title')),
      'Bản nháp',
    );
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
    await tester.tap(find.text('Tiếp tục viết'));
    await tester.pumpAndSettle();
    expect(find.text('Bản nháp'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Bỏ thay đổi'));
    await tester.pumpAndSettle();
    expect(find.text('Ghi chú của bạn'), findsOneWidget);
    expect(repository.stored, isEmpty);
  });

  testWidgets('Failed save keeps editor text and permits retry', (
    tester,
  ) async {
    final repository = MemoryRepository()..failSave = true;
    await openApp(tester, repository);
    await tester.tap(find.byKey(const ValueKey('add-note')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('note-title')),
      'Không mất nội dung',
    );
    await tester.enterText(
      find.byKey(const ValueKey('note-content')),
      'Thử lưu lại khi xảy ra lỗi.',
    );
    await pressSave(tester);
    expect(find.text('Ghi chú mới'), findsOneWidget);
    expect(repository.stored, isEmpty);
    expect(find.text('Không mất nội dung'), findsOneWidget);
    repository.failSave = false;
    await pressSave(tester);
    expect(repository.stored.single.title, 'Không mất nội dung');
  });

  testWidgets('Failed delete keeps the original note', (tester) async {
    final repository = MemoryRepository([sampleNote()])..failSave = true;
    await openApp(tester, repository);
    await tester.drag(find.byType(NoteCard), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pumpAndSettle();
    expect(repository.stored, hasLength(1));
    expect(find.byType(NoteCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Loading failure offers retry and disables creating', (
    tester,
  ) async {
    final repository = MemoryRepository([sampleNote()])..failLoad = true;
    await openApp(tester, repository);
    expect(find.text('Chưa thể tải ghi chú'), findsOneWidget);
    final add = tester.widget<FloatingActionButton>(
      find.byKey(const ValueKey('add-note')),
    );
    expect(add.onPressed, isNull);
    repository.failLoad = false;
    await tester.ensureVisible(find.text('Thử lại'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Kế hoạch học tập'), findsOneWidget);
  });

  testWidgets('Phone layout displays a long note without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final note = Note(
      id: 'long',
      title:
          'Một ghi chú có tiêu đề rất dài để kiểm tra giao diện điện thoại nhỏ',
      content: List.filled(
        20,
        'Nội dung dài được rút gọn trên thẻ ghi chú.',
      ).join('\n'),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await openApp(tester, MemoryRepository([note]));
    expect(find.byType(NoteCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Creation date is visible before the preview on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final note = Note(
      id: 'dated',
      title: 'Ghi chú đã chỉnh sửa',
      content: 'Nội dung rút gọn của ghi chú.',
      createdAt: DateTime(2026, 1, 15, 8, 30),
      updatedAt: DateTime(2026, 1, 20, 10, 45),
    );
    await openApp(tester, MemoryRepository([note]));
    expect(find.text('Thời gian tạo'), findsOneWidget);
    expect(find.text('15/01/2026 · 08:30'), findsOneWidget);
    expect(find.text('20/01/2026 · 10:45'), findsNothing);
    await tester.ensureVisible(find.byType(NoteCard));
    await tester.pumpAndSettle();
    final dateRect = tester.getRect(find.text('15/01/2026 · 08:30'));
    final cardRect = tester.getRect(find.byType(NoteCard));
    final previewRect = tester.getRect(find.text(note.content));
    expect(dateRect.top, greaterThan(cardRect.top));
    expect(dateRect.bottom, lessThanOrEqualTo(previewRect.top));
    expect(dateRect.right, lessThanOrEqualTo(cardRect.right));
    expect(dateRect.bottom, lessThanOrEqualTo(tester.view.physicalSize.height));
  });
}
