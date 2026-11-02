import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/responsive/responsive.dart';
import '../../core/utils/file_saver.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/responsive_table.dart';
import '../../data/api/api_errors.dart';
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
  String? _error;
  String _type = 'all';

  static final _cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

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
      final e = await _repo.earnings();
      if (!mounted) return;
      setState(() {
        _all = e;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = apiErrorMessage(e, fallback: 'Could not load your earnings.');
        });
      }
    }
  }

  double _sum(bool Function(EarningTxn) where) => _all.where(where).fold<double>(0, (s, e) => s + e.amount);

  /// Settled earnings less what has already been paid out or refunded.
  double get _available {
    final settled = _sum((e) => e.type == TxnType.earning && e.status == 'settled');
    final out = _sum((e) => (e.type == TxnType.payout || e.type == TxnType.refund) && e.status != 'failed');
    return (settled - out).clamp(0, double.infinity);
  }

  double get _pending => _sum((e) => e.type == TxnType.earning && e.status == 'pending');
  double get _lifetime => _sum((e) => e.type == TxnType.earning);
  double get _paidOut => _sum((e) => e.type == TxnType.payout && e.status != 'failed');

  List<EarningTxn> get _visible => _type == 'all' ? _all : _all.where((e) => e.type.name == _type).toList();

  Future<void> _export() async {
    final m = Toast.of(context);
    if (_all.isEmpty) {
      Toast.info(m, 'There are no transactions to export yet.');
      return;
    }
    final df = DateFormat('yyyy-MM-dd');
    final csv = toCsv(
      ['Transaction ID', 'Date', 'Description', 'Type', 'Status', 'Amount (INR)'],
      [
        for (final e in _all)
          [e.id, df.format(e.date), e.source, StatusUi.txn(e.type).$1, e.status, e.type == TxnType.earning ? e.amount : -e.amount],
      ],
    );
    final downloaded = await saveTextFile('aonego9-statement-${df.format(DateTime.now())}.csv', csv);
    Toast.ok(m, downloaded ? 'Statement downloaded' : 'Statement copied to clipboard as CSV');
  }

  Future<void> _requestPayout() async {
    final available = _available;
    if (available <= 0) {
      Toast.info(Toast.of(context), 'There is no settled balance to withdraw yet.');
      return;
    }
    final req = await showAdaptiveSheet<(double, String)>(
      context,
      builder: (_) => _PayoutForm(available: available),
    );
    if (req == null || !mounted) return;
    final m = Toast.of(context);
    try {
      await _repo.sendToDesk(
        'payout_request',
        message: 'Payout request for ${_cur.format(req.$1)} (available ${_cur.format(available)}).'
            '${req.$2.isEmpty ? '' : '\nPay to: ${req.$2}'}',
        extra: {'amount': req.$1, 'payout_to': req.$2},
      );
      Toast.ok(m, 'Payout request for ${_cur.format(req.$1)} sent — the desk processes payouts within 2–3 working days.');
    } catch (e) {
      Toast.error(m, apiErrorMessage(e, fallback: 'Could not send the payout request.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _all.isEmpty) return ErrorView(message: _error!, onRetry: _load);
    if (_loading) return const LoadingView();
    final list = _visible;

    return PageBody(
      onRefresh: _load,
      children: [
        PageHeader(
          title: 'Earnings',
          subtitle: 'Balance, payouts and your full transaction history',
          actions: [
            OutlinedButton.icon(onPressed: _export, icon: const Icon(Icons.download_outlined, size: 18), label: const Text('Statement (CSV)')),
          ],
        ),
        const SizedBox(height: 20),
        _walletCard(),
        const SizedBox(height: 16),
        ResponsiveGrid(minTileWidth: 200, children: [
          StatCard(label: 'Lifetime earnings', value: _cur.format(_lifetime), icon: Icons.trending_up, color: AppColors.success),
          StatCard(label: 'Pending settlement', value: _cur.format(_pending), icon: Icons.hourglass_bottom, color: AppColors.warning),
          StatCard(label: 'Paid out', value: _cur.format(_paidOut), icon: Icons.account_balance_outlined, color: AppColors.info),
        ]),
        const SizedBox(height: 20),
        SectionCard(
          title: 'Transactions',
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            PillBar(children: [
              for (final (v, l) in const [('all', 'All'), ('earning', 'Earnings'), ('payout', 'Payouts'), ('refund', 'Refunds')])
                FilterPill(
                  label: l,
                  selected: _type == v,
                  count: v == 'all' ? _all.length : _all.where((e) => e.type.name == v).length,
                  onTap: () => setState(() => _type = v),
                ),
            ]),
            const SizedBox(height: 10),
            if (list.isEmpty)
              const EmptyView(
                icon: Icons.receipt_long_outlined,
                message: 'No transactions yet',
                detail: 'Earnings appear here once bookings are completed and settled.',
              )
            else
              ResponsiveTable(
                columns: const [
                  TableColumn('Date', flex: 2),
                  TableColumn('Description', flex: 4),
                  TableColumn('Type', flex: 2),
                  TableColumn('Status', flex: 2),
                  TableColumn('Amount', flex: 2, numeric: true),
                ],
                rowCount: list.length,
                mobileCardBuilder: (i) => _mobileRow(list[i]),
                cellsBuilder: (i) {
                  final e = list[i];
                  final (label, color) = StatusUi.txn(e.type);
                  final credit = e.type == TxnType.earning;
                  return [
                    tcell(DateFormat('d MMM yyyy').format(e.date)),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(e.source.isEmpty ? '—' : e.source,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.body(size: 13.5, weight: FontWeight.w600)),
                      Text(e.id, style: AppType.mono(size: 11)),
                    ]),
                    StatusChip(label: label, color: color),
                    _statusChip(e.status),
                    tcell('${credit ? '+' : '−'}${_cur.format(e.amount)}',
                        numeric: true, weight: FontWeight.w700, color: credit ? AppColors.success : AppColors.textPrimary),
                  ];
                },
              ),
          ]),
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    final c = switch (status) {
      'settled' || 'paid' || 'completed' => AppColors.success,
      'failed' => AppColors.danger,
      _ => AppColors.warning,
    };
    return StatusChip(label: status.isEmpty ? '—' : status[0].toUpperCase() + status.substring(1), color: c);
  }

  Widget _mobileRow(EarningTxn e) {
    final (label, color) = StatusUi.txn(e.type);
    final credit = e.type == TxnType.earning;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(e.source.isEmpty ? label : e.source, style: AppType.body(size: 13.5, weight: FontWeight.w600))),
          Text('${credit ? '+' : '−'}${_cur.format(e.amount)}',
              style: AppType.mono(size: 14, weight: FontWeight.w700, color: credit ? AppColors.success : AppColors.textPrimary)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          StatusChip(label: label, color: color),
          const SizedBox(width: 6),
          _statusChip(e.status),
          const Spacer(),
          Text(DateFormat('d MMM yyyy').format(e.date), style: AppType.mono(size: 11.5)),
        ]),
      ]),
    );
  }

  Widget _walletCard() {
    final mobile = Responsive.isMobile(context);
    final actions = [
      ElevatedButton.icon(
        onPressed: _requestPayout,
        icon: const Icon(Icons.account_balance, size: 18),
        label: const Text('Request payout'),
      ),
      OutlinedButton.icon(
        onPressed: _export,
        icon: const Icon(Icons.receipt_long_outlined, size: 16),
        label: const Text('Download statement'),
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.premiumWash),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Flex(
        direction: mobile ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: mobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: mobile ? 0 : 1,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AVAILABLE TO WITHDRAW', style: AppType.eyebrow(color: AppColors.textSecondary, size: 10.5)),
              const SizedBox(height: 8),
              Text(_cur.format(_available), style: AppType.display(size: 32, weight: FontWeight.w700, color: AppColors.gold)),
              const SizedBox(height: 4),
              Text('${_cur.format(_pending)} pending settlement after booking completion',
                  style: AppType.body(size: 12.5, color: AppColors.textMuted)),
            ]),
          ),
          SizedBox(width: mobile ? 0 : 16, height: mobile ? 18 : 0),
          Wrap(spacing: 10, runSpacing: 10, children: actions),
        ],
      ),
    );
  }
}

