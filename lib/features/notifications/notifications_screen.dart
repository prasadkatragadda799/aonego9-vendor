import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/common.dart';
import '../../data/api/api_errors.dart';
import '../../data/models/models.dart';
import '../../data/models/status_ui.dart';
import '../../data/repositories/vendor_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = VendorRepository();
  List<NotificationItem> _all = [];
  bool _loading = true;
  bool _markingAll = false;
  bool _unreadOnly = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _all.isEmpty;
      _error = null;
    });
    try {
      final n = await _repo.notifications();
      if (!mounted) return;
      setState(() {
        _all = n;
        _loading = false;
      });
      ShellBadges.unread.value = n.where((x) => x.unread).length;
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = apiErrorMessage(e, fallback: 'Could not load notifications.');
        });
      }
    }
  }

  Future<void> _markAll() async {
    final m = Toast.of(context);
    final before = _all;
    setState(() {
      _markingAll = true;
      _all = [for (final n in _all) n.markRead()];
    });
    ShellBadges.unread.value = 0;
    try {
      await _repo.markAllRead();
      Toast.ok(m, 'All caught up');
    } catch (e) {
      if (mounted) setState(() => _all = before);
      ShellBadges.unread.value = before.where((x) => x.unread).length;
      Toast.error(m, apiErrorMessage(e, fallback: 'Could not mark notifications as read.'));
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _open(NotificationItem n) async {
    if (n.unread && n.id.isNotEmpty) {
      final i = _all.indexOf(n);
      setState(() => _all[i] = n.markRead());
      ShellBadges.unread.value = (ShellBadges.unread.value - 1).clamp(0, 1 << 30);
      // Read state is best-effort; the destination still opens if it fails.
      _repo.markNotificationRead(n.id).catchError((_) {});
    }
    final route = switch (n.kind) {
      IconKind.booking => '/bookings',
      IconKind.payment => n.title.toLowerCase().contains('subscription') || n.body.toLowerCase().contains('plan') ? '/subscription' : '/earnings',
      IconKind.review => '/reviews',
      IconKind.message => '/messages',
      IconKind.system => null,
    };
    if (route != null && mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _all.isEmpty) return ErrorView(message: _error!, onRetry: _load);
    if (_loading) return const LoadingView();
    final unread = _all.where((n) => n.unread).length;
    final list = _unreadOnly ? _all.where((n) => n.unread).toList() : _all;

    // Group by day so a long feed stays scannable.
    final groups = <String, List<NotificationItem>>{};
    final today = DateUtils.dateOnly(DateTime.now());
    for (final n in list) {
      final d = DateUtils.dateOnly(n.time);
      final key = d == today
          ? 'Today'
          : d == today.subtract(const Duration(days: 1))
              ? 'Yesterday'
              : DateFormat('EEEE, d MMM').format(d);
      groups.putIfAbsent(key, () => []).add(n);
    }

    return PageBody(
      onRefresh: _load,
      maxWidth: 900,
      children: [
        PageHeader(
          title: 'Notifications',
          subtitle: unread == 0 ? 'Booking, payment and account activity' : '$unread unread',
          actions: [
            OutlinedButton.icon(
              onPressed: unread == 0 || _markingAll ? null : _markAll,
              icon: _markingAll ? ButtonSpinner(color: AppColors.gold) : const Icon(Icons.done_all, size: 18),
              label: const Text('Mark all read'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PillBar(children: [
          FilterPill(label: 'All', count: _all.length, selected: !_unreadOnly, onTap: () => setState(() => _unreadOnly = false)),
          FilterPill(label: 'Unread', count: unread, selected: _unreadOnly, onTap: () => setState(() => _unreadOnly = true)),
        ]),
        const SizedBox(height: 16),
        if (list.isEmpty)
          EmptyView(
            icon: Icons.notifications_none,
            message: _all.isEmpty ? 'No notifications yet' : 'No unread notifications',
            detail: _all.isEmpty ? 'New requests, payments and reviews will show up here.' : null,
          )
        else
          for (final g in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Text(g.key.toUpperCase(), style: AppType.eyebrow(size: 10)),
            ),
            SectionCard(
              padding: const EdgeInsets.all(6),
              child: Column(children: [
                for (var i = 0; i < g.value.length; i++) ...[
                  _row(g.value[i]),
                  if (i < g.value.length - 1) const Divider(height: 1),
                ],
              ]),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _row(NotificationItem n) {
    final color = StatusUi.kindColor(n.kind);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _open(n),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.unread ? AppColors.gold.withValues(alpha: 0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
            child: Icon(StatusUi.kind(n.kind), size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(n.title,
                      style: AppType.body(size: 14, weight: n.unread ? FontWeight.w700 : FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Text(DateFormat('h:mm a').format(n.time), style: AppType.mono(size: 11)),
                if (n.unread)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle)),
                  ),
              ]),
              if (n.body.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(n.body, style: AppType.body(size: 13, color: AppColors.textSecondary, height: 1.45)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
