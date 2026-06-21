import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/responsive_table.dart';
import '../../data/models/models.dart';
import '../../data/models/status_ui.dart';
import '../../data/repositories/vendor_repository.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final _repo = VendorRepository();
  List<EarningTxn> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo.earnings().then((e) {
      if (mounted) setState(() { _all = e; _loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    final cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final settled = _all.where((e) => e.type == TxnType.earning && e.status == 'settled').fold<double>(0, (s, e) => s + e.amount);
    final pending = _all.where((e) => e.type == TxnType.earning && e.status == 'pending').fold<double>(0, (s, e) => s + e.amount);

    return ListView(
      padding: EdgeInsets.all(responsiveValue(context, mobile: 16, desktop: 28)),
      children: [
        PageHeader(title: 'Earnings', subtitle: 'Wallet, payouts and transaction history'),
        const SizedBox(height: 24),
        _walletCard(cur, settled, pending),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Transactions',
          padding: const EdgeInsets.all(16),
          child: ResponsiveTable(
            columns: const [
              TableColumn('ID', flex: 2),
              TableColumn('Source', flex: 4),
              TableColumn('Type', flex: 2),
              TableColumn('Date', flex: 2),
              TableColumn('Amount', flex: 2, numeric: true),
              TableColumn('Status', flex: 2),
            ],
            rowCount: _all.length,
            cellsBuilder: (i) {
              final e = _all[i];
              final (label, color) = StatusUi.txn(e.type);
              final sign = e.type == TxnType.payout || e.type == TxnType.refund ? '-' : '+';
              return [
                tcell(e.id, color: AppColors.textMuted),
                tcell(e.source, weight: FontWeight.w600),
                StatusChip(label: label, color: color),
                tcell(DateFormat('d MMM').format(e.date)),
                tcell('$sign${cur.format(e.amount)}', numeric: true, weight: FontWeight.w700, color: sign == '+' ? AppColors.success : AppColors.textPrimary),
                StatusChip(label: e.status[0].toUpperCase() + e.status.substring(1), color: e.status == 'settled' ? AppColors.success : AppColors.warning),
              ];
            },
          ),
        ),
      ],
    );
  }

  Widget _walletCard(NumberFormat cur, double settled, double pending) {
    final content = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2A2410), Color(0xFF1C1F27)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Available balance', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Text(cur.format(settled), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 30)),
        const SizedBox(height: 4),
        Text('${cur.format(pending)} pending settlement', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 20),
        Row(children: [
          ElevatedButton.icon(onPressed: () => _withdraw(cur, settled), icon: const Icon(Icons.account_balance, size: 18), label: const Text('Withdraw')),
          const SizedBox(width: 12),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.receipt_long_outlined, size: 16), label: const Text('Statements')),
        ]),
      ]),
    );

    if (Responsive.isMobile(context)) return content;
    return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(flex: 2, child: content),
      const SizedBox(width: 16),
      Expanded(child: StatCard(label: 'Lifetime Earnings', value: cur.format(settled + pending + 510000), icon: Icons.trending_up, color: AppColors.success, delta: '+22%')),
      const SizedBox(width: 16),
      Expanded(child: StatCard(label: 'Next Payout', value: '18 Jun', icon: Icons.event_outlined, color: AppColors.info)),
    ]);
  }

  void _withdraw(NumberFormat cur, double balance) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Withdraw funds'),
        content: Text('Transfer ${cur.format(balance)} to your linked bank account ••4521?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal initiated'), backgroundColor: AppColors.surfaceAlt)); }, child: const Text('Confirm')),
        ],
      ),
    );
  }
}
