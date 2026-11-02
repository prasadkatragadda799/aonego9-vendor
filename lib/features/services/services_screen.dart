import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/category/vendor_category.dart';
import '../../core/widgets/common.dart';
import '../../data/api/api_errors.dart';
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
  String? _error;
  final Set<String> _toggling = {};

  static final _cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _all.isEmpty;
      _error = null;
    });
    try {
      final s = await _repo.services();
      if (!mounted) return;
      setState(() {
        _all = s;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = apiErrorMessage(e, fallback: 'Could not load your packages.');
        });
      }
    }
  }

  /// Optimistic: the switch moves immediately and rolls back on failure.
  Future<void> _toggle(ServicePackage p, bool v) async {
    final m = Toast.of(context);
    final i = _all.indexWhere((x) => x.id == p.id);
    if (i == -1) return;
    setState(() {
      _all[i] = p.copyWith(active: v);
      _toggling.add(p.id);
    });
    try {
      await _repo.toggleService(p.id);
      Toast.ok(m, v ? '“${p.title}” is live on your profile' : '“${p.title}” is hidden from clients');
    } catch (e) {
      if (mounted) setState(() => _all[i] = p);
      Toast.error(m, apiErrorMessage(e, fallback: 'Could not update the package.'));
    } finally {
      if (mounted) setState(() => _toggling.remove(p.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = VendorSession.config;
    if (_error != null && _all.isEmpty) return ErrorView(message: _error!, onRetry: _load);
    final live = _all.where((p) => p.active).length;

    return PageBody(
      onRefresh: _load,
      children: [
        PageHeader(
          title: cfg.servicesLabel,
          subtitle: cfg.servicesSubtitle,
          actions: [
            ElevatedButton.icon(onPressed: () => _openEditor(), icon: const Icon(Icons.add, size: 18), label: const Text('Add package')),
          ],
        ),
        const SizedBox(height: 18),
        if (_all.isNotEmpty) ...[
          InlineNotice(
            icon: Icons.storefront_outlined,
            color: live == 0 ? AppColors.warning : AppColors.info,
            message: live == 0
                ? 'No package is live — clients cannot book you from the marketplace until at least one is switched on.'
                : '$live of ${_all.length} packages are live on your marketplace profile.',
          ),
          const SizedBox(height: 16),
        ],
        if (_loading)
          const LoadingView()
        else if (_all.isEmpty)
          EmptyView(
            icon: Icons.layers_outlined,
            message: 'No packages yet',
            detail: 'Packages are what clients book. Add your first one with a clear price and what is included.',
            action: ElevatedButton.icon(onPressed: () => _openEditor(), icon: const Icon(Icons.add, size: 18), label: const Text('Add your first package')),
          )
        else
          ResponsiveGrid(minTileWidth: 320, maxColumns: 3, children: [for (final p in _all) _card(p)]),
      ],
    );
  }

  Widget _card(ServicePackage p) {
    return SectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title, style: AppType.body(size: 15, weight: FontWeight.w700)),
              if (p.category.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(p.category.toUpperCase(), style: AppType.eyebrow(size: 9.5, color: AppColors.gold)),
              ],
            ]),
          ),
          Tooltip(
            message: p.active ? 'Live — tap to hide' : 'Hidden — tap to publish',
            child: Switch(value: p.active, onChanged: _toggling.contains(p.id) ? null : (v) => _toggle(p, v)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          p.description.isEmpty ? 'No description yet — tell clients what is included.' : p.description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppType.body(size: 12.5, color: p.description.isEmpty ? AppColors.textMuted : AppColors.textSecondary, height: 1.45),
        ),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_cur.format(p.price), style: AppType.mono(size: 18, weight: FontWeight.w800, color: AppColors.gold)),
          if (p.unit.isNotEmpty)
            Flexible(child: Text(' / ${p.unit}', overflow: TextOverflow.ellipsis, style: AppType.body(size: 12, color: AppColors.textMuted))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          StatusChip(label: p.active ? 'Live' : 'Hidden', color: p.active ? AppColors.success : AppColors.textMuted),
          const SizedBox(width: 8),
          Flexible(child: StatusChip(label: '${p.bookingsCount} booked', color: AppColors.info)),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => _openEditor(p),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 12)),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
          ),
        ]),
      ]),
    );
  }

  Future<void> _openEditor([ServicePackage? existing]) async {
    final saved = await showAdaptiveSheet<String>(
      context,
      builder: (ctx) => _PackageForm(existing: existing, repo: _repo),
    );
    if (saved == null || !mounted) return;
    Toast.ok(Toast.of(context), saved);
    _load();
  }
}

