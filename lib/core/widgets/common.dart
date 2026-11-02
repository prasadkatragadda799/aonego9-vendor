import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/theme_mode_store.dart';
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
  /// Null means the brand gold for the active theme — it cannot be a default
  /// value now that gold is a theme-dependent getter.
  final Color? accent;
  const AmbientBackground({super.key, required this.child, this.accent});

  @override
  Widget build(BuildContext context) {
    final accent = this.accent ?? AppColors.gold;
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.bg),
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
  /// Null means the brand gold for the active theme.
  final Color? color;
  const Eyebrow(this.text, {super.key, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.gold;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 1.5, color: c),
        const SizedBox(width: 8),
        Flexible(child: Text(text.toUpperCase(), style: AppType.eyebrow(color: c, size: 10.5))),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.surfaceLift],
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
              // Title and actions share a row when there is room; on a phone
              // a long title plus two actions wrapped under each other.
              LayoutBuilder(builder: (context, c) {
                final titleText = Text(title!, style: AppType.display(size: 16.5, weight: FontWeight.w600));
                if (actions.isEmpty) return titleText;
                if (c.maxWidth < 420 && actions.length > 1) {
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    titleText,
                    const SizedBox(height: 10),
                    Wrap(spacing: 10, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: actions),
                  ]);
                }
                return Row(children: [
                  Expanded(child: titleText),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: actions,
                    ),
                  ),
                ]);
              }),
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
  final VoidCallback? onTap;
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.delta,
    this.deltaUp = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HoverFx(
      onTap: onTap,
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
                  if (onTap != null && delta == null)
                    Icon(Icons.arrow_outward, size: 16, color: h ? color : AppColors.textMuted),
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
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, maxLines: 1, style: AppType.display(size: 26, weight: FontWeight.w600)),
              ),
              const SizedBox(height: 5),
              Text(label.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.eyebrow(color: AppColors.textSecondary, size: 10.5)),
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
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.body(size: 11.5, weight: FontWeight.w600, color: color)),
          ),
        ],
      ),
    );
  }
}

/// Search field used above lists / tables.
class SearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final String initial;
  const SearchField({super.key, this.hint = 'Search…', required this.onChanged, this.initial = ''});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _c,
        builder: (context, v, _) => TextField(
          controller: _c,
          onChanged: widget.onChanged,
          textInputAction: TextInputAction.search,
          style: AppType.body(size: 13.5),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted),
            suffixIcon: v.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _c.clear();
                      widget.onChanged('');
                    },
                  ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
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
      Center(child: Padding(padding: const EdgeInsets.all(48), child: CircularProgressIndicator(color: AppColors.gold)));
}

class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? detail;
  final Widget? action;
  const EmptyView({
    super.key,
    this.message = 'Nothing here yet',
    this.icon = Icons.inbox_outlined,
    this.detail,
    this.action,
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
            Text(message,
                textAlign: TextAlign.center,
                style: AppType.body(size: 14, weight: FontWeight.w600, color: AppColors.textPrimary)),
            if (detail != null) ...[
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Text(detail!,
                    textAlign: TextAlign.center,
                    style: AppType.body(size: 12.5, color: AppColors.textSecondary, height: 1.5)),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// A load failure with a way out. Every screen used to hand-roll this (or
/// skip it and spin forever when a request failed).
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.danger.withValues(alpha: .35)),
            ),
            child: Icon(Icons.cloud_off_outlined, size: 28, color: AppColors.danger),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Text(message,
                textAlign: TextAlign.center,
                style: AppType.body(size: 13.5, color: AppColors.textSecondary, height: 1.5)),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try again'),
          ),
        ]),
      ),
    );
  }
}

/// An inline banner for a non-blocking problem or notice inside a page.
class InlineNotice extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;
  final Widget? action;
  const InlineNotice({super.key, required this.message, this.icon = Icons.info_outline, this.color, this.action});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: .38)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 17, color: c)),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: AppType.body(size: 12.5, color: c, height: 1.45, weight: FontWeight.w600))),
        if (action != null) ...[const SizedBox(width: 8), action!],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PAGE SCAFFOLDING
// ─────────────────────────────────────────────────────────────

