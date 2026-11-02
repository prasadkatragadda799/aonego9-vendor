import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../core/utils/date_util.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/responsive/responsive.dart';
import '../../core/utils/launch_util.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../../data/repositories/vendor_repository.dart';
import '../../data/upload_service.dart';
import '../../core/utils/image_pick_util.dart';
import '../../data/api/api_errors.dart';


/// Subscription & billing — the vendor's plan with AOneGo9.
///
/// Paid plans are no longer activated instantly: the vendor scans a UPI QR,
/// pays manually, uploads a receipt, and an admin approves the request on
/// the backend before the plan actually switches over.
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
  List<SubscriptionRequest> _requests = [];
  PaymentSettings? _payment;
  bool _loading = true;
  String? _error;

  SubscriptionRequest? get _pendingRequest {
    for (final r in _requests) {
      if (r.status == 'pending') return r;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _plans.isEmpty;
      _error = null;
    });
    try {
      // Plans are the page; the rest degrade so one failing endpoint does
      // not hide the plans a vendor came here to compare.
      final results = await Future.wait<Object?>([
        _repo.plans(),
        _repo.currentSubscription().catchError((_) => null),
        _repo.billingHistory().catchError((_) => <BillingEntry>[]),
        _repo.paymentInfo().then<PaymentSettings?>((v) => v).catchError((_) => null),
        _repo.myRequests().catchError((_) => <SubscriptionRequest>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _plans = results[0] as List<SubscriptionPlan>;
        _sub = results[1] as VendorSubscription?;
        _billing = results[2] as List<BillingEntry>;
        _payment = results[3] as PaymentSettings?;
        _requests = results[4] as List<SubscriptionRequest>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = apiErrorMessage(e, fallback: 'Could not load plans.');
        });
      }
    }
  }

  Future<void> _choose(SubscriptionPlan p) async {
    if (p.id == _sub?.planId) return;
    if (_pendingRequest != null) return;

    if (p.price == 0) {
      // Free plans switch instantly — no receipt needed.
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Switch to ${p.name}?'),
          content: Text('You will move to the free ${p.name} plan at the end of the current cycle.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Switch')),
          ],
        ),
      );
      if (confirmed != true) return;
      if (!mounted) return;
      final m = Toast.of(context);
      try {
        final req = await _repo.requestSubscription(p.id, '');
        await _load();
        Toast.ok(m, req.status == 'approved' ? 'You are now on the ${p.name} plan' : 'Request submitted — the desk will review it shortly');
      } catch (e) {
        Toast.error(m, apiErrorMessage(e, fallback: 'Could not switch plans.'));
      }
      return;
    }

    if (_payment == null || !_payment!.isConfigured) {
      Toast.error(Toast.of(context), 'Online payment is not set up yet. Contact the AOneGo9 desk from Settings to upgrade.');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => _PaymentDialog(plan: p, payment: _payment!, repo: _repo, onSubmitted: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _plans.isEmpty) return ErrorView(message: _error!, onRetry: _load);
    if (_loading) return const LoadingView();
    final pending = _pendingRequest;
    final rejected = _requests.where((r) => r.status == 'rejected').firstOrNull;
    final showUpgradeBanner = _sub != null &&
        _sub!.price > 0 &&
        _plans.any((p) => p.price >= _sub!.price && p.id != _sub!.planId);
    return PageBody(
      onRefresh: _load,
      children: [
        const PageHeader(title: 'Subscription & Billing', subtitle: 'Manage your AOneGo9 plan and invoices'),
        const SizedBox(height: 24),
        if (_sub != null) _currentCard(),
        if (pending != null) ...[
          const SizedBox(height: 16),
          _pendingCard(pending),
        ] else if (rejected != null && rejected.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)))) ...[
          const SizedBox(height: 16),
          InlineNotice(
            icon: Icons.error_outline,
            color: AppColors.danger,
            message: 'Your ${rejected.planName} request was not approved'
                '${(rejected.adminNote ?? '').trim().isEmpty ? '.' : ': ${rejected.adminNote}'} You can submit a new request below.',
          ),
        ],
        const SizedBox(height: 24),
        if (showUpgradeBanner) ...[
          _upgradeBanner(),
          const SizedBox(height: 14),
        ],
        Text('Plans', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 14),
        if (_plans.isEmpty)
          const EmptyView(icon: Icons.workspace_premium_outlined, message: 'No plans available right now', detail: 'Plans are being updated — check back shortly.')
        else
          ResponsiveGrid(minTileWidth: 250, maxColumns: 3, children: [for (final p in _plans) _planCard(p, pending: pending != null)]),
        const SizedBox(height: 24),
        _billingCard(),
      ],
    );
  }

  Widget _upgradeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.trending_up, size: 18, color: AppColors.gold),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "You're on the ${_sub!.planName} plan — upgrade for more",
            style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ]),
    );
  }

  Widget _pendingCard(SubscriptionRequest r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Your ${r.planName} subscription is pending admin review',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            const SizedBox(height: 4),
            Text('Submitted ${formatIstDateTime(r.createdAt)}', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _currentCard() {
    final cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final s = _sub!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.premiumWash),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Current plan', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(width: 10),
              StatusChip(label: s.status == 'active' ? 'Active' : s.status, color: AppColors.success),
            ]),
            const SizedBox(height: 8),
            Text(s.planName, style: AppType.display(size: 26, weight: FontWeight.w700, color: AppColors.gold)),
            const SizedBox(height: 4),
            Text(
              s.price == 0 ? 'Free forever' : '${cur.format(s.price)} · renews ${DateFormat('d MMM yyyy').format(s.renewsOn)}',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
          ]),
        ),
        Icon(Icons.workspace_premium_outlined, color: AppColors.gold, size: 40),
      ]),
    );
  }

  Widget _planCard(SubscriptionPlan p, {required bool pending}) {
    final cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isCurrent = p.id == _sub?.planId;
    final isDowngrade = _sub != null && _sub!.price > 0 && p.price < _sub!.price && !isCurrent;
    final accent = p.recommended ? AppColors.gold : AppColors.border;
    return Opacity(
      opacity: isDowngrade ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isCurrent ? AppColors.gold : accent, width: isCurrent || p.recommended ? 1.4 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(p.name, style: AppType.body(size: 16, weight: FontWeight.w700))),
            if (p.recommended) StatusChip(label: 'Popular', color: AppColors.gold),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(p.price == 0 ? 'Free' : cur.format(p.price), style: AppType.display(size: 24, weight: FontWeight.w700)),
            if (p.price != 0) Text(p.periodShort, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ]),
          const SizedBox(height: 14),
          for (final f in p.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.check_circle, size: 15, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(child: Text(f, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35))),
              ]),
            ),
          const Spacer(),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: isCurrent
                ? const OutlinedButton(onPressed: null, child: Text('Current plan'))
                : ElevatedButton(
                    onPressed: pending ? null : () => _choose(p),
                    child: Text(p.price == 0 ? 'Switch' : (isDowngrade ? 'Downgrade' : 'Upgrade')),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _billingCard() {
    final cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final df = DateFormat('d MMM yyyy');
    return SectionCard(
      title: 'Billing History',
      child: _billing.isEmpty
          ? const EmptyView(icon: Icons.receipt_long_outlined, message: 'No invoices yet', detail: 'Paid plan invoices appear here.')
          : Column(
        children: [
          for (final b in _billing)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b.description, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5)),
                  Text('${b.id} · ${df.format(b.date)}', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ])),
                Text(cur.format(b.amount), style: AppType.mono(size: 13.5, weight: FontWeight.w700, color: AppColors.textPrimary)),
                if (!Responsive.isMobile(context)) ...[
                  const SizedBox(width: 12),
                  StatusChip(label: b.status == 'paid' ? 'Paid' : b.status, color: b.status == 'paid' ? AppColors.success : AppColors.warning),
                ],
              ]),
            ),
        ],
      ),
    );
  }
}

