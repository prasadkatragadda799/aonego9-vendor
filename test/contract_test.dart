import 'package:flutter_test/flutter_test.dart';
import 'package:aonego9_vendor/core/utils/file_saver.dart';
import 'package:aonego9_vendor/data/api/api_client.dart';
import 'package:aonego9_vendor/data/api/api_errors.dart';
import 'package:aonego9_vendor/data/models/models.dart';

/// The console reads both the backend's snake_case and its own legacy
/// camelCase, and never throws on a partial payload.
void main() {
  group('models read the backend contract', () {
    test('package bookings_count (user app key) and bookingsCount both parse', () {
      expect(ServicePackage.fromJson({'id': 1, 'bookings_count': 4}).bookingsCount, 4);
      expect(ServicePackage.fromJson({'id': 1, 'bookingsCount': 2}).bookingsCount, 2);
    });

    test('roster day_rate and dayRate both parse', () {
      expect(TalentMember.fromJson({'id': 'a', 'day_rate': 2500}).dayRate, 2500);
      expect(TalentMember.fromJson({'id': 'a', 'dayRate': '1800'}).dayRate, 1800);
    });

    test('booking status accepts in_progress and inProgress', () {
      expect(VendorBooking.fromJson({'id': 'b', 'status': 'in_progress'}).status, BookingStatus.inProgress);
      expect(VendorBooking.fromJson({'id': 'b', 'status': 'inProgress'}).status, BookingStatus.inProgress);
    });

    test('an inquiry reference marks the booking as an inquiry', () {
      final b = VendorBooking.fromJson({'id': 'b', 'inquiry_ref': 'AO9-123456'});
      expect(b.source, BookingSource.inquiry);
      expect(b.inquiryRef, 'AO9-123456');
    });

    test('thread and notification survive missing timestamps', () {
      expect(() => ChatThread.fromJson({'id': 't'}), returnsNormally);
      expect(() => NotificationItem.fromJson({'id': 'n'}), returnsNormally);
      expect(() => VendorReview.fromJson({'id': 'r'}), returnsNormally);
    });

    test('notification read state and kind', () {
      final n = NotificationItem.fromJson({'id': 'n', 'kind': 'payout', 'unread': true, 'title': 'Paid'});
      expect(n.kind, IconKind.payment);
      expect(n.unread, isTrue);
      expect(n.markRead().unread, isFalse);
    });

    test('plan period suffix', () {
      expect(SubscriptionPlan.fromJson({'id': 'p', 'price': 0}).periodShort, '');
      expect(SubscriptionPlan.fromJson({'id': 'p', 'price': 999, 'period': 'per month'}).periodShort, ' / mo');
      expect(SubscriptionPlan.fromJson({'id': 'p', 'price': 9999, 'period': 'yearly'}).periodShort, ' / yr');
    });
  });

  group('ApiClient.asList', () {
    test('accepts a bare list, an envelope, and junk', () {
      expect(ApiClient.asList([{'a': 1}]).length, 1);
      expect(ApiClient.asList({'items': [{'a': 1}, {'a': 2}]}).length, 2);
      expect(ApiClient.asList({'points': [{'a': 1}]}, 'points').length, 1);
      expect(ApiClient.asList(null), isEmpty);
      expect(ApiClient.asList('oops'), isEmpty);
    });
  });

  group('error messages are human', () {
    test('never leaks the exception class name', () {
      expect(apiErrorMessage(const ApiException(500, 'Internal')), isNot(contains('ApiException')));
      expect(apiErrorMessage(const ApiException(401, 'x')), contains('sign in'));
      expect(apiErrorMessage(const ApiException(422, 'email: value is not a valid email')), contains('email'));
      expect(apiErrorMessage(StateError('boom'), fallback: 'Nope'), 'Nope');
    });
  });

  group('CSV export', () {
    test('quotes commas and quotes, neutralises formulas, keeps the BOM', () {
      final csv = toCsv(['a', 'b'], [
        ['x, y', 'say "hi"'],
        ['=SUM(A1)', 5],
      ]);
      expect(csv.startsWith('﻿'), isTrue);
      expect(csv, contains('"x, y"'));
      expect(csv, contains('"say ""hi"""'));
      expect(csv, contains("'=SUM(A1)"));
    });
  });
}