/// Standard page body: responsive gutters, a max content width so lines do
/// not run 2000px wide on an ultrawide monitor, and pull-to-refresh.
class PageBody extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final double maxWidth;
  const PageBody({super.key, required this.children, this.onRefresh, this.maxWidth = 1320});

  @override
  Widget build(BuildContext context) {
    final pad = responsiveValue<double>(context, mobile: 16, tablet: 22, desktop: 28);
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + 24),
      children: [
        // Full width up to [maxWidth], then centred. Without the SizedBox a
        // child narrower than the page (a pill bar, a notice) was centred
        // instead of sitting on the left edge with everything else.
        for (final c in children)
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SizedBox(width: double.infinity, child: c),
            ),
          ),
      ],
    );
    if (onRefresh == null) return list;
    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.surface,
      onRefresh: onRefresh!,
      child: list,
    );
  }
}

/// A grid whose tiles size to their content.
///
/// `GridView.count` with a fixed `childAspectRatio` clipped or overflowed
/// cards whenever the viewport made a cell shorter than its content — every
/// stat row on a 360px phone. This picks a column count from the available
/// width and lets each row be as tall as it needs.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minTileWidth;
  final int maxColumns;
  final double spacing;
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 240,
    this.maxColumns = 4,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      var cols = ((w + spacing) / (minTileWidth + spacing)).floor().clamp(1, maxColumns);
      if (children.length < cols) cols = children.length.clamp(1, maxColumns);
      final tileW = (w - spacing * (cols - 1)) / cols;
      final rows = <Widget>[];
      for (var i = 0; i < children.length; i += cols) {
        final slice = children.sublist(i, (i + cols).clamp(0, children.length));
        rows.add(IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var j = 0; j < cols; j++) ...[
              if (j > 0) SizedBox(width: spacing),
              SizedBox(width: tileW, child: j < slice.length ? slice[j] : const SizedBox()),
            ],
          ]),
        ));
        if (i + cols < children.length) rows.add(SizedBox(height: spacing));
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
    });
  }
}

/// Selectable filter pill with an optional count, used for status tabs.
class FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final int? count;
  final VoidCallback onTap;
  final Color? color;
  const FilterPill({super.key, required this.label, required this.selected, required this.onTap, this.count, this.color});

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.gold;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.14) : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? accent : AppColors.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                style: AppType.body(
                    size: 12.5, weight: FontWeight.w600, color: selected ? accent : AppColors.textSecondary)),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? accent.withValues(alpha: .18) : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                    style: AppType.mono(size: 10.5, weight: FontWeight.w700, color: selected ? accent : AppColors.textSecondary)),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Horizontally scrollable row of pills on phones (so seven status tabs do
/// not wrap into three lines), a wrapping row on wider screens.
class PillBar extends StatelessWidget {
  final List<Widget> children;
  const PillBar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ]),
      );
    }
    return Wrap(spacing: 10, runSpacing: 10, children: children);
  }
}

// ─────────────────────────────────────────────────────────────
// FEEDBACK
// ─────────────────────────────────────────────────────────────

/// Toasts. Capture the messenger BEFORE an await (`final m = Toast.of(context)`)
/// so a toast after a dialog closes never reaches for a dead context.
class Toast {
  Toast._();

  static ScaffoldMessengerState of(BuildContext context) => ScaffoldMessenger.of(context);

  static void ok(ScaffoldMessengerState m, String msg) => _show(m, msg, Icons.check_circle_outline, AppColors.success);

  static void info(ScaffoldMessengerState m, String msg) => _show(m, msg, Icons.info_outline, AppColors.info);

  static void error(ScaffoldMessengerState m, String msg) =>
      _show(m, msg, Icons.error_outline, AppColors.danger, duration: const Duration(seconds: 5));

  static void _show(ScaffoldMessengerState m, String msg, IconData icon, Color color,
      {Duration duration = const Duration(seconds: 3)}) {
    m
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: duration,
        content: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: AppType.body(size: 13.5, color: AppColors.textPrimary))),
        ]),
      ));
  }
}

/// Confirmation dialog for destructive or consequential actions.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Text(message)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: destructive
              ? ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dangerFill,
                  foregroundColor: AppColors.onAccent(AppColors.dangerFill),
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Small inline spinner for buttons.
class ButtonSpinner extends StatelessWidget {
  final Color? color;
  const ButtonSpinner({super.key, this.color});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: color ?? AppColors.onAccent(AppColors.gold)),
      );
}

