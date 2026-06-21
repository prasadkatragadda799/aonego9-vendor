import '../models/models.dart';
import '../mock/mock_data.dart';
import '../../core/category/vendor_category.dart';

/// ───────────────────────────────────────────────────────────────
/// VENDOR REPOSITORY — the single seam between UI and backend.
/// BACKEND DEV: replace each mock body with a real HTTP call.
/// Suggested REST endpoints noted above each method.
/// ───────────────────────────────────────────────────────────────
class VendorRepository {
  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 350));

  // Per-category mutable caches, lazily seeded so toggles persist within a
  // session and each vendor type sees data that matches their business.
  static final Map<VendorCategory, List<ServicePackage>> _packages = {};
  static final Map<VendorCategory, List<TalentMember>> _roster = {};

  List<ServicePackage> _packagesCache() =>
      _packages.putIfAbsent(VendorSession.category, () => packagesFor(VendorSession.category));
  List<TalentMember> _rosterCache() =>
      _roster.putIfAbsent(VendorSession.category, () => rosterFor(VendorSession.category));

  // GET /api/vendor/dashboard/summary
  Future<Map<String, num>> dashboardSummary() async {
    await _delay();
    final completed = MockData.bookings.where((b) => b.status == BookingStatus.completed);
    return {
      'pendingRequests': MockData.bookings.where((b) => b.status == BookingStatus.requested).length,
      'upcoming': MockData.bookings.where((b) => b.status == BookingStatus.confirmed).length,
      'monthEarnings': MockData.earnings.where((e) => e.type == TxnType.earning).fold<double>(0, (s, e) => s + e.amount),
      'pendingPayout': MockData.earnings.where((e) => e.type == TxnType.earning && e.status == 'pending').fold<double>(0, (s, e) => s + e.amount),
      'completed': completed.length,
      'rating': 4.8,
      'activeTalent': _rosterCache().where((m) => m.available).length,
    };
  }

  // GET /api/vendor/services
  Future<List<ServicePackage>> services() async { await _delay(); return List.of(_packagesCache()); }

  // PATCH /api/vendor/services/{id} { active }
  Future<void> toggleService(String id, bool active) async {
    await _delay();
    final list = _packagesCache();
    final i = list.indexWhere((p) => p.id == id);
    if (i != -1) list[i] = list[i].copyWith(active: active);
  }

  // GET /api/vendor/talent
  Future<List<TalentMember>> roster() async { await _delay(); return List.of(_rosterCache()); }

  // PATCH /api/vendor/talent/{id} { available }
  Future<void> toggleAvailability(String id, bool available) async {
    await _delay();
    final list = _rosterCache();
    final i = list.indexWhere((m) => m.id == id);
    if (i != -1) list[i] = list[i].copyWith(available: available);
  }

  // GET /api/vendor/bookings
  Future<List<VendorBooking>> bookings() async { await _delay(); return List.of(MockData.bookings); }

  // POST /api/vendor/bookings/{id}/respond { action: accept|reject }
  Future<void> respondBooking(String id, BookingStatus status) async {
    await _delay();
    final i = MockData.bookings.indexWhere((b) => b.id == id);
    if (i != -1) MockData.bookings[i] = MockData.bookings[i].copyWith(status: status);
  }

  // GET /api/vendor/earnings
  Future<List<EarningTxn>> earnings() async { await _delay(); return List.of(MockData.earnings); }

  // GET /api/vendor/reviews
  Future<List<VendorReview>> reviews() async { await _delay(); return List.of(MockData.reviews); }

  // GET /api/vendor/messages
  Future<List<ChatThread>> threads() async { await _delay(); return List.of(MockData.threads); }

  // GET /api/vendor/notifications
  Future<List<NotificationItem>> notifications() async { await _delay(); return List.of(MockData.notifications); }

  // GET /api/vendor/analytics/earnings
  Future<List<KpiPoint>> earningsTrend() async { await _delay(); return List.of(MockData.earningsTrend); }

  // GET /api/vendor/subscription/plans
  Future<List<SubscriptionPlan>> plans() async { await _delay(); return List.of(MockData.plans); }

  // GET /api/vendor/subscription
  Future<VendorSubscription> currentSubscription() async {
    await _delay();
    final p = MockData.plans.firstWhere((p) => p.id == MockData.currentPlanId);
    return VendorSubscription(
      planId: p.id,
      planName: p.name,
      price: p.price,
      status: p.price == 0 ? 'active' : 'active',
      renewsOn: DateTime(2026, 7, 1),
    );
  }

  // POST /api/vendor/subscription { planId }
  Future<void> changePlan(String planId) async {
    await _delay();
    MockData.currentPlanId = planId;
  }

  // GET /api/vendor/subscription/billing
  Future<List<BillingEntry>> billingHistory() async { await _delay(); return List.of(MockData.billing); }
}
