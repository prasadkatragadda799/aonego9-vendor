import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/responsive/responsive.dart';
import '../../core/utils/launch_util.dart';
import '../../core/widgets/common.dart';
import '../../data/api/api_errors.dart';
import '../../data/models/models.dart';
import '../../data/models/status_ui.dart';
import '../../data/repositories/vendor_repository.dart';

class BookingsScreen extends StatefulWidget {
  final String initialQuery;
  const BookingsScreen({super.key, this.initialQuery = ''});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final _repo = VendorRepository();
  List<VendorBooking> _all = [];
  bool _loading = true;
  String? _error;
  BookingStatus? _filter;
  late String _query = widget.initialQuery;
  bool _latestFirst = false;
  final Set<String> _busy = {};

  static final _cur = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BookingsScreen old) {
    super.didUpdateWidget(old);
    if (old.initialQuery != widget.initialQuery) setState(() => _query = widget.initialQuery);
  }

  Future<void> _load() async {
    setState(() {
      _loading = _all.isEmpty;
      _error = null;
    });
    try {
      final b = await _repo.bookings();
      if (!mounted) return;
      setState(() {
        _all = b;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = apiErrorMessage(e, fallback: 'Could not load bookings.');
        });
      }
    }
  }

  List<VendorBooking> get _filtered {
    final q = _query.trim().toLowerCase();
    final list = _all.where((b) {
      if (_filter != null && b.status != _filter) return false;
      if (q.isEmpty) return true;
      return [b.id, b.clientName, b.service, b.location, b.notes, b.inquiryRef ?? '']
          .any((f) => f.toLowerCase().contains(q));
    }).toList();
    list.sort((a, b) => _latestFirst ? b.date.compareTo(a.date) : a.date.compareTo(b.date));
    return list;
  }

  Future<void> _respond(VendorBooking b, BookingStatus s) async {
    final date = DateFormat('d MMM yyyy').format(b.date);
    if (s == BookingStatus.cancelled) {
      final ok = await confirmAction(
        context,
        title: b.status == BookingStatus.requested ? 'Decline this request?' : 'Cancel this booking?',
        message: '${b.clientName.isEmpty ? 'The client' : b.clientName} will be notified that ${b.service} on $date '
            '${b.status == BookingStatus.requested ? 'is not available' : 'has been cancelled'}.',
        confirmLabel: b.status == BookingStatus.requested ? 'Decline' : 'Cancel booking',
        destructive: true,
      );
      if (!ok) return;
    } else if (s == BookingStatus.completed) {
      final ok = await confirmAction(
        context,
        title: 'Mark as completed?',
        message: 'Confirm that ${b.service} for ${b.clientName.isEmpty ? 'the client' : b.clientName} on $date is done. '
            'The payout moves to settlement once the AOneGo9 desk confirms.',
        confirmLabel: 'Mark completed',
      );
      if (!ok) return;
    }
    if (!mounted) return;
    final m = Toast.of(context);
    setState(() => _busy.add(b.id));
    try {
      await _repo.respondBooking(b.id, s);
      final idx = _all.indexWhere((x) => x.id == b.id);
      if (idx != -1 && mounted) setState(() => _all[idx] = _all[idx].copyWith(status: s));
      Toast.ok(m, switch (s) {
        BookingStatus.confirmed => 'Booking accepted — the client has been notified',
        BookingStatus.inProgress => 'Job started',
        BookingStatus.completed => 'Marked as completed',
        BookingStatus.cancelled => 'Booking declined',
        _ => 'Booking updated',
      });
      _load();
    } catch (e) {
      Toast.error(m, apiErrorMessage(e, fallback: 'Could not update the booking.'));
    } finally {
      if (mounted) setState(() => _busy.remove(b.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _all.isEmpty) return ErrorView(message: _error!, onRetry: _load);
    final list = _filtered;
    int count(BookingStatus? s) => s == null ? _all.length : _all.where((b) => b.status == s).length;

    return PageBody(
      onRefresh: _load,
      children: [
        PageHeader(
          title: 'Bookings',
          subtitle: 'Accept new requests and manage every job from inquiry to completion',
          actions: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _latestFirst = !_latestFirst),
              icon: Icon(_latestFirst ? Icons.arrow_downward : Icons.arrow_upward, size: 16),
              label: Text(_latestFirst ? 'Latest first' : 'Soonest first'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        PillBar(children: [
          FilterPill(label: 'All', count: count(null), selected: _filter == null, onTap: () => setState(() => _filter = null)),
          for (final (label, s) in const [
            ('Requests', BookingStatus.requested),
            ('Confirmed', BookingStatus.confirmed),
            ('In progress', BookingStatus.inProgress),
            ('Completed', BookingStatus.completed),
            ('Cancelled', BookingStatus.cancelled),
            ('Disputed', BookingStatus.disputed),
          ])
            FilterPill(label: label, count: count(s), selected: _filter == s, onTap: () => setState(() => _filter = s)),
        ]),
        const SizedBox(height: 14),
        SearchField(
          key: ValueKey('bq-${widget.initialQuery}'),
          initial: _query,
          hint: 'Search client, service, location or inquiry reference…',
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 16),
        if (_loading)
          const LoadingView()
        else if (list.isEmpty)
          EmptyView(
            icon: Icons.event_note_outlined,
            message: _all.isEmpty ? 'No bookings yet' : 'No bookings match',
            detail: _all.isEmpty
                ? 'When clients send an inquiry or book a package from the marketplace, it appears here.'
                : 'Try another status or clear the search.',
          )
        else
          for (final b in list) Padding(padding: const EdgeInsets.only(bottom: 14), child: _bookingCard(b)),
      ],
    );
  }

  Widget _bookingCard(VendorBooking b) {
    final (label, color) = StatusUi.booking(b.status);
    final busy = _busy.contains(b.id);
    final next = StatusUi.nextStep(b.status);
    final mobile = Responsive.isMobile(context);
    final past = DateUtils.dateOnly(b.date).isBefore(DateUtils.dateOnly(DateTime.now()));

    return SectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          StatusChip(label: label, color: color),
          if (b.source == BookingSource.inquiry) _inquiryTag(b.inquiryRef),
          if (past && (b.status == BookingStatus.confirmed || b.status == BookingStatus.requested))
            StatusChip(label: 'Date passed', color: AppColors.warning),
        ]),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.service.isEmpty ? 'Booking' : b.service, style: AppType.body(size: 15, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(b.clientName.isEmpty ? 'Client' : b.clientName,
                  style: AppType.body(size: 13, color: AppColors.textSecondary)),
            ]),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(b.amount > 0 ? _cur.format(b.amount) : 'Quote pending',
                style: AppType.mono(size: 16, weight: FontWeight.w800, color: AppColors.gold)),
            if (b.advancePaid > 0)
              Text('Advance ${_cur.format(b.advancePaid)}', style: AppType.mono(size: 11.5, color: AppColors.success)),
          ]),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 18, runSpacing: 8, children: [
          _meta(Icons.calendar_today_outlined, DateFormat('EEE, d MMM yyyy').format(b.date)),
          if (b.location.isNotEmpty) _meta(Icons.location_on_outlined, b.location),
          if (b.advancePaid > 0) _meta(Icons.account_balance_wallet_outlined, 'Balance due ${_cur.format(b.balanceDue)}'),
        ]),
        if (b.notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: AppColors.gold.withValues(alpha: .6), width: 3)),
            ),
            child: Text(b.notes, style: AppType.body(size: 13, color: AppColors.textSecondary, height: 1.45)),
          ),
        ],
        if (b.clientPhone.isNotEmpty || b.clientEmail.isNotEmpty || b.inquiryRef != null) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 4, runSpacing: 0, children: [
            if (b.clientPhone.isNotEmpty) ...[
              TextButton.icon(
                onPressed: () => openExternal(context, telUri(b.clientPhone)),
                icon: const Icon(Icons.call_outlined, size: 16),
                label: const Text('Call'),
              ),
              TextButton.icon(
                onPressed: () => openExternal(context,
                    whatsappUri(b.clientPhone, text: 'Hi ${b.clientName}, this is ${b.service} via AOneGo9${b.inquiryRef != null ? ' (ref ${b.inquiryRef})' : ''}.')),
                icon: const Icon(Icons.chat_outlined, size: 16),
                label: const Text('WhatsApp'),
              ),
            ],
            if (b.clientEmail.isNotEmpty)
              TextButton.icon(
                onPressed: () => openExternal(
                    context, mailUri(b.clientEmail, subject: 'Your AOneGo9 booking${b.inquiryRef != null ? ' · ${b.inquiryRef}' : ''}')),
                icon: const Icon(Icons.mail_outline, size: 16),
                label: const Text('Email'),
              ),
            if (b.inquiryRef != null)
              TextButton.icon(
                onPressed: () => copyToClipboard(context, b.inquiryRef!, label: 'Reference ${b.inquiryRef} copied'),
                icon: const Icon(Icons.copy, size: 15),
                label: const Text('Copy ref'),
              ),
          ]),
        ],
        if (b.status == BookingStatus.requested) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: busy ? null : () => _respond(b, BookingStatus.confirmed),
                icon: busy ? const ButtonSpinner() : const Icon(Icons.check, size: 18),
                label: const Text('Accept'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : () => _respond(b, BookingStatus.cancelled),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Decline'),
              ),
            ),
          ]),
        ] else if (next != null) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: [
            SizedBox(
              width: mobile ? double.infinity : null,
              child: ElevatedButton.icon(
                onPressed: busy ? null : () => _respond(b, next.$2),
                icon: busy
                    ? const ButtonSpinner()
                    : Icon(next.$2 == BookingStatus.completed ? Icons.task_alt : Icons.play_arrow_rounded, size: 18),
                label: Text(next.$1),
              ),
            ),
            if (b.status == BookingStatus.confirmed)
              SizedBox(
                width: mobile ? double.infinity : null,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => _respond(b, BookingStatus.cancelled),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                  icon: const Icon(Icons.event_busy_outlined, size: 18),
                  label: const Text('Cancel booking'),
                ),
              ),
          ]),
        ] else if (b.status == BookingStatus.disputed) ...[
          const SizedBox(height: 12),
          const InlineNotice(
            icon: Icons.gavel_outlined,
            message: 'This booking is under review by the AOneGo9 desk. You will be notified when it is resolved.',
          ),
        ],
      ]),
    );
  }

  Widget _meta(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: AppType.body(size: 12.5, color: AppColors.textSecondary))),
      ]);

  Widget _inquiryTag(String? reference) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.forum_outlined, size: 12, color: AppColors.info),
          const SizedBox(width: 4),
          Text(reference == null ? 'Inquiry' : 'Inquiry · $reference',
              style: AppType.mono(size: 10.5, weight: FontWeight.w700, color: AppColors.info)),
        ]),
      );
}
