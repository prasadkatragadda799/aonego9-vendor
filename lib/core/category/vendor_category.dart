import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// ───────────────────────────────────────────────────────────────
/// VENDOR CATEGORY SYSTEM
///
/// A vendor's category (chosen at sign-up) reshapes the whole console
/// so every vendor type — talent agency, photographer, videographer,
/// venue, event service — sees terminology, screens and seed data that
/// match their business. Mirrors the category-aware vendor flow in the
/// user app so the three apps stay on one design line.
/// ───────────────────────────────────────────────────────────────
enum VendorCategory { talent, photography, videography, venue, events }

/// Per-category configuration consumed by every screen.
class VendorCategoryConfig {
  final VendorCategory category;
  final String label; // vendor-type display name, e.g. "Talent Agency"
  final Color accent;
  final IconData icon;

  // Roster / inventory section ("Talent Roster" for talent, "Spaces" for venue…)
  final bool hasRoster;
  final String rosterLabel; // nav + page title
  final IconData rosterIcon;
  final String rosterSubtitle;
  final String rosterAddLabel;
  final String rosterNameHeader; // "Name" / "Space"
  final String rosterRoleHeader; // "Role" / "Type" / "Specialty"
  final String rosterRateHeader; // "Day Rate" / "Rate"
  final String rosterCountHeader; // "Shoots" / "Events" / "Projects"

  // Services / packages section
  final String servicesLabel;
  final String servicesSubtitle;
  final String serviceUnitHint; // "per shoot" / "per day" / "per event"
  final String serviceCategoryHint;

  // Dashboard
  final String activeMetricLabel; // "Active Talent" / "Bookable Spaces" / "Crew on call"
  final IconData activeMetricIcon;

  // Login / brand
  final String loginTagline;

  /// Relabel and re-tint an archetype for a specific marketplace category.
  /// Only these two vary — everything else IS the console shape.
  VendorCategoryConfig copyWith({String? label, Color? accent}) => VendorCategoryConfig(
        category: category,
        label: label ?? this.label,
        accent: accent ?? this.accent,
        icon: icon,
        hasRoster: hasRoster,
        rosterLabel: rosterLabel,
        rosterIcon: rosterIcon,
        rosterSubtitle: rosterSubtitle,
        rosterAddLabel: rosterAddLabel,
        rosterNameHeader: rosterNameHeader,
        rosterRoleHeader: rosterRoleHeader,
        rosterRateHeader: rosterRateHeader,
        rosterCountHeader: rosterCountHeader,
        servicesLabel: servicesLabel,
        servicesSubtitle: servicesSubtitle,
        serviceUnitHint: serviceUnitHint,
        serviceCategoryHint: serviceCategoryHint,
        activeMetricLabel: activeMetricLabel,
        activeMetricIcon: activeMetricIcon,
        loginTagline: loginTagline,
      );

  const VendorCategoryConfig({
    required this.category,
    required this.label,
    required this.accent,
    required this.icon,
    required this.hasRoster,
    required this.rosterLabel,
    required this.rosterIcon,
    required this.rosterSubtitle,
    required this.rosterAddLabel,
    required this.rosterNameHeader,
    required this.rosterRoleHeader,
    required this.rosterRateHeader,
    required this.rosterCountHeader,
    required this.servicesLabel,
    required this.servicesSubtitle,
    required this.serviceUnitHint,
    required this.serviceCategoryHint,
    required this.activeMetricLabel,
    required this.activeMetricIcon,
    required this.loginTagline,
  });
}

