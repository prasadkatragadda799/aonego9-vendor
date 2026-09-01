import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aonego9_vendor/core/category/vendor_category.dart';
import 'package:aonego9_vendor/core/theme/app_colors.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

const aa = 4.5;
String hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

void main() {
  for (final brightness in [Brightness.dark, Brightness.light]) {
    final name = brightness == Brightness.dark ? 'dark' : 'light';

    group('$name theme', () {
      setUp(() => AppColors.applyBrightness(brightness));

      Map<String, Color> surfaces() => {
            'bg': AppColors.bg,
            'surface': AppColors.surface,
            'surfaceAlt': AppColors.surfaceAlt,
            'sidebar': AppColors.sidebar,
          };

      test('text ramp clears AA on every surface', () {
        final ramp = {
          'textPrimary': AppColors.textPrimary,
          'textSecondary': AppColors.textSecondary,
          'textMuted': AppColors.textMuted,
        };
        for (final t in ramp.entries) {
          for (final s in surfaces().entries) {
            final r = contrast(t.value, s.value);
            expect(r, greaterThanOrEqualTo(aa),
                reason: '$name: ${t.key} ${hex(t.value)} on ${s.key} ${hex(s.value)} '
                    'is ${r.toStringAsFixed(2)}:1');
          }
        }
      });

      test('gold and status colours clear AA as text', () {
        final ink = {
          'gold': AppColors.gold,
          'success': AppColors.success,
          'warning': AppColors.warning,
          'danger': AppColors.danger,
          'info': AppColors.info,
        };
        for (final t in ink.entries) {
          for (final s in surfaces().entries) {
            final r = contrast(t.value, s.value);
            expect(r, greaterThanOrEqualTo(aa),
                reason: '$name: ${t.key} ${hex(t.value)} on ${s.key} '
                    'is ${r.toStringAsFixed(2)}:1');
          }
        }
      });

      test('every marketplace accent is readable as a label', () {
        for (final c in marketCategories) {
          for (final s in surfaces().entries) {
            final r = contrast(c.accent, s.value);
            expect(r, greaterThanOrEqualTo(aa),
                reason: '$name: ${c.id} accent ${hex(c.accent)} on ${s.key} '
                    'is ${r.toStringAsFixed(2)}:1');
          }
        }
      });

      test('onAccent stays legible on the fill it names', () {
        final fills = <String, Color>{
          'gold': AppColors.gold,
          'danger': AppColors.danger,
          'success': AppColors.success,
          for (final c in marketCategories) c.id: c.accent,
        };
        for (final f in fills.entries) {
          final r = contrast(AppColors.onAccent(f.value), f.value);
          expect(r, greaterThanOrEqualTo(aa),
              reason: '$name: onAccent on ${f.key} ${hex(f.value)} '
                  'is ${r.toStringAsFixed(2)}:1');
        }
      });

      test('surfaces are distinguishable', () {
        expect(AppColors.bg, isNot(AppColors.surface));
        expect(AppColors.bg, isNot(AppColors.sidebar));
      });
    });
  }

  group('taxonomy', () {
    test('ids are unique and every archetype resolves', () {
      final ids = marketCategories.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final c in marketCategories) {
        expect(categoryConfigs[c.archetype], isNotNull, reason: '${c.id} has no archetype config');
      }
    });

    test('resolves the most specific term first', () {
      expect(marketCategoryFromLabel('Makeup Studio')?.id, 'makeupStudio');
      expect(marketCategoryFromLabel('Makeup Artist')?.id, 'makeupArtist');
      expect(marketCategoryFromLabel('Video Editor')?.id, 'editVideo');
      expect(marketCategoryFromLabel('Videography')?.id, 'video');
      expect(marketCategoryFromLabel('Photo Studio')?.id, 'studio');
      expect(marketCategoryFromLabel('Photography')?.id, 'photo');
    });

    test('does not file female models as male', () {
      // "female model" contains the substring "male model".
      expect(marketCategoryFromLabel('Female Models')?.id, 'modelF');
      expect(marketCategoryFromLabel('Male Models')?.id, 'modelM');
    });

    test('the original five labels still resolve', () {
      expect(marketCategoryFromLabel('Photography')?.archetype, VendorCategory.photography);
      expect(marketCategoryFromLabel('Videography')?.archetype, VendorCategory.videography);
      expect(marketCategoryFromLabel('Venue')?.archetype, VendorCategory.venue);
      expect(marketCategoryFromLabel('Event Services')?.archetype, VendorCategory.events);
      expect(marketCategoryFromLabel('Talent Agency')?.archetype, VendorCategory.talent);
    });

    test('configForLabel relabels the archetype', () {
      AppColors.applyBrightness(Brightness.dark);
      final cfg = configForLabel('Jewellery');
      expect(cfg.label, 'Jewellery');
      // Behaves like a venue console but is not called one.
      expect(cfg.category, VendorCategory.venue);
    });

    test('unrecognised text falls back rather than throwing', () {
      expect(marketCategoryFromLabel('qwertyuiop'), isNull);
      expect(marketCategoryFromLabel(''), isNull);
      expect(configForLabel('qwertyuiop').label, isNotEmpty);
    });
  });
}
