import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:gv_ui/gv_ui.dart';

import '../core/app_colors.dart';
import '../core/gv_toast.dart';
import '../services/im_api.dart';

Future<void> showReportDialog(
  BuildContext context, {
  required ImApi api,
  required int targetUserId,
  required String targetName,
}) {
  return showGvIosModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetCtx) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom),
      child: SafeArea(
        top: false,
        child: _ReportSheet(
          api: api,
          targetUserId: targetUserId,
          targetName: targetName,
        ),
      ),
    ),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({
    required this.api,
    required this.targetUserId,
    required this.targetName,
  });

  final ImApi api;
  final int targetUserId;
  final String targetName;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _selectedReason;
  final _descController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedReason == null) {
      GvToast.show(context, l10n.reportPickReason);
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.api.submitReport(
        targetId: widget.targetUserId,
        reason: _selectedReason!,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      GvToast.show(context, l10n.reportSubmitted);
    } catch (e) {
      if (!mounted) return;
      GvToast.show(context, l10n.reportFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fg = AppColors.textPrimary.resolveFrom(context);
    final fgSec = AppColors.textSecondary.resolveFrom(context);
    final reasons = [
      l10n.reportReasonObscene,
      l10n.reportReasonHarassment,
      l10n.reportReasonScam,
      l10n.reportReasonPolitical,
      l10n.reportReasonIllegal,
      l10n.reportReasonOther,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GvSpacing.page,
            vertical: 12,
          ),
          child: Text(
            l10n.reportTitle(widget.targetName),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GvSpacing.page,
            vertical: 8,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: reasons.map((r) {
              final selected = _selectedReason == r;
              return ChoiceChip(
                label: Text(r),
                selected: selected,
                selectedColor:
                    CupertinoColors.systemBlue.withValues(alpha: 0.15),
                onSelected: (_) => setState(() => _selectedReason = r),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GvSpacing.page),
          child: TextField(
            controller: _descController,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: l10n.reportDescHint,
              hintStyle: TextStyle(color: fgSec),
              filled: true,
              fillColor: AppColors.bgSearchField.resolveFrom(context),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: GvSpacing.fieldH,
                vertical: GvSpacing.fieldV,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GvRadii.input),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GvSpacing.page),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.reportSubmit),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