/// UPI-QR + receipt upload dialog for a paid plan.
class _PaymentDialog extends StatefulWidget {
  final SubscriptionPlan plan;
  final PaymentSettings payment;
  final VendorRepository repo;
  final Future<void> Function() onSubmitted;
  const _PaymentDialog({required this.plan, required this.payment, required this.repo, required this.onSubmitted});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  Uint8List? _imageBytes;
  bool _submitting = false;

  String get _upiLink {
    final p = widget.payment;
    final plan = widget.plan;
    return 'upi://pay?pa=${p.upiId}&pn=${Uri.encodeComponent(p.payeeName)}'
        '&am=${plan.price.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent('AONEGO9 ${plan.name}')}';
  }


  Future<void> _pickReceipt() async {
    try {
      final picked = await pickImageFromGallery();
      if (picked == null || !mounted) return;
      setState(() => _imageBytes = picked.bytes);
    } catch (_) {
      if (mounted) Toast.error(Toast.of(context), 'Could not open the photo picker.');
    }
  }

  Future<void> _submit() async {
    if (_imageBytes == null || _submitting) return;
    // Captured up front: the dialog is gone by the time the toast shows.
    final m = Toast.of(context);
    final nav = Navigator.of(context);
    setState(() => _submitting = true);
    try {
      final url = await UploadService.uploadImage(
        bytes: _imageBytes!,
        filename: 'receipt.jpg',
        folder: 'receipts',
      );
      await widget.repo.requestSubscription(widget.plan.id, url);
      nav.pop();
      Toast.ok(m, "Receipt submitted — you'll be notified once the desk approves it");
      await widget.onSubmitted();
    } catch (e) {
      if (mounted) setState(() => _submitting = false);
      Toast.error(m, friendlyApiError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return AlertDialog(
      title: Text('Subscribe to ${widget.plan.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${cur.format(widget.plan.price)} · ${widget.plan.name}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Scan with any UPI app to pay, then upload the receipt below',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: QrImageView(data: _upiLink, size: 180, backgroundColor: Colors.white),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => copyToClipboard(context, widget.payment.upiId, label: 'UPI ID copied'),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(widget.payment.upiId, style: AppType.mono(size: 12.5, color: AppColors.textSecondary)),
                  const SizedBox(width: 6),
                  Icon(Icons.copy, size: 14, color: AppColors.textMuted),
                ]),
              ),
            ),
            if (widget.payment.payeeName.isNotEmpty)
              Text('Payee: ${widget.payment.payeeName}', style: AppType.body(size: 11.5, color: AppColors.textMuted)),
            const SizedBox(height: 18),
            if (_imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(_imageBytes!, height: 120, fit: BoxFit.cover),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: _submitting ? null : _pickReceipt,
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: Text(_imageBytes == null ? 'Upload payment receipt' : 'Change receipt'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _submitting ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: (_imageBytes == null || _submitting) ? null : _submit,
          child: _submitting
              ? const ButtonSpinner()
              : const Text('Submit for review'),
        ),
      ],
    );
  }
}
