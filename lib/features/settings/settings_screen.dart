import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/category/vendor_category.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_mode_store.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/image_pick_util.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/common.dart';
import '../../data/api/api_errors.dart';
import '../../data/repositories/vendor_repository.dart';
import '../../data/upload_service.dart';

/// Settings & KYC.
///
/// Every row here does something real: KYC documents are uploaded and sent
/// to the AOneGo9 desk for verification, payout details and support
/// questions go to the same desk inbox, appearance is saved on the device.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _repo = VendorRepository();
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>> _submittedDocs = [];

  String get _docsKey => 'vendor_kyc_submitted_${VendorSession.vendorId}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _profile.isEmpty;
      _error = null;
    });
    try {
      final p = await _repo.myProfile();
      VendorSession.setVendorFromProfile(p);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_docsKey);
      if (!mounted) return;
      setState(() {
        _profile = p;
        _submittedDocs = raw == null ? [] : (jsonDecode(raw) as List).whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = apiErrorMessage(e, fallback: 'Could not load your account.');
        });
      }
    }
  }

  Future<void> _rememberDoc(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final next = [
      {'type': type, 'at': DateTime.now().toIso8601String()},
      ..._submittedDocs.where((d) => d['type'] != type),
    ];
    await prefs.setString(_docsKey, jsonEncode(next));
    if (mounted) setState(() => _submittedDocs = next);
  }

  Future<void> _uploadKyc() async {
    final result = await showAdaptiveSheet<String>(context, builder: (_) => _KycUploadForm(repo: _repo));
    if (result == null || !mounted) return;
    await _rememberDoc(result);
    if (mounted) Toast.ok(Toast.of(context), '$result sent for verification — the desk reviews documents within 1–2 working days.');
  }

  Future<void> _deskRequest({
    required String kind,
    required String title,
    required String intro,
    required String hint,
    required String success,
    String prefill = '',
  }) async {
    final text = await showAdaptiveSheet<String>(
      context,
      builder: (_) => _DeskMessageForm(title: title, intro: intro, hint: hint, prefill: prefill),
    );
    if (text == null || !mounted) return;
    final m = Toast.of(context);
    try {
      await _repo.sendToDesk(kind, message: text);
      Toast.ok(m, success);
    } catch (e) {
      Toast.error(m, apiErrorMessage(e, fallback: 'Could not send — please try again.'));
    }
  }

  Future<void> _passwordReset() async {
    final email = VendorSession.email;
    final ok = await confirmAction(
      context,
      title: 'Reset your password?',
      message: 'We will ask the AOneGo9 desk to send a password reset link to ${email.isEmpty ? 'your account email' : email}. '
          'You stay signed in here until you change it.',
      confirmLabel: 'Request reset',
    );
    if (!ok || !mounted) return;
    final m = Toast.of(context);
    try {
      await _repo.requestPasswordReset(email);
      Toast.ok(m, 'Reset requested — check ${email.isEmpty ? 'your inbox' : email} for the link.');
    } catch (e) {
      Toast.error(m, apiErrorMessage(e, fallback: 'Could not send the request.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _profile.isEmpty) return ErrorView(message: _error!, onRetry: _load);
    if (_loading) return const LoadingView();
    return PageBody(
      onRefresh: _load,
      children: [
        const PageHeader(title: 'Settings & KYC', subtitle: 'Account, verification, payouts and support'),
        const SizedBox(height: 20),
        ResponsiveLayout(
          mobile: (_) => Column(children: [
            _accountCard(),
            const SizedBox(height: 16),
            _kycCard(),
            const SizedBox(height: 16),
            _payoutCard(),
            const SizedBox(height: 16),
            _appearanceCard(),
            const SizedBox(height: 16),
            _supportCard(),
          ]),
          desktop: (_) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(children: [_accountCard(), const SizedBox(height: 16), _kycCard(), const SizedBox(height: 16), _payoutCard()])),
            const SizedBox(width: 16),
            Expanded(child: Column(children: [_appearanceCard(), const SizedBox(height: 16), _supportCard()])),
          ]),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 120, child: Text(k, style: AppType.body(size: 12.5, color: AppColors.textMuted))),
          Expanded(child: Text(v.isEmpty ? '—' : v, style: AppType.body(size: 13.5, weight: FontWeight.w600))),
        ]),
      );

  Widget _accountCard() {
    final status = VendorSession.approvalStatus;
    final (label, color) = switch (status) {
      'approved' => ('Live on marketplace', AppColors.success),
      'pending' => ('Awaiting approval', AppColors.warning),
      'rejected' => ('Not approved', AppColors.danger),
      'suspended' => ('Suspended', AppColors.danger),
      _ => ('Active', AppColors.info),
    };
    return SectionCard(
      title: 'Account',
      actions: [StatusChip(label: label, color: color)],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          InitialsAvatar(name: VendorSession.vendorName, size: 48, imageUrl: VendorSession.avatarUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(VendorSession.vendorName, style: AppType.body(size: 15, weight: FontWeight.w700)),
              Text(VendorSession.profileSubtitle, style: AppType.body(size: 12.5, color: AppColors.textMuted)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        _kv('Contact', VendorSession.contactName),
        _kv('Email', VendorSession.email),
        _kv('Phone', VendorSession.phone),
        _kv('Plan', VendorSession.plan.isEmpty ? 'Free' : VendorSession.plan),
        if ((_profile['joined_at'] ?? _profile['created_at']) != null)
          _kv('Member since',
              DateFormat('MMMM yyyy').format(DateTime.tryParse('${_profile['joined_at'] ?? _profile['created_at']}') ?? DateTime.now())),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, children: [
          OutlinedButton.icon(onPressed: () => context.go('/profile'), icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Edit profile')),
          OutlinedButton.icon(onPressed: () => context.go('/subscription'), icon: const Icon(Icons.workspace_premium_outlined, size: 16), label: const Text('Manage plan')),
        ]),
      ]),
    );
  }

  Widget _kycCard() {
    final verified = VendorSession.kycVerified;
    return SectionCard(
      title: 'KYC verification',
      actions: [
        if (!verified)
          ElevatedButton.icon(
            onPressed: _uploadKyc,
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 14)),
            icon: const Icon(Icons.upload_outlined, size: 16),
            label: const Text('Upload'),
          ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InlineNotice(
          icon: verified ? Icons.verified_rounded : Icons.shield_outlined,
          color: verified ? AppColors.success : AppColors.warning,
          message: verified
              ? 'Your business is KYC verified. Clients see a verified badge on your profile.'
              : 'Verify your business to earn the verified badge and receive payouts. Upload a government ID and a business proof (PAN or GST).',
        ),
        if (_submittedDocs.isNotEmpty && !verified) ...[
          const SizedBox(height: 12),
          for (final d in _submittedDocs)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                Icon(Icons.description_outlined, size: 19, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${d['type']}', style: AppType.body(size: 13.5, weight: FontWeight.w600)),
                    Text('Sent ${DateFormat('d MMM yyyy').format(DateTime.tryParse('${d['at']}') ?? DateTime.now())}',
                        style: AppType.mono(size: 11)),
                  ]),
                ),
                StatusChip(label: 'Under review', color: AppColors.warning),
              ]),
            ),
        ],
      ]),
    );
  }

  Widget _payoutCard() {
    return SectionCard(
      title: 'Payouts',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Payouts are transferred by the AOneGo9 desk to the bank account or UPI ID on file.',
            style: AppType.body(size: 12.5, color: AppColors.textSecondary, height: 1.45)),
        const SizedBox(height: 6),
        _link(
          'Update payout details',
          Icons.account_balance_outlined,
          onTap: () => _deskRequest(
            kind: 'payout_details',
            title: 'Update payout details',
            intro: 'Share the account payouts should go to. For your security the desk confirms changes by phone before using them.',
            hint: 'Account holder name\nBank, account number and IFSC\n— or your UPI ID',
            success: 'Payout details sent — the desk will confirm with you before the next payout.',
          ),
        ),
        _link('View earnings & request payout', Icons.account_balance_wallet_outlined, onTap: () => context.go('/earnings')),
      ]),
    );
  }

  Widget _appearanceCard() {
    return SectionCard(
      title: 'Appearance',
      child: ValueListenableBuilder<String>(
        valueListenable: ThemeModeStore.mode,
        builder: (_, mode, __) => SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 'system', icon: const Icon(Icons.brightness_auto_rounded, size: 18), label: Text(Responsive.isMobile(context) ? 'Auto' : 'Match device')),
            const ButtonSegment(value: 'light', icon: Icon(Icons.light_mode_rounded, size: 18), label: Text('Light')),
            const ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode_rounded, size: 18), label: Text('Dark')),
          ],
          selected: {mode},
          onSelectionChanged: (s) => ThemeModeStore.set(s.first),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (st) => st.contains(WidgetState.selected) ? AppColors.gold.withValues(alpha: .16) : Colors.transparent,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (st) => st.contains(WidgetState.selected) ? AppColors.gold : AppColors.textSecondary,
            ),
            side: WidgetStatePropertyAll(BorderSide(color: AppColors.border)),
          ),
        ),
      ),
    );
  }

  Widget _supportCard() {
    return SectionCard(
      title: 'Help & security',
      child: Column(children: [
        _link(
          'Contact the AOneGo9 desk',
          Icons.support_agent_outlined,
          onTap: () => _deskRequest(
            kind: 'vendor_support',
            title: 'Contact the AOneGo9 desk',
            intro: 'Ask about bookings, payouts, your listing or anything else. The desk replies by email or phone.',
            hint: 'How can we help?',
            success: 'Message sent — the desk usually replies within one working day.',
          ),
        ),
        _link(
          VendorSession.isLive ? 'Report a problem with a booking' : 'Request another listing review',
          VendorSession.isLive ? Icons.report_gmailerrorred_outlined : Icons.fact_check_outlined,
          onTap: () => _deskRequest(
            kind: VendorSession.isLive ? 'booking_issue' : 'listing_review',
            title: VendorSession.isLive ? 'Report a booking problem' : 'Request a listing review',
            intro: VendorSession.isLive
                ? 'Include the booking or inquiry reference so the desk can find it quickly.'
                : 'Tell the desk what you have updated since the last review.',
            hint: VendorSession.isLive ? 'Reference (AO9-…) and what happened' : 'What changed?',
            success: 'Sent to the desk — you will hear back shortly.',
          ),
        ),
        _link('Reset password', Icons.lock_reset_outlined, onTap: _passwordReset),
        _link('Sign out', Icons.logout, color: AppColors.danger, onTap: () => signOutWithConfirm(context)),
      ]),
    );
  }

  Widget _link(String title, IconData icon, {Color? color, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(children: [
          Icon(icon, size: 19, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: AppType.body(size: 13.5, weight: FontWeight.w500, color: color ?? AppColors.textPrimary))),
          Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
        ]),
      ),
    );
  }
}

