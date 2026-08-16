import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/typography.dart';
import '../../core/responsive/responsive.dart';
import '../../core/category/vendor_category.dart';
import '../../core/utils/image_pick_util.dart';
import '../../core/widgets/common.dart';
import '../../data/api/api_client.dart';
import '../../data/api/api_errors.dart';
import '../../data/repositories/vendor_repository.dart';
import '../../data/upload_service.dart';
import 'profile_details_section.dart';

/// One portfolio work — mirrors the consumer app's gallery item shape.
class PortfolioWork {
  static const maxImages = 8;

  final String? id;
  String headline;
  String description;
  String tag;
  String emoji;
  String imageUrl;
  List<String> imageUrls;
  int bg;
  bool featured;
  PortfolioWork({
    this.id,
    required this.headline,
    required this.description,
    required this.tag,
    required this.emoji,
    this.imageUrl = '',
    List<String>? imageUrls,
    this.bg = 0,
    this.featured = false,
  }) : imageUrls = imageUrls ?? (imageUrl.isNotEmpty ? [imageUrl] : []);

  String get coverUrl => imageUrls.isNotEmpty ? imageUrls.first : imageUrl;

  factory PortfolioWork.fromJson(Map<String, dynamic> j) {
    final urls = (j['images'] as List?)
            ?.map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        <String>[];
    final legacy = (j['image_url'] as String?)?.trim() ?? '';
    final images = urls.isNotEmpty ? urls : (legacy.isNotEmpty ? [legacy] : <String>[]);
    return PortfolioWork(
      id: j['id'] as String?,
      headline: j['headline'] as String? ?? '',
      description: j['description'] as String? ?? '',
      tag: j['tag'] as String? ?? '',
      emoji: j['emoji'] as String? ?? '🖼️',
      imageUrl: images.isNotEmpty ? images.first : legacy,
      imageUrls: images,
      bg: (j['bg'] as num?)?.toInt() ?? 0,
      featured: j['featured'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final images = imageUrls.isNotEmpty ? imageUrls : (imageUrl.isNotEmpty ? [imageUrl] : <String>[]);
    return {
      'headline': headline,
      'description': description,
      'tag': tag,
      'emoji': emoji,
      'image_url': images.isNotEmpty ? images.first : imageUrl,
      'images': images,
      'bg': bg,
      'featured': featured,
    };
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _repo = VendorRepository();
  List<PortfolioWork> _works = [];
  Map<String, dynamic> _profileDetails = {};
  int _rosterCount = 0;

  bool _loading = true;
  bool _saving = false;
  String _error = '';
  double _rating = 0;
  int _totalBookings = 0;
  bool _kycVerified = false;
  String _plan = 'Starter';

  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  String _email = '';
  String _avatarUrl = '';
  List<String> _galleryUrls = [];
  static const _maxGalleryImages = 8;
  String _serverCategory = '';
  bool _avatarUploading = false;
  bool _galleryUploading = false;
  bool _uploadsReady = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  String _friendlyError(Object e) => friendlyApiError(e);

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final results = await Future.wait([
        _repo.myProfile(),
        _repo.portfolio(),
        _repo.profileDetails(),
        _repo.roster(),
        ApiClient.uploadsConfigured(),
      ]);
      final data = results[0] as Map<String, dynamic>;
      final portfolio = results[1] as List<Map<String, dynamic>>;
      final details = results[2] as Map<String, dynamic>;
      final roster = results[3] as List;
      final uploadsReady = results[4] as bool;
      if (!mounted) return;
      setState(() {
        _nameCtrl.text = (data['name'] ?? '') as String;
        _companyCtrl.text = (data['company'] ?? '') as String;
        _email = (data['email'] ?? '') as String;
        _phoneCtrl.text = (data['phone'] ?? '') as String;
        _cityCtrl.text = (data['city'] ?? '') as String;
        _bioCtrl.text = (data['bio'] ?? '') as String;
        _avatarUrl = (data['avatar_url'] ?? '') as String;
        _galleryUrls = ((data['gallery_urls'] as List?) ?? [])
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .take(_maxGalleryImages)
            .toList();
        _serverCategory = (data['category'] ?? '') as String;
        _rating = ((data['rating'] as num?) ?? 0).toDouble();
        _totalBookings = ((data['total_bookings'] as num?) ?? 0).toInt();
        _kycVerified = data['kyc_verified'] as bool? ?? false;
        _plan = (data['plan'] ?? 'Starter') as String;
        _works = portfolio.map(PortfolioWork.fromJson).toList();
        _profileDetails = details;
        _rosterCount = roster.length;
        _uploadsReady = uploadsReady;
        _loading = false;
      });
      VendorSession.setVendorFromProfile(data);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = _friendlyError(e); _loading = false; });
    }
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = ''; });
    try {
      await _repo.updateProfile({
        'name': _nameCtrl.text.trim(),
        'company': _companyCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'avatar_url': _avatarUrl,
        'gallery_urls': _galleryUrls,
      });
      VendorSession.setVendorFromProfile({
        'name': _nameCtrl.text.trim(),
        'company': _companyCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'category': _serverCategory,
      });
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('Profile saved');
    } catch (e) {
      if (!mounted) return;
      final msg = _friendlyError(e);
      setState(() { _error = msg; _saving = false; });
      _toast(msg.isEmpty ? 'Failed to save profile' : msg);
    }
  }

  Future<void> _toggleFeatured(PortfolioWork work) async {
    if (work.id == null) return;
    try {
      final updated = await _repo.togglePortfolioFeature(work.id!);
      if (!mounted) return;
      setState(() {
        final idx = _works.indexWhere((w) => w.id == work.id);
        if (idx != -1) _works[idx] = PortfolioWork.fromJson(updated);
      });
    } catch (e) {
      _toast(_friendlyError(e).isEmpty ? 'Failed to update work' : _friendlyError(e));
    }
  }

  Future<void> _deleteWork(PortfolioWork work) async {
    if (work.id == null) {
      setState(() => _works.remove(work));
      return;
    }
    try {
      await _repo.deletePortfolioItem(work.id!);
      if (!mounted) return;
      setState(() => _works.remove(work));
      _toast('Work removed from portfolio');
    } catch (e) {
      _toast(_friendlyError(e).isEmpty ? 'Failed to delete work' : _friendlyError(e));
    }
  }

  Future<String> _uploadBytes({
    required Uint8List bytes,
    required String filename,
    required String folder,
  }) async {
    _toast('Uploading photo…');
    final url = await UploadService.uploadImage(
      bytes: bytes,
      filename: filename,
      folder: folder,
    );
    return url;
  }

  Future<void> _pickAvatar() async {
    if (_avatarUploading) return;
    try {
      final picked = await pickImageFromGallery();
      if (picked == null) return;
      setState(() => _avatarUploading = true);
      final url = await _uploadBytes(
        bytes: picked.bytes,
        filename: 'avatar.${picked.extension}',
        folder: 'avatars',
      );
      if (!mounted) return;
      setState(() {
        _avatarUrl = url;
        _avatarUploading = false;
      });
      _toast('Profile photo uploaded — tap Save Changes to keep it');
    } catch (e) {
      if (mounted) setState(() => _avatarUploading = false);
      _toast(_friendlyError(e));
    }
  }

  Future<void> _addGalleryImage() async {
    if (_galleryUploading || _galleryUrls.length >= _maxGalleryImages) return;
    try {
      final picked = await pickImageFromGallery();
      if (picked == null) return;
      setState(() => _galleryUploading = true);
      final url = await _uploadBytes(
        bytes: picked.bytes,
        filename: 'gallery.${picked.extension}',
        folder: 'portfolio',
      );
      if (!mounted) return;
      setState(() {
        _galleryUrls = [..._galleryUrls, url].take(_maxGalleryImages).toList();
        _galleryUploading = false;
      });
      _toast('Gallery photo added — tap Save Changes to keep it');
    } catch (e) {
      if (mounted) setState(() => _galleryUploading = false);
      _toast(_friendlyError(e));
    }
  }

  void _removeGalleryImage(int index) {
    setState(() => _galleryUrls = [..._galleryUrls]..removeAt(index));
  }

  Widget _avatarWidget(double size) {
    if (_avatarUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => InitialsAvatar(name: _displayName, size: size),
        ),
      );
    }
    return InitialsAvatar(name: _displayName, size: size);
  }

  Widget _portfolioCover({required VendorCategoryConfig cfg, PortfolioWork? work, Uint8List? previewBytes, double emojiSize = 38}) {
    if (previewBytes != null) {
      return Image.memory(previewBytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
    final url = work?.coverUrl ?? '';
    if (url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [cfg.accent.withValues(alpha: 0.30), AppColors.surfaceAlt])),
          child: Center(child: Text(work?.emoji ?? '🖼️', style: TextStyle(fontSize: emojiSize))),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [cfg.accent.withValues(alpha: 0.30), AppColors.surfaceAlt])),
      child: Center(child: Text(work?.emoji ?? '🖼️', style: TextStyle(fontSize: emojiSize))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cfg = VendorSession.config;
    if (_loading) return const LoadingView();
    return ListView(
      padding: EdgeInsets.all(responsiveValue(context, mobile: 16, desktop: 28)),
      children: [
        FadeUp(
          child: PageHeader(
            eyebrow: '${cfg.label} · Portfolio',
            accent: cfg.accent,
            title: 'Profile & Portfolio',
            subtitle: 'Everything here is exactly how clients see you on the marketplace',
            actions: [
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1407)))
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_saving ? 'Saving…' : 'Save Changes'),
              ),
            ],
          ),
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
              const SizedBox(width: 8),
              Expanded(child: Text(_error, style: AppType.body(size: 12.5, color: AppColors.danger))),
            ]),
          ),
        ],
        if (!_uploadsReady) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.45)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.cloud_off_outlined, size: 16, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Photo uploads are disabled on the backend. Set CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, and CLOUDINARY_API_SECRET on Render, redeploy, then refresh this page.',
                  style: AppType.body(size: 12.5, color: AppColors.warning, height: 1.45),
                ),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 22),
        FadeUp(delay: const Duration(milliseconds: 90), child: _performanceStrip(cfg)),
        const SizedBox(height: 16),
        FadeUp(
          delay: const Duration(milliseconds: 150),
          child: ResponsiveLayout(
            mobile: (_) => Column(children: [
              _profileCard(context, cfg),
              const SizedBox(height: 16),
              _marketplacePreview(context, cfg),
              const SizedBox(height: 16),
              _portfolioManager(context, cfg),
              const SizedBox(height: 16),
              _profileDetailsSection(cfg),
            ]),
            desktop: (_) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 2, child: Column(children: [
                  _profileCard(context, cfg),
                  const SizedBox(height: 16),
                  _marketplacePreview(context, cfg),
                ])),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: _portfolioManager(context, cfg)),
              ]),
              const SizedBox(height: 16),
              _profileDetailsSection(cfg),
            ]),
          ),
        ),
      ],
    );
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Widget _profileDetailsSection(VendorCategoryConfig cfg) {
    return ProfileDetailsSection(
      cfg: cfg,
      initial: _profileDetails,
      onSave: (payload) async {
        final updated = await _repo.updateProfileDetails(payload);
        if (!mounted) return;
        setState(() => _profileDetails = updated);
        _toast('Profile details saved');
      },
    );
  }

  // ── Profile performance — real stats from the vendor account. ──
  Widget _performanceStrip(VendorCategoryConfig cfg) {
    final metrics = [
      ('Rating', _rating > 0 ? _rating.toStringAsFixed(1) : '—', Icons.star_outline, AppColors.gold, '$_totalBookings bookings'),
      ('Total bookings', '$_totalBookings', Icons.event_available_outlined, cfg.accent, _plan),
      ('Portfolio works', '${_works.length}', Icons.collections_outlined, AppColors.info, '${_works.where((w) => w.featured).length} featured'),
      ('KYC status', _kycVerified ? 'Verified' : 'Pending', Icons.verified_outlined, _kycVerified ? AppColors.success : AppColors.warning, _plan),
    ];
    final cols = responsiveValue(context, mobile: 2, tablet: 4, desktop: 4);
    return GridView.count(
      crossAxisCount: cols,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: responsiveValue(context, mobile: 2.1, tablet: 2.4, desktop: 2.4),
      children: [
        for (final m in metrics)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [m.$4.withValues(alpha: 0.10), AppColors.surface]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(children: [
                Icon(m.$3, size: 16, color: m.$4),
                const Spacer(),
                Text(m.$5, style: AppType.body(size: 11, weight: FontWeight.w700, color: AppColors.success)),
              ]),
              const SizedBox(height: 8),
              Text(m.$2, style: AppType.display(size: 21, weight: FontWeight.w600)),
              Text(m.$1.toUpperCase(), style: AppType.eyebrow(color: AppColors.textSecondary, size: 9.5)),
            ]),
          ),
      ],
    );
  }

  String get _displayName => _companyCtrl.text.trim().isNotEmpty ? _companyCtrl.text.trim() : 'Your business';

  String get _profileSubtitle {
    final city = _cityCtrl.text.trim();
    final cfg = VendorSession.config;
    return city.isEmpty ? cfg.label : '${cfg.label} · $city';
  }

  static const _unset = 'Not set yet';

  String _detailText(String key) {
    final v = (_profileDetails[key] as String?)?.trim() ?? '';
    return v.isEmpty ? _unset : v;
  }

  String _joinStrings(List<dynamic> items) {
    final values = items.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    return values.isEmpty ? _unset : values.join(', ');
  }

  List<MapEntry<String, String>> _profileSummaryFields(VendorCategoryConfig cfg) {
    final d = _profileDetails;
    final services = ((d['services'] as List?) ?? []).cast<dynamic>();
    final amenities = ((d['amenities'] as List?) ?? []).cast<dynamic>();
    final spaces = ((d['spaces'] as List?) ?? []).cast<Map>();
    final equipment = ((d['equipment'] as List?) ?? []).cast<Map>();
    final tags = ((d['tags'] as List?) ?? []).cast<dynamic>();

    String specialities() {
      if (tags.isNotEmpty) return _joinStrings(tags);
      if (services.isNotEmpty) return _joinStrings(services);
      return _unset;
    }

    switch (cfg.category) {
      case VendorCategory.talent:
        return [
          MapEntry('Roster size', _rosterCount > 0 ? '$_rosterCount on roster' : _unset),
          MapEntry('Specialities', specialities()),
          MapEntry('Languages', _detailText('languages')),
          MapEntry('Experience', _detailText('experience')),
        ];
      case VendorCategory.photography:
      case VendorCategory.videography:
        final gear = equipment
            .map((e) => (e['name'] as String?)?.trim() ?? '')
            .where((s) => s.isNotEmpty)
            .take(4)
            .join(', ');
        return [
          MapEntry('Primary gear', gear.isEmpty ? _unset : gear),
          MapEntry('Specialities', specialities()),
          MapEntry('Experience', _detailText('experience')),
        ];
      case VendorCategory.venue:
        return [
          MapEntry('Spaces listed', spaces.isEmpty ? _unset : '${spaces.length} space${spaces.length == 1 ? '' : 's'}'),
          MapEntry('Amenities', _joinStrings(amenities)),
          MapEntry('Overview', _detailText('overview')),
        ];
      case VendorCategory.events:
        return [
          MapEntry('Team on roster', _rosterCount > 0 ? '$_rosterCount crew' : _unset),
          MapEntry('Services managed', _joinStrings(services)),
          MapEntry('Experience', _detailText('experience')),
        ];
    }
  }

  Widget _profileCard(BuildContext context, VendorCategoryConfig cfg) {
    return SectionCard(
      title: 'Business Profile',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Column(children: [
            GestureDetector(
              onTap: _avatarUploading ? null : _pickAvatar,
              child: Stack(children: [
                _avatarWidget(84),
                if (_avatarUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
                    ),
                  ),
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: cfg.accent, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, size: 14, color: Color(0xFF1A1407)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 6),
            Text('Tap photo for profile picture', style: AppType.body(size: 11, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Profile gallery (up to $_maxGalleryImages photos)', style: AppType.body(size: 12.5, weight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            Text('Shown on your public profile alongside your main photo.', style: AppType.body(size: 11.5, color: AppColors.textMuted, height: 1.4)),
            const SizedBox(height: 10),
            _imageUrlGrid(
              urls: _galleryUrls,
              uploading: _galleryUploading,
              maxCount: _maxGalleryImages,
              onAdd: _addGalleryImage,
              onRemove: _removeGalleryImage,
            ),
            const SizedBox(height: 12),
            Text(_displayName, style: AppType.display(size: 17, weight: FontWeight.w600)),
            Text(_profileSubtitle, style: AppType.body(color: AppColors.textMuted, size: 13)),
            const SizedBox(height: 8),
            StatusChip(
              label: _kycVerified ? 'KYC Verified' : 'KYC Pending',
              color: _kycVerified ? AppColors.success : AppColors.warning,
            ),
          ]),
        ),
        const Divider(height: 32),
        _Field(label: 'Contact name', controller: _nameCtrl),
        _Field(label: 'Business name', controller: _companyCtrl),
        _Field(label: 'Contact email', value: _email, enabled: false),
        _Field(label: 'Phone', controller: _phoneCtrl),
        _Field(label: 'City', controller: _cityCtrl),
        for (final f in _profileSummaryFields(cfg))
          _Field(label: f.key, value: f.value, enabled: false),
        _Field(label: 'About', controller: _bioCtrl, lines: 3),
      ]),
    );
  }

  /// Live mini-render of the consumer marketplace listing card.
  Widget _marketplacePreview(BuildContext context, VendorCategoryConfig cfg) {
    return SectionCard(
      title: 'Marketplace Preview',
      actions: [StatusChip(label: 'Live', color: AppColors.success)],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How your card appears to users browsing AOneGo9.', style: AppType.body(size: 12.5, color: AppColors.textMuted)),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 132,
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [cfg.accent.withValues(alpha: 0.32), AppColors.surface])),
              child: Stack(children: [
                Center(child: Icon(cfg.icon, size: 46, color: cfg.accent.withValues(alpha: 0.85))),
                Positioned(top: 10, left: 10, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xCC09090B), borderRadius: BorderRadius.circular(20)),
                  child: Text(cfg.label.toUpperCase(), style: AppType.eyebrow(color: cfg.accent, size: 9)),
                )),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(_displayName, style: AppType.display(size: 16, weight: FontWeight.w600))),
                  const Icon(Icons.verified, size: 16, color: AppColors.gold),
                ]),
                const SizedBox(height: 3),
                Text(_profileSubtitle, style: AppType.body(size: 12, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.star, size: 14, color: AppColors.gold),
                  const SizedBox(width: 4),
                  Text(_rating > 0 ? _rating.toStringAsFixed(1) : 'New', style: AppType.body(size: 12.5, weight: FontWeight.w700)),
                  Text('  ·  $_totalBookings bookings', style: AppType.body(size: 12, color: AppColors.textMuted)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: cfg.accent, borderRadius: BorderRadius.circular(8)),
                    child: Text('Enquire', style: AppType.body(size: 12, weight: FontWeight.w700, color: const Color(0xFF1A1407))),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── The SaaS portfolio manager ──
  Widget _portfolioManager(BuildContext context, VendorCategoryConfig cfg) {
    final cols = responsiveValue(context, mobile: 1, tablet: 2, desktop: 2);
    final featured = _works.where((w) => w.featured).length;
    return SectionCard(
      title: 'Portfolio',
      actions: [
        Text('${_works.length} works · $featured featured', style: AppType.body(size: 12, color: AppColors.textMuted)),
        const SizedBox(width: 12),
        ElevatedButton.icon(onPressed: () => _editWork(cfg, null), icon: const Icon(Icons.add, size: 16), label: const Text('Add work')),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Each work shows a cover, a category tag and a description underneath — exactly as it renders in the user app gallery. Drag the star to feature your best work first.',
            style: AppType.body(size: 12.5, color: AppColors.textMuted, height: 1.5)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.18,
          children: [
            for (var i = 0; i < _sorted.length; i++) _workCard(cfg, _sorted[i]),
            _addCard(cfg),
          ],
        ),
      ]),
    );
  }

  List<PortfolioWork> get _sorted {
    final list = [..._works];
    list.sort((a, b) => (b.featured ? 1 : 0).compareTo(a.featured ? 1 : 0));
    return list;
  }

  Widget _workCard(VendorCategoryConfig cfg, PortfolioWork w) {
    return HoverFx(
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: h ? cfg.accent.withValues(alpha: 0.5) : AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cover
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              _portfolioCover(cfg: cfg, work: w),
              Positioned(top: 9, left: 9, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xCC09090B), borderRadius: BorderRadius.circular(20)),
                child: Text(w.tag.toUpperCase(), style: AppType.eyebrow(color: cfg.accent, size: 8.5)),
              )),
              if (w.imageUrls.length > 1)
                Positioned(
                  bottom: 9,
                  right: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xCC09090B), borderRadius: BorderRadius.circular(20)),
                    child: Text('${w.imageUrls.length} photos', style: AppType.body(size: 10, weight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              Positioned(top: 6, right: 6, child: IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: w.featured ? 'Featured' : 'Feature this',
                icon: Icon(w.featured ? Icons.star : Icons.star_border, size: 18, color: w.featured ? AppColors.gold : Colors.white70),
                onPressed: () => _toggleFeatured(w),
              )),
            ]),
          ),
          // Headline + description underneath (the explicit ask)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(w.headline, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.body(size: 13.5, weight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(w.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppType.body(size: 11.5, color: AppColors.textMuted, height: 1.4)),
              const SizedBox(height: 8),
              Row(children: [
                _miniBtn(Icons.edit_outlined, 'Edit', () => _editWork(cfg, w)),
                const SizedBox(width: 8),
                _miniBtn(Icons.delete_outline, 'Delete', () => _deleteWork(w), danger: true),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _addCard(VendorCategoryConfig cfg) {
    return HoverFx(
      onTap: () => _editWork(cfg, null),
      builder: (h) => DottedPanel(
        active: h,
        accent: cfg.accent,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_photo_alternate_outlined, size: 30, color: h ? cfg.accent : AppColors.textMuted),
          const SizedBox(height: 8),
          Text('Add a work', style: AppType.body(size: 13, weight: FontWeight.w600, color: h ? cfg.accent : AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text('Image · headline · description', style: AppType.body(size: 11, color: AppColors.textMuted)),
        ]),
      ),
    );
  }

  Widget _miniBtn(IconData icon, String label, VoidCallback onTap, {bool danger = false}) {
    final c = danger ? AppColors.danger : AppColors.textSecondary;
    return HoverFx(
      onTap: onTap,
      builder: (h) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: h ? c.withValues(alpha: 0.12) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: h ? c.withValues(alpha: 0.4) : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 5),
          Text(label, style: AppType.body(size: 11.5, weight: FontWeight.w600, color: c)),
        ]),
      ),
    );
  }

  Widget _imageUrlGrid({
    required List<String> urls,
    required bool uploading,
    required int maxCount,
    required VoidCallback onAdd,
    required void Function(int index) onRemove,
  }) {
    final cols = responsiveValue(context, mobile: 3, tablet: 4, desktop: 4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: urls.length + (urls.length < maxCount ? 1 : 0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemBuilder: (_, i) {
            if (i == urls.length) {
              return OutlinedButton(
                onPressed: uploading ? null : onAdd,
                style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(72, 72)),
                child: uploading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.add_photo_alternate_outlined, size: 22),
                        const SizedBox(height: 4),
                        Text('Add', style: AppType.body(size: 10, color: AppColors.textMuted)),
                      ]),
              );
            }
            final url = urls[i];
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.surfaceAlt)),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => onRemove(i),
                      child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, size: 14, color: Colors.white)),
                    ),
                  ),
                ),
                if (i == 0)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(6)),
                      child: Text('Cover', style: AppType.body(size: 9, weight: FontWeight.w800, color: const Color(0xFF1A1407))),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        Text('${urls.length}/$maxCount photos', style: AppType.body(size: 11, color: AppColors.textMuted)),
      ],
    );
  }

  // Add / edit a work via a sheet, with the same fields the user app renders.
  void _editWork(VendorCategoryConfig cfg, PortfolioWork? existing) {
    final headline = TextEditingController(text: existing?.headline ?? '');
    final desc = TextEditingController(text: existing?.description ?? '');
    final tag = TextEditingController(text: existing?.tag ?? '');
    final emoji = TextEditingController(text: existing?.emoji ?? cfg.label.characters.first);
    bool featured = existing?.featured ?? false;
    List<String> imageUrls = [...(existing?.imageUrls ?? <String>[])];
    bool uploading = false;

    Future<void> addWorkPhoto(void Function(void Function()) setLocal) async {
      if (uploading || imageUrls.length >= PortfolioWork.maxImages) return;
      try {
        _toast('Choose a photo…');
        final picked = await pickImageFromGallery();
        if (picked == null) {
          _toast('No photo selected');
          return;
        }
        if (!mounted) return;
        setLocal(() => uploading = true);
        final url = await _uploadBytes(
          bytes: picked.bytes,
          filename: 'portfolio.${picked.extension}',
          folder: 'portfolio',
        );
        if (!mounted) return;
        setLocal(() {
          imageUrls = [...imageUrls, url].take(PortfolioWork.maxImages).toList();
          uploading = false;
        });
        _toast('Photo added (${imageUrls.length}/${PortfolioWork.maxImages})');
      } catch (e) {
        if (mounted) setLocal(() => uploading = false);
        _toast(_friendlyError(e));
      }
    }

    PortfolioWork? previewWork() {
      if (imageUrls.isEmpty) return existing;
      return PortfolioWork(
        headline: headline.text,
        description: desc.text,
        tag: tag.text,
        emoji: emoji.text,
        imageUrls: imageUrls,
        featured: featured,
      );
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: StatefulBuilder(
        builder: (ctx, setLocal) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              Text(existing == null ? 'Add portfolio work' : 'Edit work', style: AppType.display(size: 20, weight: FontWeight.w600)),
              const SizedBox(height: 16),
              _dlgLabel('Photos (up to ${PortfolioWork.maxImages}, first is cover)'),
              _imageUrlGrid(
                urls: imageUrls,
                uploading: uploading,
                maxCount: PortfolioWork.maxImages,
                onAdd: () => addWorkPhoto(setLocal),
                onRemove: (i) => setLocal(() => imageUrls = [...imageUrls]..removeAt(i)),
              ),
              if (imageUrls.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: _portfolioCover(cfg: cfg, work: previewWork(), emojiSize: 48),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _dlgLabel('Headline'),
              TextField(controller: headline, decoration: const InputDecoration(hintText: 'e.g. Vogue India Editorial')),
              const SizedBox(height: 14),
              _dlgLabel('Description (shown under the image)'),
              TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(hintText: 'What the project was, where, and your role…')),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _dlgLabel('Category tag'),
                  TextField(controller: tag, decoration: const InputDecoration(hintText: 'Editorial')),
                ])),
                const SizedBox(width: 12),
                SizedBox(width: 96, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _dlgLabel('Fallback emoji'),
                  TextField(controller: emoji, textAlign: TextAlign.center, decoration: const InputDecoration(hintText: '📷')),
                ])),
              ]),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: cfg.accent,
                value: featured,
                onChanged: (v) => setLocal(() => featured = v),
                title: Text('Feature on profile', style: AppType.body(size: 13, weight: FontWeight.w600)),
                subtitle: Text('Featured works appear first', style: AppType.body(size: 11, color: AppColors.textMuted)),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: uploading ? null : () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: uploading ? null : () async {
                      if (headline.text.trim().isEmpty) {
                        _toast('Headline is required');
                        return;
                      }
                      setLocal(() => uploading = true);
                      try {
                        final payload = {
                          'headline': headline.text.trim(),
                          'description': desc.text.trim(),
                          'tag': tag.text.trim().isEmpty ? cfg.label : tag.text.trim(),
                          'emoji': emoji.text.trim().isEmpty ? '🖼️' : emoji.text.trim(),
                          'images': imageUrls,
                          'image_url': imageUrls.isNotEmpty ? imageUrls.first : '',
                          'featured': featured,
                        };
                        if (existing == null) {
                          final created = await _repo.createPortfolioItem(payload);
                          if (!mounted) return;
                          setState(() => _works.add(PortfolioWork.fromJson(created)));
                        } else if (existing.id != null) {
                          final updated = await _repo.updatePortfolioItem(existing.id!, payload);
                          if (!mounted) return;
                          setState(() {
                            final idx = _works.indexWhere((w) => w.id == existing.id);
                            if (idx != -1) _works[idx] = PortfolioWork.fromJson(updated);
                          });
                        }
                        if (!context.mounted) return;
                        Navigator.pop(ctx);
                        _toast(existing == null ? 'Work added to your portfolio' : 'Work updated');
                      } catch (e) {
                        setLocal(() => uploading = false);
                        _toast(_friendlyError(e));
                      }
                    },
                    child: uploading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1407)))
                        : Text(existing == null ? 'Add work' : 'Save'),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
      ),
    );
  }

  Widget _dlgLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(t, style: AppType.body(size: 12.5, weight: FontWeight.w600)),
      );
}

/// Dashed-look "add" panel.
class DottedPanel extends StatelessWidget {
  final Widget child;
  final bool active;
  final Color accent;
  const DottedPanel({super.key, required this.child, required this.active, required this.accent});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: active ? accent.withValues(alpha: 0.06) : AppColors.surfaceAlt.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? accent.withValues(alpha: 0.5) : AppColors.border),
      ),
      child: Center(child: child),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String? value;
  final TextEditingController? controller;
  final int lines;
  final bool enabled;
  const _Field({required this.label, this.value, this.controller, this.lines = 1, this.enabled = true})
      : assert(value != null || controller != null, 'Provide either a static value or a controller');
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppType.body(weight: FontWeight.w600, size: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller ?? TextEditingController(text: value),
          maxLines: lines,
          enabled: enabled,
        ),
      ]),
    );
  }
}
