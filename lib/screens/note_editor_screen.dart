import 'package:flutter/material.dart';

import '../models/note.dart';
import '../state/notes_controller.dart';
import '../theme/app_theme.dart';
import '../utils/note_date.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, required this.controller, this.note});
  final NotesController controller;
  final Note? note;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _content;
  late int _colorIndex;
  bool _saving = false;
  bool _discardDialogOpen = false;

  bool get _hasChanges =>
      _title.text != (widget.note?.title ?? '') ||
      _content.text != (widget.note?.content ?? '') ||
      _colorIndex != (widget.note?.colorIndex ?? 0);

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.note?.title ?? '');
    _content = TextEditingController(text: widget.note?.content ?? '');
    _colorIndex = widget.note?.colorIndex ?? 0;
    _title.addListener(_refresh);
    _content.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_saving || _discardDialogOpen) return;
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }
    _discardDialogOpen = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bỏ thay đổi chưa lưu?'),
        content: const Text(
          'Những thay đổi của bạn chưa được lưu vào ghi chú.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tiếp tục viết'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bỏ thay đổi'),
          ),
        ],
      ),
    );
    _discardDialogOpen = false;
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await widget.controller.saveNote(
        original: widget.note,
        title: _title.text,
        content: _content.text,
        colorIndex: _colorIndex,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể lưu ghi chú. Nội dung vẫn được giữ để bạn thử lại.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      color: AppTheme.muted,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final editing = widget.note != null;
    return PopScope<bool>(
      canPop: !_hasChanges && !_saving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Quay lại',
            onPressed: _saving ? null : _leave,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(
            editing ? 'Chỉnh sửa ghi chú' : 'Ghi chú mới',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          ),
        ),
        bottomNavigationBar: _saveBar(editing),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        editing
                            ? 'Mỗi ý tưởng đều đáng được lưu giữ.'
                            : 'Một trang mới cho ý tưởng của bạn.',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          height: 1.5,
                        ),
                      ),
                      if (editing) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Ngày tạo: ${formatNoteDate(widget.note!.createdAt)}',
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      _label('TIÊU ĐỀ'),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const ValueKey('note-title'),
                        controller: _title,
                        enabled: !_saving,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        maxLength: 120,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Đặt tên cho ghi chú…',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Vui lòng nhập tiêu đề.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _label('NỘI DUNG'),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const ValueKey('note-content'),
                        controller: _content,
                        enabled: !_saving,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        minLines: 8,
                        maxLines: 18,
                        style: const TextStyle(fontSize: 16, height: 1.7),
                        decoration: InputDecoration(
                          hintText: 'Viết điều bạn muốn ghi nhớ…',
                          fillColor: AppTheme.noteColors[_colorIndex]
                              .withValues(alpha: 0.45),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Vui lòng nhập nội dung.'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      _label('MÀU GHI CHÚ'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: List.generate(
                          AppTheme.noteColors.length,
                          (index) => Semantics(
                            button: true,
                            selected: index == _colorIndex,
                            label: 'Màu ${AppTheme.colorNames[index]}',
                            child: Tooltip(
                              message: AppTheme.colorNames[index],
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: _saving
                                    ? null
                                    : () => setState(() => _colorIndex = index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: AppTheme.noteColors[index],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: index == _colorIndex
                                          ? AppTheme.accent
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: index == _colorIndex
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 21,
                                          color: AppTheme.accent,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _saveBar(bool editing) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 712),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                key: const ValueKey('save-note'),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 20),
                label: Text(
                  _saving
                      ? 'Đang lưu…'
                      : editing
                      ? 'Lưu thay đổi'
                      : 'Lưu ghi chú',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ghi chú được lưu trên thiết bị của bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
