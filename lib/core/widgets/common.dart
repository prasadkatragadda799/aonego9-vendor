import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/typography.dart';
import '../responsive/responsive.dart';

// ─────────────────────────────────────────────────────────────
// MOTION & AMBIENCE
// Ported from the consumer app so all three apps share one feel.
// ─────────────────────────────────────────────────────────────

/// Fade + rise entrance animation. Wrap dashboard sections / cards and
/// stagger with [delay] for the editorial "settle in" effect.
class FadeUp extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double offset;
  const FadeUp({super.key, required this.child, this.delay = Duration.zero, this.offset = 16});

  @override
  State<FadeUp> createState() => _FadeUpState();
}

class _FadeUpState extends State<FadeUp> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 460));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curved,
      builder: (_, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(offset: Offset(0, widget.offset * (1 - curved.value)), child: child),
      ),
      child: widget.child,
    );
  }
}

/// Hover-state wrapper. `builder(hovering)` lets callers add lift / glow.
class HoverFx extends StatefulWidget {
  final Widget Function(bool hovering) builder;
  final VoidCallback? onTap;
  const HoverFx({super.key, required this.builder, this.onTap});

  @override
  State<HoverFx> createState() => _HoverFxState();
}

class _HoverFxState extends State<HoverFx> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(onTap: widget.onTap, child: widget.builder(_h)),
    );
  }
}

/// Deep charcoal canvas with two soft radial glows for premium depth.
/// Wrap the page body once (in the shell). [accent] tints the primary glow —
/// pass the signed-in vendor's category accent so the whole console reads
/// in their colour.
class AmbientBackground extends StatelessWidget {
  final Widget child;
  final Color accent;
  const AmbientBackground({super.key, required this.child, this.accent = AppColors.gold});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.bg),
      child: Stack(
        children: [
          Positioned(top: -160, right: -120, child: _glow(accent.withValues(alpha: 0.12), 460)),
          Positioned(bottom: -200, left: -140, child: _glow(accent.withValues(alpha: 0.05), 520)),
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  Widget _glow(Color c, double size) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [c, c.withValues(alpha: 0)]),
          ),
        ),
      );
}

/// Tiny uppercase tracked label with a leading accent tick — the
/// consumer app's signature "eyebrow" above headings.
class Eyebrow extends StatelessWidget {
  final String text;
  final Color color;
  const Eyebrow(this.text, {super.key, this.color = AppColors.gold});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 1.5, color: color),
        const SizedBox(width: 8),
        Text(text.toUpperCase(), style: AppType.eyebrow(color: color, size: 10.5)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SURFACES
// ─────────────────────────────────────────────────────────────

/// A titled container card used to group content.
class SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final List<Widget> actions;
  final EdgeInsets padding;
  const SectionCard({
    super.key,
    this.title,
    required this.child,
    this.actions = const [],
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, Color(0xFF181B22)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Expanded(child: Text(title!, style: AppType.display(size: 16.5, weight: FontWeight.w600))),
                  ...actions,
                ],
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: 16),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// KPI / metric card for dashboards — tinted to its metric colour, with a
/// hover lift + glow.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? delta;
  final bool deltaUp;
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.delta,
    this.deltaUp = true,
  });

  @override
  Widget build(BuildContext context) {
    return HoverFx(
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, h ? -3 : 0, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.10), AppColors.surface],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: h ? color.withValues(alpha: 0.55) : AppColors.border),
          boxShadow: h
              ? [BoxShadow(color: color.withValues(alpha: 0.16), blurRadius: 24, offset: const Offset(0, 12))]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  if (delta != null)
                    Row(
                      children: [
                        Icon(deltaUp ? Icons.trending_up : Icons.trending_down,
                            size: 15, color: deltaUp ? AppColors.success : AppColors.danger),
                        const SizedBox(width: 3),
                        Text(delta!,
                            style: AppType.body(
                                size: 12,
                                weight: FontWeight.w700,
                                color: deltaUp ? AppColors.success : AppColors.danger)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(value, style: AppType.display(size: 27, weight: FontWeight.w600)),
              const SizedBox(height: 5),
              Text(label.toUpperCase(), style: AppType.eyebrow(color: AppColors.textSecondary, size: 10.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Coloured status pill.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const StatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: AppType.body(size: 11.5, weight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

/// Search field used above lists / tables.
class SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const SearchField({super.key, this.hint = 'Search…', required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}

/// Filter dropdown chip.
class FilterDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) label;
  final ValueChanged<T?> onChanged;
  const FilterDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          dropdownColor: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: AppType.body(size: 13, color: AppColors.textPrimary),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(label(e)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Generic loading / empty / error wrappers.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: AppColors.gold)));
}

class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyView({super.key, this.message = 'Nothing here yet', this.icon = Icons.inbox_outlined});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 32, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            Text(message, style: AppType.body(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// Avatar with initials fallback.
class InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  const InitialsAvatar({super.key, required this.name, this.size = 38});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.goldDark, AppColors.gold]),
        shape: BoxShape.circle,
      ),
      child: Text(_initials,
          style: AppType.display(
              color: const Color(0xFF1A1407), weight: FontWeight.w700, size: size * 0.36)),
    );
  }
}

/// Page header with an eyebrow + Fraunces title + optional actions.
/// [accent] colours the eyebrow tick so each vendor category reads in its tint.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final Color accent;
  final List<Widget> actions;
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.accent = AppColors.gold,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final stack = Responsive.isMobile(context);
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Eyebrow(eyebrow!, color: accent),
          const SizedBox(height: 10),
        ],
        Text(title, style: AppType.display(size: stack ? 26 : 30, weight: FontWeight.w600, height: 1.1)),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(subtitle!, style: AppType.body(size: 13.5, color: AppColors.textSecondary)),
        ],
      ],
    );
    if (stack) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 10, runSpacing: 10, children: actions),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleBlock),
        ...actions.expand((a) => [a, const SizedBox(width: 10)]),
      ],
    );
  }
}
