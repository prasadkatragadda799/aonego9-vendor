import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/category/vendor_category.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/responsive_table.dart';
import '../../data/api/api_errors.dart';
import '../../data/models/models.dart';
import '../../data/repositories/vendor_repository.dart';

class RosterScreen extends StatefulWidget {
  final String initialQuery;
  const RosterScreen({super.key, this.initialQuery = ''});
  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  final _repo = VendorRepository();
  List<TalentMember> _all = [];
  bool _loading = true;
  String? _error;
  late String _query = widget.initialQuery;
  bool _availableOnly = false;
  final Set<String> _toggling = {};

  static final _cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RosterScreen old) {
    super.didUpdateWidget(old);
    if (old.initialQuery != widget.initialQuery) setState(() => _query = widget.initialQuery);
  }

  Future<void> _load() async {
    setState(() {
      _loading = _all.isEmpty;
      _error = null;
    });
    try {
      final r = await _repo.roster();
      if (!mounted) return;
      setState(() {
        _all = r..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = apiErrorMessage(e, fallback: 'Could not load your roster.');
        });
      }
    }
  }

  List<TalentMember> get _filtered {
    final q = _query.trim().toLowerCase();
    return _all.where((m) {
      if (_availableOnly && !m.available) return false;
      return q.isEmpty || '${m.name} ${m.role} ${m.city}'.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _toggle(TalentMember m, bool v) async {
    final msg = Toast.of(context);
    final i = _all.indexWhere((x) => x.id == m.id);
    if (i == -1) return;
    setState(() {
      _all[i] = m.copyWith(available: v);
      _toggling.add(m.id);
    });
    try {
      await _repo.toggleAvailability(m.id);
    } catch (e) {
      if (mounted) setState(() => _all[i] = m);
      Toast.error(msg, apiErrorMessage(e, fallback: 'Could not update availability.'));
    } finally {
      if (mounted) setState(() => _toggling.remove(m.id));
    }
  }

  Future<void> _openForm([TalentMember? existing]) async {
    final result = await showAdaptiveSheet<String>(context, builder: (_) => _MemberForm(existing: existing, repo: _repo));
    if (result == null || !mounted) return;
    Toast.ok(Toast.of(context), result);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = VendorSession.config;
    if (_error != null && _all.isEmpty) return ErrorView(message: _error!, onRetry: _load);
    final list = _filtered;
    final available = _all.where((m) => m.available).length;

    return PageBody(
      onRefresh: _load,
      children: [
        PageHeader(
          title: cfg.rosterLabel,
          subtitle: cfg.rosterSubtitle,
          actions: [
            ElevatedButton.icon(onPressed: () => _openForm(), icon: const Icon(Icons.person_add_alt, size: 18), label: Text(cfg.rosterAddLabel)),
          ],
        ),
        const SizedBox(height: 18),
        if (!_loading && _all.isNotEmpty) ...[
          ResponsiveGrid(minTileWidth: 180, children: [
            StatCard(label: 'On roster', value: '${_all.length}', icon: cfg.rosterIcon, color: AppColors.gold),
            StatCard(label: 'Available now', value: '$available', icon: Icons.event_available_outlined, color: AppColors.success),
            StatCard(
              label: cfg.rosterCountHeader,
              value: '${_all.fold<int>(0, (s, m) => s + m.shoots)}',
              icon: Icons.work_outline,
              color: AppColors.info,
            ),
          ]),
          const SizedBox(height: 16),
        ],
        SectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Wrap(spacing: 12, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SearchField(
                  key: ValueKey('rq-${widget.initialQuery}'),
                  initial: _query,
                  hint: 'Search ${cfg.rosterLabel.toLowerCase()} by name, role or city…',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              FilterPill(
                label: 'Available only',
                selected: _availableOnly,
                onTap: () => setState(() => _availableOnly = !_availableOnly),
              ),
            ]),
            const SizedBox(height: 8),
            if (_loading)
              const LoadingView()
            else if (list.isEmpty)
              EmptyView(
                icon: cfg.rosterIcon,
                message: _all.isEmpty ? 'Your ${cfg.rosterLabel.toLowerCase()} is empty' : 'No one matches',
                detail: _all.isEmpty ? 'Add the people and resources clients can book through you.' : 'Try a different search.',
                action: _all.isEmpty
                    ? ElevatedButton.icon(onPressed: () => _openForm(), icon: const Icon(Icons.add, size: 18), label: Text(cfg.rosterAddLabel))
                    : null,
              )
            else
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
                rowCount: list.length,
                onRowTap: (i) => _openForm(list[i]),
                mobileCardBuilder: (i) => _mobileCard(list[i]),
                cellsBuilder: (i) {
                  final m = list[i];
                  return [
                    Row(children: [
                      InitialsAvatar(name: m.name, size: 34),
                      const SizedBox(width: 10),
                      Expanded(child: Text(m.name, style: AppType.body(size: 13.5, weight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                    ]),
                    tcell(m.role.isEmpty ? '—' : m.role),
                    tcell(m.city.isEmpty ? '—' : m.city),
                    tcell(m.dayRate > 0 ? _cur.format(m.dayRate) : '—', numeric: true, weight: FontWeight.w600),
                    tcell(m.rating > 0 ? m.rating.toStringAsFixed(1) : '—', numeric: true),
                    tcell('${m.shoots}', numeric: true),
                    Switch(value: m.available, onChanged: _toggling.contains(m.id) ? null : (v) => _toggle(m, v)),
                  ];
                },
              ),
          ]),
        ),
      ],
    );
  }

  Widget _mobileCard(TalentMember m) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        InitialsAvatar(name: m.name, size: 42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.name, style: AppType.body(size: 14, weight: FontWeight.w700), overflow: TextOverflow.ellipsis),
            Text([if (m.role.isNotEmpty) m.role, if (m.city.isNotEmpty) m.city].join(' · '),
                style: AppType.body(size: 12, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              [if (m.dayRate > 0) _cur.format(m.dayRate), if (m.rating > 0) '${m.rating.toStringAsFixed(1)} ★', '${m.shoots} ${VendorSession.config.rosterCountHeader.toLowerCase()}'].join(' · '),
              style: AppType.mono(size: 11.5, color: AppColors.textSecondary),
            ),
          ]),
        ),
        Switch(value: m.available, onChanged: _toggling.contains(m.id) ? null : (v) => _toggle(m, v)),
      ]),
    );
  }
}