/// The full registry — one config per category, fully populated so no
/// vendor type is ever missing a field or label.
const Map<VendorCategory, VendorCategoryConfig> categoryConfigs = {
  VendorCategory.talent: VendorCategoryConfig(
    category: VendorCategory.talent,
    label: 'Talent Agency',
    accent: Color(0xFFC898AA),
    icon: Icons.groups_outlined,
    hasRoster: true,
    rosterLabel: 'Talent Roster',
    rosterIcon: Icons.groups_outlined,
    rosterSubtitle: 'The models and talent you represent',
    rosterAddLabel: 'Add Talent',
    rosterNameHeader: 'Name',
    rosterRoleHeader: 'Role',
    rosterRateHeader: 'Day Rate',
    rosterCountHeader: 'Shoots',
    servicesLabel: 'Services & Packages',
    servicesSubtitle: 'Create and manage what clients can book',
    serviceUnitHint: 'per shoot',
    serviceCategoryHint: 'Models',
    activeMetricLabel: 'Active Talent',
    activeMetricIcon: Icons.groups_outlined,
    loginTagline:
        'Manage your talent roster, list services, accept bookings, track earnings and chat with clients — all in one place.',
  ),
  VendorCategory.photography: VendorCategoryConfig(
    category: VendorCategory.photography,
    label: 'Photography',
    accent: Color(0xFFC4B098),
    icon: Icons.camera_alt_outlined,
    hasRoster: true,
    rosterLabel: 'Crew & Gear',
    rosterIcon: Icons.camera_outlined,
    rosterSubtitle: 'Your photographers, assistants and equipment',
    rosterAddLabel: 'Add Crew',
    rosterNameHeader: 'Name',
    rosterRoleHeader: 'Specialty',
    rosterRateHeader: 'Day Rate',
    rosterCountHeader: 'Shoots',
    servicesLabel: 'Shoot Packages',
    servicesSubtitle: 'Define the photography packages clients can book',
    serviceUnitHint: 'per shoot',
    serviceCategoryHint: 'Photography',
    activeMetricLabel: 'Crew on call',
    activeMetricIcon: Icons.camera_outlined,
    loginTagline:
        'Showcase your portfolio, list shoot packages, manage your crew and gear, accept bookings and track earnings — all in one place.',
  ),
  VendorCategory.videography: VendorCategoryConfig(
    category: VendorCategory.videography,
    label: 'Videography',
    accent: Color(0xFF7C9EC8),
    icon: Icons.videocam_outlined,
    hasRoster: true,
    rosterLabel: 'Production Crew',
    rosterIcon: Icons.movie_outlined,
    rosterSubtitle: 'Your directors, operators, editors and rigs',
    rosterAddLabel: 'Add Crew',
    rosterNameHeader: 'Name',
    rosterRoleHeader: 'Role',
    rosterRateHeader: 'Day Rate',
    rosterCountHeader: 'Projects',
    servicesLabel: 'Production Packages',
    servicesSubtitle: 'Define the film & video packages clients can book',
    serviceUnitHint: 'per project',
    serviceCategoryHint: 'Videography',
    activeMetricLabel: 'Crew on call',
    activeMetricIcon: Icons.movie_outlined,
    loginTagline:
        'Publish your reels, list production packages, manage your crew, accept bookings and track earnings — all in one place.',
  ),
  VendorCategory.venue: VendorCategoryConfig(
    category: VendorCategory.venue,
    label: 'Venue',
    accent: Color(0xFF7DB5A0),
    icon: Icons.location_city_outlined,
    hasRoster: true,
    rosterLabel: 'Spaces & Halls',
    rosterIcon: Icons.meeting_room_outlined,
    rosterSubtitle: 'The bookable spaces at your property',
    rosterAddLabel: 'Add Space',
    rosterNameHeader: 'Space',
    rosterRoleHeader: 'Type',
    rosterRateHeader: 'Rate',
    rosterCountHeader: 'Events',
    servicesLabel: 'Hire Packages',
    servicesSubtitle: 'Define the venue hire packages clients can book',
    serviceUnitHint: 'per day',
    serviceCategoryHint: 'Venue',
    activeMetricLabel: 'Bookable Spaces',
    activeMetricIcon: Icons.meeting_room_outlined,
    loginTagline:
        'List your spaces, set capacities and hire packages, manage availability, accept bookings and track earnings — all in one place.',
  ),
  VendorCategory.events: VendorCategoryConfig(
    category: VendorCategory.events,
    label: 'Event Services',
    accent: Color(0xFFC4A870),
    icon: Icons.celebration_outlined,
    hasRoster: true,
    rosterLabel: 'Event Crew',
    rosterIcon: Icons.engineering_outlined,
    rosterSubtitle: 'Your planners, coordinators and on-ground crew',
    rosterAddLabel: 'Add Crew',
    rosterNameHeader: 'Name',
    rosterRoleHeader: 'Role',
    rosterRateHeader: 'Day Rate',
    rosterCountHeader: 'Events',
    servicesLabel: 'Event Packages',
    servicesSubtitle: 'Define the event management packages clients can book',
    serviceUnitHint: 'per event',
    serviceCategoryHint: 'Event Services',
    activeMetricLabel: 'Crew on call',
    activeMetricIcon: Icons.engineering_outlined,
    loginTagline:
        'List your event packages, manage your crew, accept bookings, track earnings and chat with clients — all in one place.',
  ),
};

