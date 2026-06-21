import '../models/models.dart';

/// Seed data for the vendor app demo. Backend dev: delete once APIs are live.
class MockData {
  static final _now = DateTime(2026, 6, 16);

  static final packages = <ServicePackage>[
    ServicePackage(id: 'P-1', title: 'Fashion Editorial — Half Day', category: 'Models', price: 45000, unit: 'per shoot', active: true, bookingsCount: 38, description: 'Up to 2 models, 4 hours, studio or location.'),
    ServicePackage(id: 'P-2', title: 'Runway Show Roster', category: 'Models', price: 180000, unit: 'per event', active: true, bookingsCount: 12, description: '6 runway models with fittings and rehearsal.'),
    ServicePackage(id: 'P-3', title: 'Brand Campaign — Full Day', category: 'Models', price: 95000, unit: 'per day', active: true, bookingsCount: 21, description: 'Lead model + styling coordination, 8 hours.'),
    ServicePackage(id: 'P-4', title: 'Catalogue Shoot Package', category: 'Models', price: 60000, unit: 'per day', active: false, bookingsCount: 9, description: 'E-commerce catalogue, up to 40 looks.'),
  ];

  static final roster = <TalentMember>[
    TalentMember(id: 'M-1', name: 'Priya Sharma', role: 'Fashion Model', city: 'Mumbai', dayRate: 35000, rating: 4.8, available: true, shoots: 34),
    TalentMember(id: 'M-2', name: 'Kabir Anand', role: 'Runway Model', city: 'Delhi', dayRate: 28000, rating: 4.6, available: true, shoots: 27),
    TalentMember(id: 'M-3', name: 'Riya Malhotra', role: 'Commercial Model', city: 'Delhi', dayRate: 32000, rating: 4.9, available: false, shoots: 41),
    TalentMember(id: 'M-4', name: 'Aditya Rao', role: 'Fitness Model', city: 'Bengaluru', dayRate: 25000, rating: 4.4, available: true, shoots: 18),
    TalentMember(id: 'M-5', name: 'Sara Khan', role: 'Editorial Model', city: 'Mumbai', dayRate: 40000, rating: 4.7, available: true, shoots: 30),
  ];

  static final bookings = <VendorBooking>[
    VendorBooking(id: 'B-9001', clientName: 'Vogue India', service: 'Fashion Editorial — Half Day', date: _now.add(const Duration(days: 2)), amount: 45000, status: BookingStatus.requested, location: 'Studio 7, Mumbai', notes: 'Theme: monsoon editorial. 2 models required.', source: BookingSource.inquiry, inquiryRef: 'AO9-7K2P9X', advancePaid: 5000),
    VendorBooking(id: 'B-9002', clientName: 'Myntra', service: 'Catalogue Shoot Package', date: _now.add(const Duration(days: 4)), amount: 60000, status: BookingStatus.requested, location: 'Bengaluru', notes: 'Summer collection, 40 looks.'),
    VendorBooking(id: 'B-9003', clientName: 'Lakmé', service: 'Brand Campaign — Full Day', date: _now.add(const Duration(days: 6)), amount: 95000, status: BookingStatus.confirmed, location: 'Film City, Mumbai', notes: 'Lead model confirmed: Priya Sharma.', advancePaid: 25000),
    VendorBooking(id: 'B-9004', clientName: 'FDCI', service: 'Runway Show Roster', date: _now.add(const Duration(days: 9)), amount: 180000, status: BookingStatus.confirmed, location: 'Pragati Maidan, Delhi', notes: '6 runway models + rehearsal on day prior.'),
    VendorBooking(id: 'B-9005', clientName: 'Tanishq', service: 'Fashion Editorial — Half Day', date: _now.subtract(const Duration(days: 1)), amount: 45000, status: BookingStatus.inProgress, location: 'Studio 3, Mumbai', notes: 'Jewellery campaign.'),
    VendorBooking(id: 'B-9006', clientName: 'Nykaa', service: 'Brand Campaign — Full Day', date: _now.subtract(const Duration(days: 8)), amount: 95000, status: BookingStatus.completed, location: 'Mumbai', notes: 'Delivered. Awaiting payout.'),
    VendorBooking(id: 'B-9007', clientName: 'H&M', service: 'Catalogue Shoot Package', date: _now.subtract(const Duration(days: 14)), amount: 60000, status: BookingStatus.completed, location: 'Bengaluru', notes: 'Paid out.'),
    VendorBooking(id: 'B-9008', clientName: 'Local Boutique', service: 'Fashion Editorial — Half Day', date: _now.subtract(const Duration(days: 5)), amount: 45000, status: BookingStatus.cancelled, location: 'Pune', notes: 'Client cancelled — date clash.'),
  ];

