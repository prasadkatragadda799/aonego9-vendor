import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/common.dart';
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

  @override
  void initState() {
    super.initState();
    _repo.reviews().then((r) {
      if (mounted) setState(() { _all = r; _loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    final avg = _all.isEmpty ? 0.0 : _all.map((r) => r.stars).reduce((a, b) => a + b) / _all.length;

    return ListView(
      padding: EdgeInsets.all(responsiveValue(context, mobile: 16, desktop: 28)),
      children: [
        PageHeader(title: 'Reviews', subtitle: 'What your clients are saying'),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: StatCard(label: 'Average Rating', value: '${avg.toStringAsFixed(1)} ★', icon: Icons.star, color: AppColors.gold)),
          const SizedBox(width: 16),
          Expanded(child: StatCard(label: 'Total Reviews', value: '${_all.length}', icon: Icons.reviews_outlined, color: AppColors.info)),
          if (!Responsive.isMobile(context)) ...[
            const SizedBox(width: 16),
            Expanded(child: StatCard(label: 'Response Rate', value: '92%', icon: Icons.reply_outlined, color: AppColors.success)),
          ],
        ]),
        const SizedBox(height: 24),
        ..._all.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SectionCard(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    InitialsAvatar(name: r.client, size: 38),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.client, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(DateFormat('d MMM yyyy').format(r.date), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ])),
                    Row(children: List.generate(5, (i) => Icon(i < r.stars ? Icons.star : Icons.star_border, size: 16, color: AppColors.gold))),
                  ]),
                  const SizedBox(height: 12),
                  Text(r.text, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
                  if (r.reply != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: AppColors.gold.withValues(alpha: 0.6), width: 3))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Your reply', style: TextStyle(color: AppColors.gold, fontSize: 11.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(r.reply!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                      ]),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.reply, size: 16), label: const Text('Reply')),
                  ],
                ]),
              ),
            )),
      ],
    );
  }
}