class _DeskMessageForm extends StatefulWidget {
  final String title, intro, hint, prefill;
  const _DeskMessageForm({required this.title, required this.intro, required this.hint, this.prefill = ''});
  @override
  State<_DeskMessageForm> createState() => _DeskMessageFormState();
}

class _DeskMessageFormState extends State<_DeskMessageForm> {
  late final _c = TextEditingController(text: widget.prefill);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.title, style: AppType.display(size: 20)),
        const SizedBox(height: 6),
        Text(widget.intro, style: AppType.body(size: 12.5, color: AppColors.textSecondary, height: 1.45)),
        const SizedBox(height: 16),
        TextField(
          controller: _c,
          autofocus: true,
          minLines: 4,
          maxLines: 8,
          maxLength: 1500,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: widget.hint),
        ),
        const SizedBox(height: 6),
        Text('Sent from ${VendorSession.vendorName}${VendorSession.email.isEmpty ? '' : ' · ${VendorSession.email}'}',
            style: AppType.body(size: 11.5, color: AppColors.textMuted)),
        const SizedBox(height: 12),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _c,
          builder: (_, v, __) => SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: v.text.trim().length < 5 ? null : () => Navigator.pop(context, v.text.trim()),
              child: const Text('Send to desk'),
            ),
          ),
        ),
      ]),
    );
  }
}

