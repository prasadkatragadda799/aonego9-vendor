import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/typography.dart';

/// ─────────────────────────────────────────────
/// BRAND MARK — the AOneGo9 logo, shared with the user app.
///
/// Renders the same bundled artwork the marketplace uses
/// (assets/brand/aonego9_logo.png), falling back to a native wordmark drawn
/// from the same letterforms and sampled colours if the asset fails to
/// decode.
///
/// The master artwork bakes its neutral letters in white, which is right on
/// the night ground and invisible on paper, so the light theme draws the
/// text wordmark instead of tinting or plating the PNG — the same rule the
/// user app follows.
/// ─────────────────────────────────────────────
const String logoAssetPath = 'assets/brand/aonego9_logo.png';

class BrandLogo extends StatelessWidget {
  /// Cap height of the wordmark in logical pixels.
  final double size;
  const BrandLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final height = size * 1.18;
    if (AppColors.isLight) return _wordmark();
    return Image.asset(
      logoAssetPath,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => _wordmark(),
      frameBuilder: (_, child, frame, wasSync) =>
          wasSync || frame != null ? child : SizedBox(height: height),
    );
  }

  Widget _wordmark() {
    TextStyle mark(Color c) => AppType.display(
          size: size,
          weight: FontWeight.w700,
          color: c,
          height: 1,
          letterSpacing: -size * 0.045,
        );
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: 'A', style: mark(AppColors.logoAmber)),
        TextSpan(text: 'o', style: mark(AppColors.logoNeutral)),
        TextSpan(text: 'n', style: mark(AppColors.logoAmber)),
        TextSpan(text: 'e', style: mark(AppColors.logoNeutral)),
        TextSpan(text: 'G', style: mark(AppColors.logoCyan)),
        TextSpan(text: 'o', style: mark(AppColors.logoNeutral)),
        TextSpan(text: '9', style: mark(AppColors.logoAmber).copyWith(fontStyle: FontStyle.italic)),
      ]),
      maxLines: 1,
      overflow: TextOverflow.visible,
    );
  }
}

/// Square "A9" monogram — the favicon mark, for the collapsed rail and the
/// mobile app bar where the full wordmark does not fit. Amber A, cyan 9 on
/// the brand black, as in web/favicon.png.
class BrandMonogram extends StatelessWidget {
  final double size;
  const BrandMonogram({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final style = AppType.display(size: size * 0.42, weight: FontWeight.w800, height: 1, letterSpacing: 0);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0D),
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(color: AppColors.gold.withValues(alpha: 0.22), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Text.rich(TextSpan(children: [
        TextSpan(text: 'A', style: style.copyWith(color: AppColors.logoAmber)),
        TextSpan(text: '9', style: style.copyWith(color: AppColors.logoCyan, fontStyle: FontStyle.italic)),
      ])),
    );
  }
}

/// The console lockup: wordmark over a tracked product label
/// ("VENDOR CONSOLE" / "SUPER ADMIN").
class ConsoleLockup extends StatelessWidget {
  final String label;
  final double size;
  const ConsoleLockup({super.key, required this.label, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandLogo(size: size),
        const SizedBox(height: 5),
        Text(label.toUpperCase(), style: AppType.eyebrow(color: AppColors.gold, size: 9)),
      ],
    );
  }
}
