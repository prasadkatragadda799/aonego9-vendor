import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive.dart';
import '../../core/category/vendor_category.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../../data/repositories/vendor_repository.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _repo = VendorRepository();
  List<ServicePackage> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _repo.services();
    if (!mounted) return;
    setState(() { _all = s; _loading = false; });
  }

  Future<void> _toggle(ServicePackage p, bool v) async {
    await _repo.toggleService(p.id, v);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final cols = responsiveValue(context, mobile: 1, tablet: 2, desktop: 2);

    return ListView(
      padding: EdgeInsets.all(responsiveValue(context, mobile: 16, desktop: 28)),
      children: [
        PageHeader(
          title: VendorSession.config.servicesLabel,
          subtitle: VendorSession.config.servicesSubtitle,
          actions: [ElevatedButton.icon(onPressed: _openEditor, icon: const Icon(Icons.add, size: 18), label: const Text('Add Package'))],
        ),
        const SizedBox(height: 24),
        if (_loading) const LoadingView() else
          GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: responsiveValue(context, mobile: 1.7, tablet: 1.9, desktop: 2.1),
            children: [
              for (final p in _all)
                SectionCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                      Switch(value: p.active, activeColor: AppColors.gold, onChanged: (v) => _toggle(p, v)),
                    ]),
                    const SizedBox(height: 2),
                    Text(p.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(children: [
                      Text(cur.format(p.price), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold, fontSize: 17)),
                      Text(' / ${p.unit}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      const Spacer(),
                      StatusChip(label: '${p.bookingsCount} booked', color: AppColors.info),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      OutlinedButton.icon(onPressed: _openEditor, icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Edit')),
                      const SizedBox(width: 10),
                      if (!p.active) const StatusChip(label: 'Hidden', color: AppColors.textMuted),
                    ]),
                  ]),
                ),
            ],
          ),
      ],
    );
  }

  void _openEditor() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: BoxConstraints(maxWidth: Responsive.isMobile(context) ? double.infinity : 520),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.viewInsetsOf(ctx).bottom + 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Package details', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 20),
          const _Field(label: 'Title', hint: 'e.g. Fashion Editorial — Half Day'),
          _Field(label: 'Category', hint: VendorSession.config.serviceCategoryHint),
          Row(children: [
            const Expanded(child: _Field(label: 'Price (₹)', hint: '45000')),
            const SizedBox(width: 12),
            Expanded(child: _Field(label: 'Unit', hint: VendorSession.config.serviceUnitHint)),
          ]),
          const _Field(label: 'Description', hint: 'What is included…', lines: 3),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Save Package'))),
        ]),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label, hint;
  final int lines;
  const _Field({required this.label, required this.hint, this.lines = 1});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(maxLines: lines, decoration: InputDecoration(hintText: hint)),
      ]),
    );
  }
}
