// GFCI/AFCI Requirements - Design System v2.6
// Enhanced with expandable cards and NEC edition awareness
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/expandable_reference_card.dart';
import '../../services/state_preferences_service.dart';

class GfciAfciScreen extends ConsumerWidget {
  const GfciAfciScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final necBadge = ref.watch(necEditionBadgeProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colors.bgBase,
        appBar: AppBar(
          backgroundColor: colors.bgBase,
          elevation: 0,
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'GFCI/AFCI',
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
          ),
          bottom: TabBar(
            indicatorColor: colors.accentPrimary,
            labelColor: colors.accentPrimary,
            unselectedLabelColor: colors.textSecondary,
            tabs: const [Tab(text: 'GFCI'), Tab(text: 'AFCI')],
          ),
        ),
        body: TabBarView(
          children: [
            _GfciTab(colors: colors, necBadge: necBadge),
            _AfciTab(colors: colors, necBadge: necBadge),
          ],
        ),
      ),
    );
  }
}

class _GfciTab extends StatelessWidget {
  final ZaftoColors colors;
  final String necBadge;

  const _GfciTab({required this.colors, required this.necBadge});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // NEC Edition Badge
          NecEditionBadge(edition: necBadge, colors: colors),
          const SizedBox(height: 16),
          // Header card
          _NecCard(
            title: 'NEC 210.8',
            subtitle: 'Ground-Fault Circuit-Interrupter Protection',
            colors: colors,
          ),
          const SizedBox(height: 24),
          // Dwelling Units Section
          _SectionHeader(title: 'DWELLING UNITS - 210.8(A)', colors: colors),
          const SizedBox(height: 12),
          ..._dwellingGfciRequirements.map(
            (data) => ExpandableReferenceCard(data: data, colors: colors),
          ),
          const SizedBox(height: 24),
          // Other Than Dwelling Units Section
          _SectionHeader(title: 'OTHER THAN DWELLING UNITS - 210.8(B)', colors: colors),
          const SizedBox(height: 12),
          ..._commercialGfciRequirements.map(
            (data) => ExpandableReferenceCard(data: data, colors: colors),
          ),
        ],
      ),
    );
  }
}

class _AfciTab extends StatelessWidget {
  final ZaftoColors colors;
  final String necBadge;