/// Holds the signed-in vendor's category for the session. Set at login;
/// read by the shell and every screen. Defaults to talent so deep-links
/// and hot-reload still render a valid console.
class VendorSession {
  VendorSession._();
  static VendorCategory category = VendorCategory.talent;

  /// The precise marketplace category, when the stored string resolved to
  /// one. Null falls back to the archetype's own label.
  static MarketCategory? market;

  /// The console shape, relabelled and re-tinted with the marketplace
  /// category — so a jewellery house is not told it is running a "Venue".
  static VendorCategoryConfig get config {
    final base = categoryConfigs[category]!;
    final m = market;
    return m == null ? base : base.copyWith(label: m.label, accent: m.accent);
  }
  static bool _profileLoaded = false;

  /// The signed-in vendor's display name (company, falling back to name),
  /// as returned by `GET /vendors/me`. Populated on login; read by the
  /// shell header and dashboard greeting instead of a hardcoded name.
  static String vendorName = 'Vendor';
  static String vendorCity = '';

  static String get profileSubtitle {
    final city = vendorCity.trim();
    return city.isEmpty ? config.label : '${config.label} · $city';
  }

  static void setVendorFromProfile(Map<String, dynamic> profile) {
    final company = (profile['company'] as String?)?.trim() ?? '';
    final name = (profile['name'] as String?)?.trim() ?? '';
    vendorName = company.isNotEmpty ? company : (name.isNotEmpty ? name : 'Vendor');
    vendorCity = (profile['city'] as String?)?.trim() ?? '';
    setCategoryFromServer((profile['category'] as String?)?.trim() ?? '');
    _profileLoaded = true;
  }

  /// Maps whatever the backend stores (label, id or free text) → console
  /// category, via the marketplace taxonomy.
  ///
  /// The previous chain checked broad substrings in declaration order, so
  /// "Makeup Studio" fell past every branch and "Video Editor" became a
  /// videography console. [marketCategoryFromLabel] checks the most specific
  /// terms first and knows all eighteen categories.
  static void setCategoryFromServer(String raw) {
    if (raw.isEmpty) return;
    final resolved = marketCategoryFromLabel(raw);
    if (resolved != null) {
      market = resolved;
      category = resolved.archetype;
      return;
    }
    market = null;
    setFromLabel(raw);
  }

  static void reset() {
    market = null;
    category = VendorCategory.talent;
    vendorName = 'Vendor';
    vendorCity = '';
    _profileLoaded = false;
  }

  static bool get profileLoaded => _profileLoaded;

  /// Maps the registration dropdown label → category.
  static void setFromLabel(String label) {
    category = switch (label) {
      'Photography' => VendorCategory.photography,
      'Videography' => VendorCategory.videography,
      'Venue' => VendorCategory.venue,
      'Event Services' => VendorCategory.events,
      _ => VendorCategory.talent,
    };
  }
}

/// Portfolio category tags fixed per vendor module (matches user-app browse filters).
const Map<VendorCategory, List<String>> portfolioTagOptions = {
  VendorCategory.talent: ['Fashion', 'Ethnic', 'Ramp', 'Film', 'Commercial', 'Fitness'],
  VendorCategory.photography: ['Fashion', 'Wedding', 'Commercial', 'Portrait'],
  VendorCategory.videography: ['Brand Films', 'Wedding', 'Social Media', 'Documentary'],
  VendorCategory.venue: ['Indoor', 'Outdoor', 'Rooftop', 'Heritage'],
  VendorCategory.events: ['Fashion Shows', 'Corporate', 'Wedding Events', 'Concerts'],
};

/// Accent helper used where a category tint is wanted instead of gold.
Color categoryAccent() => VendorSession.config.accent;

/// Sanity guard kept referenced so the import of AppColors is never dropped
/// during refactors — the fallback tint for any future category is gold.
Color categoryAccentOr(Color? c) => c ?? AppColors.gold;

