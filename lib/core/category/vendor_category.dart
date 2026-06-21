import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../data/models/models.dart';

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

/// Category-specific seed rows for the roster / inventory table.
/// Reuses [TalentMember]: name, role(=type), city, dayRate(=rate),
/// rating, available, shoots(=count) — relabeled per category.
const Map<VendorCategory, List<Map<String, dynamic>>> _rosterSeed = {
  VendorCategory.talent: [
    {'id': 'M-1', 'name': 'Priya Sharma', 'role': 'Fashion Model', 'city': 'Mumbai', 'dayRate': 35000, 'rating': 4.8, 'available': true, 'shoots': 34},
    {'id': 'M-2', 'name': 'Kabir Anand', 'role': 'Runway Model', 'city': 'Delhi', 'dayRate': 28000, 'rating': 4.6, 'available': true, 'shoots': 27},
    {'id': 'M-3', 'name': 'Riya Malhotra', 'role': 'Commercial Model', 'city': 'Delhi', 'dayRate': 32000, 'rating': 4.9, 'available': false, 'shoots': 41},
    {'id': 'M-4', 'name': 'Aditya Rao', 'role': 'Fitness Model', 'city': 'Bengaluru', 'dayRate': 25000, 'rating': 4.4, 'available': true, 'shoots': 18},
    {'id': 'M-5', 'name': 'Sara Khan', 'role': 'Editorial Model', 'city': 'Mumbai', 'dayRate': 40000, 'rating': 4.7, 'available': true, 'shoots': 30},
  ],
  VendorCategory.photography: [
    {'id': 'C-1', 'name': 'Rohan Mehta', 'role': 'Lead Photographer', 'city': 'Mumbai', 'dayRate': 45000, 'rating': 4.9, 'available': true, 'shoots': 120},
    {'id': 'C-2', 'name': 'Ananya Iyer', 'role': 'Fashion Photographer', 'city': 'Mumbai', 'dayRate': 38000, 'rating': 4.7, 'available': true, 'shoots': 86},
    {'id': 'C-3', 'name': 'Vikram Singh', 'role': 'Second Shooter', 'city': 'Delhi', 'dayRate': 18000, 'rating': 4.5, 'available': true, 'shoots': 64},
    {'id': 'C-4', 'name': 'Studio Kit A1', 'role': 'Lighting & Gear', 'city': 'Mumbai', 'dayRate': 12000, 'rating': 4.8, 'available': false, 'shoots': 200},
  ],
  VendorCategory.videography: [
    {'id': 'V-1', 'name': 'Arjun Nair', 'role': 'Director / DOP', 'city': 'Mumbai', 'dayRate': 60000, 'rating': 4.9, 'available': true, 'shoots': 54},
    {'id': 'V-2', 'name': 'Meera Joshi', 'role': 'Editor / Colorist', 'city': 'Mumbai', 'dayRate': 30000, 'rating': 4.8, 'available': true, 'shoots': 72},
    {'id': 'V-3', 'name': 'Sahil Verma', 'role': 'Camera Operator', 'city': 'Pune', 'dayRate': 22000, 'rating': 4.6, 'available': true, 'shoots': 48},
    {'id': 'V-4', 'name': 'Ronin Rig 2', 'role': 'Gimbal & Drone', 'city': 'Mumbai', 'dayRate': 15000, 'rating': 4.7, 'available': false, 'shoots': 90},
  ],
  VendorCategory.venue: [
    {'id': 'S-1', 'name': 'The Grand Ballroom', 'role': 'Banquet Hall', 'city': 'Mumbai', 'dayRate': 150000, 'rating': 4.8, 'available': true, 'shoots': 210},
    {'id': 'S-2', 'name': 'Skyline Rooftop', 'role': 'Open-air Rooftop', 'city': 'Mumbai', 'dayRate': 90000, 'rating': 4.7, 'available': true, 'shoots': 134},
    {'id': 'S-3', 'name': 'Heritage Courtyard', 'role': 'Outdoor Heritage', 'city': 'Mumbai', 'dayRate': 120000, 'rating': 4.9, 'available': false, 'shoots': 88},
    {'id': 'S-4', 'name': 'The Studio Loft', 'role': 'Indoor Studio', 'city': 'Mumbai', 'dayRate': 45000, 'rating': 4.5, 'available': true, 'shoots': 156},
  ],
  VendorCategory.events: [
    {'id': 'E-1', 'name': 'Neha Kapoor', 'role': 'Lead Planner', 'city': 'Delhi', 'dayRate': 40000, 'rating': 4.9, 'available': true, 'shoots': 64},
    {'id': 'E-2', 'name': 'Imran Sheikh', 'role': 'Show Director', 'city': 'Mumbai', 'dayRate': 55000, 'rating': 4.8, 'available': true, 'shoots': 47},
    {'id': 'E-3', 'name': 'Tara Bose', 'role': 'Coordinator', 'city': 'Delhi', 'dayRate': 18000, 'rating': 4.6, 'available': true, 'shoots': 92},
    {'id': 'E-4', 'name': 'Stage & Rigging Crew', 'role': 'On-ground Crew', 'city': 'Delhi', 'dayRate': 60000, 'rating': 4.7, 'available': false, 'shoots': 130},
  ],
};

