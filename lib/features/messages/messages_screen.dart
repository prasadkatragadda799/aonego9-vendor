import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../../data/repositories/vendor_repository.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _repo = VendorRepository();
  List<ChatThread> _threads = [];
  ChatThread? _active;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo.threads().then((t) {
      if (mounted) setState(() { _threads = t; _active = t.isNotEmpty ? t.first : null; _loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();

    if (Responsive.isMobile(context)) {
      return _active == null
          ? _ThreadList(threads: _threads, active: null, onTap: (t) => setState(() => _active = t))
          : _ChatView(thread: _active!, onBack: () => setState(() => _active = null));
    }

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const PageHeader(title: 'Messages', subtitle: 'Chat with clients and AOneGo9 support'),
        const SizedBox(height: 20),
        Expanded(
          child: Card(
            child: Row(children: [
              SizedBox(width: 320, child: _ThreadList(threads: _threads, active: _active, onTap: (t) => setState(() => _active = t))),
              const VerticalDivider(width: 1),
              Expanded(child: _active == null ? const EmptyView(message: 'Select a conversation') : _ChatView(thread: _active!)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ThreadList extends StatelessWidget {
  final List<ChatThread> threads;
  final ChatThread? active;
  final ValueChanged<ChatThread> onTap;
  const _ThreadList({required this.threads, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        if (Responsive.isMobile(context))
          const Padding(padding: EdgeInsets.all(12), child: Text('Messages', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20))),
        for (final t in threads)
          Material(
            color: active?.id == t.id ? AppColors.gold.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onTap(t),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  InitialsAvatar(name: t.name, size: 42),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis)),
                      Text(DateFormat('HH:mm').format(t.time), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ]),
                    const SizedBox(height: 3),
                    Row(children: [
                      Expanded(child: Text(t.lastMessage, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (t.unread > 0) Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(10)),
                        child: Text('${t.unread}', style: const TextStyle(color: Color(0xFF1A1407), fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ])),
                ]),
              ),
            ),
          ),
      ],
    );
  }
}

class _ChatView extends StatelessWidget {
  final ChatThread thread;
  final VoidCallback? onBack;
  const _ChatView({required this.thread, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(children: [
          if (onBack != null) IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, size: 20)),
          InitialsAvatar(name: thread.name, size: 38),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(thread.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Text('Active now', style: TextStyle(color: AppColors.success, fontSize: 12)),
          ])),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, size: 20)),
        ]),
      ),
      Expanded(
        child: ListView(
          reverse: true,
          padding: const EdgeInsets.all(16),
          children: [
            for (final m in thread.messages.reversed)
              Align(
                alignment: m.fromMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: const BoxConstraints(maxWidth: 360),
                  decoration: BoxDecoration(
                    color: m.fromMe ? AppColors.gold : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(m.text, style: TextStyle(color: m.fromMe ? const Color(0xFF1A1407) : AppColors.textPrimary, fontSize: 13.5, height: 1.4)),
                ),
              ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
        child: Row(children: [
          const Expanded(child: TextField(decoration: InputDecoration(hintText: 'Type a message…'))),
          const SizedBox(width: 10),
          CircleAvatar(radius: 22, backgroundColor: AppColors.gold, child: IconButton(onPressed: () {}, icon: const Icon(Icons.send, size: 18, color: Color(0xFF1A1407)))),
        ]),
      ),
    ]);
  }
}