/// ───────────────────────────────────────────────────────────────
/// MARKETPLACE TAXONOMY
///
/// [VendorCategory] above describes the shape of the CONSOLE — five distinct
/// workflows (roster + comp card, crew + gear, crew + reels, spaces, service
/// list). The marketplace has eighteen categories inside eight divisions, and
/// most of them reuse one of those five shapes: a makeup artist and a model
/// both need a roster and a comp card, they are simply listed differently.
///
/// Conflating the two would mean eighteen near-identical configs and a switch
/// in every screen. Instead each marketplace category names its own label,
/// division and accent, and points at the console archetype it behaves like.
///
/// Ids and accents are byte-identical to aonego9-user's `data/taxonomy.dart`
/// and `theme/tokens.dart` — a vendor sees the colour their listing wears.
/// ───────────────────────────────────────────────────────────────
class MarketCategory {
  /// Matches the id used by the marketplace and the super-admin console.
  final String id;
  final String label;

  /// Division id: talent | crew | post | beauty | fashion | spaces |
  /// hospitality | education.
  final String division;
  final String divisionLabel;
  /// Authored for the dark ground; [accent] adapts it to the active theme.
  final Color accentDark;

  /// The console shape this category behaves like.
  final VendorCategory archetype;

  const MarketCategory({
    required this.id,
    required this.label,
    required this.division,
    required this.divisionLabel,
    required this.accentDark,
    required this.archetype,
  });

  /// The accent for the active theme — deepened for the light ground so it
  /// stays readable as a label rather than washing out at ~2:1.
  Color get accent => AppColors.forGround(accentDark);
}

const List<MarketCategory> marketCategories = [
  // ── Talent ──
  MarketCategory(id: 'modelF', label: 'Female Models', division: 'talent', divisionLabel: 'Talent', accentDark: Color(0xFFC898AA), archetype: VendorCategory.talent),
  MarketCategory(id: 'modelM', label: 'Male Models', division: 'talent', divisionLabel: 'Talent', accentDark: Color(0xFF8898B6), archetype: VendorCategory.talent),
  // ── Production ──
  MarketCategory(id: 'photo', label: 'Photography', division: 'crew', divisionLabel: 'Production', accentDark: Color(0xFFC4B098), archetype: VendorCategory.photography),
  MarketCategory(id: 'video', label: 'Videography', division: 'crew', divisionLabel: 'Production', accentDark: Color(0xFF7C9EC8), archetype: VendorCategory.videography),
  MarketCategory(id: 'studio', label: 'Photo Studios', division: 'crew', divisionLabel: 'Production', accentDark: Color(0xFFA8B8C4), archetype: VendorCategory.venue),
  MarketCategory(id: 'events', label: 'Event Services', division: 'crew', divisionLabel: 'Production', accentDark: Color(0xFFC4A870), archetype: VendorCategory.events),
  // ── Post & Design ──
  MarketCategory(id: 'editVideo', label: 'Video Editors', division: 'post', divisionLabel: 'Post & Design', accentDark: Color(0xFF8FB0C0), archetype: VendorCategory.videography),
  MarketCategory(id: 'editVfx', label: 'VFX Artists', division: 'post', divisionLabel: 'Post & Design', accentDark: Color(0xFFA898C8), archetype: VendorCategory.videography),
  MarketCategory(id: 'edit3d', label: '3D & Animation', division: 'post', divisionLabel: 'Post & Design', accentDark: Color(0xFF7FBAB4), archetype: VendorCategory.videography),
  MarketCategory(id: 'editGraphic', label: 'Graphic Design', division: 'post', divisionLabel: 'Post & Design', accentDark: Color(0xFFC8A890), archetype: VendorCategory.events),
  // ── Hair & Makeup ──
  MarketCategory(id: 'makeupArtist', label: 'Makeup Artists', division: 'beauty', divisionLabel: 'Hair & Makeup', accentDark: Color(0xFFD09AA8), archetype: VendorCategory.talent),
  MarketCategory(id: 'makeupStudio', label: 'Makeup Studios', division: 'beauty', divisionLabel: 'Hair & Makeup', accentDark: Color(0xFFC0A0B8), archetype: VendorCategory.venue),
  // ── Fashion & Retail ──
  MarketCategory(id: 'designer', label: 'Fashion Designers', division: 'fashion', divisionLabel: 'Fashion & Retail', accentDark: Color(0xFFC4A0C0), archetype: VendorCategory.events),
  MarketCategory(id: 'clothShop', label: 'Cloth & Showrooms', division: 'fashion', divisionLabel: 'Fashion & Retail', accentDark: Color(0xFFB8A888), archetype: VendorCategory.venue),
  MarketCategory(id: 'jewellery', label: 'Jewellery', division: 'fashion', divisionLabel: 'Fashion & Retail', accentDark: Color(0xFFD4BC80), archetype: VendorCategory.venue),
  // ── Venues ──
  MarketCategory(id: 'venue', label: 'Event Venues', division: 'spaces', divisionLabel: 'Venues', accentDark: Color(0xFF7DB5A0), archetype: VendorCategory.venue),
  // ── Hospitality ──
  MarketCategory(id: 'hotel', label: 'Hotels', division: 'hospitality', divisionLabel: 'Hospitality', accentDark: Color(0xFF88B0A0), archetype: VendorCategory.venue),
  // ── Academy ──
  MarketCategory(id: 'academy', label: 'Schools & Academies', division: 'education', divisionLabel: 'Academy', accentDark: Color(0xFF98A8C8), archetype: VendorCategory.events),
];

