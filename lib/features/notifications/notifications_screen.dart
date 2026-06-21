import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/common.dart';
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

  @override
  void initState() {
    super.initState();
    _repo.notifications().then((n) {
      if (mounted) setState(() { _all = n; _loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    return ListView(
      padding: EdgeInsets.all(responsiveValue(context, mobile: 16, desktop: 28)),
      children: [
        PageHeader(
          title: 'Notifications',
          subtitle: 'Booking, payment and account activity',
          actions: [TextButton(onPressed: () {}, child: const Text('Mark all read'))],
        ),
        const SizedBox(height: 20),
        SectionCard(
          padding: const EdgeInsets.all(8),
          child: Column(children: [
            for (var i = 0; i < _all.length; i++) ...[
              _row(_all[i]),
              if (i < _all.length - 1) const Divider(height: 1),
            ],
          ]),
        ),
      ],
    );
  }

  Widget _row(NotificationItem n) {
    return Container(
      padding: const EdgeInsets.all(14),
      color: n.unread ? AppColors.gold.withValues(alpha: 0.05) : Colors.transparent,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: StatusUi.kindColor(n.kind).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
          child: Icon(StatusUi.kind(n.kind), size: 18, color: StatusUi.kindColor(n.kind)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
            if (n.unread) const Padding(padding: EdgeInsets.only(left: 8), child: CircleAvatar(radius: 4, backgroundColor: AppColors.gold)),
          ]),
          const SizedBox(height: 3),
          Text(n.body, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          const SizedBox(height: 4),
          Text(DateFormat('d MMM, HH:mm').format(n.time), style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
        ])),
      ]),
    );
  }
}
