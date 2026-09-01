import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/common.dart';
import '../../data/repositories/vendor_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _repo = VendorRepository();
  bool _bookingAlerts = true;
  bool _payoutAlerts = true;
  bool _marketing = false;
  bool _kycVerified = false;
  bool _loadingKyc = true;

  @override
  void initState() {
    super.initState();
    _loadKyc();
  }

  Future<void> _loadKyc() async {
    try {
      final profile = await _repo.myProfile();
      if (!mounted) return;
      setState(() {
        _kycVerified = profile['kyc_verified'] as bool? ?? false;
        _loadingKyc = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingKyc = false);
    }
  }

  List<(String, String, Color)> get _docs => _kycVerified
      ? [
          ('Platform KYC', 'Verified by admin', AppColors.success),
        ]
      : [
          ('Platform KYC', 'Pending admin review', AppColors.warning),
        ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(responsiveValue(context, mobile: 16, desktop: 28)),
      children: [
        const PageHeader(title: 'Settings & KYC', subtitle: 'Account, documents and notification preferences'),
        const SizedBox(height: 24),
        ResponsiveLayout(
          mobile: (_) => Column(children: [_kycCard(), const SizedBox(height: 16), _prefsCard(), const SizedBox(height: 16), _accountCard()]),
          desktop: (_) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _kycCard()),
            const SizedBox(width: 16),
            Expanded(child: Column(children: [_prefsCard(), const SizedBox(height: 16), _accountCard()])),
          ]),
        ),
      ],
    );
  }

  Widget _kycCard() {
    return SectionCard(
      title: 'KYC Documents',
      actions: [OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.upload_outlined, size: 16), label: const Text('Upload'))],
      child: Column(children: [
        if (_loadingKyc)
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        else
          for (final d in _docs)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Icon(Icons.description_outlined, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(child: Text(d.$1, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5))),
              StatusChip(label: d.$2, color: d.$3),
            ]),
          ),
      ]),
    );
  }

  Widget _prefsCard() {
    return SectionCard(
      title: 'Notifications',
      child: Column(children: [
        _toggle('Booking alerts', 'New requests and updates', _bookingAlerts, (v) => setState(() => _bookingAlerts = v)),
        _toggle('Payout alerts', 'Settlement and withdrawal updates', _payoutAlerts, (v) => setState(() => _payoutAlerts = v)),
        _toggle('Marketing emails', 'Tips and platform offers', _marketing, (v) => setState(() => _marketing = v)),
      ]),
    );
  }

  Widget _accountCard() {
    return SectionCard(
      title: 'Account',
      child: Column(children: [
        _link('Change password', Icons.lock_outline),
        _link('Linked bank account', Icons.account_balance_outlined),
        _link('Help & support', Icons.help_outline),
        _link('Log out', Icons.logout, color: AppColors.danger, onTap: _logout),
      ]),
    );
  }

  Future<void> _logout() async {
    await _repo.logout();
    if (mounted) context.go('/login');
  }

  Widget _toggle(String title, String sub, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5)),
          Text(sub, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ])),
        Switch(value: value, activeColor: AppColors.gold, onChanged: onChanged),
      ]),
    );
  }

  Widget _link(String title, IconData icon, {Color? color, VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Icon(icon, size: 19, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: color ?? AppColors.textPrimary))),
          Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
        ]),
      ),
    );
  }
}