/// Category-specific seed rows for the services / packages grid.
const Map<VendorCategory, List<Map<String, dynamic>>> _packagesSeed = {
  VendorCategory.talent: [
    {'id': 'P-1', 'title': 'Fashion Editorial — Half Day', 'category': 'Models', 'price': 45000, 'unit': 'per shoot', 'active': true, 'bookingsCount': 38, 'description': 'Up to 2 models, 4 hours, studio or location.'},
    {'id': 'P-2', 'title': 'Runway Show Roster', 'category': 'Models', 'price': 180000, 'unit': 'per event', 'active': true, 'bookingsCount': 12, 'description': '6 runway models with fittings and rehearsal.'},
    {'id': 'P-3', 'title': 'Brand Campaign — Full Day', 'category': 'Models', 'price': 95000, 'unit': 'per day', 'active': true, 'bookingsCount': 21, 'description': 'Lead model + styling coordination, 8 hours.'},
    {'id': 'P-4', 'title': 'Catalogue Shoot Package', 'category': 'Models', 'price': 60000, 'unit': 'per day', 'active': false, 'bookingsCount': 9, 'description': 'E-commerce catalogue, up to 40 looks.'},
  ],
  VendorCategory.photography: [
    {'id': 'P-1', 'title': 'Fashion Shoot — Half Day', 'category': 'Photography', 'price': 40000, 'unit': 'per shoot', 'active': true, 'bookingsCount': 64, 'description': '4 hours, 1 photographer, 60 edited images.'},
    {'id': 'P-2', 'title': 'Wedding Full Coverage', 'category': 'Photography', 'price': 150000, 'unit': 'per event', 'active': true, 'bookingsCount': 28, 'description': '2 shooters, full-day coverage, album + 400 edits.'},
    {'id': 'P-3', 'title': 'E-commerce Catalogue', 'category': 'Photography', 'price': 55000, 'unit': 'per day', 'active': true, 'bookingsCount': 41, 'description': 'Studio, up to 50 products, white-background edits.'},
    {'id': 'P-4', 'title': 'Portrait Session', 'category': 'Photography', 'price': 18000, 'unit': 'per shoot', 'active': false, 'bookingsCount': 15, 'description': '90 minutes, 20 retouched portraits.'},
  ],
  VendorCategory.videography: [
    {'id': 'P-1', 'title': 'Brand Film — Standard', 'category': 'Videography', 'price': 220000, 'unit': 'per project', 'active': true, 'bookingsCount': 18, 'description': '60–90s film, 1 shoot day, edit + grade + mix.'},
    {'id': 'P-2', 'title': 'Wedding Cinematic', 'category': 'Videography', 'price': 175000, 'unit': 'per event', 'active': true, 'bookingsCount': 22, 'description': 'Full-day, highlight film + full ceremony edit.'},
    {'id': 'P-3', 'title': 'Social Reels Bundle', 'category': 'Videography', 'price': 65000, 'unit': 'per day', 'active': true, 'bookingsCount': 37, 'description': '1 shoot day, 8 vertical reels, captions + grade.'},
    {'id': 'P-4', 'title': 'Documentary Day Rate', 'category': 'Videography', 'price': 80000, 'unit': 'per day', 'active': false, 'bookingsCount': 6, 'description': 'Director + operator, run-and-gun coverage.'},
  ],
  VendorCategory.venue: [
    {'id': 'P-1', 'title': 'Half Day Hire', 'category': 'Venue', 'price': 80000, 'unit': 'per half-day', 'active': true, 'bookingsCount': 96, 'description': '4 hrs access, basic lighting, 1 coordinator, seating 100.'},
    {'id': 'P-2', 'title': 'Full Day Hire', 'category': 'Venue', 'price': 150000, 'unit': 'per day', 'active': true, 'bookingsCount': 134, 'description': '8 hrs, premium lighting, 2 coordinators, seating 200, AV.'},
    {'id': 'P-3', 'title': 'Signature Event', 'category': 'Venue', 'price': 300000, 'unit': 'per event', 'active': true, 'bookingsCount': 41, 'description': '12 hrs, full AV production, 400 guests, catering, décor.'},
    {'id': 'P-4', 'title': 'Photoshoot Slot', 'category': 'Venue', 'price': 35000, 'unit': 'per half-day', 'active': false, 'bookingsCount': 22, 'description': '4 hrs space-only for stills / video, no catering.'},
  ],
  VendorCategory.events: [
    {'id': 'P-1', 'title': 'Fashion Show Production', 'category': 'Event Services', 'price': 450000, 'unit': 'per event', 'active': true, 'bookingsCount': 24, 'description': 'Stage, ramp, lighting, sound, backstage management.'},
    {'id': 'P-2', 'title': 'Corporate Event — Full', 'category': 'Event Services', 'price': 280000, 'unit': 'per event', 'active': true, 'bookingsCount': 33, 'description': 'AV, stage, registration, hospitality, coordination.'},
    {'id': 'P-3', 'title': 'Wedding Management', 'category': 'Event Services', 'price': 350000, 'unit': 'per event', 'active': true, 'bookingsCount': 47, 'description': 'End-to-end planning, décor, vendors, on-day crew.'},
    {'id': 'P-4', 'title': 'Concert Logistics', 'category': 'Event Services', 'price': 500000, 'unit': 'per event', 'active': false, 'bookingsCount': 8, 'description': 'Rigging, barricades, crew, permits coordination.'},
  ],
};

List<TalentMember> rosterFor(VendorCategory c) =>
    (_rosterSeed[c] ?? const []).map(TalentMember.fromJson).toList();

List<ServicePackage> packagesFor(VendorCategory c) =>
    (_packagesSeed[c] ?? const []).map(ServicePackage.fromJson).toList();

/// Accent helper used where a category tint is wanted instead of gold.
Color categoryAccent() => VendorSession.config.accent;

/// Sanity guard kept referenced so the import of AppColors is never dropped
/// during refactors — the fallback tint for any future category is gold.
Color categoryAccentOr(Color? c) => c ?? AppColors.gold;