class _PayoutForm extends StatefulWidget {
  final double available;
  const _PayoutForm({required this.available});
  @override
  State<_PayoutForm> createState() => _PayoutFormState();
}

class _PayoutFormState extends State<_PayoutForm> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(text: widget.available.toStringAsFixed(0));
  final _to = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _to.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Request a payout', style: AppType.display(size: 20)),
          const SizedBox(height: 4),
          Text('Available: ${cur.format(widget.available)}. The AOneGo9 desk verifies and transfers payouts within 2–3 working days.',
              style: AppType.body(size: 12.5, color: AppColors.textSecondary, height: 1.45)),
          const SizedBox(height: 18),
          LabeledField(
            label: 'Amount (₹)',
            child: TextFormField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(prefixText: '₹ '),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim()) ?? 0;
                if (n <= 0) return 'Enter an amount';
                if (n > widget.available) return 'You can withdraw up to ${cur.format(widget.available)}';
                return null;
              },
            ),
          ),
          LabeledField(
            label: 'Pay to (UPI ID or bank account)',
            hint: 'Leave blank to use the payout details already on file with the desk.',
            child: TextFormField(controller: _to, decoration: const InputDecoration(hintText: 'name@bank  or  A/C 1234…, IFSC')),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (!(_formKey.currentState?.validate() ?? false)) return;
                Navigator.pop(context, (double.parse(_amount.text.trim()), _to.text.trim()));
              },
              child: const Text('Send request'),
            ),
          ),
        ]),
      ),
    );
  }
}