class _PackageForm extends StatefulWidget {
  final ServicePackage? existing;
  final VendorRepository repo;
  const _PackageForm({required this.existing, required this.repo});

  @override
  State<_PackageForm> createState() => _PackageFormState();
}

class _PackageFormState extends State<_PackageForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _category = TextEditingController(text: widget.existing?.category ?? VendorSession.config.serviceCategoryHint);
  late final _price = TextEditingController(text: widget.existing != null ? widget.existing!.price.toStringAsFixed(0) : '');
  late final _unit = TextEditingController(text: widget.existing?.unit ?? VendorSession.config.serviceUnitHint);
  late final _desc = TextEditingController(text: widget.existing?.description ?? '');
  bool _saving = false;
  bool _deleting = false;
  String _error = '';

  @override
  void dispose() {
    for (final c in [_title, _category, _price, _unit, _desc]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _delete() async {
    final ok = await confirmAction(
      context,
      title: 'Delete package?',
      message: '“${_title.text}” will be removed from your profile permanently. Existing bookings are not affected.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() {
      _deleting = true;
      _error = '';
    });
    try {
      await widget.repo.deleteService(widget.existing!.id);
      if (mounted) Navigator.pop(context, 'Package deleted');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = apiErrorMessage(e, fallback: 'Could not delete the package.');
          _deleting = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      final pkg = ServicePackage(
        id: widget.existing?.id ?? '',
        title: _title.text.trim(),
        category: _category.text.trim(),
        price: double.parse(_price.text.trim()),
        unit: _unit.text.trim(),
        description: _desc.text.trim(),
        active: widget.existing?.active ?? true,
        bookingsCount: widget.existing?.bookingsCount ?? 0,
      );
      if (widget.existing != null) {
        await widget.repo.updateService(pkg);
      } else {
        await widget.repo.createService(pkg);
      }
      if (mounted) Navigator.pop(context, widget.existing != null ? 'Package updated' : 'Package added and live');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = apiErrorMessage(e, fallback: 'Could not save the package.');
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _saving || _deleting;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.existing != null ? 'Edit package' : 'New package', style: AppType.display(size: 20)),
          const SizedBox(height: 4),
          Text('This is exactly what clients see and book on your profile.',
              style: AppType.body(size: 12.5, color: AppColors.textSecondary)),
          const SizedBox(height: 18),
          if (_error.isNotEmpty) ...[
            InlineNotice(message: _error, icon: Icons.error_outline, color: AppColors.danger),
            const SizedBox(height: 14),
          ],
          LabeledField(
            label: 'Title',
            child: TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'e.g. Fashion Editorial — Half Day'),
              validator: (v) => (v ?? '').trim().length < 3 ? 'Give the package a clear title' : null,
            ),
          ),
          LabeledField(
            label: 'Category',
            child: TextFormField(controller: _category, decoration: InputDecoration(hintText: VendorSession.config.serviceCategoryHint)),
          ),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: LabeledField(
                label: 'Price (₹)',
                child: TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                  decoration: const InputDecoration(hintText: '45000', prefixText: '₹ '),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').trim());
                    if (n == null) return 'Enter a price';
                    if (n < 0) return 'Price cannot be negative';
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LabeledField(
                label: 'Priced per',
                child: TextFormField(controller: _unit, decoration: InputDecoration(hintText: VendorSession.config.serviceUnitHint)),
              ),
            ),
          ]),
          LabeledField(
            label: 'What is included',
            hint: 'Write each inclusion as a sentence — clients see them as a checklist.',
            child: TextFormField(
              controller: _desc,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: '4 hours on set. 20 retouched images. Hair & makeup artist.'),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: busy ? null : _submit,
              child: _saving ? const ButtonSpinner() : Text(widget.existing != null ? 'Save changes' : 'Add package'),
            ),
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed: busy ? null : _delete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
                ),
                icon: _deleting ? ButtonSpinner(color: AppColors.danger) : const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete package'),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