class _MemberForm extends StatefulWidget {
  final TalentMember? existing;
  final VendorRepository repo;
  const _MemberForm({required this.existing, required this.repo});

  @override
  State<_MemberForm> createState() => _MemberFormState();
}

class _MemberFormState extends State<_MemberForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _role = TextEditingController(text: widget.existing?.role ?? '');
  late final _city = TextEditingController(text: widget.existing?.city ?? VendorSession.vendorCity);
  late final _rate = TextEditingController(
      text: widget.existing != null && widget.existing!.dayRate > 0 ? widget.existing!.dayRate.toStringAsFixed(0) : '');
  bool _saving = false;
  bool _deleting = false;
  String _error = '';

  @override
  void dispose() {
    for (final c in [_name, _role, _city, _rate]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cfg = VendorSession.config;
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      final e = widget.existing;
      final member = TalentMember(
        id: e?.id ?? '',
        name: _name.text.trim(),
        role: _role.text.trim().isEmpty ? cfg.rosterRoleHeader : _role.text.trim(),
        city: _city.text.trim(),
        dayRate: double.tryParse(_rate.text.trim()) ?? 0,
        rating: e?.rating ?? 0,
        available: e?.available ?? true,
        shoots: e?.shoots ?? 0,
      );
      if (e == null) {
        await widget.repo.addTalent(member);
      } else {
        await widget.repo.updateTalent(member);
      }
      if (mounted) Navigator.pop(context, e == null ? '${member.name} added' : '${member.name} updated');
    } catch (err) {
      if (mounted) {
        setState(() {
          _error = apiErrorMessage(err, fallback: 'Could not save.');
          _saving = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    final e = widget.existing!;
    final ok = await confirmAction(
      context,
      title: 'Remove ${e.name}?',
      message: '${e.name} will be removed from your ${VendorSession.config.rosterLabel.toLowerCase()}. Past bookings are kept.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() {
      _deleting = true;
      _error = '';
    });
    try {
      await widget.repo.deleteTalent(e.id);
      if (mounted) Navigator.pop(context, '${e.name} removed');
    } catch (err) {
      if (mounted) {
        setState(() {
          _error = apiErrorMessage(err, fallback: 'Could not remove.');
          _deleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = VendorSession.config;
    final busy = _saving || _deleting;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.existing == null ? cfg.rosterAddLabel : 'Edit ${widget.existing!.name}', style: AppType.display(size: 20)),
          const SizedBox(height: 18),
          if (_error.isNotEmpty) ...[
            InlineNotice(message: _error, icon: Icons.error_outline, color: AppColors.danger),
            const SizedBox(height: 14),
          ],
          LabeledField(
            label: cfg.rosterNameHeader == 'Name' ? 'Full name' : cfg.rosterNameHeader,
            child: TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'e.g. Priya Sharma'),
              validator: (v) => (v ?? '').trim().length < 2 ? 'Enter a name' : null,
            ),
          ),
          LabeledField(
            label: cfg.rosterRoleHeader,
            child: TextFormField(
              controller: _role,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(hintText: cfg.rosterRoleHeader),
            ),
          ),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: LabeledField(
                label: 'City',
                child: TextFormField(controller: _city, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(hintText: 'Mumbai')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LabeledField(
                label: '${cfg.rosterRateHeader} (₹)',
                child: TextFormField(
                  controller: _rate,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                  decoration: const InputDecoration(hintText: '25000', prefixText: '₹ '),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: busy ? null : _save,
              child: _saving ? const ButtonSpinner() : Text(widget.existing == null ? 'Add to roster' : 'Save changes'),
            ),
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed: busy ? null : _delete,
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: BorderSide(color: AppColors.danger.withValues(alpha: .4))),
                icon: _deleting ? ButtonSpinner(color: AppColors.danger) : const Icon(Icons.person_remove_outlined, size: 18),
                label: const Text('Remove from roster'),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
