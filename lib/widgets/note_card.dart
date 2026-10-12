import 'package:flutter/material.dart';

import '../models/note.dart';
import '../theme/app_theme.dart';
import '../utils/note_date.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onActions,
    required this.onDelete,
    this.enabled = true,
  });
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onActions;
  final Future<void> Function() onDelete;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Dismissible(
    key: ValueKey('dismiss-${note.id}'),
    direction: enabled ? DismissDirection.endToStart : DismissDirection.none,
    confirmDismiss: (_) async {
      await onDelete();
      // Việc loại ghi chú khỏi danh sách do controller quyết định sau khi lưu.
      return false;
    },
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(Icons.delete_outline_rounded), Text('Xóa ghi chú')],
      ),
    ),
    child: Material(
      color: AppTheme.noteColors[note.colorIndex],
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onActions : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 12, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        note.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tùy chọn ghi chú',
                    onPressed: enabled ? onActions : null,
                    icon: const Icon(Icons.more_horiz_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: Color(0xFF596158),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thời gian tạo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF596158),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatNoteDate(note.createdAt),
                          key: ValueKey('note-created-${note.id}'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF596158),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
