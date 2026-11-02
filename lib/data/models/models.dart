// ─────────────────────────────────────────────────────────────
// Vendor-side domain models. Each has fromJson/toJson so the
// backend dev can map API responses without touching the UI.
// ─────────────────────────────────────────────────────────────

import '../../core/utils/date_util.dart';

enum BookingStatus { requested, confirmed, inProgress, completed, cancelled, disputed }

/// How a booking reached the vendor — directly, or from a user inquiry
/// raised in the user app (the inquiry → booking pipeline).
enum BookingSource { direct, inquiry }

enum TxnType { earning, payout, refund }

String _name(Object e) => e.toString().split('.').last;

/// Enum lookup that also understands the backend's snake_case
/// (`in_progress` → inProgress) and is case-insensitive.
T _fromStr<T>(List<T> values, Object? raw, T fb) {
  if (raw == null) return fb;
  final n = '$raw'.replaceAll('_', '').replaceAll('-', '').toLowerCase();
  return values.firstWhere((e) => _name(e as Object).toLowerCase() == n, orElse: () => fb);
}

/// First non-null value among the given keys, so a model reads both the
/// backend's snake_case and the console's legacy camelCase.
Object? _pick(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    final v = j[k];
    if (v != null) return v;
  }
  return null;
}

double _num(Object? v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
int _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
String _str(Object? v) => v == null ? '' : '$v';
bool _bool(Object? v, {bool fb = false}) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v.toLowerCase() == 'true' || v == '1';
  return fb;
}

/// API timestamps are UTC; a missing or malformed one becomes "now" rather
/// than throwing and blanking the screen.
DateTime _date(Object? v) {
  final raw = _str(v);
  if (raw.isEmpty) return DateTime.now();
  return DateTime.tryParse(raw)?.toLocal() ?? DateTime.now();
}

class ServicePackage {
  final String id;
  final String title;
  final String category;
  final double price;
  final String unit; // per day, per shoot, per event
  final bool active;
  final int bookingsCount;
  final String description;

  ServicePackage({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.unit,
    required this.active,
    required this.bookingsCount,
    required this.description,
  });

  factory ServicePackage.fromJson(Map<String, dynamic> j) => ServicePackage(
        id: _str(j['id']),
        title: _str(j['title']),
        category: _str(j['category']),
        price: _num(j['price']),
        unit: _str(j['unit']),
        active: _bool(_pick(j, ['active', 'is_active']), fb: true),
        bookingsCount: _int(_pick(j, ['bookings_count', 'bookingsCount'])),
        description: _str(j['description']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'price': price,
        'unit': unit,
        'active': active,
        'bookingsCount': bookingsCount,
        'description': description,
      };

  ServicePackage copyWith({bool? active}) => ServicePackage(
        id: id, title: title, category: category, price: price, unit: unit,
        active: active ?? this.active, bookingsCount: bookingsCount, description: description,
      );
}

class TalentMember {
  final String id;
  final String name;
  final String role; // Model, Actor, etc.
  final String city;
  final double dayRate;
  final double rating;
  final bool available;
  final int shoots;

  TalentMember({
    required this.id,
    required this.name,
    required this.role,
    required this.city,
    required this.dayRate,
    required this.rating,
    required this.available,
    required this.shoots,
  });

  factory TalentMember.fromJson(Map<String, dynamic> j) => TalentMember(
        id: _str(j['id']),
        name: _str(j['name']),
        role: _str(j['role']),
        city: _str(j['city']),
        dayRate: _num(_pick(j, ['dayRate', 'day_rate', 'rate'])),
        rating: _num(j['rating']),
        available: _bool(_pick(j, ['available', 'is_available']), fb: true),
        shoots: _int(_pick(j, ['shoots', 'jobs', 'jobs_done'])),
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'role': role, 'city': city,
        'dayRate': dayRate, 'rating': rating, 'available': available, 'shoots': shoots,
      };

