import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/responsive/responsive.dart';
import '../../core/category/vendor_category.dart';
import '../../core/widgets/common.dart';
import '../../data/repositories/vendor_repository.dart';

/// Live label → category map so the brand panel re-themes as the vendor
/// picks their business type (mirrors VendorSession.setFromLabel).
VendorCategory _catFromLabel(String label) => switch (label) {
      'Photography' => VendorCategory.photography,
      'Videography' => VendorCategory.videography,
      'Venue' => VendorCategory.venue,
      'Event Services' => VendorCategory.events,
      _ => VendorCategory.talent,
    };

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _register = false;
  bool _obscure = true;
  bool _loading = false;
  String _error = '';
  String _category = 'Talent Agency';
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _company = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  String _otpHint = '';
  bool _otpSending = false;
  final _repo = VendorRepository();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _company.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phone.text.trim().length < 10) {
      setState(() => _error = 'Enter a valid mobile number first.');
      return;
    }
    setState(() { _otpSending = true; _error = ''; _otpHint = ''; });
    try {
      final res = await _repo.sendOtp(_phone.text.trim(), purpose: 'vendor_register');
      setState(() {
        _otpHint = res['debug_code'] != null ? 'Dev OTP: ${res['debug_code']}' : 'OTP sent to your phone.';
      });
    } catch (e) {
      setState(() => _error = 'Could not send OTP.');
    } finally {
      if (mounted) setState(() => _otpSending = false);
    }
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = ''; });
    try {
      if (_register) {
        await _repo.register(
          name: _company.text.trim().isEmpty ? _email.text.split('@').first : _company.text.trim(),
          company: _company.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          phone: _phone.text.trim(),
          phoneOtp: _otp.text.trim(),
          category: _category,
        );
        VendorSession.setVendorFromProfile(await _repo.myProfile());
      } else {
        await _repo.login(_email.text.trim(), _password.text);
        VendorSession.setVendorFromProfile(await _repo.myProfile());
      }
      if (mounted) context.go('/dashboard');
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('ApiException', '').replaceAll(RegExp(r'^\(\d+\):\s*'), ''); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = _AuthForm(
      register: _register,
      email: _email,
      password: _password,
      company: _company,
      obscure: _obscure,
      loading: _loading,
      error: _error,
      category: _category,
      onCategory: (v) => setState(() => _category = v),
      onToggleObscure: () => setState(() => _obscure = !_obscure),
      onSwitch: () => setState(() { _register = !_register; _error = ''; }),
      onSubmit: _submit,
      phone: _phone,
      otp: _otp,
      otpHint: _otpHint,
      otpSending: _otpSending,
      onSendOtp: _sendOtp,
      onPlans: () => context.go('/subscription'),
    );
    final cfg = _register
        ? categoryConfigs[_catFromLabel(_category)]!
        : categoryConfigs[VendorCategory.talent]!;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Responsive.isMobile(context)
          ? SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: form)))
          : Row(children: [
              Expanded(child: _BrandPanel(config: cfg)),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(48),
                    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 380), child: form),
                  ),
                ),
              ),
            ]),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  final VendorCategoryConfig config;
  const _BrandPanel({required this.config});
  @override
  Widget build(BuildContext context) {
    final accent = config.accent;
    return AmbientBackground(
      accent: accent,
      child: Padding(
        padding: const EdgeInsets.all(56),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 58, height: 58, alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.goldLight, AppColors.goldDark]),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 22, offset: const Offset(0, 8))],
            ),
            child: Text('A9', style: AppType.display(color: const Color(0xFF1A1407), weight: FontWeight.w700, size: 22)),
          ),
          const SizedBox(height: 30),
          // Eyebrow re-themes to the selected category in real time.
          Eyebrow('${config.label} Console', color: accent),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              style: AppType.display(size: 38, weight: FontWeight.w600, height: 1.1),
              children: [
                const TextSpan(text: 'Grow your\nbusiness '),
                TextSpan(text: 'on AOneGo9', style: AppType.display(size: 38, weight: FontWeight.w600, height: 1.1, color: accent, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(width: 380, child: Text(
            config.loginTagline,
            style: AppType.body(size: 14, color: AppColors.textSecondary, height: 1.6),
          )),
          const SizedBox(height: 40),
          Text('Sign in with your vendor account — your console theme is set automatically from your profile.',
              style: AppType.body(size: 13, color: AppColors.textMuted, height: 1.5)),
        ]),
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  final bool register, obscure, loading, otpSending;
  final TextEditingController email, password, company, phone, otp;
  final String category, error, otpHint;
  final ValueChanged<String> onCategory;
  final VoidCallback onToggleObscure, onSwitch, onSubmit, onSendOtp, onPlans;
  const _AuthForm({
    required this.register,
    required this.email,
    required this.password,
    required this.company,
    required this.phone,
    required this.otp,
    required this.obscure,
    required this.loading,
    required this.otpSending,
    required this.error,
    required this.category,
    required this.otpHint,
    required this.onCategory,
    required this.onToggleObscure,
    required this.onSwitch,
    required this.onSubmit,
    required this.onSendOtp,
    required this.onPlans,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
          ),
          child: const Icon(Icons.storefront_outlined, color: AppColors.gold, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(register ? 'Create vendor account' : 'Vendor sign in', style: Theme.of(context).textTheme.headlineSmall),
            Text(register ? 'Start listing your services in minutes' : 'Welcome back to your vendor console', style: const TextStyle(color: AppColors.textSecondary)),
          ]),
        ),
      ]),
      const SizedBox(height: 28),
      if (error.isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
          child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 13)),
        ),
      ],
      if (register) ...[
        const _Label('Business name'),
        TextField(controller: company, decoration: const InputDecoration(hintText: 'e.g. Spotlight Talent Co.')),
        const SizedBox(height: 16),
      ],
      const _Label('Email'),
      TextField(controller: email, decoration: const InputDecoration(hintText: 'you@business.com')),
      const SizedBox(height: 16),
      const _Label('Password'),
      TextField(
        controller: password,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: '••••••••',
          suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20), onPressed: onToggleObscure),
        ),
      ),
      if (register) ...[
        const SizedBox(height: 16),
        const _Label('Mobile number'),
        TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '+91 98765 43210')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: otp, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'OTP'))),
          const SizedBox(width: 10),
          OutlinedButton(onPressed: otpSending ? null : onSendOtp, child: Text(otpSending ? '…' : 'Send OTP')),
        ]),
        if (otpHint.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(otpHint, style: const TextStyle(color: AppColors.gold, fontSize: 12)),
        ],
        const SizedBox(height: 16),
        const _Label('Category'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: category,
              dropdownColor: AppColors.surfaceAlt,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              items: const [
                DropdownMenuItem(value: 'Talent Agency', child: Text('Talent Agency')),
                DropdownMenuItem(value: 'Photography', child: Text('Photography')),
                DropdownMenuItem(value: 'Videography', child: Text('Videography')),
                DropdownMenuItem(value: 'Venue', child: Text('Venue')),
                DropdownMenuItem(value: 'Event Services', child: Text('Event Services')),
              ],
              onChanged: (v) { if (v != null) onCategory(v); },
            ),
          ),
        ),
      ],
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: loading ? null : onSubmit,
          child: loading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1407)))
              : Text(register ? 'Create account' : 'Sign In'),
        ),
      ),
      const SizedBox(height: 16),
      Center(
        child: TextButton.icon(
          onPressed: onPlans,
          icon: const Icon(Icons.workspace_premium_outlined, size: 18),
          label: const Text('View subscription plans'),
        ),
      ),
      Center(
        child: TextButton(
          onPressed: onSwitch,
          child: Text(register ? 'Already have an account? Sign in' : "New to AOneGo9? Become a vendor"),
        ),
      ),
    ]);
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );
}
