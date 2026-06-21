// ─────────────────────────────────────────────────────────────
// Vendor-side domain models. Each has fromJson/toJson so the
// backend dev can map API responses without touching the UI.
// ─────────────────────────────────────────────────────────────

enum BookingStatus { requested, confirmed, inProgress, completed, cancelled, disputed }

/// How a booking reached the vendor — directly, or from a user inquiry
/// raised in the user app (the inquiry → booking pipeline).
enum BookingSource { direct, inquiry }

enum TxnType { earning, payout, refund }

String _name(Object e) => e.toString().split('.').last;
T _fromStr<T>(List<T> values, String? n, T fb) =>
    n == null ? fb : values.firstWhere((e) => _name(e as Object).toLowerCase() == n.toLowerCase(), orElse: () => fb);

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
        id: j['id'].toString(),
        title: j['title'] ?? '',
        category: j['category'] ?? '',
        price: (j['price'] ?? 0).toDouble(),
        unit: j['unit'] ?? '',
        active: j['active'] ?? true,
        bookingsCount: j['bookingsCount'] ?? 0,
        description: j['description'] ?? '',
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
        id: j['id'].toString(),
        name: j['name'] ?? '',
        role: j['role'] ?? '',
        city: j['city'] ?? '',
        dayRate: (j['dayRate'] ?? 0).toDouble(),
        rating: (j['rating'] ?? 0).toDouble(),
        available: j['available'] ?? true,
        shoots: j['shoots'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'role': role, 'city': city,
        'dayRate': dayRate, 'rating': rating, 'available': available, 'shoots': shoots,
      };

  TalentMember copyWith({bool? available}) => TalentMember(
        id: id, name: name, role: role, city: city, dayRate: dayRate,
        rating: rating, available: available ?? this.available, shoots: shoots,
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
  });

  double get balanceDue => (amount - advancePaid).clamp(0, amount);

  factory VendorBooking.fromJson(Map<String, dynamic> j) => VendorBooking(
        id: j['id'].toString(),
        clientName: j['clientName'] ?? '',
        service: j['service'] ?? '',
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
        amount: (j['amount'] ?? 0).toDouble(),
        status: _fromStr(BookingStatus.values, j['status'], BookingStatus.requested),
        location: j['location'] ?? j['city'] ?? '',
        notes: j['notes'] ?? '',
        source: _fromStr(BookingSource.values, j['source'], BookingSource.direct),
        inquiryRef: j['inquiryRef'],
        advancePaid: (j['advancePaid'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'clientName': clientName, 'service': service, 'date': date.toIso8601String(),
        'amount': amount, 'status': _name(status), 'location': location, 'notes': notes,
        'source': _name(source), 'inquiryRef': inquiryRef, 'advancePaid': advancePaid,
      };

  VendorBooking copyWith({BookingStatus? status}) => VendorBooking(
        id: id, clientName: clientName, service: service, date: date, amount: amount,
        status: status ?? this.status, location: location, notes: notes,
        source: source, inquiryRef: inquiryRef, advancePaid: advancePaid,
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
        id: j['id'].toString(),
        source: j['source'] ?? '',
        type: _fromStr(TxnType.values, j['type'], TxnType.earning),
        amount: (j['amount'] ?? 0).toDouble(),
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
        status: j['status'] ?? 'settled',
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
}

class ChatThread {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime time;
  final int unread;
  final List<ChatMessage> messages;
  ChatThread({required this.id, required this.name, required this.lastMessage, required this.time, required this.unread, required this.messages});
}

class ChatMessage {
  final String text;
  final bool fromMe;
  final DateTime time;
  ChatMessage(this.text, this.fromMe, this.time);
}

class NotificationItem {
  final String title;
  final String body;
  final IconKind kind;
  final DateTime time;
  final bool unread;
  NotificationItem({required this.title, required this.body, required this.kind, required this.time, required this.unread});
}

enum IconKind { booking, payment, review, system }

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
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    required this.features,
    this.recommended = false,
  });
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
}
