import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../../data/repositories/vendor_repository.dart';

/// Subscription & billing — the vendor's plan with AOneGo9.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _repo = VendorRepository();
  List<SubscriptionPlan> _plans = [];
  VendorSubscription? _sub;
  List<BillingEntry> _billing = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await _repo.plans();
    final s = await _repo.currentSubscription();
    final b = await _repo.billingHistory();
    if (!mounted) return;
    setState(() { _plans = p; _sub = s; _billing = b; _loading = false; });
  }

  Future<void> _choose(SubscriptionPlan p) async {
    if (p.id == _sub?.planId) return;
    final cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(p.price == 0 ? 'Switch to ${p.name}?' : 'Subscribe to ${p.name}?'),
        content: Text(p.price == 0
            ? 'You will move to the free ${p.name} plan at the end of the current cycle.'
            : 'You will be charged ${cur.format(p.price)} ${p.period}. Cancel anytime.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(p.price == 0 ? 'Switch' : 'Pay & Subscribe')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.changePlan(p.id);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You are now on the ${p.name} plan')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    final cols = responsiveValue(context, mobile: 1, tablet: 3, desktop: 3);
    return ListView(
      padding: EdgeInsets.all(responsiveValue(context, mobile: 16, desktop: 28)),
      children: [
        const PageHeader(title: 'Subscription & Billing', subtitle: 'Manage your AOneGo9 plan and invoices'),
        const SizedBox(height: 24),
        _currentCard(),
        const SizedBox(height: 24),
        Text('Plans', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: responsiveValue(context, mobile: 1.25, tablet: 0.72, desktop: 0.82),
          children: [for (final p in _plans) _planCard(p)],
        ),
        const SizedBox(height: 24),
        _billingCard(),
      ],
    );
  }

  Widget _currentCard() {
    final cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final s = _sub!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2A2410), Color(0xFF1C1F27)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Current plan', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(width: 10),
              StatusChip(label: s.status == 'active' ? 'Active' : s.status, color: AppColors.success),
            ]),
            const SizedBox(height: 8),
            Text(s.planName, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 26)),
            const SizedBox(height: 4),
            Text(
              s.price == 0 ? 'Free forever' : '${cur.format(s.price)} / month · renews ${DateFormat('d MMM yyyy').format(s.renewsOn)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
          ]),
        ),
        const Icon(Icons.workspace_premium_outlined, color: AppColors.gold, size: 40),
      ]),
    );
  }

  Widget _planCard(SubscriptionPlan p) {
    final cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isCurrent = p.id == _sub?.planId;
    final accent = p.recommended ? AppColors.gold : AppColors.border;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isCurrent ? AppColors.gold : accent, width: isCurrent || p.recommended ? 1.4 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const Spacer(),
          if (p.recommended) const StatusChip(label: 'Popular', color: AppColors.gold),
        ]),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(p.price == 0 ? 'Free' : cur.format(p.price), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
          if (p.price != 0) Text(' / mo', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ]),
        const SizedBox(height: 14),
        for (final f in p.features)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.check_circle, size: 15, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(child: Text(f, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35))),
            ]),
          ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: isCurrent
              ? OutlinedButton(onPressed: null, child: const Text('Current plan'))
              : ElevatedButton(onPressed: () => _choose(p), child: Text(p.price == 0 ? 'Switch' : 'Upgrade')),
        ),
      ]),
    );
  }

  Widget _billingCard() {
    final cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final df = DateFormat('d MMM yyyy');
    return SectionCard(
      title: 'Billing History',
      child: Column(
        children: [
          for (final b in _billing)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                const Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b.description, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5)),
                  Text('${b.id} · ${df.format(b.date)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ])),
                Text(cur.format(b.amount), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(width: 12),
                StatusChip(label: b.status == 'paid' ? 'Paid' : b.status, color: b.status == 'paid' ? AppColors.success : AppColors.warning),
              ]),
            ),
        ],
      ),
    );
  }
}
