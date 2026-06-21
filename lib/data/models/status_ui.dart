import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../models/models.dart';

class StatusUi {
  static (String, Color) booking(BookingStatus s) => switch (s) {
        BookingStatus.requested => ('New Request', AppColors.info),
        BookingStatus.confirmed => ('Confirmed', AppColors.success),
        BookingStatus.inProgress => ('In Progress', AppColors.gold),
        BookingStatus.completed => ('Completed', AppColors.success),
        BookingStatus.cancelled => ('Cancelled', AppColors.textMuted),
        BookingStatus.disputed => ('Disputed', AppColors.danger),
      };

  static (String, Color) txn(TxnType t) => switch (t) {
        TxnType.earning => ('Earning', AppColors.success),
        TxnType.payout => ('Payout', AppColors.info),
        TxnType.refund => ('Refund', AppColors.danger),
      };

  static IconData kind(IconKind k) => switch (k) {
        IconKind.booking => Icons.event_available_outlined,
        IconKind.payment => Icons.payments_outlined,
        IconKind.review => Icons.star_outline,
        IconKind.system => Icons.info_outline,
      };

  static Color kindColor(IconKind k) => switch (k) {
        IconKind.booking => AppColors.success,
        IconKind.payment => AppColors.gold,
        IconKind.review => AppColors.info,
        IconKind.system => AppColors.textSecondary,
      };
}
