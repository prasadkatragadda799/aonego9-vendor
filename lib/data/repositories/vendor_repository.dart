import '../models/models.dart';
import '../api/api_client.dart';
import '../../core/category/vendor_category.dart';

/// ───────────────────────────────────────────────────────────────
/// VENDOR REPOSITORY — every method calls the FastAPI backend.
/// Base URL is configured in api_client.dart (kBaseUrl).
///
/// Lists go through [ApiClient.asList], which accepts a bare array or a page
/// envelope; a hard `as List` cast here used to throw on the envelope and
/// blank the screen.
/// ───────────────────────────────────────────────────────────────
class VendorRepository {
  // ── Auth ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = ApiClient.asMap(
      await ApiClient.post('/auth/login/vendor', {'email': email, 'password': password}, auth: false),
    );
    await ApiClient.saveTokens('${data['access_token']}', '${data['refresh_token'] ?? ''}');
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String company,
    required String email,
    required String password,
    String phone = '',
    String phoneOtp = '',
    String city = '',
    String category = '',
  }) async {
    final data = ApiClient.asMap(await ApiClient.post('/auth/register/vendor', {
      'name': name,
      'company': company,
      'email': email,
      'password': password,
      'phone': phone,
      'city': city,
      'category': category,
      if (phoneOtp.isNotEmpty) 'phone_otp': phoneOtp,
    }, auth: false));
    await ApiClient.saveTokens('${data['access_token']}', '${data['refresh_token'] ?? ''}');
    return data;
  }

  Future<Map<String, dynamic>> sendOtp(String phone, {String purpose = 'vendor_register'}) async {
    return ApiClient.asMap(
      await ApiClient.post('/auth/otp/send', {'phone': phone, 'purpose': purpose}, auth: false),
    );
  }

  Future<void> logout() async {
    await ApiClient.clearTokens();
    VendorSession.reset();
  }

  // ── Dashboard ─────────────────────────────────────────────────

  // GET /api/v1/analytics/vendor/dashboard
  Future<Map<String, num>> dashboardSummary() async {
    final data = ApiClient.asMap(await ApiClient.get('/analytics/vendor/dashboard'));
    // Every field is optional. A brand-new vendor legitimately has no
    // bookings and no rating, and an unguarded cast would crash the first
    // screen after sign-in rather than showing zeroes.
    num n(String key) {
      final v = data[key];
      return v is num ? v : num.tryParse('${v ?? ''}') ?? 0;
    }

    return {
      'pendingRequests': n('pending_requests'),
      'upcoming': n('active_bookings'),
      'monthEarnings': n('total_earned'),
      'pendingPayout': n('pending_payout'),
      'completed': n('completed_bookings'),
      'rating': n('average_rating'),
      'reviews': n('total_reviews'),
    };
  }

  // GET /api/v1/analytics/vendor/earnings-trend
  Future<List<KpiPoint>> earningsTrend() async {
    final data = await ApiClient.get('/analytics/vendor/earnings-trend');
    return ApiClient.asList(data, 'points').map((j) {
      final v = j['value'];
      return KpiPoint('${j['label'] ?? ''}', v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
    }).toList();
  }

  // ── Services / Packages ───────────────────────────────────────

  // GET /api/v1/vendors/me/packages
  Future<List<ServicePackage>> services() async {
    return ApiClient.asList(await ApiClient.get('/vendors/me/packages')).map(ServicePackage.fromJson).toList();
  }

  // POST /api/v1/vendors/me/packages
  Future<ServicePackage> createService(ServicePackage pkg) async {
    final body = pkg.toJson();
    return ServicePackage.fromJson(ApiClient.asMap(await ApiClient.post('/vendors/me/packages', body)));
  }

  // PUT /api/v1/vendors/me/packages/{id}
  Future<ServicePackage> updateService(ServicePackage pkg) async {
    return ServicePackage.fromJson(ApiClient.asMap(await ApiClient.put('/vendors/me/packages/${pkg.id}', pkg.toJson())));
  }

  // PATCH /api/v1/vendors/me/packages/{id}/toggle
  Future<void> toggleService(String id) async {
    await ApiClient.patch('/vendors/me/packages/$id/toggle');
  }

  // DELETE /api/v1/vendors/me/packages/{id}
  Future<void> deleteService(String id) => ApiClient.delete('/vendors/me/packages/$id');

  // ── Talent Roster ─────────────────────────────────────────────

  // GET /api/v1/vendors/me/roster
  Future<List<TalentMember>> roster() async {
    return ApiClient.asList(await ApiClient.get('/vendors/me/roster')).map(TalentMember.fromJson).toList();
  }

  // POST /api/v1/vendors/me/roster
  Future<TalentMember> addTalent(TalentMember member) async {
    final body = member.toJson();
    return TalentMember.fromJson(ApiClient.asMap(await ApiClient.post('/vendors/me/roster', body)));
  }

  // PUT /api/v1/vendors/me/roster/{id}
  Future<TalentMember> updateTalent(TalentMember member) async {
    return TalentMember.fromJson(ApiClient.asMap(await ApiClient.put('/vendors/me/roster/${member.id}', member.toJson())));
  }

  // PATCH /api/v1/vendors/me/roster/{id}/availability
  Future<void> toggleAvailability(String id) async {
    await ApiClient.patch('/vendors/me/roster/$id/availability');
  }

  // DELETE /api/v1/vendors/me/roster/{id}
  Future<void> deleteTalent(String id) => ApiClient.delete('/vendors/me/roster/$id');

  // ── Bookings ──────────────────────────────────────────────────

  // GET /api/v1/bookings/vendor
  Future<List<VendorBooking>> bookings({String? status}) async {
    final q = status != null ? '?status=${Uri.encodeQueryComponent(status)}' : '';
    final list = (await ApiClient.getAllPages('/bookings/vendor$q')).map(VendorBooking.fromJson).toList();
    // Soonest first — what a vendor needs to act on next.
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  // GET /api/v1/bookings/vendor/calendar
  Future<List<VendorBooking>> calendarBookings(int year, int month) async {
    return ApiClient.asList(await ApiClient.get('/bookings/vendor/calendar?year=$year&month=$month'))
        .map(VendorBooking.fromJson)
        .toList();
  }

  // PUT /api/v1/bookings/{id}/status
  Future<void> respondBooking(String id, BookingStatus status) async {
    await ApiClient.put('/bookings/$id/status', {'status': status.name});
  }

  // PUT /api/v1/bookings/{id}/quote — price an inquiry (they arrive at ₹0).
  Future<void> setQuote(String id, double amount) async {
    await ApiClient.put('/bookings/$id/quote', {'amount': amount});
  }

  // ── Earnings ──────────────────────────────────────────────────

  // GET /api/v1/payments/earnings
  Future<List<EarningTxn>> earnings() async {
    final list = (await ApiClient.getAllPages('/payments/earnings')).map(EarningTxn.fromJson).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // ── Reviews ───────────────────────────────────────────────────

  // GET /api/v1/reviews/vendor
  Future<List<VendorReview>> reviews() async {
    final list = (await ApiClient.getAllPages('/reviews/vendor')).map(VendorReview.fromJson).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // POST /api/v1/reviews/{id}/reply
  Future<void> replyReview(String reviewId, String reply) async {
    await ApiClient.post('/reviews/$reviewId/reply', {'reply': reply});
  }

  // ── Messages ──────────────────────────────────────────────────

  // GET /api/v1/messages/threads
  Future<List<ChatThread>> threads() async {
    final list = ApiClient.asList(await ApiClient.get('/messages/threads')).map(ChatThread.fromJson).toList();
    list.sort((a, b) => b.time.compareTo(a.time));
    return list;
  }

  // GET /api/v1/messages/threads/{id}
  Future<ChatThread> threadDetail(String threadId) async {
    final t = ChatThread.fromJson(ApiClient.asMap(await ApiClient.get('/messages/threads/$threadId')));
    final msgs = [...t.messages]..sort((a, b) => a.time.compareTo(b.time));
    return t.copyWith(messages: msgs);
  }

  // POST /api/v1/messages/threads/{id}/messages
  Future<void> sendMessage(String threadId, String text) async {
    await ApiClient.post('/messages/threads/$threadId/messages', {'text': text});
  }

  // ── Notifications ─────────────────────────────────────────────

  // GET /api/v1/notifications
  Future<List<NotificationItem>> notifications() async {
    final list = ApiClient.asList(await ApiClient.get('/notifications')).map(NotificationItem.fromJson).toList();
    list.sort((a, b) => b.time.compareTo(a.time));
    return list;
  }

  /// Unread count for the shell's bell. Never throws — a failed badge must
  /// not break the header.
  Future<int> unreadNotifications() async {
    try {
      return (await notifications()).where((n) => n.unread).length;
    } catch (_) {
      return 0;
    }
  }

  // PATCH /api/v1/notifications/{id}/read
  Future<void> markNotificationRead(String id) => ApiClient.patch('/notifications/$id/read');

  // POST /api/v1/notifications/mark-all-read
  Future<void> markAllRead() => ApiClient.post('/notifications/mark-all-read', {});

  // ── Subscription ─────────────────────────────────────────────

  // GET /api/v1/subscriptions/plans?audience=vendor
  Future<List<SubscriptionPlan>> plans({bool auth = true}) async {
    final list = ApiClient.asList(await ApiClient.get('/subscriptions/plans?audience=vendor', auth: auth))
        .map(SubscriptionPlan.fromJson)
        .where((p) => p.audience == 'vendor' || p.audience == 'both')
        .toList();
    list.sort((a, b) => a.price.compareTo(b.price));
    return list;
  }

  // GET /api/v1/subscriptions/me — returns null if the vendor has no active
  // subscription yet (backend responds 404 in that case).
  Future<VendorSubscription?> currentSubscription() async {
    try {
      final data = ApiClient.asMap(await ApiClient.get('/subscriptions/me'));
      if (data.isEmpty) return null;
      final renews = DateTime.tryParse('${data['renews_on'] ?? ''}');
      return VendorSubscription(
        planId: '${data['plan_id'] ?? ''}',
        planName: '${data['plan_name'] ?? 'Plan'}',
        price: (data['price'] as num?)?.toDouble() ?? 0,
        status: '${data['status'] ?? 'active'}',
        renewsOn: renews ?? DateTime.now().add(const Duration(days: 30)),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  // GET /api/v1/subscriptions/payment-info
  Future<PaymentSettings> paymentInfo() async {
    return PaymentSettings.fromJson(ApiClient.asMap(await ApiClient.get('/subscriptions/payment-info')));
  }

  // POST /api/v1/subscriptions/request
  Future<SubscriptionRequest> requestSubscription(String planId, String receiptImageUrl) async {
    final data = await ApiClient.post('/subscriptions/request', {
      'plan_id': planId,
      'receipt_image': receiptImageUrl,
    });
    return SubscriptionRequest.fromJson(ApiClient.asMap(data));
  }

  // GET /api/v1/subscriptions/requests/mine
  Future<List<SubscriptionRequest>> myRequests() async {
    final list = ApiClient.asList(await ApiClient.get('/subscriptions/requests/mine'))
        .map(SubscriptionRequest.fromJson)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // GET /api/v1/subscriptions/billing
  Future<List<BillingEntry>> billingHistory() async {
    final list = ApiClient.asList(await ApiClient.get('/subscriptions/billing')).map(BillingEntry.fromJson).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // ── Vendor profile ────────────────────────────────────────────

  // GET /api/v1/vendors/me
  Future<Map<String, dynamic>> myProfile() async {
    return ApiClient.asMap(await ApiClient.get('/vendors/me'));
  }

  // PUT /api/v1/vendors/me
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> fields) async {
    return ApiClient.asMap(await ApiClient.put('/vendors/me', fields));
  }

  // ── Portfolio ─────────────────────────────────────────────────

  // GET /api/v1/vendors/me/portfolio
  Future<List<Map<String, dynamic>>> portfolio() async {
    return ApiClient.asList(await ApiClient.get('/vendors/me/portfolio'));
  }

  // POST /api/v1/vendors/me/portfolio
  Future<Map<String, dynamic>> createPortfolioItem(Map<String, dynamic> item) async {
    return ApiClient.asMap(await ApiClient.post('/vendors/me/portfolio', item));
  }

  // PUT /api/v1/vendors/me/portfolio/{id}
  Future<Map<String, dynamic>> updatePortfolioItem(String id, Map<String, dynamic> item) async {
    return ApiClient.asMap(await ApiClient.put('/vendors/me/portfolio/$id', item));
  }

  // PATCH /api/v1/vendors/me/portfolio/{id}/feature
  Future<Map<String, dynamic>> togglePortfolioFeature(String id) async {
    return ApiClient.asMap(await ApiClient.patch('/vendors/me/portfolio/$id/feature'));
  }

  // DELETE /api/v1/vendors/me/portfolio/{id}
  Future<void> deletePortfolioItem(String id) => ApiClient.delete('/vendors/me/portfolio/$id');

  // ── Profile details ─────────────────────────────────────────────

  Future<Map<String, dynamic>> profileDetails() async {
    return ApiClient.asMap(await ApiClient.get('/vendors/me/profile-details'));
  }

  Future<Map<String, dynamic>> updateProfileDetails(Map<String, dynamic> body) async {
    return ApiClient.asMap(await ApiClient.put('/vendors/me/profile-details', body));
  }

  // ── Requests to the AOneGo9 desk ──────────────────────────────
  //
  // Payout requests, KYC documents, support questions and password resets
  // all land in the super-admin console's "Leads & Applications" inbox, the
  // same channel the user app's Contact / Apply forms use. Each request is
  // stamped with the vendor's identity so the desk can act on it without a
  // back-and-forth. Mirrors UserRepository.submitLead: falls back to the
  // contribution endpoint so a request is never silently dropped.

  Future<void> sendToDesk(String kind, {required String message, Map<String, dynamic> extra = const {}}) async {
    final body = <String, dynamic>{
      'kind': kind,
      'name': VendorSession.contactName.isNotEmpty ? VendorSession.contactName : VendorSession.vendorName,
      'email': VendorSession.email,
      'phone': VendorSession.phone,
      'city': VendorSession.vendorCity,
      'message': message,
      'source': 'vendor_console',
      'vendor_id': VendorSession.vendorId,
      'company': VendorSession.vendorName,
      'category': VendorSession.config.label,
      ...extra,
    };
    // Sent WITH the vendor's token: the backend takes vendor_id from the
    // token, not the body, so the desk can trust who is asking.
    try {
      await ApiClient.post('/browse/leads', body);
      return;
    } on ApiException catch (e) {
      if (!e.isMissingRoute) rethrow;
    }
    await ApiClient.post('/browse/newsletter/contribute', body, auth: false);
  }

  /// Anonymous variant for the sign-in page (forgot password), where there
  /// is no session to stamp the request with.
  Future<void> requestPasswordReset(String email) async {
    final body = <String, dynamic>{
      'kind': 'password_reset',
      'name': email.split('@').first,
      'email': email,
      'message': 'Vendor console password reset requested for $email.',
      'source': 'vendor_console',
    };
    try {
      await ApiClient.post('/browse/leads', body, auth: false);
      return;
    } on ApiException catch (e) {
      if (!e.isMissingRoute) rethrow;
    }
    await ApiClient.post('/browse/newsletter/contribute', body, auth: false);
  }
}