final Map<String, MarketCategory> marketCategoryById = {
  for (final c in marketCategories) c.id: c,
};

/// Resolve the vendor's stored category string to a marketplace category.
///
/// The backend stores free text that a vendor typed at registration, so this
/// matches on substrings, MOST SPECIFIC FIRST — "makeup studio" must not fall
/// through to "makeup", and "video editor" must not become "video". Female
/// terms precede male ones because "female model" contains "male model".
MarketCategory? marketCategoryFromLabel(String raw) {
  final s = raw.toLowerCase().trim();
  if (s.isEmpty) return null;

  final byExactLabel = marketCategories.where((c) => c.label.toLowerCase() == s);
  if (byExactLabel.isNotEmpty) return byExactLabel.first;
  final byId = marketCategoryById[raw.trim()];
  if (byId != null) return byId;

  const ordered = <List<String>>[
    ['makeupStudio', 'makeup studio', 'beauty studio', 'salon'],
    ['makeupArtist', 'makeup', 'mua', 'hair stylist', 'hairstylist'],
    ['editVfx', 'vfx', 'compositing', 'roto'],
    ['edit3d', '3d', 'animation', 'animator', 'cgi'],
    ['editGraphic', 'graphic', 'illustrat'],
    ['editVideo', 'video editor', 'editor', 'post production', 'post-production'],
    ['studio', 'photo studio', 'film studio', 'shooting floor'],
    ['jewellery', 'jewellery', 'jewelry', 'jeweller'],
    ['clothShop', 'showroom', 'cloth', 'fabric', 'boutique', 'garment'],
    ['designer', 'designer', 'couture', 'fashion house'],
    ['hotel', 'hotel', 'resort', 'stay', 'banquet'],
    ['academy', 'academy', 'school', 'college', 'university', 'institute', 'training'],
    ['venue', 'venue', 'hall', 'lawn', 'palace'],
    ['events', 'event', 'wedding planner', 'production house'],
    ['photo', 'photograph'],
    ['video', 'videograph', 'cinematograph', 'film crew'],
    ['modelF', 'female model', 'female', 'actress', 'women model'],
    ['modelM', 'male model', 'men model', 'mens model', 'actor', 'male'],
    ['modelF', 'model', 'talent'],
  ];

  for (final row in ordered) {
    for (var i = 1; i < row.length; i++) {
      if (s.contains(row[i])) return marketCategoryById[row[0]];
    }
  }
  return null;
}

/// The console config for a stored category string — the archetype's shape,
/// relabelled and re-tinted with the precise marketplace category so a
/// jewellery house is not told it is running a "Venue".
VendorCategoryConfig configForLabel(String raw) {
  final market = marketCategoryFromLabel(raw);
  final base = categoryConfigs[market?.archetype ?? VendorCategory.talent]!;
  if (market == null) return base;
  return base.copyWith(label: market.label, accent: market.accent);
}
