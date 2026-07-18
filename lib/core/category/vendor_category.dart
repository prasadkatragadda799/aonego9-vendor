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

  // Profile
  final String profileType; // "Talent Agency · Delhi"
  final List<MapEntry<String, String>> profileFields;

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
    required this.profileType,
    required this.profileFields,
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
    profileType: 'Talent Agency · Delhi',
    profileFields: [
      MapEntry('Roster size', '24 models'),
      MapEntry('Specialities', 'Editorial, Runway, Commercial'),
      MapEntry('Languages', 'Hindi, English, Marathi'),
    ],
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
    profileType: 'Photography Studio · Mumbai',
    profileFields: [
      MapEntry('Primary gear', 'Sony A1, Profoto B10'),
      MapEntry('Specialities', 'Fashion, Wedding, Commercial'),
      MapEntry('Turnaround', '7–10 days'),
    ],
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
    profileType: 'Production House · Mumbai',
    profileFields: [
      MapEntry('Primary gear', 'RED Komodo, DJI Ronin'),
      MapEntry('Specialities', 'Brand films, Weddings, Social'),
      MapEntry('Delivery', '2–3 weeks'),
    ],
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
    profileType: 'Event Venue · Mumbai',
    profileFields: [
      MapEntry('Total capacity', '400 guests'),
      MapEntry('Spaces', '3 halls + rooftop'),
      MapEntry('Amenities', 'Parking, Catering, AV, Green room'),
    ],
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
    profileType: 'Event Production · Delhi',
    profileFields: [
      MapEntry('Team size', '18 crew'),
      MapEntry('Specialities', 'Fashion shows, Corporate, Weddings'),
      MapEntry('Cities served', 'Delhi, Mumbai, Goa'),
    ],
  ),
};

/// Holds the signed-in vendor's category for the session. Set at login;
/// read by the shell and every screen. Defaults to talent so deep-links
/// and hot-reload still render a valid console.
class VendorSession {
  VendorSession._();
  static VendorCategory category = VendorCategory.talent;
  static VendorCategoryConfig get config => categoryConfigs[category]!;

  /// The signed-in vendor's display name (company, falling back to name),
  /// as returned by `GET /vendors/me`. Populated on login; read by the
  /// shell header and dashboard greeting instead of a hardcoded name.
  static String vendorName = 'Vendor';

  static void setVendorFromProfile(Map<String, dynamic> profile) {
    final company = (profile['company'] as String?)?.trim() ?? '';
    final name = (profile['name'] as String?)?.trim() ?? '';
    vendorName = company.isNotEmpty ? company : (name.isNotEmpty ? name : 'Vendor');
  }

  /// Maps the login dropdown label → category.
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

/// Accent helper used where a category tint is wanted instead of gold.
Color categoryAccent() => VendorSession.config.accent;

/// Sanity guard kept referenced so the import of AppColors is never dropped
/// during refactors — the fallback tint for any future category is gold.
Color categoryAccentOr(Color? c) => c ?? AppColors.gold;
