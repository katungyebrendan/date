import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report_reason.dart';
import '../providers/safety_providers.dart';

enum _SafetyAction { report, block }

/// Overflow menu offering "Report" and "Block" for another user, reused by
/// [PersonCard] and [ChatScreen]. Owns its own confirmation dialogs and
/// Firestore calls so both call sites stay in sync.
class SafetyMenuButton extends ConsumerWidget {
  const SafetyMenuButton({
    super.key,
    required this.myUid,
    required this.targetUid,
    required this.targetName,
    this.onBlocked,
    this.iconColor,
  });

  final String myUid;
  final String targetUid;
  final String targetName;

  /// Called after a successful block, e.g. to pop a chat screen.
  final VoidCallback? onBlocked;
  final Color? iconColor;

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<(ReportReason, String)>(
      context: context,
      builder: (context) => _ReportDialog(targetName: targetName),
    );
    if (result == null || !context.mounted) return;

    await ref.read(safetyServiceProvider).reportUser(
          reporterUid: myUid,
          reportedUid: targetUid,
          reason: result.$1,
          details: result.$2,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted. Thank you for helping keep Velo safe.')),
    );
  }

  Future<void> _block(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block $targetName?'),
        content: const Text(
          "You won't see each other in Discover or Matches anymore, and they won't be able to message you.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Block', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(safetyServiceProvider).blockUser(uid: myUid, blockedUid: targetUid);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Blocked $targetName.')));
    onBlocked?.call();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopupMenuButton<_SafetyAction>(
      icon: Icon(Icons.more_vert, color: iconColor ?? colorScheme.onSurfaceVariant),
      onSelected: (action) {
        if (action == _SafetyAction.report) {
          _report(context, ref);
        } else {
          _block(context, ref);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _SafetyAction.report,
          child: ListTile(leading: Icon(Icons.flag_outlined), title: Text('Report')),
        ),
        PopupMenuItem(
          value: _SafetyAction.block,
          child: ListTile(
            leading: Icon(Icons.block, color: colorScheme.error),
            title: Text('Block', style: TextStyle(color: colorScheme.error)),
          ),
        ),
      ],
    );
  }
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog({required this.targetName});

  final String targetName;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  ReportReason _reason = ReportReason.inappropriatePhotos;
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report ${widget.targetName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value!),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: ReportReason.values
                    .map(
                      (reason) => RadioListTile<ReportReason>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(reason.label),
                        value: reason,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Additional details (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((_reason, _detailsController.text.trim())),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
