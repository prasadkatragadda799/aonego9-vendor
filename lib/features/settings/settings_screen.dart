import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _bookingAlerts = true;
  bool _payoutAlerts = true;
  bool _marketing = false;

  final _docs = const [
    ('PAN Card', 'Verified', AppColors.success),
    ('GST Certificate', 'Verified', AppColors.success),
    ('Bank Account ••4521', 'Verified', AppColors.success),
    ('Business Registration', 'Pending review', AppColors.warning),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(responsiveValue(context, mobile: 16, desktop: 28)),
      children: [
        PageHeader(title: 'Settings & KYC', subtitle: 'Account, documents and notification preferences'),
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
        for (final d in _docs)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              const Icon(Icons.description_outlined, size: 20, color: AppColors.textSecondary),
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
        _link('Log out', Icons.logout, color: AppColors.danger),
      ]),
    );
  }

  Widget _toggle(String title, String sub, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5)),
          Text(sub, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ])),
        Switch(value: value, activeColor: AppColors.gold, onChanged: onChanged),
      ]),
    );
  }

  Widget _link(String title, IconData icon, {Color? color}) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Icon(icon, size: 19, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: color ?? AppColors.textPrimary))),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
        ]),
      ),
    );
  }
}