class _KycUploadForm extends StatefulWidget {
  final VendorRepository repo;
  const _KycUploadForm({required this.repo});
  @override
  State<_KycUploadForm> createState() => _KycUploadFormState();
}

class _KycUploadFormState extends State<_KycUploadForm> {
  static const _types = ['Aadhaar card', 'PAN card', 'GST certificate', 'Passport', 'Business registration', 'Cancelled cheque'];
  String _type = _types.first;
  final _number = TextEditingController();
  PickedImageFile? _file;
  bool _sending = false;
  String _error = '';

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final f = await pickImageFromGallery();
      if (f != null && mounted) setState(() => _file = f);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not open the photo picker.');
    }
  }

  Future<void> _submit() async {
    final f = _file;
    if (f == null) return;
    setState(() {
      _sending = true;
      _error = '';
    });
    try {
      final url = await UploadService.uploadImage(bytes: f.bytes, filename: 'kyc.${f.extension}', folder: 'kyc');
      final last4 = _number.text.trim().length >= 4 ? _number.text.trim().substring(_number.text.trim().length - 4) : '';
      await widget.repo.sendToDesk(
        'kyc_document',
        message: 'KYC document submitted: $_type${last4.isEmpty ? '' : ' (ending $last4)'}.\nDocument: $url',
        extra: {'document_type': _type, 'document_url': url, if (last4.isNotEmpty) 'document_last4': last4},
      );
      if (mounted) Navigator.pop(context, _type);
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = friendlyApiError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = _file?.bytes;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Upload a KYC document', style: AppType.display(size: 20)),
        const SizedBox(height: 6),
        Text('A clear photo of the full document. It is shared only with the AOneGo9 verification desk.',
            style: AppType.body(size: 12.5, color: AppColors.textSecondary, height: 1.45)),
        const SizedBox(height: 16),
        if (_error.isNotEmpty) ...[
          InlineNotice(message: _error, icon: Icons.error_outline, color: AppColors.danger),
          const SizedBox(height: 12),
        ],
        LabeledField(
          label: 'Document type',
          child: DropdownButtonFormField<String>(
            initialValue: _type,
            dropdownColor: AppColors.surfaceAlt,
            items: [for (final t in _types) DropdownMenuItem(value: t, child: Text(t))],
            onChanged: _sending ? null : (v) => setState(() => _type = v ?? _type),
          ),
        ),
        LabeledField(
          label: 'Document number (optional)',
          hint: 'Only the last 4 digits are kept with the request.',
          child: TextField(controller: _number, decoration: const InputDecoration(hintText: 'e.g. ABCDE1234F')),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _sending ? null : _pick,
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bytes == null ? AppColors.borderHi : AppColors.gold),
            ),
            clipBehavior: Clip.antiAlias,
            child: bytes == null
                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text('Tap to choose a photo', style: AppType.body(size: 13, color: AppColors.textSecondary)),
                    Text('JPG, PNG or WebP · up to 10 MB', style: AppType.body(size: 11.5, color: AppColors.textMuted)),
                  ])
                : Stack(fit: StackFit.expand, children: [
                    Image.memory(bytes, fit: BoxFit.cover),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                        child: Text('Change', style: AppType.body(size: 12, color: Colors.white, weight: FontWeight.w600)),
                      ),
                    ),
                  ]),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: bytes == null || _sending ? null : _submit,
            child: _sending ? const ButtonSpinner() : const Text('Submit for verification'),
          ),
        ),
      ]),
    );
  }
}
