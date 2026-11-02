import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/common.dart';
import '../../data/api/api_errors.dart';
import '../../data/models/models.dart';
import '../../data/repositories/vendor_repository.dart';

/// Two-pane inbox on wide screens, list → conversation on phones.
///
/// The thread list only carries a preview, so a conversation is loaded from
/// its detail endpoint when opened (the old screen rendered the empty
/// `messages` array from the list and had no working send button).
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _repo = VendorRepository();
  List<ChatThread> _threads = [];
  String? _activeId;
  bool _loading = true;
  String? _error;
  String _query = '';
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    // Light polling so a client's reply appears without a manual refresh.
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = _threads.isEmpty;
        _error = null;
      });
    }
    try {
      final t = await _repo.threads();
      if (!mounted) return;
      setState(() {
        _threads = t;
        _loading = false;
        if (_activeId == null && t.isNotEmpty && Responsive.isWide(context)) _activeId = t.first.id;
      });
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _loading = false;
        _error = apiErrorMessage(e, fallback: 'Could not load your messages.');
      });
    }
  }

  void _select(ChatThread t) {
    setState(() {
      _activeId = t.id;
      final i = _threads.indexWhere((x) => x.id == t.id);
      if (i != -1) _threads[i] = _threads[i].copyWith(unread: 0);
    });
  }

  void _onSent(String threadId, String text) {
    final i = _threads.indexWhere((x) => x.id == threadId);
    if (i == -1) return;
    setState(() {
      final updated = _threads[i].copyWith(lastMessage: text, time: DateTime.now());
      _threads
        ..removeAt(i)
        ..insert(0, updated);
    });
  }

  List<ChatThread> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _threads;
    return _threads.where((t) => '${t.name} ${t.lastMessage}'.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _threads.isEmpty) return ErrorView(message: _error!, onRetry: _load);
    if (_loading) return const LoadingView();
    final active = _threads.where((t) => t.id == _activeId).firstOrNull;

    final list = _ThreadList(
      threads: _visible,
      activeId: _activeId,
      onTap: _select,
      onSearch: (v) => setState(() => _query = v),
      onRefresh: _load,
      empty: _threads.isEmpty,
    );

    if (Responsive.isMobile(context)) {
      if (active == null) return list;
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) setState(() => _activeId = null);
        },
        child: _ChatView(
          key: ValueKey(active.id),
          thread: active,
          repo: _repo,
          onBack: () => setState(() => _activeId = null),
          onSent: (text) => _onSent(active.id, text),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(responsiveValue(context, mobile: 16, tablet: 20, desktop: 28)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const PageHeader(title: 'Messages', subtitle: 'Conversations with clients from your bookings and inquiries'),
        const SizedBox(height: 18),
        Expanded(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              SizedBox(width: Responsive.isTablet(context) ? 280 : 340, child: list),
              VerticalDivider(width: 1, color: AppColors.border),
              Expanded(
                child: active == null
                    ? const EmptyView(message: 'Select a conversation', icon: Icons.forum_outlined)
                    : _ChatView(
                        key: ValueKey(active.id),
                        thread: active,
                        repo: _repo,
                        onSent: (text) => _onSent(active.id, text),
                      ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ThreadList extends StatelessWidget {
  final List<ChatThread> threads;
  final String? activeId;
  final ValueChanged<ChatThread> onTap;
  final ValueChanged<String> onSearch;
  final Future<void> Function() onRefresh;
  final bool empty;
  const _ThreadList({
    required this.threads,
    required this.activeId,
    required this.onTap,
    required this.onSearch,
    required this.onRefresh,
    required this.empty,
  });

  String _when(DateTime t) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(t, now)) return DateFormat('h:mm a').format(t);
    if (now.difference(t).inDays < 7) return DateFormat('EEE').format(t);
    return DateFormat('d MMM').format(t);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(10),
        children: [
          if (Responsive.isMobile(context))
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 12),
              child: Text('Messages', style: AppType.display(size: 22)),
            ),
          Padding(padding: const EdgeInsets.only(bottom: 8), child: SearchField(hint: 'Search conversations…', onChanged: onSearch)),
          if (empty)
            const EmptyView(
              icon: Icons.chat_bubble_outline,
              message: 'No conversations yet',
              detail: 'When a client messages you about an inquiry or booking, the conversation appears here.',
            )
          else if (threads.isEmpty)
            const EmptyView(icon: Icons.search_off, message: 'No matches')
          else
            for (final t in threads)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Material(
                  color: activeId == t.id ? AppColors.gold.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onTap(t),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        InitialsAvatar(name: t.name, size: 42),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(
                                child: Text(t.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppType.body(size: 14, weight: t.unread > 0 ? FontWeight.w700 : FontWeight.w600)),
                              ),
                              Text(_when(t.time), style: AppType.mono(size: 11)),
                            ]),
                            const SizedBox(height: 3),
                            Row(children: [
                              Expanded(
                                child: Text(t.lastMessage.isEmpty ? 'No messages yet' : t.lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppType.body(
                                        size: 12.5, color: t.unread > 0 ? AppColors.textPrimary : AppColors.textMuted)),
                              ),
                              if (t.unread > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                                  decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(10)),
                                  child: Text('${t.unread}',
                                      style: AppType.mono(size: 11, weight: FontWeight.w700, color: AppColors.onAccent(AppColors.gold))),
                                ),
                            ]),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  final ChatThread thread;
  final VendorRepository repo;
  final VoidCallback? onBack;
  final ValueChanged<String> onSent;
  const _ChatView({super.key, required this.thread, required this.repo, required this.onSent, this.onBack});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _messages = [...widget.thread.messages];
    _load();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final t = await widget.repo.threadDetail(widget.thread.id);
      if (!mounted) return;
      setState(() {
        // Keep any optimistic bubbles that have not round-tripped yet.
        final pending = _messages.where((m) => m.pending || m.failed).toList();
        _messages = [...t.messages, ...pending];
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _loading = false;
        _error = apiErrorMessage(e, fallback: 'Could not load this conversation.');
      });
    }
  }

  Future<void> _send([ChatMessage? retry]) async {
    final text = retry?.text ?? _input.text.trim();
    if (text.isEmpty) return;
    final optimistic = ChatMessage(text, true, DateTime.now(), pending: true);
    setState(() {
      if (retry != null) _messages.remove(retry);
      _messages.add(optimistic);
      if (retry == null) _input.clear();
    });
    _focus.requestFocus();
    try {
      await widget.repo.sendMessage(widget.thread.id, text);
      if (!mounted) return;
      setState(() {
        final i = _messages.indexOf(optimistic);
        if (i != -1) _messages[i] = ChatMessage(text, true, optimistic.time);
      });
      widget.onSent(text);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final i = _messages.indexOf(optimistic);
        if (i != -1) _messages[i] = ChatMessage(text, true, optimistic.time, failed: true);
      });
      Toast.error(Toast.of(context), apiErrorMessage(e, fallback: 'Message not sent — tap it to retry.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.thread;
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(children: [
          if (widget.onBack != null) IconButton(tooltip: 'Back', onPressed: widget.onBack, icon: const Icon(Icons.arrow_back, size: 20)),
          InitialsAvatar(name: t.name, size: 38),
          const SizedBox(width: 12),
          Expanded(child: Text(t.name, overflow: TextOverflow.ellipsis, style: AppType.body(size: 14.5, weight: FontWeight.w700))),
          IconButton(tooltip: 'Refresh', onPressed: () => _load(), icon: const Icon(Icons.refresh, size: 20)),
        ]),
      ),
      Expanded(
        child: _loading
            ? const LoadingView()
            : _error != null && _messages.isEmpty
                ? ErrorView(message: _error!, onRetry: _load)
                : _messages.isEmpty
                    ? const EmptyView(icon: Icons.waving_hand_outlined, message: 'Say hello', detail: 'Start the conversation below.')
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final idx = _messages.length - 1 - i;
                          final m = _messages[idx];
                          final prev = idx > 0 ? _messages[idx - 1] : null;
                          final newDay = prev == null || !DateUtils.isSameDay(prev.time, m.time);
                          return Column(children: [
                            if (newDay)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text(DateFormat('EEE, d MMM').format(m.time), style: AppType.mono(size: 11)),
                              ),
                            _bubble(m),
                          ]);
                        },
                      ),
      ),
      SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: CallbackShortcuts(
                bindings: {const SingleActivator(LogicalKeyboardKey.enter): () => _send()},
                child: TextField(
                  controller: _input,
                  focusNode: _focus,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(hintText: 'Type a message…'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _input,
              builder: (_, v, __) => IconButton.filled(
                tooltip: 'Send',
                onPressed: v.text.trim().isEmpty ? null : () => _send(),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.onAccent(AppColors.gold),
                  disabledBackgroundColor: AppColors.surfaceAlt,
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _bubble(ChatMessage m) {
    final mine = m.fromMe;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: m.failed ? () => _send(m) : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: Responsive.isMobile(context) ? 280 : 420),
          decoration: BoxDecoration(
            color: m.failed ? AppColors.dangerSoft : (mine ? AppColors.gold : AppColors.surfaceAlt),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(mine ? 14 : 4),
              bottomRight: Radius.circular(mine ? 4 : 14),
            ),
            border: m.failed ? Border.all(color: AppColors.danger) : null,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(m.text,
                style: AppType.body(
                    size: 13.5,
                    height: 1.4,
                    color: m.failed ? AppColors.textPrimary : (mine ? AppColors.onAccent(AppColors.gold) : AppColors.textPrimary))),
            const SizedBox(height: 4),
            Text(
              m.failed ? 'Not sent · tap to retry' : (m.pending ? 'Sending…' : DateFormat('h:mm a').format(m.time)),
              style: AppType.mono(
                size: 10,
                color: m.failed
                    ? AppColors.danger
                    : (mine ? AppColors.onAccent(AppColors.gold).withValues(alpha: .75) : AppColors.textMuted),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
