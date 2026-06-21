import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/responsive/responsive.dart';
import '../../core/category/vendor_category.dart';
import '../../core/widgets/common.dart';

/// One portfolio work — mirrors the consumer app's gallery item shape
/// (a cover, a category tag, a headline, and a description underneath).
class PortfolioWork {
  String headline;
  String description;
  String tag;
  String emoji;
  int bg;
  bool featured;
  PortfolioWork({
    required this.headline,
    required this.description,
    required this.tag,
    required this.emoji,
    this.bg = 0,
    this.featured = false,
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late List<PortfolioWork> _works = _seedFor(VendorSession.category);

  // Category-specific starter portfolio so every vendor type sees relevant
  // sample work to edit. These are exactly the fields the user app renders.
  static List<PortfolioWork> _seedFor(VendorCategory c) {
    switch (c) {
      case VendorCategory.photography:
        return [
          PortfolioWork(headline: 'Vogue India Editorial', description: 'March 2025 cover story · 8-page fashion editorial shot on Sony A1.', tag: 'Editorial', emoji: '📷', bg: 0, featured: true),
          PortfolioWork(headline: 'Puma Brand Campaign', description: 'Pan-India print + digital · 3-city outdoor and studio shoot.', tag: 'Commercial', emoji: '🛍️', bg: 1),
          PortfolioWork(headline: 'Myntra E-commerce', description: '50-product catalogue · white-background + lifestyle edits.', tag: 'Catalogue', emoji: '📦', bg: 2),
          PortfolioWork(headline: 'Riverside Wedding', description: 'Full-day coverage · 2 shooters · album + 400 edited frames.', tag: 'Wedding', emoji: '💑', bg: 3),
        ];
      case VendorCategory.videography:
        return [
          PortfolioWork(headline: 'Nike India Brand Film', description: '90-second hero film · RED Komodo · edit, grade and mix.', tag: 'Brand Film', emoji: '🎥', bg: 0, featured: true),
          PortfolioWork(headline: 'Cinematic Wedding Reel', description: 'Highlight film + full ceremony edit · drone + gimbal coverage.', tag: 'Wedding', emoji: '💒', bg: 1),
          PortfolioWork(headline: 'Social Reels Bundle', description: '8 vertical reels in a single shoot day · captions + grade.', tag: 'Social', emoji: '📱', bg: 2),
          PortfolioWork(headline: 'NGO Documentary', description: '6-minute documentary short · run-and-gun field coverage.', tag: 'Documentary', emoji: '🎞️', bg: 3),
        ];
      case VendorCategory.venue:
        return [
          PortfolioWork(headline: 'The Grand Ballroom', description: 'Up to 600 guests · premium lighting, AV and in-house catering.', tag: 'Banquet', emoji: '🏛️', bg: 0, featured: true),
          PortfolioWork(headline: 'Skyline Rooftop', description: '270° city views · open-air evenings up to 120 guests.', tag: 'Rooftop', emoji: '🌆', bg: 1),
          PortfolioWork(headline: 'Heritage Courtyard', description: 'Outdoor heritage setting · weddings and brand showcases.', tag: 'Outdoor', emoji: '🌿', bg: 2),
          PortfolioWork(headline: 'The Studio Loft', description: 'Indoor studio space · ideal for shoots and intimate events.', tag: 'Studio', emoji: '📸', bg: 3),
        ];
      case VendorCategory.events:
        return [
          PortfolioWork(headline: 'Lakmé Fashion Show', description: 'Stage, ramp, lighting, sound and full backstage management.', tag: 'Fashion Show', emoji: '👗', bg: 0, featured: true),
          PortfolioWork(headline: 'Corporate Award Night', description: '500-guest gala · AV, stage, registration and hospitality.', tag: 'Corporate', emoji: '🏆', bg: 1),
          PortfolioWork(headline: 'Product Launch', description: 'FMCG launch · décor, talent and on-ground coordination.', tag: 'Launch', emoji: '🚀', bg: 2),
          PortfolioWork(headline: 'Destination Wedding', description: 'End-to-end planning · vendors, décor and on-day crew.', tag: 'Wedding', emoji: '💍', bg: 3),
        ];
      case VendorCategory.talent:
        return [
          PortfolioWork(headline: 'Lakmé Fashion Week', description: 'Opening runway walk · AW25 collection · lead model.', tag: 'Ramp', emoji: '👠', bg: 0, featured: true),
          PortfolioWork(headline: 'Puma India Campaign', description: 'National print + digital campaign · 3-city outdoor shoot.', tag: 'Commercial', emoji: '📢', bg: 1),
          PortfolioWork(headline: 'Banarasi Silk Editorial', description: 'Handloom ethnic campaign for Jaipur Fashion Week.', tag: 'Ethnic', emoji: '🥻', bg: 2),
          PortfolioWork(headline: "Short Film — 'Monsoon Letters'", description: 'Romantic lead role · independent film · 2024 release.', tag: 'Film', emoji: '🎬', bg: 3),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = VendorSession.config;
    return ListView(
      padding: EdgeInsets.all(responsiveValue(context, mobile: 16, desktop: 28)),
      children: [
        FadeUp(
          child: PageHeader(
            eyebrow: '${cfg.label} · Portfolio',
            accent: cfg.accent,
            title: 'Profile & Portfolio',
            subtitle: 'Everything here is exactly how clients see you on the marketplace',
            actions: [ElevatedButton.icon(onPressed: () => _toast('Profile saved'), icon: const Icon(Icons.save_outlined, size: 18), label: const Text('Save Changes'))],
          ),
        ),
        const SizedBox(height: 22),
        FadeUp(delay: const Duration(milliseconds: 90), child: _performanceStrip(cfg)),
        const SizedBox(height: 16),
        FadeUp(
          delay: const Duration(milliseconds: 150),
          child: ResponsiveLayout(
            mobile: (_) => Column(children: [
              _profileCard(context, cfg),
              const SizedBox(height: 16),
              _marketplacePreview(context, cfg),
              const SizedBox(height: 16),
              _portfolioManager(context, cfg),
            ]),
            desktop: (_) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 2, child: Column(children: [
                _profileCard(context, cfg),
                const SizedBox(height: 16),
                _marketplacePreview(context, cfg),
              ])),
              const SizedBox(width: 16),
              Expanded(flex: 3, child: _portfolioManager(context, cfg)),
            ]),
          ),
        ),
      ],
    );
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  // ── Portfolio performance — the same reach metrics users generate by
  //    opening and sharing this profile in the consumer app. ──
  Widget _performanceStrip(VendorCategoryConfig cfg) {
    final metrics = [
      ('Profile views', '12.4K', Icons.visibility_outlined, AppColors.info, '+18%'),
      ('Total reach', '34.8K', Icons.trending_up, cfg.accent, '+12%'),
      ('Link shares', '1,290', Icons.ios_share, AppColors.gold, '+7%'),
      ('Saved by clients', '486', Icons.bookmark_outline, AppColors.success, '+9%'),
    ];
    final cols = responsiveValue(context, mobile: 2, tablet: 4, desktop: 4);
    return GridView.count(
      crossAxisCount: cols,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: responsiveValue(context, mobile: 2.1, tablet: 2.4, desktop: 2.4),
      children: [
        for (final m in metrics)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [m.$4.withValues(alpha: 0.10), AppColors.surface]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(children: [
                Icon(m.$3, size: 16, color: m.$4),
                const Spacer(),
                Text(m.$5, style: AppType.body(size: 11, weight: FontWeight.w700, color: AppColors.success)),
              ]),
              const SizedBox(height: 8),
              Text(m.$2, style: AppType.display(size: 21, weight: FontWeight.w600)),
              Text(m.$1.toUpperCase(), style: AppType.eyebrow(color: AppColors.textSecondary, size: 9.5)),
            ]),
          ),
      ],
    );
  }

  Widget _profileCard(BuildContext context, VendorCategoryConfig cfg) {
    return SectionCard(
      title: 'Business Profile',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Column(children: [
            Stack(children: [
              const InitialsAvatar(name: 'Spotlight Talent', size: 84),
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: cfg.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, size: 14, color: Color(0xFF1A1407)),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Text('Spotlight Talent Co.', style: AppType.display(size: 17, weight: FontWeight.w600)),
            Text(cfg.profileType, style: AppType.body(color: AppColors.textMuted, size: 13)),
            const SizedBox(height: 8),
            const StatusChip(label: 'KYC Verified', color: AppColors.success),
          ]),
        ),
        const Divider(height: 32),
        const _Field(label: 'Business name', value: 'Spotlight Talent Co.'),
        const _Field(label: 'Contact email', value: 'aisha@spotlight.in'),
        const _Field(label: 'Phone', value: '+91 99300 44556'),
        const _Field(label: 'City', value: 'Delhi'),
        for (final f in cfg.profileFields) _Field(label: f.key, value: f.value),
        const _Field(label: 'About', value: 'Premium talent agency representing editorial and runway models across India.', lines: 3),
      ]),
    );
  }

  /// Live mini-render of the consumer marketplace listing card.
  Widget _marketplacePreview(BuildContext context, VendorCategoryConfig cfg) {
    return SectionCard(
      title: 'Marketplace Preview',
      actions: [StatusChip(label: 'Live', color: AppColors.success)],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How your card appears to users browsing AOneGo9.', style: AppType.body(size: 12.5, color: AppColors.textMuted)),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 132,
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [cfg.accent.withValues(alpha: 0.32), AppColors.surface])),
              child: Stack(children: [
                Center(child: Icon(cfg.icon, size: 46, color: cfg.accent.withValues(alpha: 0.85))),
                Positioned(top: 10, left: 10, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xCC09090B), borderRadius: BorderRadius.circular(20)),
                  child: Text(cfg.label.toUpperCase(), style: AppType.eyebrow(color: cfg.accent, size: 9)),
                )),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('Spotlight Talent Co.', style: AppType.display(size: 16, weight: FontWeight.w600))),
                  const Icon(Icons.verified, size: 16, color: AppColors.gold),
                ]),
                const SizedBox(height: 3),
                Text(cfg.profileType, style: AppType.body(size: 12, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.star, size: 14, color: AppColors.gold),
                  const SizedBox(width: 4),
                  Text('4.8', style: AppType.body(size: 12.5, weight: FontWeight.w700)),
                  Text('  ·  132 bookings', style: AppType.body(size: 12, color: AppColors.textMuted)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: cfg.accent, borderRadius: BorderRadius.circular(8)),
                    child: Text('Enquire', style: AppType.body(size: 12, weight: FontWeight.w700, color: const Color(0xFF1A1407))),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── The SaaS portfolio manager ──
  Widget _portfolioManager(BuildContext context, VendorCategoryConfig cfg) {
    final cols = responsiveValue(context, mobile: 1, tablet: 2, desktop: 2);
    final featured = _works.where((w) => w.featured).length;
    return SectionCard(
      title: 'Portfolio',
      actions: [
        Text('${_works.length} works · $featured featured', style: AppType.body(size: 12, color: AppColors.textMuted)),
        const SizedBox(width: 12),
        ElevatedButton.icon(onPressed: () => _editWork(cfg, null), icon: const Icon(Icons.add, size: 16), label: const Text('Add work')),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Each work shows a cover, a category tag and a description underneath — exactly as it renders in the user app gallery. Drag the star to feature your best work first.',
            style: AppType.body(size: 12.5, color: AppColors.textMuted, height: 1.5)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.18,
          children: [
            for (var i = 0; i < _sorted.length; i++) _workCard(cfg, _sorted[i]),
            _addCard(cfg),
          ],
        ),
      ]),
    );
  }

  List<PortfolioWork> get _sorted {
    final list = [..._works];
    list.sort((a, b) => (b.featured ? 1 : 0).compareTo(a.featured ? 1 : 0));
    return list;
  }

  Widget _workCard(VendorCategoryConfig cfg, PortfolioWork w) {
    return HoverFx(
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: h ? cfg.accent.withValues(alpha: 0.5) : AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cover
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [cfg.accent.withValues(alpha: 0.30), AppColors.surfaceAlt]),
                ),
                child: Center(child: Text(w.emoji, style: const TextStyle(fontSize: 38))),
              ),
              Positioned(top: 9, left: 9, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xCC09090B), borderRadius: BorderRadius.circular(20)),
                child: Text(w.tag.toUpperCase(), style: AppType.eyebrow(color: cfg.accent, size: 8.5)),
              )),
              Positioned(top: 6, right: 6, child: IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: w.featured ? 'Featured' : 'Feature this',
                icon: Icon(w.featured ? Icons.star : Icons.star_border, size: 18, color: w.featured ? AppColors.gold : Colors.white70),
                onPressed: () => setState(() => w.featured = !w.featured),
              )),
            ]),
          ),
          // Headline + description underneath (the explicit ask)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(w.headline, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.body(size: 13.5, weight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(w.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppType.body(size: 11.5, color: AppColors.textMuted, height: 1.4)),
              const SizedBox(height: 8),
              Row(children: [
                _miniBtn(Icons.edit_outlined, 'Edit', () => _editWork(cfg, w)),
                const SizedBox(width: 8),
                _miniBtn(Icons.delete_outline, 'Delete', () => setState(() => _works.remove(w)), danger: true),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _addCard(VendorCategoryConfig cfg) {
    return HoverFx(
      onTap: () => _editWork(cfg, null),
      builder: (h) => DottedPanel(
        active: h,
        accent: cfg.accent,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_photo_alternate_outlined, size: 30, color: h ? cfg.accent : AppColors.textMuted),
          const SizedBox(height: 8),
          Text('Add a work', style: AppType.body(size: 13, weight: FontWeight.w600, color: h ? cfg.accent : AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text('Image · headline · description', style: AppType.body(size: 11, color: AppColors.textMuted)),
        ]),
      ),
    );
  }

  Widget _miniBtn(IconData icon, String label, VoidCallback onTap, {bool danger = false}) {
    final c = danger ? AppColors.danger : AppColors.textSecondary;
    return HoverFx(
      onTap: onTap,
      builder: (h) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: h ? c.withValues(alpha: 0.12) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: h ? c.withValues(alpha: 0.4) : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 5),
          Text(label, style: AppType.body(size: 11.5, weight: FontWeight.w600, color: c)),
        ]),
      ),
    );
  }

  // Add / edit a work via a sheet, with the same fields the user app renders.
  void _editWork(VendorCategoryConfig cfg, PortfolioWork? existing) {
    final headline = TextEditingController(text: existing?.headline ?? '');
    final desc = TextEditingController(text: existing?.description ?? '');
    final tag = TextEditingController(text: existing?.tag ?? '');
    final emoji = TextEditingController(text: existing?.emoji ?? cfg.label.characters.first);
    bool featured = existing?.featured ?? false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
          title: Text(existing == null ? 'Add portfolio work' : 'Edit work', style: AppType.display(size: 20, weight: FontWeight.w600)),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                _dlgLabel('Headline'),
                TextField(controller: headline, decoration: const InputDecoration(hintText: 'e.g. Vogue India Editorial')),
                const SizedBox(height: 14),
                _dlgLabel('Description (shown under the image)'),
                TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(hintText: 'What the project was, where, and your role…')),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _dlgLabel('Category tag'),
                    TextField(controller: tag, decoration: const InputDecoration(hintText: 'Editorial')),
                  ])),
                  const SizedBox(width: 12),
                  SizedBox(width: 96, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _dlgLabel('Cover'),
                    TextField(controller: emoji, textAlign: TextAlign.center, decoration: const InputDecoration(hintText: '📷')),
                  ])),
                ]),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: cfg.accent,
                  value: featured,
                  onChanged: (v) => setLocal(() => featured = v),
                  title: Text('Feature on profile', style: AppType.body(size: 13, weight: FontWeight.w600)),
                  subtitle: Text('Featured works appear first', style: AppType.body(size: 11, color: AppColors.textMuted)),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (headline.text.trim().isEmpty) return;
                setState(() {
                  if (existing == null) {
                    _works.add(PortfolioWork(
                      headline: headline.text.trim(),
                      description: desc.text.trim(),
                      tag: tag.text.trim().isEmpty ? cfg.label : tag.text.trim(),
                      emoji: emoji.text.trim().isEmpty ? '🖼️' : emoji.text.trim(),
                      featured: featured,
                    ));
                  } else {
                    existing
                      ..headline = headline.text.trim()
                      ..description = desc.text.trim()
                      ..tag = tag.text.trim().isEmpty ? existing.tag : tag.text.trim()
                      ..emoji = emoji.text.trim().isEmpty ? existing.emoji : emoji.text.trim()
                      ..featured = featured;
                  }
                });
                Navigator.pop(ctx);
                _toast(existing == null ? 'Work added to your portfolio' : 'Work updated');
              },
              child: Text(existing == null ? 'Add work' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dlgLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(t, style: AppType.body(size: 12.5, weight: FontWeight.w600)),
      );
}

/// Dashed-look "add" panel.
class DottedPanel extends StatelessWidget {
  final Widget child;
  final bool active;
  final Color accent;
  const DottedPanel({super.key, required this.child, required this.active, required this.accent});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: active ? accent.withValues(alpha: 0.06) : AppColors.surfaceAlt.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? accent.withValues(alpha: 0.5) : AppColors.border),
      ),
      child: Center(child: child),
    );
  }
}

class _Field extends StatelessWidget {
  final String label, value;
  final int lines;
  const _Field({required this.label, required this.value, this.lines = 1});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppType.body(weight: FontWeight.w600, size: 13)),
        const SizedBox(height: 8),
        TextField(controller: TextEditingController(text: value), maxLines: lines),
      ]),
    );
  }
}
