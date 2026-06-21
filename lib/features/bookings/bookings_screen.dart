import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/responsive/responsive.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../../data/models/status_ui.dart';
import '../../data/repositories/vendor_repository.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final _repo = VendorRepository();
  List<VendorBooking> _all = [];
  bool _loading = true;
  BookingStatus? _filter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final b = await _repo.bookings();
    if (!mounted) return;
    setState(() { _all = b; _loading = false; });
  }

  List<VendorBooking> get _filtered => _filter == null ? _all : _all.where((b) => b.status == _filter).toList();

  Future<void> _respond(VendorBooking b, BookingStatus s) async {
    await _repo.respondBooking(b.id, s);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${b.id} → ${StatusUi.booking(s).$1}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return ListView(
      padding: EdgeInsets.all(responsiveValue(context, mobile: 16, desktop: 28)),
      children: [
        PageHeader(title: 'Bookings', subtitle: 'Accept new requests and manage your schedule'),
        const SizedBox(height: 20),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _tab('All', null),
          _tab('Requests', BookingStatus.requested),
          _tab('Confirmed', BookingStatus.confirmed),
          _tab('In Progress', BookingStatus.inProgress),
          _tab('Completed', BookingStatus.completed),
          _tab('Cancelled', BookingStatus.cancelled),
          _tab('Disputed', BookingStatus.disputed),
        ]),
        const SizedBox(height: 16),
        if (_loading) const LoadingView() else if (_filtered.isEmpty) const EmptyView(message: 'No bookings here') else
          ..._filtered.map((b) {
            final (label, color) = StatusUi.booking(b.status);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SectionCard(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(b.id, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(width: 10),
                        StatusChip(label: label, color: color),
                        if (b.source == BookingSource.inquiry) ...[
                          const SizedBox(width: 8),
                          _inquiryTag(reference: b.inquiryRef),
                        ],
                      ]),
                      const SizedBox(height: 8),
                      Text(b.service, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(b.clientName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ])),
                    Text(cur.format(b.amount), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold, fontSize: 16)),
                  ]),
                  const SizedBox(height: 14),
                  Wrap(spacing: 20, runSpacing: 8, children: [
                    _meta(Icons.calendar_today_outlined, DateFormat('EEE, d MMM yyyy').format(b.date)),
                    _meta(Icons.location_on_outlined, b.location),
                    if (b.advancePaid > 0)
                      _meta(Icons.account_balance_wallet_outlined, 'Advance ${cur.format(b.advancePaid)} · Balance ${cur.format(b.balanceDue)}'),
                  ]),
                  if (b.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(8)),
                      child: Text(b.notes, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                    ),
                  ],
                  if (b.status == BookingStatus.requested) ...[
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: ElevatedButton.icon(onPressed: () => _respond(b, BookingStatus.confirmed), icon: const Icon(Icons.check, size: 18), label: const Text('Accept'))),
                      const SizedBox(width: 12),
                      Expanded(child: OutlinedButton.icon(onPressed: () => _respond(b, BookingStatus.cancelled), style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger), icon: const Icon(Icons.close, size: 18), label: const Text('Decline'))),
                    ]),
                  ] else if (b.status == BookingStatus.confirmed) ...[
                    const SizedBox(height: 14),
                    Row(children: [
                      OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline, size: 16), label: const Text('Message client')),
                      const SizedBox(width: 10),
                      OutlinedButton(onPressed: () => _respond(b, BookingStatus.inProgress), child: const Text('Mark in progress')),
                    ]),
                  ],
                ]),
              ),
            );
          }),
      ],
    );
  }

  Widget _meta(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ]);

  Widget _inquiryTag({String? reference}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.forum_outlined, size: 11, color: AppColors.info),
          const SizedBox(width: 3),
          Text(reference == null ? 'Inquiry' : 'Inquiry · $reference',
              style: const TextStyle(color: AppColors.info, fontSize: 10.5, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _tab(String label, BookingStatus? status) {
    final selected = _filter == status;
    final count = status == null ? _all.length : _all.where((b) => b.status == status).length;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _filter = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold.withValues(alpha: 0.14) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.gold : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(color: selected ? AppColors.gold : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12.5)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10)),
            child: Text('$count', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}
