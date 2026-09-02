import 'package:flutter_test/flutter_test.dart';
import 'package:aonego9_vendor/data/models/models.dart';

/// The backend is still being built, so partial and null-filled payloads are
/// the normal case rather than an edge case. Every model has to survive one
/// without throwing — a TypeError here blanks a whole screen.
void main() {
  group('models survive a payload with nothing in it', () {
    test('ServicePackage', () {
      expect(() => ServicePackage.fromJson({'id': '1'}), returnsNormally);
    });

    test('TalentMember', () {
      expect(() => TalentMember.fromJson({'id': '1'}), returnsNormally);
    });

    test('VendorBooking', () {
      expect(() => VendorBooking.fromJson({'id': '1'}), returnsNormally);
    });

    test('EarningTxn', () {
      expect(() => EarningTxn.fromJson({'id': '1'}), returnsNormally);
    });
  });

  group('models survive explicit nulls', () {
    test('numeric fields fall back to zero rather than throwing', () {
      final p = ServicePackage.fromJson({'id': '1', 'price': null});
      expect(p.price, 0);
      final t = TalentMember.fromJson({'id': '1', 'dayRate': null, 'rating': null});
      expect(t.dayRate, 0);
      expect(t.rating, 0);
    });
  });
}
