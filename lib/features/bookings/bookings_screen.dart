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

  /// Asks for the booking's price. Returns null when dismissed, 0 when the
  /// vendor accepts without a price yet ([optional] only).
  Future<double?> _askQuote(VendorBooking b, {required String title, required String confirmLabel, bool optional = false}) =>
      showDialog<double>(
        context: context,
        builder: (_) => _QuoteDialog(booking: b, title: title, confirmLabel: confirmLabel, optional: optional),
      );

  Future<bool> _saveQuote(VendorBooking b, double amount, ScaffoldMessengerState m) async {
    try {
      await _repo.setQuote(b.id, amount);
      final idx = _all.indexWhere((x) => x.id == b.id);
      if (idx != -1 && mounted) setState(() => _all[idx] = _all[idx].copyWith(amount: amount));
      return true;
    } catch (e) {
      Toast.error(m, apiErrorMessage(e, fallback: 'Could not save the quote.'));
      return false;
    }
  }

  Future<void> _editQuote(VendorBooking b) async {
    final amount = await _askQuote(b, title: b.amount > 0 ? 'Update quote' : 'Set quote', confirmLabel: 'Save quote');
    if (amount == null || amount <= 0 || !mounted) return;
    final m = Toast.of(context);
    setState(() => _busy.add(b.id));
    if (await _saveQuote(b, amount, m)) Toast.ok(m, 'Quote saved — ${_cur.format(amount)}');
    if (mounted) setState(() => _busy.remove(b.id));
  }

  Future<void> _respond(VendorBooking b, BookingStatus s) async {
    final date = DateFormat('d MMM yyyy').format(b.date);
    double? quote;
    if (s == BookingStatus.confirmed && b.amount <= 0) {
      // Inquiries arrive unpriced — price it while accepting, or later.
      quote = await _askQuote(b, title: 'Accept this request', confirmLabel: 'Accept', optional: true);
      if (quote == null) return;
    } else if (s == BookingStatus.completed && b.amount <= 0) {
      // Earnings and commission are booked off the final amount.
      quote = await _askQuote(b, title: 'Final amount', confirmLabel: 'Mark completed');
      if (quote == null) return;
    } else if (s == BookingStatus.cancelled) {
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
    if (quote != null && quote > 0 && !await _saveQuote(b, quote, m)) {
      if (mounted) setState(() => _busy.remove(b.id));
      return;
    }
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
            Text(b.amount > 0 ? _cur.format(b.amount) : (_quotable(b.status) ? 'Quote pending' : 'Not priced'),
                style: AppType.mono(
                    size: 16, weight: FontWeight.w800, color: b.amount > 0 || _quotable(b.status) ? AppColors.gold : AppColors.textMuted)),
            if (b.advancePaid > 0)
              Text('Advance ${_cur.format(b.advancePaid)}', style: AppType.mono(size: 11.5, color: AppColors.success)),
          ]),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 18, runSpacing: 8, children: [
          _meta(Icons.calendar_today_outlined, DateFormat('EEE, d MMM yyyy').format(b.date)),
          if (b.location.isNotEmpty) _meta(Icons.location_on_outlined, b.location),
          if (b.advancePaid > 0 && b.amount > 0 && b.status != BookingStatus.cancelled)
            _meta(Icons.account_balance_wallet_outlined, 'Balance due ${_cur.format(b.balanceDue)}'),
          if (b.advancePaid > 0 && b.status == BookingStatus.cancelled)
            _meta(Icons.undo_rounded, 'Advance refund queued with the desk'),
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
        if (_quotable(b.status)) ...[
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: busy ? null : () => _editQuote(b),
            icon: Icon(b.amount > 0 ? Icons.edit_outlined : Icons.request_quote_outlined, size: 16),
            label: Text(b.amount > 0 ? 'Update quote' : 'Set quote'),
          ),
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

  static bool _quotable(BookingStatus s) =>
      s == BookingStatus.requested || s == BookingStatus.confirmed || s == BookingStatus.inProgress;

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

class _QuoteDialog extends StatefulWidget {
  final VendorBooking booking;
  final String title;
  final String confirmLabel;
  final bool optional;
  const _QuoteDialog({required this.booking, required this.title, required this.confirmLabel, this.optional = false});
  @override
  State<_QuoteDialog> createState() => _QuoteDialogState();
}

class _QuoteDialogState extends State<_QuoteDialog> {
  late final _ctrl = TextEditingController(text: widget.booking.amount > 0 ? widget.booking.amount.toStringAsFixed(0) : '');
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _ctrl.text.replaceAll(RegExp(r'[,\s₹]'), '');
    if (raw.isEmpty && widget.optional) return Navigator.pop(context, 0.0);
    final v = double.tryParse(raw);
    final min = widget.booking.advancePaid;
    setState(() => _error = v == null || v <= 0
        ? 'Enter the amount in rupees'
        : v > 100000000
            ? 'That amount looks too large'
            : v < min
                ? 'Cannot be below the advance already paid (${_BookingsScreenState._cur.format(min)})'
                : null);
    if (_error == null) Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            '${b.service.isEmpty ? 'Booking' : b.service} for ${b.clientName.isEmpty ? 'the client' : b.clientName} · '
            '${DateFormat('d MMM yyyy').format(b.date)}',
            style: AppType.body(size: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: widget.optional ? 'Your quote (optional)' : 'Amount',
            hint: widget.optional
                ? 'Leave blank to send the price later from this card.'
                : 'Your earnings and the platform commission are calculated from this amount.',
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(prefixText: '₹ ', hintText: 'e.g. 45000', errorText: _error),
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