  static final earnings = <EarningTxn>[
    EarningTxn(id: 'E-1', source: 'H&M — Catalogue Shoot', type: TxnType.earning, amount: 51000, date: _now.subtract(const Duration(days: 12)), status: 'settled'),
    EarningTxn(id: 'E-2', source: 'Payout to bank ••4521', type: TxnType.payout, amount: 51000, date: _now.subtract(const Duration(days: 11)), status: 'settled'),
    EarningTxn(id: 'E-3', source: 'Nykaa — Brand Campaign', type: TxnType.earning, amount: 80750, date: _now.subtract(const Duration(days: 7)), status: 'pending'),
    EarningTxn(id: 'E-4', source: 'Tanishq — Editorial', type: TxnType.earning, amount: 38250, date: _now.subtract(const Duration(days: 1)), status: 'pending'),
    EarningTxn(id: 'E-5', source: 'Local Boutique — Refund', type: TxnType.refund, amount: 45000, date: _now.subtract(const Duration(days: 5)), status: 'settled'),
  ];

  static final reviews = <VendorReview>[
    VendorReview(id: 'R-1', client: 'Nykaa', stars: 5, text: 'Flawless coordination and the models were a perfect fit for our brief.', date: _now.subtract(const Duration(days: 6)), reply: 'Thank you! It was a pleasure working with your team.'),
    VendorReview(id: 'R-2', client: 'H&M', stars: 4, text: 'Great talent roster, shoot ran slightly over time.', date: _now.subtract(const Duration(days: 13))),
    VendorReview(id: 'R-3', client: 'Tanishq', stars: 5, text: 'Professional and punctual. Highly recommend.', date: _now.subtract(const Duration(days: 2))),
  ];

  static final threads = <ChatThread>[
    ChatThread(id: 'T-1', name: 'Vogue India', lastMessage: 'Can we lock 2 models for the 18th?', time: _now.subtract(const Duration(minutes: 24)), unread: 2, messages: [
      ChatMessage('Hi! Loved your roster. We need 2 editorial models.', false, _now.subtract(const Duration(hours: 2))),
      ChatMessage('Absolutely — Priya and Sara are available that week.', true, _now.subtract(const Duration(hours: 1, minutes: 50))),
      ChatMessage('Can we lock 2 models for the 18th?', false, _now.subtract(const Duration(minutes: 24))),
    ]),
    ChatThread(id: 'T-2', name: 'Lakmé', lastMessage: 'Contract signed, see you on set!', time: _now.subtract(const Duration(hours: 5)), unread: 0, messages: [
      ChatMessage('Contract signed, see you on set!', false, _now.subtract(const Duration(hours: 5))),
    ]),
    ChatThread(id: 'T-3', name: 'AOneGo9 Support', lastMessage: 'Your KYC has been approved.', time: _now.subtract(const Duration(days: 1)), unread: 0, messages: [
      ChatMessage('Your KYC has been approved.', false, _now.subtract(const Duration(days: 1))),
    ]),
  ];

  static final notifications = <NotificationItem>[
    NotificationItem(title: 'New booking request', body: 'Vogue India requested “Fashion Editorial — Half Day”.', kind: IconKind.booking, time: _now.subtract(const Duration(minutes: 24)), unread: true),
    NotificationItem(title: 'Payout pending', body: '₹80,750 from Nykaa will settle in 48h.', kind: IconKind.payment, time: _now.subtract(const Duration(hours: 6)), unread: true),
    NotificationItem(title: 'New review', body: 'Tanishq left you a 5★ review.', kind: IconKind.review, time: _now.subtract(const Duration(days: 2)), unread: false),
    NotificationItem(title: 'KYC approved', body: 'Your documents have been verified.', kind: IconKind.system, time: _now.subtract(const Duration(days: 1)), unread: false),
  ];

  static final earningsTrend = <KpiPoint>[
    KpiPoint('Jan', 2.1), KpiPoint('Feb', 2.8), KpiPoint('Mar', 2.5),
    KpiPoint('Apr', 3.4), KpiPoint('May', 3.9), KpiPoint('Jun', 4.6),
  ];

  // ── Subscription billing ──────────────────────────────────────
  static const plans = <SubscriptionPlan>[
    SubscriptionPlan(id: 'starter', name: 'Starter', price: 0, period: 'forever', features: [
      'Public profile & portfolio',
      'Up to 3 service packages',
      'Receive inquiries',
      '10% platform commission',
    ]),
    SubscriptionPlan(id: 'pro', name: 'Pro', price: 999, period: 'per month', recommended: true, features: [
      'Everything in Starter',
      'Unlimited packages & roster',
      'Priority in search results',
      'Featured on category page',
      '7% platform commission',
      'Calendar & messaging',
    ]),
    SubscriptionPlan(id: 'elite', name: 'Elite', price: 2999, period: 'per month', features: [
      'Everything in Pro',
      'Top placement + live poster eligibility',
      'Verified Elite badge',
      'Dedicated account manager',
      '5% platform commission',
      'Advanced analytics',
    ]),
  ];

  // Current plan is mutable so an upgrade/downgrade persists in the demo.
  static String currentPlanId = 'pro';

  static final billing = <BillingEntry>[
    BillingEntry(id: 'INV-2026-06', date: DateTime(2026, 6, 1), description: 'Pro plan — June 2026', amount: 999, status: 'paid'),
    BillingEntry(id: 'INV-2026-05', date: DateTime(2026, 5, 1), description: 'Pro plan — May 2026', amount: 999, status: 'paid'),
    BillingEntry(id: 'INV-2026-04', date: DateTime(2026, 4, 1), description: 'Pro plan — April 2026', amount: 999, status: 'paid'),
  ];
}
