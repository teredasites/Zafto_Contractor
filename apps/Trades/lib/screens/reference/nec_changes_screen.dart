// NEC Code Changes Reference - Design System v2.6
// Shows major changes between NEC editions with edition awareness

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/state_preferences_service.dart';
import '../../data/state_nec_data.dart';
import '../../widgets/expandable_reference_card.dart';

class NecChangesScreen extends ConsumerStatefulWidget {
  const NecChangesScreen({super.key});

  @override
  ConsumerState<NecChangesScreen> createState() => _NecChangesScreenState();
}

class _NecChangesScreenState extends ConsumerState<NecChangesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final necEdition = ref.watch(necEditionProvider);
    final necBadge = ref.watch(necEditionBadgeProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'NEC Changes',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.accentPrimary,
          labelColor: colors.accentPrimary,
          unselectedLabelColor: colors.textSecondary,
          tabs: const [
            Tab(text: '2020→2023'),
            Tab(text: '2017→2020'),
            Tab(text: '2023→2026'),
          ],
        ),
      ),
      body: Column(
        children: [
          // User's edition context
          _buildEditionContext(colors, necEdition, necBadge),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ChangesTab2023(colors: colors),
                _ChangesTab2020(colors: colors),
                _ChangesTab2026(colors: colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditionContext(ZaftoColors colors, NecEdition edition, String badge) {
    String message;
    Color bgColor;
    IconData icon;

    switch (edition) {
      case NecEdition.nec2008:
        message = 'Your state uses NEC 2008. Significantly outdated - review all change tabs.';
        bgColor = colors.accentError;
        icon = LucideIcons.alertTriangle;
        break;
      case NecEdition.nec2014:
        message = 'Your state uses NEC 2014. Outdated - review all change tabs for upcoming requirements.';
        bgColor = colors.accentError;
        icon = LucideIcons.alertTriangle;
        break;
      case NecEdition.nec2017:
        message = 'Your state uses NEC 2017. Review 2017→2020 and 2020→2023 tabs for upcoming changes.';
        bgColor = Colors.orange;
        icon = LucideIcons.alertCircle;
        break;
      case NecEdition.nec2020:
        message = 'Your state uses NEC 2020. Review 2020→2023 tab for changes in the next adoption cycle.';
        bgColor = colors.accentPrimary;
        icon = LucideIcons.info;
        break;
      case NecEdition.nec2023:
        message = 'Your state uses NEC 2023 (current edition). These requirements apply now.';
        bgColor = colors.accentSuccess;
        icon = LucideIcons.checkCircle;
        break;
      case NecEdition.nec2026:
        message = 'Your state uses NEC 2026 (latest). You have the most current requirements.';
        bgColor = colors.accentInfo;
        icon = LucideIcons.sparkles;
        break;
      case NecEdition.local:
        message = 'Your state has no statewide NEC adoption. Check with your local AHJ for requirements.';
        bgColor = colors.accentWarning;
        icon = LucideIcons.mapPin;
        break;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: bgColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: colors.bgBase,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    color: colors.textSecondary,
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

// ============================================================================
// 2020 → 2023 CHANGES TAB
// ============================================================================

class _ChangesTab2023 extends StatelessWidget {
  final ZaftoColors colors;
  const _ChangesTab2023({required this.colors});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: 'MAJOR CHANGES (NEC 2020 → 2023)', colors: colors),
        const SizedBox(height: 12),
        _ChangeCard(
          colors: colors,
          title: 'GFCI Requirements Expanded',
          section: '210.8',
          accentColor: Colors.red,
          changes: [
            'All 125V-250V, single-phase, 150V-to-ground, 50A or less outlets require GFCI in listed locations',
            'Added: Outdoor outlets for dwelling units',
            'Added: Indoor damp/wet locations',
            'Clarified: Within 6ft of any sink',
          ],
        ),
        _ChangeCard(
          colors: colors,
          title: 'Emergency Disconnects',
          section: '230.85',
          accentColor: Colors.red,
          isNew: true,
          changes: [
            'Emergency disconnect required for one/two-family dwellings',
            'Must be outdoor, readily accessible',
            'Marked "Emergency Disconnect, Service Disconnect"',
            'Maximum 6 throws to disconnect all power',
          ],
        ),
        _ChangeCard(
          colors: colors,
          title: 'Surge Protection Required',
          section: '230.67',
          accentColor: colors.accentPrimary,
          isNew: true,
          changes: [
            'SPD (Type 1 or Type 2) required for dwelling unit services',
            'Must be listed device',
            'Integral to panel or separate enclosure',
          ],
        ),
        _ChangeCard(
          colors: colors,
          title: 'AFCI Requirements',
          section: '210.12',
          accentColor: Colors.orange,
          changes: [
            'Branch circuit extensions/modifications must include AFCI',
            'Applies to replacement of devices on existing circuits',
            'Exceptions clarified for fire alarm circuits',
          ],
        ),
        _ChangeCard(
          colors: colors,
          title: 'EV Charging (EVSE)',
          section: '625',
          accentColor: Colors.purple,
          changes: [
            'EV Ready requirements added for new construction',
            'Load management systems recognized',
            'Bidirectional EV charging (V2H/V2G) addressed',
          ],
        ),
        _ChangeCard(
          colors: colors,
          title: 'Reconditioned Equipment',
          section: '110.21(A)(2)',
          accentColor: colors.accentWarning,
          isNew: true,
          changes: [
            'Requirements for reconditioned equipment',
            'Must be marked "Reconditioned"',
            'Listed or field evaluated',
          ],
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: 'ARTICLES REORGANIZED', colors: colors),
        const SizedBox(height: 8),
        _ReorgCard(colors: colors, article: 'Article 235', desc: 'Branch-Circuit, Feeder, and Service Conductors Over 1000V'),
        _ReorgCard(colors: colors, article: 'Article 706', desc: 'Energy Storage Systems (ESS)'),
        _ReorgCard(colors: colors, article: 'Article 710', desc: 'Standalone Systems'),
        _ReorgCard(colors: colors, article: 'Article 712', desc: 'DC Microgrids'),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ============================================================================
// 2017 → 2020 CHANGES TAB
// ============================================================================

class _ChangesTab2020 extends StatelessWidget {
  final ZaftoColors colors;
  const _ChangesTab2020({required this.colors});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: 'MAJOR CHANGES (NEC 2017 → 2020)', colors: colors),
        const SizedBox(height: 12),
        _ChangeCard(
          colors: colors,
          title: 'Outdoor GFCI Expansion',
          section: '210.8(A)(3)',
          accentColor: Colors.red,
          changes: [
            'GFCI protection up to 250V (was 125V)',
            'Includes 240V equipment outdoors',
            'Covers pool pumps, A/C units, etc.',
          ],
        ),
        _ChangeCard(
          colors: colors,
          title: 'Kitchen GFCI Clarification',
          section: '210.8(A)(6)',
          accentColor: Colors.red,
          changes: [
            'All receptacles serving countertop surfaces',
            'Includes island and peninsula locations',
            'Clarified "countertop" definition',
          ],
        ),
        _ChangeCard(
          colors: colors,
          title: 'USB Receptacles Recognized',
          section: '406.3(E)',
          accentColor: colors.accentPrimary,
          isNew: true,
          changes: [
            'Listed USB charging receptacles permitted',
            'Can replace standard receptacles',
            'Must be listed and labeled',
          ],
        ),
        _ChangeCard(
          colors: colors,
          title: 'Ground-Fault Protection',
          section: '230.95',
          accentColor: Colors.orange,
          changes: [
            'GFP required at 150V+, 1000A+ services',
            'Expanded testing requirements',
            'Documentation requirements added',
          ],
        ),
        _ChangeCard(
          colors: colors,
          title: 'AFCI Kitchen Expansion',
          section: '210.12(A)',
          accentColor: Colors.orange,
          changes: [
            'Kitchens added to AFCI-required areas',
            'Laundry areas added',
            'All habitable rooms in dwelling units',
          ],
        ),
        _ChangeCard(
          colors: colors,
          title: 'Rapid Shutdown (PV)',
          section: '690.12',
          accentColor: Colors.purple,
          changes: [
            'Module-level shutdown required',
            '30 seconds to 80V or less',
            'Applies to rooftop PV systems',
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ============================================================================
// 2023 → 2026 CHANGES TAB
// ============================================================================

class _ChangesTab2026 extends StatelessWidget {
  final ZaftoColors colors;
  const _ChangesTab2026({required this.colors});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.accentInfo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.sparkles, color: colors.accentInfo, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'NEC 2026 Preview',
                    style: TextStyle(
                      color: colors.accentInfo,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'NEC 2026 was published in late 2025. Early-adopting jurisdictions are beginning to implement these changes.',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: 'EXPECTED MAJOR CHANGES', colors: colors),
        const SizedBox(height: 12),
        _ChangeCard(
          colors: colors,
          title: 'EV Infrastructure Expansion',
          section: '625',
          accentColor: Colors.purple,
          changes: [
            'Enhanced EV-ready requirements for multifamily',
            'Vehicle-to-grid (V2G) provisions expanded',
            'Load management system standards updated',
          ],
        ),
        _ChangeCard(
          colors: colors,
          title: 'Energy Storage Integration',
          section: '706',
          accentColor: Colors.teal,
          changes: [
            'Battery backup system requirements refined',
            'Residential ESS installation clarity',
            'Integration with solar and grid systems',
          ],
        ),
        _ChangeCard(
          colors: colors,
          title: 'Arc-Flash Labeling',
          section: '110.16',
          accentColor: Colors.orange,
          changes: [
            'Enhanced labeling requirements',
            'Incident energy information',
            'PPE category requirements',
          ],
        ),
        _ChangeCard(
          colors: colors,
          title: 'Selective Coordination',
          section: '700, 701, 708',
          accentColor: Colors.red,
          changes: [
            'Refined selective coordination rules',
            'Critical operations clarity',
            'Healthcare facility updates',
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ============================================================================
// HELPER WIDGETS
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final ZaftoColors colors;
  const _SectionHeader({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: colors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ChangeCard extends StatelessWidget {
  final ZaftoColors colors;
  final String title;
  final String section;
  final Color accentColor;
  final List<String> changes;
  final bool isNew;

  const _ChangeCard({
    required this.colors,
    required this.title,
    required this.section,
    required this.accentColor,
    required this.changes,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        section,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (isNew) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.accentSuccess,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'NEW',
                          style: TextStyle(
                            color: colors.bgBase,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...changes.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(color: accentColor)),
                        Expanded(
                          child: Text(
                            c,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _ReorgCard extends StatelessWidget {
  final ZaftoColors colors;
  final String article;
  final String desc;

  const _ReorgCard({
    required this.colors,
    required this.article,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              article,
              style: TextStyle(
                color: colors.accentPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