  const _AfciTab({required this.colors, required this.necBadge});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // NEC Edition Badge
          NecEditionBadge(edition: necBadge, colors: colors),
          const SizedBox(height: 16),
          // Header card
          _NecCard(
            title: 'NEC 210.12',
            subtitle: 'Arc-Fault Circuit-Interrupter Protection',
            colors: colors,
          ),
          const SizedBox(height: 24),
          // Dwelling Units Section
          _SectionHeader(title: 'DWELLING UNITS - 210.12(A)', colors: colors),
          const SizedBox(height: 12),
          // Warning box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.alertTriangle, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'AFCI Required Areas',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'All 120V, single-phase, 15A and 20A branch circuits supplying outlets or devices in:',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // AFCI rooms with expandable details
          ..._afciRequirements.map(
            (data) => ExpandableReferenceCard(data: data, colors: colors),
          ),
          const SizedBox(height: 24),
          // Exceptions Section
          _SectionHeader(title: 'EXCEPTIONS', colors: colors),
          const SizedBox(height: 12),
          ..._afciExceptions.map(
            (data) => ExpandableReferenceCard(
              data: data,
              colors: colors,
              leadingIcon: LucideIcons.alertCircle,
              leadingIconColor: colors.accentPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// GFCI DWELLING REQUIREMENTS DATA
// ============================================================================

const _dwellingGfciRequirements = [
  ExpandableCardData(
    title: 'Bathrooms',
    subtitle: 'All 125V, single-phase, 15A and 20A receptacles',
    necRef: '210.8(A)(1)',
    fullNecText: 'All 125-volt through 250-volt receptacles installed in bathrooms shall have ground-fault circuit-interrupter protection for personnel.',
    tips: [
      'Install GFCI at first receptacle in circuit for downstream protection',
      'Test GFCI monthly using built-in test button',
      'Consider weather-resistant GFCI for high-moisture areas',
    ],
  ),
  ExpandableCardData(
    title: 'Garages & Accessory Buildings',
    subtitle: 'All 125V through 250V receptacles, not dedicated appliances',
    necRef: '210.8(A)(2)',
    fullNecText: 'Garages, and also accessory buildings that have a floor located at or below grade level not intended as habitable rooms and limited to storage areas, work areas, and areas of similar use.',
    exceptions: [
      'Receptacles not readily accessible',
      'Single receptacle for dedicated appliance (freezer, refrigerator)',
      'Receptacle for garage door opener if not readily accessible',
    ],
    tips: [
      'Dedicated freezer circuit can be exempt if single receptacle',
      'Ceiling-mounted receptacles for openers may be exempt',
      'Consider separate circuit for frequently-tripped tools',
    ],
  ),
  ExpandableCardData(
    title: 'Outdoors',
    subtitle: 'All 125V through 250V receptacles, not exceeding 50A',
    necRef: '210.8(A)(3)',
    fullNecText: 'Outdoors where there is direct grade-level access to the dwelling unit and to the receptacles.',
    tips: [
      'Use weather-resistant (WR) GFCI receptacles',
      'Install in-use covers for outdoor locations',
      'Consider duplex GFCI or upstream protection',
    ],
  ),
  ExpandableCardData(
    title: 'Crawl Spaces',
    subtitle: 'At or below grade level',
    necRef: '210.8(A)(4)',
    fullNecText: 'Crawl spaces — at or below grade level.',
    tips: [
      'Lighting outlet may require GFCI if receptacle-type',
      'Consider portable GFCI for temporary work',
    ],
  ),
  ExpandableCardData(
    title: 'Basements',
    subtitle: 'Unfinished portions, not dedicated appliances',
    necRef: '210.8(A)(5)',
    fullNecText: 'Basements — unfinished portions. For purposes of this section, unfinished basements are defined as portions or areas of the basement not intended as habitable rooms.',
    exceptions: [
      'Single receptacle for dedicated sump pump',
      'Single receptacle supplying only a permanently installed fire alarm or burglar alarm system',
    ],
    tips: [
      'Sump pump on single receptacle can be exempt',
      'Finished portions follow standard receptacle rules',
    ],
  ),
  ExpandableCardData(
    title: 'Kitchens',
    subtitle: 'All receptacles serving countertop surfaces',
    necRef: '210.8(A)(6)',
    fullNecText: 'Kitchens — where the receptacles are installed to serve the countertop surfaces.',
    tips: [
      'Island and peninsula counters included',
      'Receptacles behind range/refrigerator may be exempt',
      'Two 20A small appliance circuits required minimum',
    ],
  ),
  ExpandableCardData(
    title: 'Sinks',
    subtitle: 'Within 6 ft of outside edge of sink',
    necRef: '210.8(A)(7)',
    fullNecText: 'Sinks — where receptacles are installed within 1.8 m (6 ft) from the top inside edge of the bowl of the sink.',
    tips: [
      'Measure from inside edge of sink bowl',
      'Applies to any sink, not just kitchen',
      'Wall-mounted sinks - measure from top edge',
    ],
  ),
  ExpandableCardData(
    title: 'Boathouses',
    subtitle: 'All 125V through 250V receptacles',
    necRef: '210.8(A)(8)',
    fullNecText: 'Boathouses.',
    tips: [
      'All receptacles regardless of location',
      'Consider marine-grade equipment for durability',
    ],
  ),
  ExpandableCardData(
    title: 'Bathtubs/Showers',
    subtitle: 'Within 6 ft of outside edge',
    necRef: '210.8(A)(9)',
    fullNecText: 'Bathtubs or shower stalls — where receptacles are installed within 1.8 m (6 ft) of the outside edge of the bathtub or shower stall.',
    tips: [
      'Measure from outside edge of tub/shower',
      'Wall penetrations count toward measurement',
      'Consider combination GFCI/switch devices',
    ],
  ),
  ExpandableCardData(
    title: 'Laundry Areas',
    subtitle: 'All 125V, single-phase, 15A and 20A receptacles',
    necRef: '210.8(A)(10)',
    fullNecText: 'Laundry areas.',
    tips: [
      'Applies to designated laundry areas only',
      'Gas dryer outlet still needs GFCI',
      '240V dryer outlet typically exempt (over 250V)',
    ],
  ),
  ExpandableCardData(
    title: 'Indoor Damp/Wet',
    subtitle: 'All 125V through 250V receptacles in damp/wet locations',
    necRef: '210.8(A)(11)',
    fullNecText: 'Indoor damp and wet locations.',
    tips: [
      'Use appropriate enclosure rating (wet vs damp)',
      'Consider cord-connected GFCI for temporary',
    ],
  ),
];

// ============================================================================
// GFCI COMMERCIAL REQUIREMENTS DATA
// ============================================================================

const _commercialGfciRequirements = [
  ExpandableCardData(
    title: 'Bathrooms',
    subtitle: 'All 125V, 15A and 20A receptacles',
    necRef: '210.8(B)(1)',
    fullNecText: 'Bathrooms.',
  ),
  ExpandableCardData(
    title: 'Kitchens',
    subtitle: 'All 125V, 15A and 20A receptacles',
    necRef: '210.8(B)(2)',
    fullNecText: 'Kitchens.',
    tips: [
      'Commercial kitchen requirements may be stricter',
      'NSF-rated equipment often required',
    ],
  ),
  ExpandableCardData(
    title: 'Rooftops',
    subtitle: 'All 125V through 250V receptacles',
    necRef: '210.8(B)(3)',
    fullNecText: 'Rooftops.',
    tips: [
      'HVAC service receptacles typically on roof',
      'Use weather-resistant equipment',
    ],
  ),
  ExpandableCardData(
    title: 'Outdoors',
    subtitle: 'All 125V through 250V receptacles (public spaces)',
    necRef: '210.8(B)(4)',
    fullNecText: 'Outdoors in public spaces.',
    exceptions: [
      'Receptacles not readily accessible following installation',
    ],
  ),
  ExpandableCardData(
    title: 'Sinks',
    subtitle: 'Within 6 ft of outside edge',
    necRef: '210.8(B)(5)',
    fullNecText: 'Sinks — where receptacles are installed within 1.8 m (6 ft) from the top inside edge of the bowl of the sink.',
  ),
  ExpandableCardData(
    title: 'Indoor Wet',
    subtitle: 'All 125V through 250V receptacles in wet locations',
    necRef: '210.8(B)(6)',
    fullNecText: 'Indoor wet locations.',
  ),
  ExpandableCardData(
    title: 'Locker Rooms',
    subtitle: 'With showers - all 125V through 250V receptacles',
    necRef: '210.8(B)(7)',
    fullNecText: 'Locker rooms with associated showering facilities.',
  ),
  ExpandableCardData(
    title: 'Garages/Service Bays',
    subtitle: 'Where electrical diagnostic equipment used',
    necRef: '210.8(B)(8)',
    fullNecText: 'Garages, service bays, and similar areas other than vehicle exhibition halls and showrooms — where electrical diagnostic equipment, electrical hand tools, or portable lighting equipment are to be used.',
  ),
  ExpandableCardData(
    title: 'Crawl Spaces',
    subtitle: 'At or below grade level',
    necRef: '210.8(B)(9)',
    fullNecText: 'Crawl spaces — at or below grade level.',
  ),
  ExpandableCardData(
    title: 'Basements',
    subtitle: 'Unfinished portions',
    necRef: '210.8(B)(10)',
    fullNecText: 'Unfinished portions or areas of the basement not intended as habitable rooms.',
  ),
];

// ============================================================================
// AFCI REQUIREMENTS DATA
// ============================================================================

const _afciRequirements = [
  ExpandableCardData(
    title: 'Kitchens',
    subtitle: '120V, 15A and 20A branch circuits',
    necRef: '210.12(A)',
    tips: [
      'Combination AFCI breaker most common solution',
      'AFCI outlet device can provide protection downstream',
    ],
  ),
  ExpandableCardData(
    title: 'Family Rooms',
    subtitle: '120V, 15A and 20A branch circuits',
    necRef: '210.12(A)',
  ),
  ExpandableCardData(
    title: 'Dining Rooms',
    subtitle: '120V, 15A and 20A branch circuits',
    necRef: '210.12(A)',
  ),
  ExpandableCardData(
    title: 'Living Rooms',
    subtitle: '120V, 15A and 20A branch circuits',
    necRef: '210.12(A)',
  ),
  ExpandableCardData(
    title: 'Parlors',
    subtitle: '120V, 15A and 20A branch circuits',
    necRef: '210.12(A)',
  ),
  ExpandableCardData(
    title: 'Libraries',
    subtitle: '120V, 15A and 20A branch circuits',
    necRef: '210.12(A)',
  ),
  ExpandableCardData(
    title: 'Dens',
    subtitle: '120V, 15A and 20A branch circuits',
    necRef: '210.12(A)',
  ),
  ExpandableCardData(
    title: 'Bedrooms',
    subtitle: '120V, 15A and 20A branch circuits',
    necRef: '210.12(A)',
    tips: [
      'AFCI required since 2002 NEC',
      'Bedroom was first required location',
    ],
  ),
  ExpandableCardData(
    title: 'Sunrooms',
    subtitle: '120V, 15A and 20A branch circuits',
    necRef: '210.12(A)',
  ),
  ExpandableCardData(
    title: 'Recreation Rooms',
    subtitle: '120V, 15A and 20A branch circuits',
    necRef: '210.12(A)',
  ),
  ExpandableCardData(
    title: 'Closets',
    subtitle: '120V, 15A and 20A branch circuits',
    necRef: '210.12(A)',
  ),
  ExpandableCardData(
    title: 'Hallways',
    subtitle: '120V, 15A and 20A branch circuits',
    necRef: '210.12(A)',
  ),
  ExpandableCardData(
    title: 'Laundry Areas',
    subtitle: '120V, 15A and 20A branch circuits',
    necRef: '210.12(A)',
    tips: [
      'Both AFCI and GFCI may be required',
      'Dual-function AFCI/GFCI devices available',
    ],
  ),
];

// ============================================================================
// AFCI EXCEPTIONS DATA
// ============================================================================

const _afciExceptions = [
  ExpandableCardData(
    title: 'Exception 1: Fire Alarm Systems',
    subtitle: 'Fire alarm systems per NFPA 72',
    necRef: 'Ex. 1',
    fullNecText: 'Branch circuits supplying fire alarm systems shall be permitted to be installed without AFCI protection where installed in accordance with NFPA 72.',
  ),
  ExpandableCardData(
    title: 'Exception 2: Fire Alarm Equipment',
    subtitle: 'Equipment per 760.41(B) or 760.121(B)',
    necRef: 'Ex. 2',
    fullNecText: 'Branch circuits supplying only fire alarm system equipment installed in accordance with 760.41(B) or 760.121(B).',
  ),
  ExpandableCardData(
    title: 'Exception 3: Metal Raceway/Sheath',
    subtitle: 'Metal raceway ≤ 50 ft to first outlet',
    necRef: 'Ex. 3',
    fullNecText: 'Where a listed metal or nonmetallic conduit or tubing, or Type MC cable with an outer metal jacket is installed for the portion of the branch circuit from the overcurrent protective device to the first outlet, and the total length does not exceed 15 m (50 ft) and the conductors are protected by one of the recognized wiring methods.',
    tips: [
      'Outlet-branch-circuit type AFCI required at first outlet',
      'Metal raceway must extend full distance to first outlet',
    ],
  ),
];

// ============================================================================
// HELPER WIDGETS
// ============================================================================

class _NecCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final ZaftoColors colors;

  const _NecCard({
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.shield, color: colors.accentPrimary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ZaftoColors colors;

  const _SectionHeader({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: TextStyle(
          color: colors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      );
}