  TalentMember copyWith({String? name, String? role, String? city, double? dayRate, bool? available}) => TalentMember(
        id: id, name: name ?? this.name, role: role ?? this.role, city: city ?? this.city,
        dayRate: dayRate ?? this.dayRate, rating: rating, available: available ?? this.available, shoots: shoots,
      );
}

class VendorBooking {
  final String id;
  final String clientName;
  final String service;
  final DateTime date;
  final double amount;
  final BookingStatus status;
  final String location;
  final String notes;
  final BookingSource source;
  final String? inquiryRef; // AO9-xxxxxx reference when raised via inquiry
  final double advancePaid; // deposit the client has already paid
  final String clientEmail;
  final String clientPhone;

  VendorBooking({
    required this.id,
    required this.clientName,
    required this.service,
    required this.date,
    required this.amount,
    required this.status,
    required this.location,
    required this.notes,
    this.source = BookingSource.direct,
    this.inquiryRef,
    this.advancePaid = 0,
    this.clientEmail = '',
    this.clientPhone = '',
  });

  double get balanceDue => (amount - advancePaid).clamp(0, amount);

  factory VendorBooking.fromJson(Map<String, dynamic> j) {
    final ref = _str(_pick(j, ['inquiry_ref', 'inquiryRef']));
    return VendorBooking(
      id: _str(j['id']),
      clientName: _str(_pick(j, ['client_name', 'clientName', 'name'])),
      service: _str(_pick(j, ['service', 'package_title', 'category'])),
      date: _date(_pick(j, ['date', 'event_date'])),
      amount: _num(j['amount']),
      status: _fromStr(BookingStatus.values, j['status'], BookingStatus.requested),
      location: _str(_pick(j, ['location', 'city'])),
      notes: _str(_pick(j, ['notes', 'message'])),
      source: _fromStr(BookingSource.values, j['source'], ref.isEmpty ? BookingSource.direct : BookingSource.inquiry),
      inquiryRef: ref.isEmpty ? null : ref,
      advancePaid: _num(_pick(j, ['advance_paid', 'advancePaid'])),
      clientEmail: _str(_pick(j, ['client_email', 'email'])),
      clientPhone: _str(_pick(j, ['client_phone', 'phone'])),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id, 'clientName': clientName, 'service': service, 'date': date.toIso8601String(),
        'amount': amount, 'status': _name(status), 'location': location, 'notes': notes,
        'source': _name(source), 'inquiryRef': inquiryRef, 'advancePaid': advancePaid,
      };

  VendorBooking copyWith({BookingStatus? status}) => VendorBooking(
        id: id, clientName: clientName, service: service, date: date, amount: amount,
        status: status ?? this.status, location: location, notes: notes,
        source: source, inquiryRef: inquiryRef, advancePaid: advancePaid,
        clientEmail: clientEmail, clientPhone: clientPhone,
      );
}

class EarningTxn {
  final String id;
  final String source;
  final TxnType type;
  final double amount;
  final DateTime date;
  final String status; // settled, pending

  EarningTxn({
    required this.id,
    required this.source,
    required this.type,
    required this.amount,
    required this.date,
    required this.status,
  });

  factory EarningTxn.fromJson(Map<String, dynamic> j) => EarningTxn(
        id: _str(j['id']),
        source: _str(_pick(j, ['source', 'description', 'party'])),
        type: _fromStr(TxnType.values, j['type'], TxnType.earning),
        amount: _num(j['amount']),
        date: _date(_pick(j, ['date', 'created_at'])),
        status: _str(j['status']).isEmpty ? 'settled' : _str(j['status']).toLowerCase(),
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'source': source, 'type': _name(type), 'amount': amount,
        'date': date.toIso8601String(), 'status': status,
      };
}

class VendorReview {
  final String id;
  final String client;
  final int stars;
  final String text;
  final DateTime date;
  final String? reply;
  VendorReview({required this.id, required this.client, required this.stars, required this.text, required this.date, this.reply});

  bool get hasReply => reply != null && reply!.trim().isNotEmpty;

