import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../../data/models/status_ui.dart';
import '../../data/repositories/vendor_repository.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _repo = VendorRepository();
  DateTime _month = DateTime(2026, 6, 1);
  DateTime _selected = DateTime(2026, 6, 16);
  List<VendorBooking> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo.bookings().then((b) {
      if (mounted) setState(() { _all = b; _loading = false; });
    });
  }

  List<VendorBooking> _on(DateTime d) =>
      _all.where((b) => b.date.year == d.year && b.date.month == d.month && b.date.day == d.day).toList();

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    return ListView(
      padding: EdgeInsets.all(responsiveValue(context, mobile: 16, desktop: 28)),
      children: [
        PageHeader(title: 'Calendar', subtitle: 'Your shoots and availability at a glance'),
        const SizedBox(height: 24),
        ResponsiveLayout(
          mobile: (_) => Column(children: [_calendarCard(), const SizedBox(height: 16), _dayCard()]),
          desktop: (_) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: _calendarCard()),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _dayCard()),
          ]),
        ),
      ],
    );
  }

  Widget _calendarCard() {
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startWeekday = first.weekday % 7; // Sun=0
    final cells = <Widget>[];
    const dow = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    for (final d in dow) {
      cells.add(Center(child: Text(d, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))));
    }
    for (var i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_month.year, _month.month, day);
      final has = _on(date).isNotEmpty;
      final selected = date.day == _selected.day && date.month == _selected.month;
      cells.add(InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _selected = date),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: selected ? AppColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.gold : Colors.transparent),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$day', style: TextStyle(color: selected ? const Color(0xFF1A1407) : AppColors.textPrimary, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
            if (has) Container(margin: const EdgeInsets.only(top: 3), width: 5, height: 5, decoration: BoxDecoration(color: selected ? const Color(0xFF1A1407) : AppColors.gold, shape: BoxShape.circle)),
          ]),
        ),
      ));
    }

    return SectionCard(
      child: Column(children: [
        Row(children: [
          Text(DateFormat('MMMM yyyy').format(_month), style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1, 1)), icon: const Icon(Icons.chevron_left)),
          IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1, 1)), icon: const Icon(Icons.chevron_right)),
        ]),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.0,
          children: cells,
        ),
      ]),
    );
  }

  Widget _dayCard() {
    final items = _on(_selected);
    final cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return SectionCard(
      title: DateFormat('EEEE, d MMM').format(_selected),
      child: items.isEmpty
          ? const EmptyView(message: 'No bookings this day', icon: Icons.event_available_outlined)
          : Column(children: [
              for (final b in items)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(b.service, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
                      StatusChip(label: StatusUi.booking(b.status).$1, color: StatusUi.booking(b.status).$2),
                    ]),
                    const SizedBox(height: 6),
                    Text('${b.clientName} · ${b.location}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(cur.format(b.amount), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                ),
            ]),
    );
  }
}
