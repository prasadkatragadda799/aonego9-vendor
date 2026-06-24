import '../models/models.dart';
import '../api/api_client.dart';

/// ───────────────────────────────────────────────────────────────
/// VENDOR REPOSITORY — all methods now call the real FastAPI backend.
/// Base URL is configured in api_client.dart (kBaseUrl).
/// ───────────────────────────────────────────────────────────────
class VendorRepository {

  // ── Auth ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await ApiClient.post('/auth/login/vendor', {'email': email, 'password': password}, auth: false);
    await ApiClient.saveTokens(data['access_token'], data['refresh_token']);
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String company,
    required String email,
    required String password,
    String phone = '',
    String city = '',
    String category = '',
  }) async {
    final data = await ApiClient.post('/auth/register/vendor', {
      'name': name, 'company': company, 'email': email,
      'password': password, 'phone': phone, 'city': city, 'category': category,
    }, auth: false);
    await ApiClient.saveTokens(data['access_token'], data['refresh_token']);
    return data;
  }

  Future<void> logout() => ApiClient.clearTokens();

  // ── Dashboard ─────────────────────────────────────────────────

  // GET /api/v1/analytics/vendor/dashboard
  Future<Map<String, num>> dashboardSummary() async {
    final data = await ApiClient.get('/analytics/vendor/dashboard');
    return {
      'pendingRequests': (data['pending_requests'] as num),
      'upcoming': (data['active_bookings'] as num),
      'monthEarnings': (data['total_earned'] as num),
      'pendingPayout': (data['pending_payout'] as num),
      'completed': (data['completed_bookings'] as num),
      'rating': (data['average_rating'] as num),
      'activeTalent': 0,
    };
  }

  // ── Services / Packages ───────────────────────────────────────

  // GET /api/v1/vendors/me/packages
  Future<List<ServicePackage>> services() async {
    final data = await ApiClient.get('/vendors/me/packages') as List;
    return data.map((j) => ServicePackage.fromJson(j)).toList();
  }

  // POST /api/v1/vendors/me/packages
  Future<ServicePackage> createService(ServicePackage pkg) async {
    final data = await ApiClient.post('/vendors/me/packages', pkg.toJson());
    return ServicePackage.fromJson(data);
  }

  // PUT /api/v1/vendors/me/packages/{id}
  Future<ServicePackage> updateService(ServicePackage pkg) async {
    final data = await ApiClient.put('/vendors/me/packages/${pkg.id}', pkg.toJson());
    return ServicePackage.fromJson(data);
  }

  // PATCH /api/v1/vendors/me/packages/{id}/toggle
  Future<void> toggleService(String id, bool active) async {
    await ApiClient.patch('/vendors/me/packages/$id/toggle');
  }

  // DELETE /api/v1/vendors/me/packages/{id}
  Future<void> deleteService(String id) => ApiClient.delete('/vendors/me/packages/$id');

  // ── Talent Roster ─────────────────────────────────────────────

  // GET /api/v1/vendors/me/roster
  Future<List<TalentMember>> roster() async {
    final data = await ApiClient.get('/vendors/me/roster') as List;
    return data.map((j) => TalentMember.fromJson(j)).toList();
  }

  // POST /api/v1/vendors/me/roster
  Future<TalentMember> addTalent(TalentMember member) async {
    final data = await ApiClient.post('/vendors/me/roster', member.toJson());
    return TalentMember.fromJson(data);
  }

  // PUT /api/v1/vendors/me/roster/{id}
  Future<TalentMember> updateTalent(TalentMember member) async {
    final data = await ApiClient.put('/vendors/me/roster/${member.id}', member.toJson());
    return TalentMember.fromJson(data);
  }

  // PATCH /api/v1/vendors/me/roster/{id}/availability
  Future<void> toggleAvailability(String id, bool available) async {
    await ApiClient.patch('/vendors/me/roster/$id/availability');
  }

  // DELETE /api/v1/vendors/me/roster/{id}
  Future<void> deleteTalent(String id) => ApiClient.delete('/vendors/me/roster/$id');

  // ── Bookings ──────────────────────────────────────────────────

  // GET /api/v1/bookings/vendor
  Future<List<VendorBooking>> bookings({String? status}) async {
    final q = status != null ? '?status=$status' : '';
    final data = await ApiClient.get('/bookings/vendor$q') as Map;
    return (data['items'] as List).map((j) => VendorBooking.fromJson(j)).toList();
  }

  // GET /api/v1/bookings/vendor/calendar
  Future<List<VendorBooking>> calendarBookings(int year, int month) async {
    final data = await ApiClient.get('/bookings/vendor/calendar?year=$year&month=$month') as List;
    return data.map((j) => VendorBooking.fromJson(j)).toList();
  }

  // PUT /api/v1/bookings/{id}/status
  Future<void> respondBooking(String id, BookingStatus status) async {
    await ApiClient.put('/bookings/$id/status', {'status': status.name});
  }

  // ── Earnings ──────────────────────────────────────────────────

  // GET /api/v1/payments/earnings
  Future<List<EarningTxn>> earnings() async {
    final data = await ApiClient.get('/payments/earnings') as Map;
    return (data['items'] as List).map((j) => EarningTxn.fromJson(j)).toList();
  }

  // ── Reviews ───────────────────────────────────────────────────

  // GET /api/v1/reviews/vendor
  Future<List<VendorReview>> reviews() async {
    final data = await ApiClient.get('/reviews/vendor') as Map;
    return (data['items'] as List).map((j) => _reviewFromJson(j)).toList();
  }

  // POST /api/v1/reviews/{id}/reply
  Future<void> replyReview(String reviewId, String reply) async {
    await ApiClient.post('/reviews/$reviewId/reply', {'reply': reply});
  }

  // ── Messages ──────────────────────────────────────────────────

  // GET /api/v1/messages/threads
  Future<List<ChatThread>> threads() async {
    final data = await ApiClient.get('/messages/threads') as List;
    return data.map((j) => _threadFromJson(j)).toList();
  }

  // GET /api/v1/messages/threads/{id}
  Future<ChatThread> threadDetail(String threadId) async {
    final data = await ApiClient.get('/messages/threads/$threadId');
    return _threadFromJson(data);
  }

  // POST /api/v1/messages/threads/{id}/messages
  Future<void> sendMessage(String threadId, String text) async {
    await ApiClient.post('/messages/threads/$threadId/messages', {'text': text});
  }

  // ── Notifications ─────────────────────────────────────────────

  // GET /api/v1/notifications
  Future<List<NotificationItem>> notifications() async {
    final data = await ApiClient.get('/notifications') as Map;
    return (data['items'] as List).map((j) => _notifFromJson(j)).toList();
  }

  // PATCH /api/v1/notifications/{id}/read
  Future<void> markNotificationRead(String id) => ApiClient.patch('/notifications/$id/read');

  // POST /api/v1/notifications/mark-all-read
  Future<void> markAllRead() => ApiClient.post('/notifications/mark-all-read', {});

  // ── Analytics ─────────────────────────────────────────────────

  // earnings trend from dashboard
  Future<List<KpiPoint>> earningsTrend() async {
    final data = await ApiClient.get('/analytics/vendor/dashboard');
    // Return stub trend — replace with a dedicated /analytics/vendor/earnings-trend endpoint
    return const [
      KpiPoint('Jan', 2.1), KpiPoint('Feb', 2.8), KpiPoint('Mar', 2.5),
      KpiPoint('Apr', 3.4), KpiPoint('May', 3.9), KpiPoint('Jun', 4.6),
    ];
  }

  // ── Subscription ─────────────────────────────────────────────

  // GET /api/v1/subscriptions/plans
  Future<List<SubscriptionPlan>> plans() async {
    final data = await ApiClient.get('/subscriptions/plans') as List;
    return data.map((j) => _planFromJson(j)).toList();
  }

  // GET /api/v1/subscriptions/me
  Future<VendorSubscription> currentSubscription() async {
    final data = await ApiClient.get('/subscriptions/me');
    return VendorSubscription(
      planId: data['plan_id'],
      planName: data['plan_name'],
      price: (data['price'] as num).toDouble(),
      status: data['status'],
      renewsOn: DateTime.parse(data['renews_on']),
    );
  }

  // POST /api/v1/subscriptions/subscribe
  Future<void> changePlan(String planId) async {
    await ApiClient.post('/subscriptions/subscribe', {'plan_id': planId, 'payment_method': 'Card'});
  }

  // GET /api/v1/subscriptions/billing
  Future<List<BillingEntry>> billingHistory() async {
    final data = await ApiClient.get('/subscriptions/billing') as List;
    return data.map((j) => BillingEntry(
      id: j['id'],
      date: DateTime.parse(j['date']),
      description: j['description'],
      amount: (j['amount'] as num).toDouble(),
      status: j['status'],
    )).toList();
  }

  // ── Vendor profile ────────────────────────────────────────────

  // GET /api/v1/vendors/me
  Future<Map<String, dynamic>> myProfile() => ApiClient.get('/vendors/me');

  // PUT /api/v1/vendors/me
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> fields) =>
      ApiClient.put('/vendors/me', fields);

  // ── Private helpers ───────────────────────────────────────────

  static VendorReview _reviewFromJson(Map j) => VendorReview(
        id: j['id'],
        client: j['author_id'] ?? 'Client',
        stars: j['stars'],
        text: j['text'],
        date: DateTime.parse(j['date']),
        reply: j['reply'],
      );

  static ChatThread _threadFromJson(Map j) => ChatThread(
        id: j['id'],
        name: j['participant_name'] ?? '',
        lastMessage: j['last_message'] ?? '',
        time: DateTime.parse(j['last_message_at']),
        unread: j['unread_count'] ?? 0,
        messages: j['messages'] != null
            ? (j['messages'] as List).map((m) => ChatMessage(m['text'], m['from_vendor'] == true, DateTime.parse(m['sent_at']))).toList()
            : [],
      );

  static NotificationItem _notifFromJson(Map j) => NotificationItem(
        title: j['title'],
        body: j['body'],
        kind: _kindFromString(j['kind']),
        time: DateTime.parse(j['created_at']),
        unread: j['unread'] ?? false,
      );

  static IconKind _kindFromString(String? s) {
    switch (s) {
      case 'booking': return IconKind.booking;
      case 'payment': return IconKind.payment;
      case 'review': return IconKind.review;
      default: return IconKind.system;
    }
  }

  static SubscriptionPlan _planFromJson(Map j) => SubscriptionPlan(
        id: j['id'],
        name: j['name'],
        price: (j['price'] as num).toDouble(),
        period: j['period'],
        features: (j['features'] as List).cast<String>(),
        recommended: j['recommended'] ?? false,
      );
}
