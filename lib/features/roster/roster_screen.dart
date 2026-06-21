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
          actions: [ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.person_add_alt, size: 18), label: Text(cfg.rosterAddLabel))],
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
