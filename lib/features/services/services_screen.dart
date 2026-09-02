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
                    Text(p.description, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(children: [
                      Text(cur.format(p.price), style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold, fontSize: 17)),
                      Text(' / ${p.unit}', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      const Spacer(),
                      StatusChip(label: '${p.bookingsCount} booked', color: AppColors.info),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      OutlinedButton.icon(onPressed: () => _openEditor(p), icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Edit')),
                      const SizedBox(width: 10),
                      if (!p.active) StatusChip(label: 'Hidden', color: AppColors.textMuted),
                    ]),
                  ]),
                ),
            ],
          ),
      ],
    );
  }

  void _openEditor([ServicePackage? existing]) {
    final title = TextEditingController(text: existing?.title ?? '');
    final category = TextEditingController(text: existing?.category ?? VendorSession.config.serviceCategoryHint);
    final price = TextEditingController(text: existing != null ? existing.price.toStringAsFixed(0) : '');
    final unit = TextEditingController(text: existing?.unit ?? VendorSession.config.serviceUnitHint);
    final desc = TextEditingController(text: existing?.description ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: BoxConstraints(maxWidth: Responsive.isMobile(context) ? double.infinity : 520),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _PackageForm(
        existing: existing,
        title: title,
        category: category,
        price: price,
        unit: unit,
        desc: desc,
        onSave: (pkg) async {
          Navigator.pop(ctx);
          if (existing != null) {
            await _repo.updateService(pkg);
          } else {
            await _repo.createService(pkg);
          }
          await _load();
        },
        onDelete: existing != null
            ? (id) async {
                await _repo.deleteService(id);
                await _load();
              }
            : null,
      ),
    );
  }
}

class _PackageForm extends StatefulWidget {
  final ServicePackage? existing;
  final TextEditingController title, category, price, unit, desc;
  final Future<void> Function(ServicePackage) onSave;
  final Future<void> Function(String id)? onDelete;

  const _PackageForm({
    required this.existing,
    required this.title,
    required this.category,
    required this.price,
    required this.unit,
    required this.desc,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_PackageForm> createState() => _PackageFormState();
}

class _PackageFormState extends State<_PackageForm> {
  bool _saving = false;
  bool _deleting = false;
  String _error = '';

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete package?'),
        content: Text('This will permanently remove "${widget.title.text}" and cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() { _deleting = true; _error = ''; });
    try {
      await widget.onDelete!(widget.existing!.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('ApiException', '').replaceAll(RegExp(r'^\(\d+\):\s*'), '');
        _deleting = false;
      });
    }
  }

  Future<void> _submit() async {
    final titleVal = widget.title.text.trim();
    final priceVal = double.tryParse(widget.price.text.trim()) ?? -1;

    if (titleVal.isEmpty) { setState(() => _error = 'Title is required'); return; }
    if (priceVal < 0) { setState(() => _error = 'Enter a valid price'); return; }

    setState(() { _saving = true; _error = ''; });
    try {
      final pkg = ServicePackage(
        id: widget.existing?.id ?? '',
        title: titleVal,
        category: widget.category.text.trim(),
        price: priceVal,
        unit: widget.unit.text.trim(),
        description: widget.desc.text.trim(),
        active: widget.existing?.active ?? true,
        bookingsCount: widget.existing?.bookingsCount ?? 0,
      );
      await widget.onSave(pkg);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('ApiException', '').replaceAll(RegExp(r'^\(\d+\):\s*'), '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.viewInsetsOf(context).bottom + 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.existing != null ? 'Edit package' : 'New package',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 20),
        if (_error.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Text(_error, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ],
        _Field(label: 'Title', hint: 'e.g. Fashion Editorial — Half Day', controller: widget.title),
        _Field(label: 'Category', hint: VendorSession.config.serviceCategoryHint, controller: widget.category),
        Row(children: [
          Expanded(child: _Field(label: 'Price (₹)', hint: '45000', controller: widget.price, keyboardType: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(child: _Field(label: 'Unit', hint: VendorSession.config.serviceUnitHint, controller: widget.unit)),
        ]),
        _Field(label: 'Description', hint: 'What is included…', controller: widget.desc, lines: 3),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_saving || _deleting) ? null : _submit,
            child: _saving
                ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onAccent(AppColors.gold)))
                : Text(widget.existing != null ? 'Update Package' : 'Save Package'),
          ),
        ),
        if (widget.existing != null && widget.onDelete != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (_saving || _deleting) ? null : _delete,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
              ),
              icon: _deleting
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                  : const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete Package'),
            ),
          ),
        ],
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  final String label, hint;
  final int lines;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    this.lines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: lines,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hint),
        ),
      ]),
    );
  }
}
