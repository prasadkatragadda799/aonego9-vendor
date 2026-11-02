import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/common.dart';
import '../../data/api/api_client.dart';
import '../../data/api/api_errors.dart';
import '../../data/repositories/vendor_repository.dart';

/// The AOneGo9 digest — the same newsletter the user app publishes — plus a
/// way for the vendor to pitch their own story to the desk.
class VendorNewsletterScreen extends StatefulWidget {
  const VendorNewsletterScreen({super.key});
  @override
  State<VendorNewsletterScreen> createState() => _VendorNewsletterScreenState();
}

class _VendorNewsletterScreenState extends State<VendorNewsletterScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _issues = [];
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _issues.isEmpty;
      _error = null;
    });
    try {
      final data = ApiClient.asList(await ApiClient.get('/browse/newsletters', auth: false));
      if (!mounted) return;
      setState(() {
        _issues = data;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = apiErrorMessage(e, fallback: 'Could not load the newsletter.');
        });
      }
    }
  }

  Future<void> _pitch() async {
    final c = TextEditingController();
    final text = await showAdaptiveSheet<String>(
      context,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Pitch a story', style: AppType.display(size: 20)),
          const SizedBox(height: 6),
          Text('A launch, a campaign you shot, an award, a trend you are seeing — the desk features vendor stories in the digest.',
              style: AppType.body(size: 12.5, color: AppColors.textSecondary, height: 1.45)),
          const SizedBox(height: 14),
          TextField(
            controller: c,
            autofocus: true,
            minLines: 5,
            maxLines: 10,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Headline, what happened, and links to photos or press'),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: c,
            builder: (_, v, __) => SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: v.text.trim().length < 20 ? null : () => Navigator.pop(ctx, v.text.trim()),
                child: const Text('Send pitch'),
              ),
            ),
          ),
        ]),
      ),
    );
    c.dispose();
    if (text == null || !mounted) return;
    final m = Toast.of(context);
    try {
      await VendorRepository().sendToDesk('newsletter_pitch', message: text);
      Toast.ok(m, 'Pitch sent to the newsletter desk');
    } catch (e) {
      Toast.error(m, apiErrorMessage(e, fallback: 'Could not send your pitch.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _issues.isEmpty) return ErrorView(message: _error!, onRetry: _load);
    if (_loading) return const LoadingView();
    return PageBody(
      onRefresh: _load,
      maxWidth: 900,
      children: [
        PageHeader(
          eyebrow: 'The AOneGo9 digest',
          title: 'Newsletter',
          subtitle: 'What is happening and trending across the industry, from the AOneGo9 desk',
          actions: [OutlinedButton.icon(onPressed: _pitch, icon: const Icon(Icons.edit_note, size: 18), label: const Text('Pitch a story'))],
        ),
        const SizedBox(height: 20),
        if (_issues.isEmpty)
          const EmptyView(
            message: 'No issues published yet',
            icon: Icons.auto_stories_outlined,
            detail: 'The first issue of the digest will appear here.',
          )
        else
          for (var i = 0; i < _issues.length; i++) Padding(padding: const EdgeInsets.only(bottom: 16), child: _issue(i, _issues[i])),
      ],
    );
  }

  Widget _issue(int i, Map<String, dynamic> n) {
    String s(String k) => '${n[k] ?? ''}'.trim();
    final body = s('body');
    final open = _expanded.contains(i);
    final date = DateTime.tryParse(s('date').isEmpty ? s('created_at') : s('date'));
    final meta = [
      if (s('author').isNotEmpty) s('author'),
      if (s('city').isNotEmpty) s('city'),
      if (date != null) DateFormat('d MMM yyyy').format(date) else if (s('date').isNotEmpty) s('date'),
    ].join(' · ');
    final image = s('image_url').isNotEmpty ? s('image_url') : s('cover_url');

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (image.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: AspectRatio(
              aspectRatio: 16 / 7,
              child: Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceAlt)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (s('category').isNotEmpty) ...[
              Text(s('category').toUpperCase(), style: AppType.eyebrow(color: AppColors.gold, size: 10)),
              const SizedBox(height: 8),
            ],
            Text(s('title').isEmpty ? 'Untitled' : s('title'), style: AppType.display(size: 19, weight: FontWeight.w600)),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(meta, style: AppType.mono(size: 11.5)),
            ],
            if (s('excerpt').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(s('excerpt'), style: AppType.body(size: 14, color: AppColors.textSecondary, height: 1.55)),
            ],
            if (body.isNotEmpty) ...[
              const SizedBox(height: 10),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: Text(body, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppType.body(size: 13.5, height: 1.65)),
                secondChild: Text(body, style: AppType.body(size: 13.5, height: 1.65)),
              ),
              TextButton(
                onPressed: () => setState(() => open ? _expanded.remove(i) : _expanded.add(i)),
                child: Text(open ? 'Show less' : 'Read more'),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}
