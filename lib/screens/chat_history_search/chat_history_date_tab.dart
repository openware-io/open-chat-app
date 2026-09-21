import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gv_chat_app/l10n/app_localizations.dart';
import 'package:gv_ui/gv_ui.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../core/message_preview.dart';
import '../../models/chat_message.dart';
import '../../providers/chat/chat_raw_message_parsing.dart';
import '../../services/im_api.dart';

///「日期」分类：进入即日历，有聊天记录的日期带圆点标记，点选后展示当天消息（对齐微信）。
class ChatHistoryDateTab extends StatefulWidget {
  const ChatHistoryDateTab({
    super.key,
    required this.peerId,
    required this.chatType,
    required this.senderLabel,
    required this.onOpenMessage,
  });

  final String peerId;
  final String chatType;
  final String Function(ChatMessage m) senderLabel;
  final void Function(ChatMessage m) onOpenMessage;

  @override
  State<ChatHistoryDateTab> createState() => _ChatHistoryDateTabState();
}

class _ChatHistoryDateTabState extends State<ChatHistoryDateTab> {
  final Set<String> _markedDates = <String>{};
  DateTime _visibleMonth =
      DateTime(DateTime.now().year, DateTime.now().month);
  String? _selectedDate;
  List<ChatMessage> _dayMessages = <ChatMessage>[];
  bool _loadingDay = false;

  @override
  void initState() {
    super.initState();
    _loadDates();
  }

  static String _keyOf(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadDates() async {
    try {
      final dates = await context.read<ImApi>().messageHistoryDates(
            peerId: widget.peerId,
            chatType: widget.chatType,
          );
      if (!mounted) return;
      setState(() {
        _markedDates
          ..clear()
          ..addAll(dates);
        if (dates.isNotEmpty) {
          final latest = DateTime.tryParse(dates.first);
          if (latest != null) {
            _visibleMonth = DateTime(latest.year, latest.month);
          }
        }
      });
    } catch (_) {
      // 标记日期拉取失败时保持空日历，用户仍可切换月份。
    }
  }

  Future<void> _selectDate(String key) async {
    setState(() {
      _selectedDate = key;
      _dayMessages = <ChatMessage>[];
      _loadingDay = true;
    });
    try {
      final raw = await context.read<ImApi>().messageHistory(
            peerId: widget.peerId,
            chatType: widget.chatType,
            date: key,
            pageSize: 200,
          );
      final msgs = parseChatHistoryRaw(raw)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (!mounted) return;
      setState(() {
        _dayMessages = msgs;
        _loadingDay = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDay = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _calendarCard(context, l10n),
        Divider(height: 1, color: Theme.of(context).dividerColor),
        Expanded(child: _messagesBody(context, l10n)),
      ],
    );
  }

  Widget _calendarCard(BuildContext context, AppLocalizations l10n) {
    final secondary = AppColors.textSecondary.resolveFrom(context);
    return Material(
      color: AppColors.bgWhite.resolveFrom(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(LucideIcons.chevron_left,
                      size: 20, color: secondary),
                  onPressed: () => _changeMonth(-1),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      l10n.chatHistoryMonthLabel(
                          _visibleMonth.year, _visibleMonth.month),
                      style: GvTypography.navTitle(
                          AppColors.textPrimary.resolveFrom(context)),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(LucideIcons.chevron_right,
                      size: 20, color: secondary),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            Row(
              children: [
                for (final w in _weekdayLabels(l10n))
                  Expanded(
                    child: Center(
                      child: Text(w, style: GvTypography.caption(secondary)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            _monthGrid(context),
          ],
        ),
      ),
    );
  }

  List<String> _weekdayLabels(AppLocalizations l10n) => [
        l10n.chatHistoryWeekMon,
        l10n.chatHistoryWeekTue,
        l10n.chatHistoryWeekWed,
        l10n.chatHistoryWeekThu,
        l10n.chatHistoryWeekFri,
        l10n.chatHistoryWeekSat,
        l10n.chatHistoryWeekSun,
      ];

  Widget _monthGrid(BuildContext context) {
    final year = _visibleMonth.year;
    final month = _visibleMonth.month;
    final firstDay = DateTime(year, month, 1);
    final leading = firstDay.weekday - 1; // 周一开头
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final cells = <Widget>[
      for (var i = 0; i < leading; i++) const SizedBox(),
      for (var d = 1; d <= daysInMonth; d++) _dayCell(context, DateTime(year, month, d)),
    ];
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox());
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }

  Widget _dayCell(BuildContext context, DateTime day) {
    final primary = AppColors.primary.resolveFrom(context);
    final key = _keyOf(day);
    final marked = _markedDates.contains(key);
    final selected = _selectedDate == key;
    final textColor = selected
        ? Colors.white
        : marked
            ? AppColors.textPrimary.resolveFrom(context)
            : AppColors.textHint.resolveFrom(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: marked ? () => _selectDate(key) : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: selected
                ? BoxDecoration(color: primary, shape: BoxShape.circle)
                : null,
            child: Text(
              '${day.day}',
              style: GvTypography.body(textColor),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 4,
            child: marked
                ? Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: selected ? 1 : 0.7),
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _messagesBody(BuildContext context, AppLocalizations l10n) {
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final primary = AppColors.primary.resolveFrom(context);
    if (_selectedDate == null) {
      return Center(
        child: Text(
          l10n.chatHistoryDateSelect,
          style: GvTypography.caption(secondary),
        ),
      );
    }
    if (_loadingDay) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: primary),
        ),
      );
    }
    if (_dayMessages.isEmpty) {
      return Center(
        child: Text(
          l10n.chatHistoryDateEmpty,
          style: GvTypography.caption(secondary),
        ),
      );
    }
    return _dayMessageList(context, l10n);
  }

  Widget _dayMessageList(BuildContext context, AppLocalizations l10n) {
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final dividerColor = Theme.of(context).dividerColor;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: GvSpacing.page),
      itemCount: _dayMessages.length,
      itemBuilder: (context, i) {
        final m = _dayMessages[i];
        final preview = previewTextFromContent(m.msgType, m.content);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (i > 0)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: dividerColor,
              ),
            InkWell(
              onTap: () => widget.onOpenMessage(m),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.senderLabel(m),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GvTypography.caption(secondary),
                          ),
                        ),
                        Text(
                          formatChatTime(m.timestamp),
                          style: GvTypography.caption(secondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview.isEmpty ? ' ' : preview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GvTypography.body(
                        AppColors.textPrimary.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
