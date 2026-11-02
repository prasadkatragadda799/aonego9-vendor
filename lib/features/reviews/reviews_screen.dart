import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/common.dart';
import '../../data/api/api_errors.dart';
import '../../data/models/models.dart';
import '../../data/repositories/vendor_repository.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});
  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final _repo = VendorRepository();
  List<VendorReview> _all = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all'; // all | unreplied | 5..1

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
      final r = await _repo.reviews();
      if (mounted) {
        setState(() {
          _all = r;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = apiErrorMessage(e, fallback: 'Could not load reviews.');
        });
      }
    }
  }

  List<VendorReview> get _visible => switch (_filter) {
        'unreplied' => _all.where((r) => !r.hasReply).toList(),
        'all' => _all,
        _ => _all.where((r) => '${r.stars}' == _filter).toList(),
      };

  Future<void> _reply(VendorReview r) async {
    final text = await showAdaptiveSheet<String>(context, builder: (_) => _ReplyForm(review: r));
    if (text == null || !mounted) return;
    final m = Toast.of(context);
    try {
      await _repo.replyReview(r.id, text);
      final i = _all.indexWhere((x) => x.id == r.id);
      if (i != -1 && mounted) setState(() => _all[i] = r.withReply(text));
      Toast.ok(m, 'Reply published on your profile');
    } catch (e) {
      Toast.error(m, apiErrorMessage(e, fallback: 'Could not post your reply.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _all.isEmpty) return ErrorView(message: _error!, onRetry: _load);
    if (_loading) return const LoadingView();
    final avg = _all.isEmpty ? 0.0 : _all.map((r) => r.stars).reduce((a, b) => a + b) / _all.length;
    final replied = _all.where((r) => r.hasReply).length;
    final unreplied = _all.length - replied;
    final list = _visible;

    return PageBody(
      onRefresh: _load,
      children: [
        const PageHeader(title: 'Reviews', subtitle: 'What clients say about you — replies show publicly on your profile'),
        const SizedBox(height: 20),
        ResponsiveGrid(minTileWidth: 200, maxColumns: 3, children: [
          StatCard(label: 'Average rating', value: _all.isEmpty ? '—' : '${avg.toStringAsFixed(1)} ★', icon: Icons.star, color: AppColors.gold),
          StatCard(label: 'Total reviews', value: '${_all.length}', icon: Icons.reviews_outlined, color: AppColors.info),
          StatCard(
            label: 'Response rate',
            value: _all.isEmpty ? '—' : '${((replied / _all.length) * 100).round()}%',
            icon: Icons.reply_outlined,
            color: AppColors.success,
          ),
        ]),
        if (_all.isNotEmpty) ...[
          const SizedBox(height: 18),
          SectionCard(title: 'Rating breakdown', child: _breakdown()),
          const SizedBox(height: 18),
          PillBar(children: [
            FilterPill(label: 'All', count: _all.length, selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
            FilterPill(
              label: 'Awaiting reply',
              count: unreplied,
              selected: _filter == 'unreplied',
              color: AppColors.warning,
              onTap: () => setState(() => _filter = 'unreplied'),
            ),
            for (final s in ['5', '4', '3', '2', '1'])
              FilterPill(label: '$s ★', count: _all.where((r) => '${r.stars}' == s).length, selected: _filter == s, onTap: () => setState(() => _filter = s)),
          ]),
        ],
        const SizedBox(height: 16),
        if (list.isEmpty)
          EmptyView(
            icon: Icons.star_outline,
            message: _all.isEmpty ? 'No reviews yet' : 'Nothing in this filter',
            detail: _all.isEmpty ? 'Clients can review you after a completed booking. Great work gets you your first ones.' : null,
          )
        else
          for (final r in list) Padding(padding: const EdgeInsets.only(bottom: 14), child: _card(r)),
      ],
    );
  }

  Widget _breakdown() {
    return Column(children: [
      for (final s in [5, 4, 3, 2, 1])
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            SizedBox(width: 34, child: Text('$s ★', style: AppType.mono(size: 12, color: AppColors.textSecondary))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _all.isEmpty ? 0 : _all.where((r) => r.stars == s).length / _all.length,
                  minHeight: 8,
                ),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text('${_all.where((r) => r.stars == s).length}',
                  textAlign: TextAlign.right, style: AppType.mono(size: 12, color: AppColors.textSecondary)),
            ),
          ]),
        ),
    ]);
  }

  Widget _card(VendorReview r) {
    return SectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          InitialsAvatar(name: r.client, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.client, style: AppType.body(size: 14, weight: FontWeight.w600)),
              Text(DateFormat('d MMM yyyy').format(r.date), style: AppType.mono(size: 11.5)),
            ]),
          ),
          Semantics(
            label: '${r.stars} out of 5 stars',
            child: Row(children: List.generate(5, (i) => Icon(i < r.stars ? Icons.star : Icons.star_border, size: 16, color: AppColors.gold))),
          ),
        ]),
        const SizedBox(height: 12),
        Text(r.text.isEmpty ? 'No written comment.' : r.text,
            style: AppType.body(size: 13.5, color: r.text.isEmpty ? AppColors.textMuted : AppColors.textSecondary, height: 1.55)),
        const SizedBox(height: 12),
        if (r.hasReply)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: AppColors.gold.withValues(alpha: 0.6), width: 3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('YOUR REPLY', style: AppType.eyebrow(color: AppColors.gold, size: 9.5)),
                const Spacer(),
                InkWell(
                  onTap: () => _reply(r),
                  child: Text('Edit', style: AppType.body(size: 12, weight: FontWeight.w600, color: AppColors.gold)),
                ),
              ]),
              const SizedBox(height: 6),
              Text(r.reply!, style: AppType.body(size: 13, color: AppColors.textSecondary, height: 1.45)),
            ]),
          )
        else
          OutlinedButton.icon(onPressed: () => _reply(r), icon: const Icon(Icons.reply, size: 16), label: const Text('Reply publicly')),
      ]),
    );
  }
}

class _ReplyForm extends StatefulWidget {
  final VendorReview review;
  const _ReplyForm({required this.review});
  @override
  State<_ReplyForm> createState() => _ReplyFormState();
}

class _ReplyFormState extends State<_ReplyForm> {
  late final _c = TextEditingController(text: widget.review.reply ?? '');
  static const _max = 600;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(r.hasReply ? 'Edit your reply' : 'Reply to ${r.client}', style: AppType.display(size: 20)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(8)),
          child: Text('“${r.text}”', maxLines: 4, overflow: TextOverflow.ellipsis,
              style: AppType.body(size: 12.5, color: AppColors.textSecondary, height: 1.45)),
        ),
        const SizedBox(height: 14),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _c,
          builder: (_, v, __) => TextField(
            controller: _c,
            autofocus: true,
            minLines: 4,
            maxLines: 8,
            maxLength: _max,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Thank the client and address any feedback — this is public.'),
          ),
        ),
        const SizedBox(height: 6),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _c,
          builder: (_, v, __) => SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: v.text.trim().length < 2 ? null : () => Navigator.pop(context, v.text.trim()),
              child: const Text('Publish reply'),
            ),
          ),
        ),
      ]),
    );
  }
}
