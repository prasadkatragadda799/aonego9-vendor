import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive.dart';
import '../../core/category/vendor_category.dart';
import '../../core/widgets/common.dart';
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
  List<KpiPoint>? _trend;
  List<VendorBooking>? _requests;
  List<VendorBooking>? _upcoming;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _repo.dashboardSummary();
    final t = await _repo.earningsTrend();
    final b = await _repo.bookings();
    if (!mounted) return;
    setState(() {
      _summary = s;
      _trend = t;
      _requests = b.where((x) => x.status == BookingStatus.requested).toList();
      _upcoming = b.where((x) => x.status == BookingStatus.confirmed).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_summary == null) return const LoadingView();
    final cur = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹', decimalDigits: 1);
    final cols = responsiveValue(context, mobile: 2, tablet: 2, desktop: 4);
    final cfg = VendorSession.config;

    final cards = <Widget>[
      StatCard(label: 'Month Earnings', value: cur.format(_summary!['monthEarnings']), icon: Icons.account_balance_wallet_outlined, color: AppColors.gold, delta: '+22%'),
      StatCard(label: 'Pending Payout', value: cur.format(_summary!['pendingPayout']), icon: Icons.schedule, color: AppColors.warning),
      StatCard(label: 'New Requests', value: '${_summary!['pendingRequests']}', icon: Icons.mark_email_unread_outlined, color: AppColors.info),
      StatCard(label: 'Avg. Rating', value: '${_summary!['rating']} ★', icon: Icons.star_outline, color: AppColors.success),
    ];

    return ListView(
      padding: EdgeInsets.all(responsiveValue(context, mobile: 16, desktop: 28)),
      children: [
        FadeUp(
          child: PageHeader(
            eyebrow: cfg.label,
            accent: cfg.accent,
            title: 'Welcome back, Spotlight 👋',
            subtitle: DateFormat('EEEE, d MMMM yyyy').format(DateTime(2026, 6, 16)),
            actions: [ElevatedButton.icon(onPressed: () => context.go('/services'), icon: const Icon(Icons.add, size: 18), label: const Text('New Service'))],
          ),
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: responsiveValue(context, mobile: 1.5, tablet: 2.0, desktop: 1.7),
          children: [
            for (var i = 0; i < cards.length; i++)
              FadeUp(delay: Duration(milliseconds: 60 + i * 55), child: cards[i]),
          ],
        ),
        const SizedBox(height: 24),
        FadeUp(
          delay: const Duration(milliseconds: 220),
          child: ResponsiveLayout(
            mobile: (_) => Column(children: [_earningsCard(), const SizedBox(height: 16), _requestsCard()]),
            desktop: (_) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 2, child: _earningsCard()),
              const SizedBox(width: 16),
              Expanded(child: _requestsCard()),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        FadeUp(delay: const Duration(milliseconds: 300), child: _upcomingCard()),
      ],
    );
  }

  Widget _earningsCard() {
    final pts = _trend ?? [];
    return SectionCard(
      title: 'Earnings (₹ Lakh)',
      actions: [StatusChip(label: 'Last 6 months', color: AppColors.info)],
      child: SizedBox(
        height: 240,
        child: LineChart(LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= pts.length) return const SizedBox();
              return Padding(padding: const EdgeInsets.only(top: 6), child: Text(pts[i].label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)));
            })),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < pts.length; i++) FlSpot(i.toDouble(), pts[i].value)],
              isCurved: true,
              color: AppColors.gold,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.gold.withValues(alpha: 0.25), AppColors.gold.withValues(alpha: 0.0)])),
            ),
          ],
        )),
      ),
    );
  }

  Widget _requestsCard() {
    final cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return SectionCard(
      title: 'New Requests',
      actions: [TextButton(onPressed: () => context.go('/bookings'), child: const Text('All'))],
      child: (_requests ?? []).isEmpty
          ? const EmptyView(message: 'No pending requests')
          : Column(children: [
              for (final b in _requests!)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(b.clientName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5))),
                      Text(cur.format(b.amount), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.gold, fontSize: 13)),
                    ]),
                    const SizedBox(height: 2),
                    Text(b.service, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(DateFormat('d MMM yyyy').format(b.date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ]),
                ),
            ]),
    );
  }

  Widget _upcomingCard() {
    final cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return SectionCard(
      title: 'Upcoming Bookings',
      actions: [TextButton(onPressed: () => context.go('/calendar'), child: const Text('Calendar'))],
      child: (_upcoming ?? []).isEmpty
          ? const EmptyView(message: 'Nothing scheduled')
          : Column(children: [
              for (final b in _upcoming!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(DateFormat('dd').format(b.date), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold, fontSize: 16)),
                        Text(DateFormat('MMM').format(b.date), style: const TextStyle(color: AppColors.gold, fontSize: 10)),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.service, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      Text('${b.clientName} · ${b.location}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ])),
                    if (!Responsive.isMobile(context)) ...[
                      Text(cur.format(b.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 14),
                    ],
                    StatusChip(label: StatusUi.booking(b.status).$1, color: StatusUi.booking(b.status).$2),
                  ]),
                ),
            ]),
    );
  }
}
