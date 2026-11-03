import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/responsive/responsive.dart';
import '../../core/category/vendor_category.dart';
import '../../core/widgets/common.dart';
import '../../data/api/api_errors.dart';
import '../../data/models/models.dart';
import '../../data/models/status_ui.dart';
import '../../data/repositories/vendor_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = VendorRepository();
  Map<String, num>? _summary;
  List<KpiPoint> _trend = [];
  List<VendorBooking> _requests = [];
  List<VendorBooking> _upcoming = [];
  List<(String, bool, String)> _checklist = [];
  String? _error;
  final Set<String> _busy = {};

  static final _cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      // The summary is the page; everything else degrades to empty so one
      // slow endpoint cannot blank the dashboard.
      final results = await Future.wait<Object?>([
        _repo.dashboardSummary(),
        _repo.earningsTrend().catchError((_) => <KpiPoint>[]),
        _repo.bookings().catchError((_) => <VendorBooking>[]),
        _repo.myProfile().catchError((_) => <String, dynamic>{}),
        _repo.portfolio().catchError((_) => <Map<String, dynamic>>[]),
        _repo.services().catchError((_) => <ServicePackage>[]),
      ]);
      if (!mounted) return;
      final bookings = results[2] as List<VendorBooking>;
      final today = DateUtils.dateOnly(DateTime.now());
      final profile = results[3] as Map<String, dynamic>;
      if (profile.isNotEmpty) VendorSession.setVendorFromProfile(profile);
      setState(() {
        _summary = results[0] as Map<String, num>;
        _trend = results[1] as List<KpiPoint>;
        _requests = bookings.where((x) => x.status == BookingStatus.requested).toList();
        _upcoming = bookings
            .where((x) =>
                (x.status == BookingStatus.confirmed || x.status == BookingStatus.inProgress) &&
                !DateUtils.dateOnly(x.date).isBefore(today))
            .take(6)
            .toList();
        _checklist = _buildChecklist(profile, results[4] as List, results[5] as List<ServicePackage>);
      });
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e, fallback: 'Could not load your dashboard.'));
    }
  }

  List<(String, bool, String)> _buildChecklist(Map<String, dynamic> p, List portfolio, List<ServicePackage> services) {
    String s(String k) => '${p[k] ?? ''}'.trim();
    final gallery = (p['gallery_urls'] as List?)?.isNotEmpty ?? false;
    return [
      ('Add a profile photo', s('avatar_url').isNotEmpty, '/profile'),
      ('Write a bio clients will read', s('bio').length >= 40, '/profile'),
      ('Add your phone and city', s('phone').isNotEmpty && s('city').isNotEmpty, '/profile'),
      ('Upload portfolio work', portfolio.isNotEmpty || gallery, '/profile'),
      ('Publish at least one package', services.any((x) => x.active), '/services'),
      ('Get KYC verified', p['kyc_verified'] == true, '/settings'),
    ];
  }

  Future<void> _respond(VendorBooking b, BookingStatus s) async {
    if (s == BookingStatus.cancelled) {
      final ok = await confirmAction(
        context,
        title: 'Decline this request?',
        message: '${b.clientName} will be told you are unavailable for ${b.service} on ${DateFormat('d MMM yyyy').format(b.date)}.',
        confirmLabel: 'Decline',
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    final m = Toast.of(context);
    setState(() => _busy.add(b.id));
    try {
      await _repo.respondBooking(b.id, s);
      Toast.ok(m, s == BookingStatus.confirmed ? 'Booking accepted — ${b.clientName} has been notified' : 'Request declined');
      await _load();
    } catch (e) {
      Toast.error(m, apiErrorMessage(e, fallback: 'Could not update the booking.'));
    } finally {
      if (mounted) setState(() => _busy.remove(b.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _summary == null) return ErrorView(message: _error!, onRetry: _load);
    if (_summary == null) return const LoadingView();
    final cfg = VendorSession.config;
    final s = _summary!;
    final first = (VendorSession.contactName.isNotEmpty ? VendorSession.contactName : VendorSession.vendorName).split(' ').first;
    final rating = (s['rating'] ?? 0).toDouble();

    final cards = <Widget>[
      StatCard(
        label: 'Total earned',
        value: money(s['monthEarnings'] ?? 0),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.gold,
        onTap: () => context.go('/earnings'),
      ),
      StatCard(
        label: 'Pending payout',
        value: money(s['pendingPayout'] ?? 0),
        icon: Icons.schedule,
        color: AppColors.warning,
        onTap: () => context.go('/earnings'),
      ),
      StatCard(
        label: 'New requests',
        value: '${s['pendingRequests'] ?? _requests.length}',
        icon: Icons.mark_email_unread_outlined,
        color: AppColors.info,
        onTap: () => context.go('/bookings'),
      ),
      StatCard(
        label: (s['reviews'] ?? 0) > 0 ? 'Rating · ${s['reviews']} reviews' : 'Average rating',
        value: rating == 0 ? '—' : '${rating.toStringAsFixed(1)} ★',
        icon: Icons.star_outline,
        color: AppColors.success,
        onTap: () => context.go('/reviews'),
      ),
    ];
    final open = _checklist.where((c) => !c.$2).toList();

    return PageBody(
      onRefresh: _load,
      children: [
        FadeUp(
          child: PageHeader(
            eyebrow: cfg.label,
            accent: cfg.accent,
            title: 'Welcome back, $first',
            subtitle: DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
            actions: [
              OutlinedButton.icon(
                onPressed: () => context.go('/calendar'),
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: const Text('Calendar'),
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('/services'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New package'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        ResponsiveGrid(minTileWidth: 200, children: [
          for (var i = 0; i < cards.length; i++) FadeUp(delay: Duration(milliseconds: 60 + i * 55), child: cards[i]),
        ]),
        if (open.isNotEmpty) ...[
          const SizedBox(height: 20),
          FadeUp(delay: const Duration(milliseconds: 180), child: _checklistCard(open.length)),
        ],
        const SizedBox(height: 20),
        FadeUp(
          delay: const Duration(milliseconds: 220),
          child: ResponsiveLayout(
            mobile: (_) => Column(children: [_requestsCard(), const SizedBox(height: 16), _earningsCard()]),
            tablet: (_) => Column(children: [_requestsCard(), const SizedBox(height: 16), _earningsCard()]),
            desktop: (_) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _earningsCard()),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _requestsCard()),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        FadeUp(delay: const Duration(milliseconds: 300), child: _upcomingCard()),
      ],
    );
  }

  Widget _checklistCard(int remaining) {
    final done = _checklist.length - remaining;
    return SectionCard(
      title: 'Get discovered on AOneGo9',
      actions: [StatusChip(label: '$done of ${_checklist.length} done', color: AppColors.gold)],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: done / _checklist.length, minHeight: 6),
        ),
        const SizedBox(height: 12),
        Text('Complete profiles get more inquiries — clients compare portfolios and packages before reaching out.',
            style: AppType.body(size: 12.5, color: AppColors.textSecondary, height: 1.45)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in _checklist)
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: c.$2 ? null : () => context.go(c.$3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: c.$2 ? AppColors.successSoft : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.$2 ? AppColors.success.withValues(alpha: .4) : AppColors.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(c.$2 ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 15, color: c.$2 ? AppColors.success : AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(c.$1,
                      style: AppType.body(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: c.$2 ? AppColors.success : AppColors.textPrimary)),
                  if (!c.$2) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 15, color: AppColors.textMuted),
                  ],
                ]),
              ),
            ),
        ]),
      ]),
    );
  }

  Widget _earningsCard() {
    final pts = _trend;
    final hasData = pts.any((p) => p.value > 0);
    final maxV = pts.fold<double>(0, (m, p) => p.value > m ? p.value : m);
    return SectionCard(
      title: 'Earnings trend',
      actions: [if (pts.isNotEmpty) StatusChip(label: 'Last ${pts.length} months', color: AppColors.info)],
      child: SizedBox(
        height: 240,
        child: !hasData
            ? const EmptyView(
                icon: Icons.show_chart,
                message: 'No earnings yet',
                detail: 'Completed bookings will chart here month by month.',
              )
            : LineChart(LineChartData(
                minY: 0,
                maxY: maxV * 1.15,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceAlt,
                    getTooltipItems: (spots) => [
                      for (final s in spots)
                        LineTooltipItem(
                          '${pts[s.x.toInt()].label}\n${_cur.format(s.y)}',
                          AppType.body(size: 12, weight: FontWeight.w600),
                        ),
                    ],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (v, meta) => v == meta.max
                          ? const SizedBox()
                          : Text(NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(v),
                              style: AppType.mono(size: 10.5)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= pts.length || v != i.toDouble()) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(pts[i].label, style: AppType.mono(size: 10.5)),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [for (var i = 0; i < pts.length; i++) FlSpot(i.toDouble(), pts[i].value)],
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: AppColors.gold,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.gold.withValues(alpha: 0.25), AppColors.gold.withValues(alpha: 0.0)],
                      ),
                    ),
                  ),
                ],
              )),
      ),
    );
  }

  Widget _requestsCard() {
    return SectionCard(
      title: 'New requests',
      actions: [TextButton(onPressed: () => context.go('/bookings'), child: const Text('View all'))],
      child: _requests.isEmpty
          ? const EmptyView(
              icon: Icons.mark_email_read_outlined,
              message: 'You are all caught up',
              detail: 'New booking requests and inquiries from the marketplace appear here.',
            )
          : Column(children: [
              for (final b in _requests.take(4))
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Text(b.clientName.isEmpty ? 'Client' : b.clientName,
                            overflow: TextOverflow.ellipsis, style: AppType.body(size: 13.5, weight: FontWeight.w700)),
                      ),
                      Text(b.amount > 0 ? _cur.format(b.amount) : 'Quote',
                          style: AppType.mono(size: 13, weight: FontWeight.w700, color: AppColors.gold)),
                    ]),
                    const SizedBox(height: 3),
                    Text(
                      [b.service, DateFormat('EEE, d MMM').format(b.date), if (b.location.isNotEmpty) b.location].join(' · '),
                      style: AppType.body(size: 12, color: AppColors.textMuted),
                    ),
                    if (b.inquiryRef != null) ...[
                      const SizedBox(height: 4),
                      Text('Inquiry ${b.inquiryRef}', style: AppType.mono(size: 11, color: AppColors.info)),
                    ],
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _busy.contains(b.id) ? null : () => _respond(b, BookingStatus.confirmed),
                          style: ElevatedButton.styleFrom(minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 10)),
                          child: _busy.contains(b.id) ? const ButtonSpinner() : const Text('Accept'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy.contains(b.id) ? null : () => _respond(b, BookingStatus.cancelled),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 38),
                            foregroundColor: AppColors.danger,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                    ]),
                  ]),
                ),
              if (_requests.length > 4)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => context.go('/bookings'),
                    child: Text('+ ${_requests.length - 4} more requests'),
                  ),
                ),
            ]),
    );
  }

  Widget _upcomingCard() {
    return SectionCard(
      title: 'Upcoming bookings',
      actions: [TextButton(onPressed: () => context.go('/calendar'), child: const Text('Open calendar'))],
      child: _upcoming.isEmpty
          ? const EmptyView(icon: Icons.event_available_outlined, message: 'Nothing scheduled yet', detail: 'Confirmed bookings appear here in date order.')
          : Column(children: [
              for (final b in _upcoming)
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context.go('/bookings?q=${Uri.encodeQueryComponent(b.inquiryRef ?? b.clientName)}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.gold.withValues(alpha: .3)),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(DateFormat('dd').format(b.date),
                              style: AppType.display(size: 16, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 0)),
                          Text(DateFormat('MMM').format(b.date).toUpperCase(),
                              style: AppType.eyebrow(size: 8.5, color: AppColors.gold)),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(b.service, overflow: TextOverflow.ellipsis, style: AppType.body(size: 13.5, weight: FontWeight.w600)),
                          Text([b.clientName, if (b.location.isNotEmpty) b.location].join(' · '),
                              overflow: TextOverflow.ellipsis, style: AppType.body(size: 12, color: AppColors.textMuted)),
                        ]),
                      ),
                      if (!Responsive.isMobile(context)) ...[
                        Text(_cur.format(b.amount), style: AppType.mono(size: 13, weight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(width: 14),
                      ],
                      StatusChip(label: StatusUi.booking(b.status).$1, color: StatusUi.booking(b.status).$2),
                    ]),
                  ),
                ),
            ]),
    );
  }
}
