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
  final _email = TextEditingController(text: 'vendor@aonego9.com');
  final _password = TextEditingController(text: 'demo1234');
  final _company = TextEditingController();
  final _repo = VendorRepository();

  Future<void> _submit() async {
    setState(() { _loading = true; _error = ''; });
    try {
      VendorSession.setFromLabel(_category);
      if (_register) {
        await _repo.register(
          name: _company.text.trim().isEmpty ? _email.text.split('@').first : _company.text.trim(),
          company: _company.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          category: _category,
        );
      } else {
        await _repo.login(_email.text.trim(), _password.text);
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
    );
    final cfg = categoryConfigs[_catFromLabel(_category)]!;
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
          Row(children: [
            _stat('₹18.4L', 'Earned', accent),
            _stat('132', 'Bookings', accent),
            _stat('4.8★', 'Rating', accent),
          ]),
        ]),
      ),
    );
  }

  Widget _stat(String v, String l, Color accent) => Padding(
        padding: const EdgeInsets.only(right: 36),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v, style: AppType.display(color: accent, size: 26, weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(l, style: AppType.eyebrow(color: AppColors.textMuted, size: 11)),
        ]),
      );
}

class _AuthForm extends StatelessWidget {
  final bool register, obscure, loading;
  final TextEditingController email, password, company;
  final String category, error;
  final ValueChanged<String> onCategory;
  final VoidCallback onToggleObscure, onSwitch, onSubmit;
  const _AuthForm({
    required this.register,
    required this.email,
    required this.password,
    required this.company,
    required this.obscure,
    required this.loading,
    required this.error,
    required this.category,
    required this.onCategory,
    required this.onToggleObscure,
    required this.onSwitch,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(register ? 'Create vendor account' : 'Vendor sign in', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 6),
      Text(register ? 'Start listing your services in minutes' : 'Welcome back to your vendor console', style: const TextStyle(color: AppColors.textSecondary)),
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
      const SizedBox(height: 16),
      _Label(register ? 'Category' : 'Sign in as'),
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