  VendorReview withReply(String r) =>
      VendorReview(id: id, client: client, stars: stars, text: text, date: date, reply: r);

  factory VendorReview.fromJson(Map<String, dynamic> j) {
    final reply = _str(j['reply']).trim();
    return VendorReview(
      id: _str(j['id']),
      client: _str(_pick(j, ['client_name', 'author_name', 'author'])).isEmpty
          ? 'Client'
          : _str(_pick(j, ['client_name', 'author_name', 'author'])),
      stars: _int(_pick(j, ['stars', 'rating'])).clamp(0, 5),
      text: _str(j['text']),
      date: _date(_pick(j, ['date', 'created_at'])),
      reply: reply.isEmpty ? null : reply,
    );
  }
}

class ChatThread {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime time;
  final int unread;
  final List<ChatMessage> messages;
  ChatThread({required this.id, required this.name, required this.lastMessage, required this.time, required this.unread, required this.messages});

  ChatThread copyWith({String? lastMessage, DateTime? time, int? unread, List<ChatMessage>? messages}) => ChatThread(
        id: id,
        name: name,
        lastMessage: lastMessage ?? this.lastMessage,
        time: time ?? this.time,
        unread: unread ?? this.unread,
        messages: messages ?? this.messages,
      );

  factory ChatThread.fromJson(Map<String, dynamic> j) {
    final raw = j['messages'];
    final msgs = raw is List
        ? raw.whereType<Map>().map((m) => ChatMessage.fromJson(m.cast<String, dynamic>())).toList()
        : <ChatMessage>[];
    final name = _str(_pick(j, ['participant_name', 'name', 'client_name']));
    return ChatThread(
      id: _str(j['id']),
      name: name.isEmpty ? 'Client' : name,
      lastMessage: _str(_pick(j, ['last_message', 'lastMessage'])),
      time: _date(_pick(j, ['last_message_at', 'updated_at', 'created_at'])),
      unread: _int(_pick(j, ['unread_count', 'unread'])),
      messages: msgs,
    );
  }
}

class ChatMessage {
  final String text;
  final bool fromMe;
  final DateTime time;
  /// True while an optimistic message is still in flight.
  final bool pending;
  /// True when an optimistic message failed to send.
  final bool failed;
  ChatMessage(this.text, this.fromMe, this.time, {this.pending = false, this.failed = false});

  factory ChatMessage.fromJson(Map<String, dynamic> m) => ChatMessage(
        _str(m['text']),
        _bool(_pick(m, ['from_vendor', 'fromVendor', 'from_me'])),
        _date(_pick(m, ['sent_at', 'created_at'])),
      );
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final IconKind kind;
  final DateTime time;
  final bool unread;
  NotificationItem({this.id = '', required this.title, required this.body, required this.kind, required this.time, required this.unread});

  NotificationItem markRead() =>
      NotificationItem(id: id, title: title, body: body, kind: kind, time: time, unread: false);

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
        id: _str(j['id']),
        title: _str(j['title']).isEmpty ? 'Update' : _str(j['title']),
        body: _str(_pick(j, ['body', 'message'])),
        kind: switch (_str(_pick(j, ['kind', 'type'])).toLowerCase()) {
          'booking' || 'inquiry' => IconKind.booking,
          'payment' || 'payout' || 'subscription' => IconKind.payment,
          'review' => IconKind.review,
          'message' => IconKind.message,
          _ => IconKind.system,
        },
        time: _date(j['created_at']),
        unread: _bool(_pick(j, ['unread', 'is_unread'])) || (j.containsKey('read') && !_bool(j['read'])),
      );
}

enum IconKind { booking, payment, review, message, system }

class KpiPoint {
  final String label;
  final double value;
  KpiPoint(this.label, this.value);
}

// ─────────────────────────────────────────────────────────────
// Subscription billing — the vendor's plan with AOneGo9.
// ─────────────────────────────────────────────────────────────

class SubscriptionPlan {
  final String id;
  final String name;
  final double price; // 0 = free
  final String period; // 'forever' | 'per month'
  final List<String> features;
  final bool recommended;
  final String audience; // 'vendor' | 'user' | 'both'
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    required this.features,
    this.recommended = false,
    this.audience = 'vendor',
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> j) {
    final f = j['features'];
    return SubscriptionPlan(
      id: _str(j['id']),
      name: _str(j['name']).isEmpty ? 'Plan' : _str(j['name']),
      price: _num(j['price']),
      period: _str(j['period']).isEmpty ? 'per month' : _str(j['period']),
      features: f is List ? f.map((e) => '$e').where((e) => e.trim().isNotEmpty).toList() : const [],
      recommended: _bool(_pick(j, ['recommended', 'popular'])),
      audience: _str(j['audience']).isEmpty ? 'vendor' : _str(j['audience']),
    );
  }

