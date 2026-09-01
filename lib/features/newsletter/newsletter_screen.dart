import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/common.dart';
import '../../data/api/api_client.dart';

/// Read-only digest for vendors — same newsletter the user app sees.
class VendorNewsletterScreen extends StatefulWidget {
  const VendorNewsletterScreen({super.key});
  @override
  State<VendorNewsletterScreen> createState() => _VendorNewsletterScreenState();
}

class _VendorNewsletterScreenState extends State<VendorNewsletterScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _issues = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiClient.get('/browse/newsletters', auth: false);
      if (!mounted) return;
      setState(() {
        _issues = data is List ? data.cast<Map<String, dynamic>>() : const [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _issues = const []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    return ListView(
      padding: EdgeInsets.all(responsiveValue(context, mobile: 16, desktop: 28)),
      children: [
        const PageHeader(
          title: 'Newsletter',
          subtitle: 'What’s happening and trends from the AOneGo9 desk.',
        ),
        const SizedBox(height: 20),
        if (_issues.isEmpty)
          const EmptyView(message: 'No issues published yet', icon: Icons.auto_stories_outlined)
        else
          for (final n in _issues)
            SectionCard(
              title: n['title']?.toString() ?? '',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n['excerpt']?.toString() ?? '', style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
                const SizedBox(height: 8),
                Text(n['body']?.toString() ?? '', style: const TextStyle(fontSize: 13.5, height: 1.6)),
                const SizedBox(height: 8),
                Text(
                  '${n['author'] ?? ''} · ${n['city'] ?? ''} · ${n['date'] ?? ''}',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ]),
            ),
      ],
    );
  }
}
