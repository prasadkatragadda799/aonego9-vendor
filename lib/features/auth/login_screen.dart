import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/responsive/responsive.dart';
import '../../core/category/vendor_category.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/common.dart';
import '../../data/api/api_client.dart';
import '../../data/api/api_errors.dart';
import '../../data/models/models.dart';
import '../../data/repositories/vendor_repository.dart';

final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _register = false;
  bool _obscure = true;
  bool _loading = false;
  String _error = '';
  String _category = marketCategories.first.label;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _company = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  String _otpHint = '';
  bool _otpSending = false;
  bool _otpSent = false;
  final _repo = VendorRepository();

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _company, _city, _phone, _otp]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _phoneEntered => _digits(_phone.text).isNotEmpty;

  Future<void> _sendOtp() async {
    final phone = _digits(_phone.text);
    if (phone.length < 10) {
      setState(() => _error = 'Enter a valid 10-digit mobile number first.');
      return;
    }
    setState(() {
      _otpSending = true;
      _error = '';
      _otpHint = '';
    });
    try {
      final res = await _repo.sendOtp(phone, purpose: 'vendor_register');
      final debug = res['debug_code'];
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _otpHint = (kDebugMode && debug != null) ? 'Dev OTP: $debug' : 'We sent a code to $phone. It expires in a few minutes.';
      });
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e, fallback: 'Could not send the OTP — try again.'));
    } finally {
      if (mounted) setState(() => _otpSending = false);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = '');
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_register && _phoneEntered && _otp.text.trim().length < 4) {
      setState(() => _error = 'Verify your mobile number with the OTP before creating the account.');
      return;
    }
    setState(() => _loading = true);
    try {
      if (_register) {
        await _repo.register(
          name: _name.text.trim(),
          company: _company.text.trim(),
          email: _email.text.trim().toLowerCase(),
          password: _password.text,
          phone: _digits(_phone.text),
          phoneOtp: _otp.text.trim(),
          city: _city.text.trim(),
          category: _category,
        );
      } else {
        await _repo.login(_email.text.trim().toLowerCase(), _password.text);
      }
      final profile = await _repo.myProfile();
      VendorSession.setVendorFromProfile(profile);
      TextInput.finishAutofillContext();
      if (!mounted) return;
      final from = GoRouterState.of(context).uri.queryParameters['from'];
      context.go(from != null && from.startsWith('/') && !from.startsWith('/login') ? from : '/dashboard');
    } on Object catch (e) {
      if (!mounted) return;
      final badCredentials = e is ApiException && (e.statusCode == 401 || e.statusCode == 400) && !_register;
      setState(() => _error = badCredentials
          ? 'That email and password do not match a vendor account.'
          : apiErrorMessage(e, fallback: _register ? 'Could not create the account.' : 'Could not sign in.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ForgotPasswordDialog(initial: _email.text.trim()),
    );
    if (email == null || !mounted) return;
    final m = Toast.of(context);
    try {
      await _repo.requestPasswordReset(email);
      Toast.ok(m, 'Request sent. The AOneGo9 desk will verify your account and contact you at $email.');
    } catch (e) {
      Toast.error(m, apiErrorMessage(e, fallback: 'Could not send the request — try again.'));
    }
  }

  void _switchMode() {
    setState(() {
      _register = !_register;
      _error = '';
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _register ? configForLabel(_category) : categoryConfigs[VendorCategory.talent]!;
    final form = _buildForm(context, cfg);
    final mobile = Responsive.isMobile(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(children: [
        if (mobile)
          AmbientBackground(
            accent: cfg.accent,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 32),
                  child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: form),
                ),
              ),
            ),
          )
        else
          Row(children: [
            Expanded(flex: Responsive.isTablet(context) ? 4 : 5, child: _BrandPanel(config: cfg, register: _register)),
            Expanded(
              flex: 5,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                  child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: form),
                ),
              ),
            ),
          ]),
        const Positioned(top: 8, right: 8, child: SafeArea(child: ThemeCycleButton())),
      ]),
    );
  }

  Widget _buildForm(BuildContext context, VendorCategoryConfig cfg) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          if (Responsive.isMobile(context)) ...[
            const Center(child: BrandLogo(size: 26)),
            const SizedBox(height: 6),
            Center(child: Text('VENDOR CONSOLE', style: AppType.eyebrow(color: AppColors.gold, size: 9.5))),
            const SizedBox(height: 28),
          ],
          Text(_register ? 'Create your vendor account' : 'Welcome back',
              style: AppType.display(size: 26, weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            _register
                ? 'List your services on AOneGo9 and start taking bookings.'
                : 'Sign in to manage bookings, packages and payouts.',
            style: AppType.body(size: 13.5, color: AppColors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 24),
          if (_error.isNotEmpty) ...[
            InlineNotice(message: _error, icon: Icons.error_outline, color: AppColors.danger),
            const SizedBox(height: 16),
          ],
          if (_register) ...[
            LabeledField(
              label: 'Your full name',
              child: TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(hintText: 'e.g. Priya Sharma'),
                validator: (v) => (v ?? '').trim().length < 2 ? 'Enter your name' : null,
              ),
            ),
            LabeledField(
              label: 'Business name',
              child: TextFormField(
                controller: _company,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.organizationName],
                decoration: const InputDecoration(hintText: 'e.g. Spotlight Talent Co.'),
                validator: (v) => (v ?? '').trim().length < 2 ? 'Enter your business name' : null,
              ),
            ),
            LabeledField(
              label: 'Category',
              child: DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                dropdownColor: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                menuMaxHeight: 420,
                style: AppType.body(size: 14),
                items: [
                  // Every marketplace category, grouped by division so a long
                  // list stays navigable. Values are the human labels the
                  // backend stores and matches vendors on.
                  for (final c in marketCategories)
                    DropdownMenuItem(
                      value: c.label,
                      child: Text('${c.divisionLabel} · ${c.label}', overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
            ),
          ],
          LabeledField(
            label: 'Email',
            child: TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email, AutofillHints.username],
              autocorrect: false,
              decoration: const InputDecoration(hintText: 'you@business.com', prefixIcon: Icon(Icons.mail_outline, size: 19)),
              validator: (v) => _emailRe.hasMatch((v ?? '').trim()) ? null : 'Enter a valid email address',
            ),
          ),
          LabeledField(
            label: 'Password',
            hint: _register ? 'At least 8 characters.' : null,
            child: TextFormField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: _register ? TextInputAction.next : TextInputAction.done,
              autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password],
              onFieldSubmitted: (_) {
                if (!_register) _submit();
              },
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline, size: 19),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                final p = v ?? '';
                if (p.isEmpty) return 'Enter your password';
                if (_register && p.length < 8) return 'Use at least 8 characters';
                return null;
              },
            ),
          ),
          if (!_register)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _forgotPassword, child: const Text('Forgot password?')),
            ),
          if (_register) ...[
            LabeledField(
              label: 'City',
              child: TextFormField(
                controller: _city,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.addressCity],
                decoration: const InputDecoration(hintText: 'e.g. Mumbai', prefixIcon: Icon(Icons.location_on_outlined, size: 19)),
                validator: (v) => (v ?? '').trim().length < 2 ? 'Enter the city you operate from' : null,
              ),
            ),
            LabeledField(
              label: 'Mobile number',
              hint: 'Optional — verify it to let clients reach you faster.',
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')), LengthLimitingTextInputFormatter(16)],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(hintText: '98765 43210', prefixIcon: Icon(Icons.phone_outlined, size: 19)),
                    validator: (v) {
                      final d = _digits(v ?? '');
                      if (d.isEmpty) return null;
                      return d.length < 10 ? 'Enter a 10-digit number' : null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _otpSending || !_phoneEntered ? null : _sendOtp,
                    child: _otpSending ? ButtonSpinner(color: AppColors.gold) : Text(_otpSent ? 'Resend' : 'Send OTP'),
                  ),
                ),
              ]),
            ),
            if (_phoneEntered)
              LabeledField(
                label: 'OTP',
                hint: _otpHint.isEmpty ? null : _otpHint,
                child: TextFormField(
                  controller: _otp,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(hintText: '6-digit code', prefixIcon: Icon(Icons.pin_outlined, size: 19)),
                ),
              ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading ? const ButtonSpinner() : Text(_register ? 'Create account' : 'Sign in'),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(_register ? 'Already a vendor?' : 'New to AOneGo9?',
                  style: AppType.body(size: 13, color: AppColors.textSecondary)),
              TextButton(onPressed: _switchMode, child: Text(_register ? 'Sign in' : 'Become a vendor')),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: () => showAdaptiveSheet(context, builder: (_) => const _PublicPlans()),
              icon: const Icon(Icons.workspace_premium_outlined, size: 18),
              label: const Text('See vendor plans & pricing'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  final VendorCategoryConfig config;
  final bool register;
  const _BrandPanel({required this.config, required this.register});

  @override
  Widget build(BuildContext context) {
    final accent = config.accent;
    const points = [
      (Icons.verified_user_outlined, 'Verified marketplace', 'Clients book vetted vendors with full portfolios and pricing.'),
      (Icons.event_available_outlined, 'Bookings & calendar', 'Accept requests, track advances and see every shoot at a glance.'),
      (Icons.account_balance_wallet_outlined, 'Earnings in one place', 'Settled and pending payouts with a full transaction history.'),
    ];
    return Container(
      decoration: BoxDecoration(border: Border(right: BorderSide(color: AppColors.border))),
      child: AmbientBackground(
        accent: accent,
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 48),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  const ConsoleLockup(label: 'Vendor Console', size: 30),
                  const SizedBox(height: 44),
                  // Eyebrow re-themes to the selected category in real time.
                  Eyebrow(register ? '${config.label} console' : 'For AOneGo9 vendors', color: accent),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      style: AppType.display(size: 36, weight: FontWeight.w600, height: 1.2),
                      children: [
                        const TextSpan(text: 'Grow your business '),
                        TextSpan(text: 'on AOneGo9', style: TextStyle(color: AppColors.gold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Text(config.loginTagline,
                        style: AppType.body(size: 14, color: AppColors.textSecondary, height: 1.6)),
                  ),
                  const SizedBox(height: 32),
                  for (final p in points)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(p.$1, size: 18, color: accent),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p.$2, style: AppType.body(size: 13.5, weight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(p.$3, style: AppType.body(size: 12.5, color: AppColors.textSecondary, height: 1.45)),
                          ]),
                        ),
                      ]),
                    ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  final String initial;
  const _ForgotPasswordDialog({required this.initial});
  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final _c = TextEditingController(text: widget.initial);
  String? _err;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _send() {
    final v = _c.text.trim().toLowerCase();
    if (!_emailRe.hasMatch(v)) {
      setState(() => _err = 'Enter the email you registered with');
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset your password'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            'Enter your account email. The AOneGo9 desk verifies the request and sends you a reset link — this keeps vendor accounts safe from takeover.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _c,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(hintText: 'you@business.com', errorText: _err),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _send, child: const Text('Send request')),
      ],
    );
  }
}

