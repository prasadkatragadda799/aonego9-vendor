import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/common.dart';
import '../../data/api/api_errors.dart';
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
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selected = DateUtils.dateOnly(DateTime.now());
  List<VendorBooking> _all = [];
  bool _loading = true;
  String? _error;
  int _loadToken = 0;

  static final _cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Paging months quickly must not let an older response overwrite a newer one.
    final token = ++_loadToken;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final b = await _repo.calendarBookings(_month.year, _month.month);
      if (!mounted || token != _loadToken) return;
      setState(() {
        _all = b;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _loading = false;
        _error = apiErrorMessage(e, fallback: 'Could not load your calendar.');
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
      final today = DateUtils.dateOnly(DateTime.now());
      _selected = (today.year == _month.year && today.month == _month.month) ? today : _month;
    });
    _load();
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _month = DateTime(now.year, now.month, 1);
      _selected = DateUtils.dateOnly(now);
    });
    _load();
  }

  List<VendorBooking> _on(DateTime d) => _all
      .where((b) => DateUtils.isSameDay(b.date, d) && b.status != BookingStatus.cancelled)
      .toList();

  @override
  Widget build(BuildContext context) {
    return PageBody(
      onRefresh: _load,
      children: [
        PageHeader(
          title: 'Calendar',
          subtitle: 'Your shoots and events at a glance',
          actions: [
            OutlinedButton.icon(onPressed: _goToday, icon: const Icon(Icons.today_outlined, size: 18), label: const Text('Today')),
          ],
        ),
        const SizedBox(height: 20),
        if (_error != null)
          ErrorView(message: _error!, onRetry: _load)
        else
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
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    final startWeekday = first.weekday % 7; // Sun=0
    final today = DateUtils.dateOnly(DateTime.now());
    const dow = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final mobile = Responsive.isMobile(context);

    final cells = <Widget>[
      for (final d in dow)
        Center(child: Text(mobile ? d.substring(0, 1) : d, style: AppType.eyebrow(size: 10, color: AppColors.textMuted))),
      for (var i = 0; i < startWeekday; i++) const SizedBox(),
    ];
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_month.year, _month.month, day);
      final items = _on(date);
      final selected = DateUtils.isSameDay(date, _selected);
      final isToday = DateUtils.isSameDay(date, today);
      cells.add(Semantics(
        button: true,
        selected: selected,
        label: '${DateFormat('d MMMM').format(date)}, ${items.length} bookings',
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _selected = date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: selected ? AppColors.gold : (items.isNotEmpty ? AppColors.gold.withValues(alpha: .08) : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? AppColors.gold : (isToday ? AppColors.gold.withValues(alpha: .6) : Colors.transparent)),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$day',
                  style: AppType.body(
                    size: 13,
                    weight: selected || isToday ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.onAccent(AppColors.gold) : AppColors.textPrimary,
                  )),
              if (items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    for (final b in items.take(3))
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.onAccent(AppColors.gold) : StatusUi.booking(b.status).$2,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ]),
                ),
            ]),
          ),
        ),
      ));
    }

    final monthItems = _all.where((b) => b.status != BookingStatus.cancelled).toList();
    final booked = monthItems.map((b) => DateUtils.dateOnly(b.date)).toSet().length;
    final value = monthItems.fold<double>(0, (s, b) => s + b.amount);

    return SectionCard(
      child: Column(children: [
        Row(children: [
          IconButton(tooltip: 'Previous month', onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: Text(DateFormat('MMMM yyyy').format(_month),
                textAlign: TextAlign.center, style: AppType.display(size: 18, weight: FontWeight.w600)),
          ),
          IconButton(tooltip: 'Next month', onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
        ]),
        const SizedBox(height: 4),
        Text(
          _loading ? 'Loading…' : '${monthItems.length} bookings · $booked busy days · ${_cur.format(value)}',
          style: AppType.mono(size: 11.5),
        ),
        const SizedBox(height: 10),
        Stack(children: [
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: mobile ? 0.9 : 1.15,
            children: cells,
          ),
          if (_loading) const Positioned.fill(child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 14, runSpacing: 6, children: [
          for (final s in const [BookingStatus.requested, BookingStatus.confirmed, BookingStatus.inProgress, BookingStatus.completed])
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: StatusUi.booking(s).$2, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(StatusUi.booking(s).$1, style: AppType.body(size: 11.5, color: AppColors.textMuted)),
            ]),
        ]),
      ]),
    );
  }

  Widget _dayCard() {
    final items = _on(_selected);
    return SectionCard(
      title: DateFormat('EEEE, d MMM').format(_selected),
      actions: [if (items.isNotEmpty) StatusChip(label: '${items.length} booked', color: AppColors.gold)],
      child: items.isEmpty
          ? EmptyView(
              message: 'Free on this day',
              icon: Icons.event_available_outlined,
              detail: _selected.isBefore(DateUtils.dateOnly(DateTime.now())) ? null : 'You are available for new bookings.',
            )
          : Column(children: [
              for (final b in items)
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.go('/bookings?q=${Uri.encodeQueryComponent(b.inquiryRef ?? b.clientName)}'),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border(left: BorderSide(color: StatusUi.booking(b.status).$2, width: 3)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(b.service, style: AppType.body(size: 13.5, weight: FontWeight.w600))),
                        StatusChip(label: StatusUi.booking(b.status).$1, color: StatusUi.booking(b.status).$2),
                      ]),
                      const SizedBox(height: 6),
                      Text([b.clientName, if (b.location.isNotEmpty) b.location].join(' · '),
                          style: AppType.body(size: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Text(_cur.format(b.amount), style: AppType.mono(size: 13, weight: FontWeight.w700, color: AppColors.gold)),
                    ]),
                  ),
                ),
            ]),
    );
  }
}
