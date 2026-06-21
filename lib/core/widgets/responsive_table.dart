import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../responsive/responsive.dart';

class TableColumn {
  final String label;
  final int flex;
  final bool numeric;
  const TableColumn(this.label, {this.flex = 1, this.numeric = false});
}

/// Renders tabular data as a styled table on wide screens and as
/// stacked cards on mobile — from a single data definition.
class ResponsiveTable extends StatelessWidget {
  final List<TableColumn> columns;
  final int rowCount;

  /// Builds the cell widgets for a given row (length must match columns).
  final List<Widget> Function(int index) cellsBuilder;

  /// Optional mobile card builder. If null, a default key/value card is used.
  final Widget Function(int index)? mobileCardBuilder;

  final void Function(int index)? onRowTap;

  const ResponsiveTable({
    super.key,
    required this.columns,
    required this.rowCount,
    required this.cellsBuilder,
    this.mobileCardBuilder,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return Column(
        children: [
          for (var i = 0; i < rowCount; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onRowTap == null ? null : () => onRowTap!(i),
                child: mobileCardBuilder?.call(i) ?? _defaultMobileCard(i),
              ),
            ),
        ],
      );
    }
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              for (final c in columns)
                Expanded(
                  flex: c.flex,
                  child: Text(
                    c.label.toUpperCase(),
                    textAlign: c.numeric ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Rows
        for (var i = 0; i < rowCount; i++) ...[
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onRowTap == null ? null : () => onRowTap!(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var c = 0; c < columns.length; c++)
                    Expanded(
                      flex: columns[c].flex,
                      child: Align(
                        alignment: columns[c].numeric ? Alignment.centerRight : Alignment.centerLeft,
                        child: cellsBuilder(i)[c],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (i < rowCount - 1) const Divider(height: 1),
        ],
      ],
    );
  }

  Widget _defaultMobileCard(int i) {
    final cells = cellsBuilder(i);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var c = 0; c < columns.length; c++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 110, child: Text(columns[c].label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
                  Expanded(child: cells[c]),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Plain text cell helper.
Widget tcell(String text, {FontWeight weight = FontWeight.w500, Color? color, bool numeric = false}) =>
    Text(text, style: TextStyle(fontSize: 13.5, fontWeight: weight, color: color ?? AppColors.textPrimary));