/// Labelled form field used by the console's sheets and dialogs.
class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  final String? hint;
  const LabeledField({super.key, required this.label, required this.child, this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: AppType.body(size: 12.5, weight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 7),
        child,
        if (hint != null) ...[
          const SizedBox(height: 5),
          Text(hint!, style: AppType.body(size: 11.5, color: AppColors.textMuted)),
        ],
      ]),
    );
  }
}

/// Bottom sheet on phones, centred dialog on wider screens — the right
/// container for an editor on each form factor.
Future<T?> showAdaptiveSheet<T>(BuildContext context, {required WidgetBuilder builder, double maxWidth = 560}) {
  if (Responsive.isMobile(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: builder(ctx),
      ),
    );
  }
  return showDialog<T>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: MediaQuery.sizeOf(ctx).height * .88),
        child: Padding(padding: const EdgeInsets.only(top: 18), child: builder(ctx)),
      ),
    ),
  );
}

/// Avatar with initials fallback.
class InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  /// Shown instead of the initials when set; falls back to them if it fails.
  final String imageUrl;
  const InitialsAvatar({super.key, required this.name, this.size = 38, this.imageUrl = ''});

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.goldDark, AppColors.gold]),
        shape: BoxShape.circle,
      ),
      child: Text(_initials,
          style: AppType.display(
              color: AppColors.onAccent(AppColors.gold), weight: FontWeight.w700, size: size * 0.36, letterSpacing: 0)),
    );
    if (imageUrl.trim().isEmpty) return initials;
    return ClipOval(
      child: Image.network(
        imageUrl.trim(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => initials,
        loadingBuilder: (_, child, progress) => progress == null ? child : initials,
      ),
    );
  }
}

/// Page header with an eyebrow + Fraunces title + optional actions.
/// [accent] colours the eyebrow tick so each vendor category reads in its tint.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  /// Null means the brand gold for the active theme.
  final Color? accent;
  final List<Widget> actions;
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.accent,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final accent = this.accent ?? AppColors.gold;
    final stack = Responsive.isMobile(context);
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Eyebrow(eyebrow!, color: accent),
          const SizedBox(height: 10),
        ],
        Text(title, style: AppType.display(size: stack ? 24 : 28, weight: FontWeight.w600, height: 1.2)),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(subtitle!, style: AppType.body(size: 13.5, color: AppColors.textSecondary, height: 1.45)),
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
        if (actions.isNotEmpty) ...[
          const SizedBox(width: 16),
          Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: actions),
        ],
      ],
    );
  }
}

/// Appearance picker — the three choices spelled out, for the account menu
/// and settings, where a cycling icon would be too cryptic.
Future<void> showThemePicker(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Appearance'),
      content: ValueListenableBuilder<String>(
        valueListenable: ThemeModeStore.mode,
        builder: (ctx, mode, _) => Column(mainAxisSize: MainAxisSize.min, children: [
          for (final (v, label, icon) in const [
            ('system', 'Match my device', Icons.brightness_auto_rounded),
            ('light', 'Light', Icons.light_mode_rounded),
            ('dark', 'Dark', Icons.dark_mode_rounded),
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: mode == v ? AppColors.gold : AppColors.textSecondary),
              title: Text(label),
              trailing: mode == v ? Icon(Icons.check_circle, color: AppColors.gold) : null,
              onTap: () {
                ThemeModeStore.set(v);
                Navigator.pop(ctx);
              },
            ),
        ]),
      ),
    ),
  );
}

/// Appearance cycle — system → light → dark. Sits in the shell's app bar.
///
/// A single cycling button rather than a three-way control: the console's
/// header has one slot, and "follow system" stays reachable as a step rather
/// than being collapsed away into a binary.
class ThemeCycleButton extends StatelessWidget {
  const ThemeCycleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: ThemeModeStore.mode,
      builder: (context, mode, _) {
        final (icon, tip) = switch (mode) {
          'light' => (Icons.light_mode_rounded, 'Light — tap for dark'),
          'dark' => (Icons.dark_mode_rounded, 'Dark — tap to follow system'),
          _ => (Icons.brightness_auto_rounded, 'Following system — tap for light'),
        };
        return IconButton(
          tooltip: tip,
          onPressed: ThemeModeStore.cycle,
          icon: Icon(icon, size: 20),
        );
      },
    );
  }
}