  /// Short suffix for a price — "/ mo", "/ yr", or nothing for a free plan.
  String get periodShort {
    if (price == 0) return '';
    final p = period.toLowerCase();
    if (p.contains('year') || p.contains('annual')) return ' / yr';
    if (p.contains('quarter')) return ' / qtr';
    if (p.contains('week')) return ' / wk';
    if (p.contains('forever') || p.contains('once') || p.contains('life')) return '';
    return ' / mo';
  }
}

class VendorSubscription {
  final String planId;
  final String planName;
  final double price;
  final String status; // active, trialing, past_due
  final DateTime renewsOn;
  VendorSubscription({
    required this.planId,
    required this.planName,
    required this.price,
    required this.status,
    required this.renewsOn,
  });
}

class BillingEntry {
  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final String status; // paid, pending, failed
  BillingEntry({required this.id, required this.date, required this.description, required this.amount, required this.status});

  factory BillingEntry.fromJson(Map<String, dynamic> j) => BillingEntry(
        id: _str(j['id']),
        date: _date(_pick(j, ['date', 'created_at'])),
        description: _str(_pick(j, ['description', 'plan_name'])),
        amount: _num(j['amount']),
        status: _str(j['status']).isEmpty ? 'paid' : _str(j['status']).toLowerCase(),
      );
}

/// A vendor's submitted subscription request, awaiting (or reviewed by) admin approval.
class SubscriptionRequest {
  final String id;
  final String requesterType;
  final String? vendorId;
  final String? userId;
  final String planId;
  final String planName;
  final double amount;
  final String receiptImage;
  final String status; // pending, approved, rejected
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  SubscriptionRequest({
    required this.id,
    required this.requesterType,
    this.vendorId,
    this.userId,
    required this.planId,
    required this.planName,
    required this.amount,
    required this.receiptImage,
    required this.status,
    this.adminNote,
    required this.createdAt,
    this.reviewedAt,
  });

  factory SubscriptionRequest.fromJson(Map<String, dynamic> j) => SubscriptionRequest(
        id: _str(j['id']),
        requesterType: _str(j['requester_type']),
        vendorId: j['vendor_id']?.toString(),
        userId: j['user_id']?.toString(),
        planId: _str(j['plan_id']),
        planName: _str(j['plan_name']),
        amount: _num(j['amount']),
        receiptImage: _str(j['receipt_image']),
        status: _str(j['status']).isEmpty ? 'pending' : _str(j['status']).toLowerCase(),
        adminNote: j['admin_note']?.toString(),
        createdAt: parseApiDateTime(j['created_at']?.toString() ?? ''),
        reviewedAt: j['reviewed_at'] != null ? parseApiDateTime(j['reviewed_at'].toString()) : null,
      );
}

/// UPI payment details used to build the QR code for a subscription payment.
class PaymentSettings {
  final String upiId;
  final String payeeName;
  PaymentSettings({required this.upiId, required this.payeeName});

  factory PaymentSettings.fromJson(Map<String, dynamic> j) => PaymentSettings(
        upiId: _str(j['upi_id']).trim(),
        payeeName: _str(j['payee_name']).trim(),
      );

  bool get isConfigured => upiId.contains('@');
}
