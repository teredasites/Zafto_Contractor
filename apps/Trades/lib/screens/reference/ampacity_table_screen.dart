// NEC Table 310.16 - Design System v2.6
// Enhanced with tappable rows and NEC edition awareness

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/state_preferences_service.dart';
import '../../widgets/expandable_reference_card.dart';

class AmpacityTableScreen extends ConsumerStatefulWidget {
  const AmpacityTableScreen({super.key});
  @override
  ConsumerState<AmpacityTableScreen> createState() => _AmpacityTableScreenState();
}

class _AmpacityTableScreenState extends ConsumerState<AmpacityTableScreen> {
  String _material = 'Copper';

  List<_WireData> get _currentData => _material == 'Copper' ? _copperData : _aluminumData;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
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
          'Table 310.16',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.info, color: colors.textSecondary),
            onPressed: () => _showInfo(context, colors),
          ),
        ],
      ),
      body: Column(
        children: [
          // NEC Edition Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: NecEditionBadge(edition: necBadge, colors: colors),
          ),
          // Header card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Allowable Ampacities',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Insulated conductors, ≤3 CCC in raceway/cable/earth, 30°C ambient',
                  style: TextStyle(color: colors.textTertiary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(LucideIcons.touchpad, size: 14, color: colors.accentPrimary),
                    const SizedBox(width: 6),
                    Text(
                      'Tap any row for details',
                      style: TextStyle(
                        color: colors.accentPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Material selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _MaterialButton(
                    label: 'Copper',
                    isSelected: _material == 'Copper',
                    colors: colors,
                    onTap: () => setState(() => _material = 'Copper'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MaterialButton(
                    label: 'Aluminum',
                    isSelected: _material == 'Aluminum',
                    colors: colors,
                    onTap: () => setState(() => _material = 'Aluminum'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Table header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    'Size',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Expanded(child: _TempHeader(label: '60°C', types: 'TW, UF', colors: colors)),
                Expanded(
                  child: _TempHeader(
                    label: '75°C',
                    types: 'THW, THWN',
                    colors: colors,
                    isRecommended: true,
                  ),
                ),
                Expanded(child: _TempHeader(label: '90°C', types: 'THHN', colors: colors)),
              ],
            ),
          ),
          // Table body
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                border: Border.all(color: colors.borderDefault),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _currentData.length,
                itemBuilder: (context, index) {
                  final wire = _currentData[index];
                  final isEven = index % 2 == 0;
                  return _WireRow(
                    wire: wire,
                    material: _material,
                    isEven: isEven,
                    colors: colors,
                    onTap: () => _showWireDetails(context, wire, colors),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showWireDetails(BuildContext context, _WireData wire, ZaftoColors colors) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _WireDetailSheet(
        wire: wire,
        material: _material,
        colors: colors,
      ),
    );
  }

  void _showInfo(BuildContext context, ZaftoColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Table 310.16 Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow('60°C', 'TW, UF - Moisture resistant thermoplastic', colors),
            _InfoRow('75°C', 'THW, THWN, XHHW, USE - Most common ⭐', colors),
            _InfoRow('90°C', 'THHN, THWN-2, XHHW-2 - Highest rating', colors),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.accentWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.alertTriangle, size: 16, color: colors.accentWarning),
                      const SizedBox(width: 8),
                      Text(
                        'Important Notes',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 14, 12, 10 AWG limited per 240.4(D)\n'
                    '• Apply correction factors for ambient temp\n'
                    '• Apply adjustment factors for >3 CCC\n'
                    '• Terminal temp rating may limit ampacity',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WIRE DETAIL SHEET
// ============================================================================

class _WireDetailSheet extends StatelessWidget {
  final _WireData wire;
  final String material;
  final ZaftoColors colors;

  const _WireDetailSheet({
    required this.wire,
    required this.material,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colors.accentPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          wire.size,
                          style: TextStyle(
                            fontSize: wire.size.length > 3 ? 14 : 18,
                            fontWeight: FontWeight.w700,
                            color: colors.accentPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getWireSizeLabel(wire.size),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            '$material Conductor',
                            style: TextStyle(
                              color: colors.textTertiary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Ampacity values
                Text(
                  'AMPACITY BY TEMPERATURE RATING',
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _AmpacityCard(
                        temp: '60°C',
                        amps: wire.temp60,
                        colors: colors,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AmpacityCard(
                        temp: '75°C',
                        amps: wire.temp75,
                        colors: colors,
                        isRecommended: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _AmpacityCard(
                        temp: '90°C',
                        amps: wire.temp90,
                        colors: colors,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Common applications
                if (wire.applications.isNotEmpty) ...[
                  Text(
                    'COMMON APPLICATIONS',
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...wire.applications.map(
                    (app) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(LucideIcons.check, size: 16, color: colors.accentSuccess),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              app,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Notes if any
                if (wire.notes != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.accentWarning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.alertTriangle, size: 16, color: colors.accentWarning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            wire.notes!,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Use in calculator button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Navigate to wire sizing calculator with pre-filled values
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening Wire Sizing Calculator...'),
                          backgroundColor: colors.accentPrimary,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.calculator),
                    label: const Text('Use in Wire Sizing Calculator'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accentPrimary,
                      foregroundColor: colors.bgBase,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  String _getWireSizeLabel(String size) {
    if (size.contains('/0')) {
      return '$size AWG';
    } else if (int.tryParse(size) != null && int.parse(size) <= 4) {
      return '$size AWG';
    } else if (int.tryParse(size) != null) {
      return '$size kcmil';
    }
    return size;
  }
}

class _AmpacityCard extends StatelessWidget {
  final String temp;
  final int amps;
  final ZaftoColors colors;
  final bool isRecommended;

  const _AmpacityCard({
    required this.temp,
    required this.amps,
    required this.colors,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRecommended
            ? colors.accentPrimary.withValues(alpha: 0.1)
            : colors.fillDefault,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRecommended ? colors.accentPrimary : colors.borderDefault,
        ),
      ),
      child: Column(
        children: [
          Text(
            temp,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${amps}A',
            style: TextStyle(
              color: isRecommended ? colors.accentPrimary : colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isRecommended) ...[
            const SizedBox(height: 4),
            Text(
              'Typical',
              style: TextStyle(
                color: colors.accentPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// WIRE ROW
// ============================================================================

class _WireRow extends StatelessWidget {
  final _WireData wire;
  final String material;
  final bool isEven;
  final ZaftoColors colors;
  final VoidCallback onTap;

  const _WireRow({
    required this.wire,
    required this.material,
    required this.isEven,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isEven ? Colors.transparent : colors.bgInset.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  wire.size.contains('/') || int.tryParse(wire.size) == null
                      ? wire.size
                      : '${wire.size} AWG',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${wire.temp60}',
                    style: TextStyle(fontSize: 14, color: colors.textSecondary),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.accentPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${wire.temp75}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.accentPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${wire.temp90}',
                    style: TextStyle(fontSize: 14, color: colors.textSecondary),
                  ),
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 16, color: colors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HELPER WIDGETS
// ============================================================================

class _MaterialButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ZaftoColors colors;
  final VoidCallback onTap;

  const _MaterialButton({
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colors.accentPrimary : colors.borderDefault,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? colors.bgBase : colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TempHeader extends StatelessWidget {
  final String label;
  final String types;
  final ZaftoColors colors;
  final bool isRecommended;

  const _TempHeader({
    required this.label,
    required this.types,
    required this.colors,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isRecommended ? colors.accentPrimary : colors.textPrimary,
              ),
            ),
            if (isRecommended) ...[
              const SizedBox(width: 4),
              Text('⭐', style: TextStyle(fontSize: 10)),
            ],
          ],
        ),
        Text(types, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String temp;
  final String desc;
  final ZaftoColors colors;

  const _InfoRow(this.temp, this.desc, this.colors);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(
              temp,
              style: TextStyle(
                color: colors.accentPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WIRE DATA
// ============================================================================

class _WireData {
  final String size;
  final int temp60;
  final int temp75;
  final int temp90;
  final List<String> applications;
  final String? notes;

  const _WireData({
    required this.size,
    required this.temp60,
    required this.temp75,
    required this.temp90,
    this.applications = const [],
    this.notes,
  });
}

const List<_WireData> _copperData = [
  _WireData(
    size: '14',
    temp60: 15,
    temp75: 15,
    temp90: 15,
    applications: ['General lighting circuits', '15A receptacle circuits'],
    notes: 'Limited to 15A overcurrent protection per 240.4(D)',
  ),
  _WireData(
    size: '12',
    temp60: 20,
    temp75: 20,
    temp90: 20,
    applications: ['Kitchen small appliance circuits', '20A receptacle circuits', 'Bathroom circuits'],
    notes: 'Limited to 20A overcurrent protection per 240.4(D)',
  ),
  _WireData(
    size: '10',
    temp60: 30,
    temp75: 30,
    temp90: 30,
    applications: ['Electric water heaters', 'Dryer circuits', 'A/C units', '30A appliances'],
    notes: 'Limited to 30A overcurrent protection per 240.4(D)',
  ),
  _WireData(
    size: '8',
    temp60: 40,
    temp75: 50,
    temp90: 55,
    applications: ['Electric ranges (smaller)', 'Large A/C units', '40-50A circuits'],
  ),
  _WireData(
    size: '6',
    temp60: 55,
    temp75: 65,
    temp90: 75,
    applications: ['Electric ranges', 'Large appliances', 'Sub-panel feeders'],
  ),
  _WireData(
    size: '4',
    temp60: 70,
    temp75: 85,
    temp90: 95,
    applications: ['Electric ranges (large)', 'Sub-panel feeders', 'EV chargers (Level 2)'],
  ),
  _WireData(
    size: '3',
    temp60: 85,
    temp75: 100,
    temp90: 115,
    applications: ['100A sub-panels', 'Large equipment feeders'],
  ),
  _WireData(
    size: '2',
    temp60: 95,
    temp75: 115,
    temp90: 130,
    applications: ['100A services', 'Large sub-panels', 'Commercial equipment'],
  ),
  _WireData(
    size: '1',
    temp60: 110,
    temp75: 130,
    temp90: 145,
    applications: ['125A services', 'Commercial feeders'],
  ),
  _WireData(
    size: '1/0',
    temp60: 125,
    temp75: 150,
    temp90: 170,
    applications: ['150A residential services', 'Commercial feeders'],
  ),
  _WireData(
    size: '2/0',
    temp60: 145,
    temp75: 175,
    temp90: 195,
    applications: ['175A services', 'Large commercial loads'],
  ),
  _WireData(
    size: '3/0',
    temp60: 165,
    temp75: 200,
    temp90: 225,
    applications: ['200A residential services', 'Commercial main feeders'],
  ),
  _WireData(
    size: '4/0',
    temp60: 195,
    temp75: 230,
    temp90: 260,
    applications: ['200A+ services', 'Large commercial services'],
  ),
  _WireData(size: '250', temp60: 215, temp75: 255, temp90: 290, applications: ['Commercial services', 'Industrial feeders']),
  _WireData(size: '300', temp60: 240, temp75: 285, temp90: 320, applications: ['Commercial/industrial services']),
  _WireData(size: '350', temp60: 260, temp75: 310, temp90: 350, applications: ['Large commercial services']),
  _WireData(size: '400', temp60: 280, temp75: 335, temp90: 380, applications: ['400A services']),
  _WireData(size: '500', temp60: 320, temp75: 380, temp90: 430, applications: ['Large industrial feeders']),
  _WireData(size: '600', temp60: 350, temp75: 420, temp90: 475, applications: ['Industrial main services']),
  _WireData(size: '700', temp60: 385, temp75: 460, temp90: 520, applications: ['Large industrial']),
  _WireData(size: '750', temp60: 400, temp75: 475, temp90: 535, applications: ['Large industrial']),
  _WireData(size: '800', temp60: 410, temp75: 490, temp90: 555, applications: ['Industrial']),
  _WireData(size: '900', temp60: 435, temp75: 520, temp90: 585, applications: ['Industrial']),
  _WireData(size: '1000', temp60: 455, temp75: 545, temp90: 615, applications: ['Large industrial']),
  _WireData(size: '1250', temp60: 495, temp75: 590, temp90: 665, applications: ['Utility-scale']),
  _WireData(size: '1500', temp60: 525, temp75: 625, temp90: 705, applications: ['Utility-scale']),
  _WireData(size: '1750', temp60: 545, temp75: 650, temp90: 735, applications: ['Utility-scale']),
  _WireData(size: '2000', temp60: 555, temp75: 665, temp90: 750, applications: ['Utility-scale']),
];

const List<_WireData> _aluminumData = [
  _WireData(
    size: '12',
    temp60: 15,
    temp75: 15,
    temp90: 15,
    applications: ['Not typically used for branch circuits'],
    notes: 'Aluminum not recommended for 12 AWG branch circuits',
  ),
  _WireData(
    size: '10',
    temp60: 25,
    temp75: 25,
    temp90: 25,
    applications: ['Limited applications'],
    notes: 'Aluminum not recommended for small branch circuits',
  ),
  _WireData(size: '8', temp60: 35, temp75: 40, temp90: 45, applications: ['A/C disconnects', 'Larger circuits']),
  _WireData(size: '6', temp60: 40, temp75: 50, temp90: 55, applications: ['Sub-panel feeders', 'A/C units']),
  _WireData(size: '4', temp60: 55, temp75: 65, temp90: 75, applications: ['Sub-panel feeders', 'Equipment feeders']),
  _WireData(size: '3', temp60: 65, temp75: 75, temp90: 85, applications: ['Feeders']),
  _WireData(size: '2', temp60: 75, temp75: 90, temp90: 100, applications: ['Service entrance', 'Feeders']),
  _WireData(size: '1', temp60: 85, temp75: 100, temp90: 115, applications: ['100A services (check local code)', 'Feeders']),
  _WireData(size: '1/0', temp60: 100, temp75: 120, temp90: 135, applications: ['Residential services', 'Sub-panel feeders']),
  _WireData(size: '2/0', temp60: 115, temp75: 135, temp90: 150, applications: ['Residential services']),
  _WireData(size: '3/0', temp60: 130, temp75: 155, temp90: 175, applications: ['150A services']),
  _WireData(size: '4/0', temp60: 150, temp75: 180, temp90: 205, applications: ['200A residential services (common)']),
  _WireData(size: '250', temp60: 170, temp75: 205, temp90: 230, applications: ['200A services']),
  _WireData(size: '300', temp60: 190, temp75: 230, temp90: 260, applications: ['Commercial services']),
  _WireData(size: '350', temp60: 210, temp75: 250, temp90: 280, applications: ['Commercial services']),
  _WireData(size: '400', temp60: 225, temp75: 270, temp90: 305, applications: ['Large services']),
  _WireData(size: '500', temp60: 260, temp75: 310, temp90: 350, applications: ['Commercial/industrial']),
  _WireData(size: '600', temp60: 285, temp75: 340, temp90: 385, applications: ['Industrial']),
  _WireData(size: '700', temp60: 310, temp75: 375, temp90: 420, applications: ['Industrial']),
  _WireData(size: '750', temp60: 320, temp75: 385, temp90: 435, applications: ['Industrial']),
  _WireData(size: '800', temp60: 330, temp75: 395, temp90: 450, applications: ['Industrial']),
  _WireData(size: '900', temp60: 355, temp75: 425, temp90: 480, applications: ['Industrial']),
  _WireData(size: '1000', temp60: 375, temp75: 445, temp90: 500, applications: ['Large industrial']),
  _WireData(size: '1250', temp60: 405, temp75: 485, temp90: 545, applications: ['Utility-scale']),
  _WireData(size: '1500', temp60: 435, temp75: 520, temp90: 585, applications: ['Utility-scale']),
  _WireData(size: '1750', temp60: 455, temp75: 545, temp90: 615, applications: ['Utility-scale']),
  _WireData(size: '2000', temp60: 470, temp75: 560, temp90: 630, applications: ['Utility-scale']),
];
