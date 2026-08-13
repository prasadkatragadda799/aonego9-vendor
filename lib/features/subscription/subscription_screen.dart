import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../../data/repositories/vendor_repository.dart';
import '../../data/upload_service.dart';

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
    final p = await _repo.plans();
    final s = await _repo.currentSubscription();
    final b = await _repo.billingHistory();
    final pay = await _repo.paymentInfo();
    final r = await _repo.myRequests();
    if (!mounted) return;
    setState(() {
      _plans = p;
      _sub = s;
      _billing = b;
      _payment = pay;
      _requests = r;
      _loading = false;
    });
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
      await _repo.requestSubscription(p.id, '');
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You are now on the ${p.name} plan')));
      return;
    }

    if (_payment == null) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _PaymentDialog(plan: p, payment: _payment!, repo: _repo, onSubmitted: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    final cols = responsiveValue(context, mobile: 1, tablet: 3, desktop: 3);
    final pending = _pendingRequest;
    final showUpgradeBanner = _sub != null &&
        _sub!.price > 0 &&
        _plans.any((p) => p.price >= _sub!.price && p.id != _sub!.planId);
    return ListView(
      padding: EdgeInsets.all(responsiveValue(context, mobile: 16, desktop: 28)),
      children: [
        const PageHeader(title: 'Subscription & Billing', subtitle: 'Manage your AOneGo9 plan and invoices'),
        const SizedBox(height: 24),
        if (_sub != null) _currentCard(),
        if (pending != null) ...[
          const SizedBox(height: 16),
          _pendingCard(pending),
        ],
        const SizedBox(height: 24),
        if (showUpgradeBanner) ...[
          _upgradeBanner(),
          const SizedBox(height: 14),
        ],
        Text('Plans', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: responsiveValue(context, mobile: 1.25, tablet: 0.72, desktop: 0.82),
          children: [for (final p in _plans) _planCard(p, pending: pending != null)],
        ),
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
        const Icon(Icons.trending_up, size: 18, color: AppColors.gold),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "You're on the ${_sub!.planName} plan — upgrade for more",
            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ]),
    );
  }

  Widget _pendingCard(SubscriptionRequest r) {
    final df = DateFormat('d MMM yyyy, h:mm a');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        const Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Your ${r.planName} subscription is pending admin review',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            const SizedBox(height: 4),
            Text('Submitted ${df.format(r.createdAt)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
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
            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            if (p.recommended) const StatusChip(label: 'Popular', color: AppColors.gold),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(p.price == 0 ? 'Free' : cur.format(p.price), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
            if (p.price != 0) const Text(' / mo', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
        '&am=${plan.price}&cu=INR&tn=${Uri.encodeComponent('AONEGO9 ${plan.name}')}';
  }


  Future<void> _pickReceipt() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _imageBytes = bytes);
  }

  Future<void> _submit() async {
    if (_imageBytes == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final url = await UploadService.uploadImage(
        bytes: _imageBytes!,
        filename: 'receipt.jpg',
        folder: 'receipts',
      );
      await widget.repo.requestSubscription(widget.plan.id, url);
      if (!mounted) return;
      Navigator.pop(context);
      await widget.onSubmitted();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Submitted — you'll be notified once approved")),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException', '').replaceAll(RegExp(r'^\(\d+\):\s*'), ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return AlertDialog(
      backgroundColor: AppColors.surface,
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
            const Text(
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
            Text(widget.payment.upiId, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
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
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Submit for review'),
        ),
      ],
    );
  }
}
