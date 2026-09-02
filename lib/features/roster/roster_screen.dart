import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive.dart';
import '../../core/category/vendor_category.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/responsive_table.dart';
import '../../data/models/models.dart';
import '../../data/repositories/vendor_repository.dart';

class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key});
  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  final _repo = VendorRepository();
  List<TalentMember> _all = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _repo.roster();
    if (!mounted) return;
    setState(() { _all = r; _loading = false; });
  }

  List<TalentMember> get _filtered => _all.where((m) =>
      _query.isEmpty || m.name.toLowerCase().contains(_query.toLowerCase()) || m.role.toLowerCase().contains(_query.toLowerCase())).toList();

  Future<void> _toggle(TalentMember m, bool v) async {
    await _repo.toggleAvailability(m.id, v);
    await _load();
  }

  void _openAddForm() {
    final name = TextEditingController();
    final role = TextEditingController();
    final city = TextEditingController();
    final rate = TextEditingController();
    final cfg = VendorSession.config;
    bool saving = false;
    String error = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: BoxConstraints(maxWidth: Responsive.isMobile(context) ? double.infinity : 520),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) {
        Future<void> submit() async {
          if (name.text.trim().isEmpty) { setModal(() => error = 'Name is required'); return; }
          final dayRate = double.tryParse(rate.text.trim()) ?? 0;
          setModal(() { saving = true; error = ''; });
          try {
            await _repo.addTalent(TalentMember(
              id: '',
              name: name.text.trim(),
              role: role.text.trim().isEmpty ? cfg.rosterRoleHeader : role.text.trim(),
              city: city.text.trim(),
              dayRate: dayRate,
              rating: 0,
              available: true,
              shoots: 0,
            ));
            if (ctx.mounted) Navigator.pop(ctx);
            await _load();
          } catch (e) {
            setModal(() {
              error = e.toString().replaceFirst('ApiException', '').replaceAll(RegExp(r'^\(\d+\):\s*'), '');
              saving = false;
            });
          }
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.viewInsetsOf(ctx).bottom + 28),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Add ${cfg.rosterNameHeader}', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 20),
            if (error.isNotEmpty) Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
              child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
            _RosterField(label: 'Full name', hint: 'e.g. Priya Sharma', controller: name),
            _RosterField(label: cfg.rosterRoleHeader, hint: cfg.rosterRoleHeader, controller: role),
            Row(children: [
              Expanded(child: _RosterField(label: 'City', hint: 'Mumbai', controller: city)),
              const SizedBox(width: 12),
              Expanded(child: _RosterField(label: cfg.rosterRateHeader, hint: '25000', controller: rate, numeric: true)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : submit,
                child: saving
                    ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onAccent(AppColors.gold)))
                    : const Text('Add to roster'),
              ),
            ),
          ]),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final cfg = VendorSession.config;
    return ListView(
      padding: EdgeInsets.all(responsiveValue(context, mobile: 16, desktop: 28)),
      children: [
        PageHeader(
          title: cfg.rosterLabel,
          subtitle: cfg.rosterSubtitle,
          actions: [ElevatedButton.icon(onPressed: _openAddForm, icon: const Icon(Icons.person_add_alt, size: 18), label: Text(cfg.rosterAddLabel))],
        ),
        const SizedBox(height: 20),
        SectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Padding(padding: const EdgeInsets.only(bottom: 8), child: SearchField(hint: 'Search ${cfg.rosterLabel.toLowerCase()}…', onChanged: (v) => setState(() => _query = v))),
            if (_loading) const LoadingView() else if (_filtered.isEmpty) const EmptyView() else
              ResponsiveTable(
                columns: [
                  TableColumn(cfg.rosterNameHeader, flex: 3),
                  TableColumn(cfg.rosterRoleHeader, flex: 2),
                  const TableColumn('City', flex: 2),
                  TableColumn(cfg.rosterRateHeader, flex: 2, numeric: true),
                  const TableColumn('Rating', flex: 1, numeric: true),
                  TableColumn(cfg.rosterCountHeader, flex: 1, numeric: true),
                  const TableColumn('Available', flex: 2),
                ],
                rowCount: _filtered.length,
                cellsBuilder: (i) {
                  final m = _filtered[i];
                  return [
                    Row(children: [
                      InitialsAvatar(name: m.name, size: 34),
                      const SizedBox(width: 10),
                      Expanded(child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5), overflow: TextOverflow.ellipsis)),
                    ]),
                    tcell(m.role),
                    tcell(m.city),
                    tcell(cur.format(m.dayRate), numeric: true, weight: FontWeight.w600),
                    tcell('${m.rating}', numeric: true),
                    tcell('${m.shoots}', numeric: true),
                    Switch(value: m.available, activeColor: AppColors.gold, onChanged: (v) => _toggle(m, v)),
                  ];
                },
              ),
          ]),
        ),
      ],
    );
  }
}

class _RosterField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final bool numeric;
  const _RosterField({required this.label, required this.hint, required this.controller, this.numeric = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(hintText: hint),
      ),
    ]),
  );
}
