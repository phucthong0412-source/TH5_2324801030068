import 'package:flutter/material.dart';

import '../models/note.dart';
import '../state/notes_controller.dart';
import '../theme/app_theme.dart';
import '../utils/note_date.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';

enum NoteSort { newest, oldest }

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, required this.controller});
  final NotesController controller;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _search = TextEditingController();
  bool _onlyToday = false;
  bool _deleteDialogOpen = false;
  NoteSort _sort = NoteSort.newest;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Note> get _visibleNotes {
    final query = _search.text.trim().toLowerCase();
    final notes = widget.controller.notes
        .where(
          (note) =>
              (!_onlyToday || isToday(note.createdAt)) &&
              (note.title.toLowerCase().contains(query) ||
                  note.content.toLowerCase().contains(query)),
        )
        .toList();
    notes.sort(
      (a, b) => _sort == NoteSort.newest
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt),
    );
    return notes;
  }

  Future<void> _edit([Note? note]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            NoteEditorScreen(controller: widget.controller, note: note),
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        _search.clear();
        _onlyToday = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            note == null ? 'Đã thêm ghi chú mới.' : 'Đã cập nhật ghi chú.',
          ),
        ),
      );
    }
  }

  Future<void> _actions(Note note) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Text(
                  note.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Chỉnh sửa'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Xóa ghi chú',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') await _edit(note);
    if (action == 'delete') await _delete(note);
  }

  Future<void> _delete(Note note) async {
    if (_deleteDialogOpen || widget.controller.isSaving) return;
    _deleteDialogOpen = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.delete_outline_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Xóa ghi chú này?'),
        content: Text(
          '“${note.title}” sẽ bị xóa khỏi thiết bị. Bạn không thể hoàn tác thao tác này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    _deleteDialogOpen = false;
    if (confirmed != true || !mounted) return;
    try {
      await widget.controller.deleteNote(note);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã xóa ghi chú.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xóa ghi chú. Vui lòng thử lại.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      final notes = _visibleNotes;
      return Scaffold(
        appBar: AppBar(
          titleSpacing: 24,
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Sổ tay',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: const [
            Tooltip(
              message: 'Lưu riêng trên thiết bị của bạn',
              child: Padding(
                padding: EdgeInsets.only(right: 24),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: AppTheme.muted,
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const ValueKey('add-note'),
          onPressed:
              controller.isLoading ||
                  controller.loadError != null ||
                  controller.isSaving
              ? null
              : () => _edit(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Thêm ghi chú'),
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 940
                      ? 3
                      : constraints.maxWidth >= 620
                      ? 2
                      : 1;
                  final scale = MediaQuery.textScalerOf(context).scale(1);
                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'GHI LẠI NHỮNG ĐIỀU QUAN TRỌNG',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.6,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accent,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Ghi chú của bạn',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${controller.notes.length} ghi chú · ${controller.notes.where((note) => isToday(note.createdAt)).length} tạo hôm nay',
                                style: const TextStyle(
                                  color: AppTheme.muted,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 28),
                              TextField(
                                key: const ValueKey('search-notes'),
                                controller: _search,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Tìm trong tiêu đề, nội dung…',
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: AppTheme.muted,
                                  ),
                                  suffixIcon: _search.text.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: 'Xóa tìm kiếm',
                                          onPressed: () =>
                                              setState(_search.clear),
                                          icon: const Icon(Icons.close_rounded),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ChoiceChip(
                                          label: const Text('Tất cả'),
                                          selected: !_onlyToday,
                                          showCheckmark: false,
                                          onSelected: (_) => setState(
                                            () => _onlyToday = false,
                                          ),
                                        ),
                                        ChoiceChip(
                                          label: const Text('Hôm nay'),
                                          selected: _onlyToday,
                                          showCheckmark: false,
                                          onSelected: (_) =>
                                              setState(() => _onlyToday = true),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<NoteSort>(
                                    tooltip: 'Sắp xếp ghi chú',
                                    initialValue: _sort,
                                    icon: const Icon(
                                      Icons.sort_rounded,
                                      color: AppTheme.muted,
                                    ),
                                    onSelected: (value) =>
                                        setState(() => _sort = value),
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: NoteSort.newest,
                                        child: Text('Mới tạo trước'),
                                      ),
                                      PopupMenuItem(
                                        value: NoteSort.oldest,
                                        child: Text('Cũ nhất trước'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (!controller.isLoading &&
                                  controller.loadError == null &&
                                  notes.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.touch_app_outlined,
                                      size: 14,
                                      color: AppTheme.muted,
                                    ),
                                    const SizedBox(width: 6),
                                    const Expanded(
                                      child: Text(
                                        'Chạm để sửa · Vuốt sang trái hoặc giữ để xóa',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.muted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (controller.isLoading)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(64),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        )
                      else if (controller.loadError != null)
                        SliverToBoxAdapter(
                          child: _emptyState(
                            icon: Icons.cloud_off_rounded,
                            title: 'Chưa thể tải ghi chú',
                            message: controller.loadError!,
                            action: FilledButton.icon(
                              onPressed: controller.load,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Thử lại'),
                            ),
                          ),
                        )
                      else if (notes.isEmpty)
                        SliverToBoxAdapter(
                          child: _emptyState(
                            icon: controller.notes.isEmpty
                                ? Icons.auto_stories_outlined
                                : Icons.search_off_rounded,
                            title: controller.notes.isEmpty
                                ? 'Ý tưởng đầu tiên bắt đầu ở đây'
                                : 'Không tìm thấy ghi chú',
                            message: controller.notes.isEmpty
                                ? 'Một ý tưởng, một việc cần làm hay một điều đáng nhớ.\nHãy viết ghi chú đầu tiên của bạn.'
                                : 'Thử từ khóa khác hoặc xem tất cả ghi chú.',
                            action: controller.notes.isEmpty
                                ? OutlinedButton.icon(
                                    onPressed: () => _edit(),
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Tạo ghi chú đầu tiên'),
                                  )
                                : TextButton(
                                    onPressed: () => setState(() {
                                      _search.clear();
                                      _onlyToday = false;
                                    }),
                                    child: const Text('Xem tất cả ghi chú'),
                                  ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverGrid.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 18,
                                  mainAxisSpacing: 18,
                                  mainAxisExtent:
                                      232 + (scale > 1 ? (scale - 1) * 180 : 0),
                                ),
                            itemCount: notes.length,
                            itemBuilder: (context, index) {
                              final note = notes[index];
                              return NoteCard(
                                key: ValueKey(note.id),
                                note: note,
                                enabled: !controller.isSaving,
                                onTap: () => _edit(note),
                                onActions: () => _actions(note),
                                onDelete: () => _delete(note),
                              );
                            },
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 112)),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
    required Widget action,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2EB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFE2E8D9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: AppTheme.accent),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.muted,
              height: 1.7,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 22),
          action,
        ],
      ),
    ),
  );
}