/// Plans preview for prospective vendors, before they have an account.
class _PublicPlans extends StatefulWidget {
  const _PublicPlans();
  @override
  State<_PublicPlans> createState() => _PublicPlansState();
}

class _PublicPlansState extends State<_PublicPlans> {
  late Future<List<SubscriptionPlan>> _f = VendorRepository().plans(auth: false);

  @override
  Widget build(BuildContext context) {
    final cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return FutureBuilder<List<SubscriptionPlan>>(
      future: _f,
      builder: (context, snap) {
        Widget body;
        if (snap.connectionState != ConnectionState.done) {
          body = const LoadingView();
        } else if (snap.hasError) {
          final e = snap.error!;
          final needsAuth = e is ApiException && (e.statusCode == 401 || e.statusCode == 403);
          body = needsAuth
              ? const EmptyView(
                  icon: Icons.lock_outline,
                  message: 'Plans are shown after sign-up',
                  detail: 'Create a free vendor account to compare plans. Every vendor starts on the free plan.',
                )
              : ErrorView(message: apiErrorMessage(e), onRetry: () => setState(() => _f = VendorRepository().plans(auth: false)));
        } else if (snap.data!.isEmpty) {
          body = const EmptyView(icon: Icons.workspace_premium_outlined, message: 'Plans are being updated', detail: 'Check back shortly.');
        } else {
          body = Column(children: [
            for (final p in snap.data!)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.recommended ? AppColors.gold : AppColors.border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(p.name, style: AppType.body(size: 15, weight: FontWeight.w700))),
                    if (p.recommended) StatusChip(label: 'Popular', color: AppColors.gold),
                  ]),
                  const SizedBox(height: 4),
                  Text(p.price == 0 ? 'Free' : '${cur.format(p.price)}${p.periodShort}',
                      style: AppType.display(size: 20, color: AppColors.gold)),
                  const SizedBox(height: 8),
                  for (final f in p.features)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.check, size: 15, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(child: Text(f, style: AppType.body(size: 12.5, color: AppColors.textSecondary))),
                      ]),
                    ),
                ]),
              ),
          ]);
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Vendor plans', style: AppType.display(size: 20)),
            const SizedBox(height: 4),
            Text('Start free. Upgrade any time from your console.',
                style: AppType.body(size: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            body,
          ]),
        );
      },
    );
  }
}
