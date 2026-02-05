// Conduit Dimensions Reference - Design System v2.6
// NEC Chapter 9 Table 4 - Enhanced with tap-for-details

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/state_preferences_service.dart';
import '../../widgets/expandable_reference_card.dart';

class ConduitDimensionsScreen extends ConsumerStatefulWidget {
  const ConduitDimensionsScreen({super.key});
  @override
  ConsumerState<ConduitDimensionsScreen> createState() => _ConduitDimensionsScreenState();
}

class _ConduitDimensionsScreenState extends ConsumerState<ConduitDimensionsScreen> {
  String _racewayType = 'EMT';

  List<_ConduitData> get _currentData => _data[_racewayType] ?? [];
  _RacewayInfo get _currentInfo => _racewayInfo[_racewayType]!;

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
          'Conduit Dimensions',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.info, color: colors.textSecondary),
            onPressed: () => _showFillRules(context, colors),
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
          // Raceway type selector
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _data.keys.map((type) {
                final isSelected = _racewayType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _racewayType = type);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.bgElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? colors.accentPrimary : colors.borderDefault,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          type,
                          style: TextStyle(
                            color: isSelected ? colors.bgBase : colors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Raceway info card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.accentPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _currentInfo.icon,
                    color: colors.accentPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentInfo.fullName,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _currentInfo.description,
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.accentPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _currentInfo.necArticle,
                    style: TextStyle(
                      color: colors.accentPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tap hint
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
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
          ),
          const SizedBox(height: 8),
          // Table header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                _HeaderCell('Size', flex: 2, colors: colors),
                _HeaderCell('ID', flex: 2, colors: colors),
                _HeaderCell('100%', flex: 2, colors: colors),
                _HeaderCell('40%', flex: 2, colors: colors, isHighlight: true),
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
                  final conduit = _currentData[index];
                  final isEven = index % 2 == 0;
                  return _ConduitRow(
                    conduit: conduit,
                    racewayType: _racewayType,
                    isEven: isEven,
                    colors: colors,
                    onTap: () => _showConduitDetails(context, conduit, colors),
                  );
                },
              ),
            ),
          ),
          // Legend
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LegendItem('ID', 'Internal ø (in)', colors),
                _LegendItem('100%', 'Total area (sq in)', colors),
                _LegendItem('40%', 'Max fill 3+ wires', colors, isHighlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showConduitDetails(BuildContext context, _ConduitData conduit, ZaftoColors colors) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ConduitDetailSheet(
        conduit: conduit,
        racewayType: _racewayType,
        racewayInfo: _currentInfo,
        colors: colors,
      ),
    );
  }

  void _showFillRules(BuildContext context, ZaftoColors colors) {
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
              'Conduit Fill Rules',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'NEC Chapter 9, Table 1',
              style: TextStyle(color: colors.textTertiary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _FillRuleRow(colors: colors, wires: '1 wire', fill: '53%', desc: 'Single conductor'),
            _FillRuleRow(colors: colors, wires: '2 wires', fill: '31%', desc: 'Two conductors'),
            _FillRuleRow(colors: colors, wires: '3+ wires', fill: '40%', desc: 'Over 2 conductors', isCommon: true),
            const SizedBox(height: 16),
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
                      'These percentages include insulation. Equipment grounding conductors are counted in fill calculations.',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
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
// CONDUIT DETAIL SHEET
// ============================================================================

class _ConduitDetailSheet extends StatelessWidget {
  final _ConduitData conduit;
  final String racewayType;
  final _RacewayInfo racewayInfo;
  final ZaftoColors colors;

  const _ConduitDetailSheet({
    required this.conduit,
    required this.racewayType,
    required this.racewayInfo,
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
                          conduit.tradeSize,
                          style: TextStyle(
                            fontSize: 18,
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
                            '$racewayType ${conduit.tradeSize}"',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            '${racewayInfo.fullName} (Metric ${conduit.metric})',
                            style: TextStyle(
                              color: colors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Dimensions section
                Text(
                  'DIMENSIONS',
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
                      child: _DetailCard(
                        colors: colors,
                        label: 'Internal Diameter',
                        value: '${conduit.id}"',
                        subvalue: '${(conduit.id * 25.4).toStringAsFixed(1)} mm',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DetailCard(
                        colors: colors,
                        label: 'Total Area',
                        value: '${conduit.area} sq in',
                        subvalue: '100% fill',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Fill percentages
                Text(
                  'FILL CAPACITY',
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
                      child: _FillCard(
                        colors: colors,
                        fill: '53%',
                        area: (conduit.area * 0.53).toStringAsFixed(3),
                        desc: '1 wire',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FillCard(
                        colors: colors,
                        fill: '31%',
                        area: (conduit.area * 0.31).toStringAsFixed(3),
                        desc: '2 wires',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FillCard(
                        colors: colors,
                        fill: '40%',
                        area: conduit.area40.toStringAsFixed(3),
                        desc: '3+ wires',
                        isHighlight: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Use in calculator button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening Conduit Fill Calculator...'),
                          backgroundColor: colors.accentPrimary,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.calculator),
                    label: const Text('Use in Conduit Fill Calculator'),
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
}

class _DetailCard extends StatelessWidget {
  final ZaftoColors colors;
  final String label;
  final String value;
  final String subvalue;

  const _DetailCard({
    required this.colors,
    required this.label,
    required this.value,
    required this.subvalue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.fillDefault,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            subvalue,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _FillCard extends StatelessWidget {
  final ZaftoColors colors;
  final String fill;
  final String area;
  final String desc;
  final bool isHighlight;

  const _FillCard({
    required this.colors,
    required this.fill,
    required this.area,
    required this.desc,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isHighlight
            ? colors.accentPrimary.withValues(alpha: 0.1)
            : colors.fillDefault,
        borderRadius: BorderRadius.circular(10),
        border: isHighlight
            ? Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        children: [
          Text(
            fill,
            style: TextStyle(
              color: isHighlight ? colors.accentPrimary : colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$area sq in',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
            ),
          ),
          Text(
            desc,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CONDUIT ROW
// ============================================================================

class _ConduitRow extends StatelessWidget {
  final _ConduitData conduit;
  final String racewayType;
  final bool isEven;
  final ZaftoColors colors;
  final VoidCallback onTap;

  const _ConduitRow({
    required this.conduit,
    required this.racewayType,
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              _DataCell(conduit.tradeSize, flex: 2, bold: true, colors: colors),
              _DataCell('${conduit.id}"', flex: 2, colors: colors),
              _DataCell('${conduit.area}', flex: 2, colors: colors),
              _DataCell('${conduit.area40}', flex: 2, highlight: true, colors: colors),
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

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  final ZaftoColors colors;
  final bool isHighlight;

  const _HeaderCell(
    this.text, {
    this.flex = 1,
    required this.colors,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: isHighlight ? colors.accentPrimary : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool bold;
  final bool highlight;
  final ZaftoColors colors;

  const _DataCell(
    this.text, {
    this.flex = 1,
    this.bold = false,
    this.highlight = false,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            color: highlight ? colors.accentPrimary : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final String desc;
  final ZaftoColors colors;
  final bool isHighlight;

  const _LegendItem(this.label, this.desc, this.colors, {this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isHighlight ? colors.accentPrimary : colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        Text(
          desc,
          style: TextStyle(color: colors.textTertiary, fontSize: 10),
        ),
      ],
    );
  }
}

class _FillRuleRow extends StatelessWidget {
  final ZaftoColors colors;
  final String wires;
  final String fill;
  final String desc;
  final bool isCommon;

  const _FillRuleRow({
    required this.colors,
    required this.wires,
    required this.fill,
    required this.desc,
    this.isCommon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCommon
            ? colors.accentPrimary.withValues(alpha: 0.1)
            : colors.fillDefault,
        borderRadius: BorderRadius.circular(8),
        border: isCommon
            ? Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              wires,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCommon ? colors.accentPrimary : colors.accentPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              fill,
              style: TextStyle(
                color: isCommon ? colors.bgBase : colors.accentPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
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
          if (isCommon)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.accentSuccess,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'COMMON',
                style: TextStyle(
                  color: colors.bgBase,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// DATA
// ============================================================================

class _RacewayInfo {
  final String fullName;
  final String description;
  final String necArticle;
  final IconData icon;

  const _RacewayInfo({
    required this.fullName,
    required this.description,
    required this.necArticle,
    required this.icon,
  });
}

const Map<String, _RacewayInfo> _racewayInfo = {
  'EMT': _RacewayInfo(
    fullName: 'Electrical Metallic Tubing',
    description: 'Thin-wall steel, most common',
    necArticle: 'Art. 358',
    icon: LucideIcons.pipette,
  ),
  'IMC': _RacewayInfo(
    fullName: 'Intermediate Metal Conduit',
    description: 'Medium-wall, stronger than EMT',
    necArticle: 'Art. 342',
    icon: LucideIcons.pipette,
  ),
  'RMC': _RacewayInfo(
    fullName: 'Rigid Metal Conduit',
    description: 'Heavy-wall steel, threaded',
    necArticle: 'Art. 344',
    icon: LucideIcons.pipette,
  ),
  'PVC40': _RacewayInfo(
    fullName: 'PVC Schedule 40',
    description: 'Non-metallic, standard wall',
    necArticle: 'Art. 352',
    icon: LucideIcons.circle,
  ),
  'PVC80': _RacewayInfo(
    fullName: 'PVC Schedule 80',
    description: 'Non-metallic, heavy wall',
    necArticle: 'Art. 352',
    icon: LucideIcons.circle,
  ),
  'FMC': _RacewayInfo(
    fullName: 'Flexible Metal Conduit',
    description: 'Flexible steel, for equipment',
    necArticle: 'Art. 348',
    icon: LucideIcons.waves,
  ),
};

class _ConduitData {
  final String tradeSize;
  final String metric;
  final double id;
  final double area;
  final double area40;
  final double area60;

  const _ConduitData({
    required this.tradeSize,
    required this.metric,
    required this.id,
    required this.area,
    required this.area40,
    required this.area60,
  });
}

const Map<String, List<_ConduitData>> _data = {
  'EMT': [
    _ConduitData(tradeSize: '1/2', metric: '16', id: 0.622, area: 0.304, area40: 0.122, area60: 0.182),
    _ConduitData(tradeSize: '3/4', metric: '21', id: 0.824, area: 0.533, area40: 0.213, area60: 0.320),
    _ConduitData(tradeSize: '1', metric: '27', id: 1.049, area: 0.864, area40: 0.346, area60: 0.519),
    _ConduitData(tradeSize: '1-1/4', metric: '35', id: 1.380, area: 1.496, area40: 0.598, area60: 0.897),
    _ConduitData(tradeSize: '1-1/2', metric: '41', id: 1.610, area: 2.036, area40: 0.814, area60: 1.221),
    _ConduitData(tradeSize: '2', metric: '53', id: 2.067, area: 3.356, area40: 1.342, area60: 2.013),
    _ConduitData(tradeSize: '2-1/2', metric: '63', id: 2.731, area: 5.858, area40: 2.343, area60: 3.515),
    _ConduitData(tradeSize: '3', metric: '78', id: 3.356, area: 8.846, area40: 3.538, area60: 5.307),
    _ConduitData(tradeSize: '3-1/2', metric: '91', id: 3.834, area: 11.545, area40: 4.618, area60: 6.927),
    _ConduitData(tradeSize: '4', metric: '103', id: 4.334, area: 14.753, area40: 5.901, area60: 8.852),
  ],
  'IMC': [
    _ConduitData(tradeSize: '1/2', metric: '16', id: 0.660, area: 0.342, area40: 0.137, area60: 0.205),
    _ConduitData(tradeSize: '3/4', metric: '21', id: 0.864, area: 0.586, area40: 0.235, area60: 0.352),
    _ConduitData(tradeSize: '1', metric: '27', id: 1.105, area: 0.959, area40: 0.384, area60: 0.575),
    _ConduitData(tradeSize: '1-1/4', metric: '35', id: 1.448, area: 1.647, area40: 0.659, area60: 0.988),
    _ConduitData(tradeSize: '1-1/2', metric: '41', id: 1.683, area: 2.225, area40: 0.890, area60: 1.335),
    _ConduitData(tradeSize: '2', metric: '53', id: 2.150, area: 3.630, area40: 1.452, area60: 2.178),
    _ConduitData(tradeSize: '2-1/2', metric: '63', id: 2.557, area: 5.135, area40: 2.054, area60: 3.081),
    _ConduitData(tradeSize: '3', metric: '78', id: 3.176, area: 7.922, area40: 3.169, area60: 4.753),
    _ConduitData(tradeSize: '3-1/2', metric: '91', id: 3.671, area: 10.584, area40: 4.234, area60: 6.350),
    _ConduitData(tradeSize: '4', metric: '103', id: 4.166, area: 13.631, area40: 5.452, area60: 8.179),
  ],
  'RMC': [
    _ConduitData(tradeSize: '1/2', metric: '16', id: 0.632, area: 0.314, area40: 0.125, area60: 0.188),
    _ConduitData(tradeSize: '3/4', metric: '21', id: 0.836, area: 0.549, area40: 0.220, area60: 0.329),
    _ConduitData(tradeSize: '1', metric: '27', id: 1.063, area: 0.887, area40: 0.355, area60: 0.532),
    _ConduitData(tradeSize: '1-1/4', metric: '35', id: 1.394, area: 1.526, area40: 0.610, area60: 0.916),
    _ConduitData(tradeSize: '1-1/2', metric: '41', id: 1.624, area: 2.071, area40: 0.829, area60: 1.243),
    _ConduitData(tradeSize: '2', metric: '53', id: 2.083, area: 3.408, area40: 1.363, area60: 2.045),
    _ConduitData(tradeSize: '2-1/2', metric: '63', id: 2.489, area: 4.866, area40: 1.946, area60: 2.919),
    _ConduitData(tradeSize: '3', metric: '78', id: 3.090, area: 7.499, area40: 3.000, area60: 4.499),
    _ConduitData(tradeSize: '3-1/2', metric: '91', id: 3.570, area: 10.010, area40: 4.004, area60: 6.006),
    _ConduitData(tradeSize: '4', metric: '103', id: 4.050, area: 12.882, area40: 5.153, area60: 7.729),
  ],
  'PVC40': [
    _ConduitData(tradeSize: '1/2', metric: '16', id: 0.602, area: 0.285, area40: 0.114, area60: 0.171),
    _ConduitData(tradeSize: '3/4', metric: '21', id: 0.804, area: 0.508, area40: 0.203, area60: 0.305),
    _ConduitData(tradeSize: '1', metric: '27', id: 1.029, area: 0.832, area40: 0.333, area60: 0.499),
    _ConduitData(tradeSize: '1-1/4', metric: '35', id: 1.360, area: 1.453, area40: 0.581, area60: 0.872),
    _ConduitData(tradeSize: '1-1/2', metric: '41', id: 1.590, area: 1.986, area40: 0.794, area60: 1.191),
    _ConduitData(tradeSize: '2', metric: '53', id: 2.047, area: 3.291, area40: 1.316, area60: 1.975),
    _ConduitData(tradeSize: '2-1/2', metric: '63', id: 2.445, area: 4.695, area40: 1.878, area60: 2.817),
    _ConduitData(tradeSize: '3', metric: '78', id: 3.042, area: 7.268, area40: 2.907, area60: 4.361),
    _ConduitData(tradeSize: '3-1/2', metric: '91', id: 3.521, area: 9.737, area40: 3.895, area60: 5.842),
    _ConduitData(tradeSize: '4', metric: '103', id: 3.998, area: 12.554, area40: 5.022, area60: 7.532),
  ],
  'PVC80': [
    _ConduitData(tradeSize: '1/2', metric: '16', id: 0.526, area: 0.217, area40: 0.087, area60: 0.130),
    _ConduitData(tradeSize: '3/4', metric: '21', id: 0.722, area: 0.409, area40: 0.164, area60: 0.246),
    _ConduitData(tradeSize: '1', metric: '27', id: 0.936, area: 0.688, area40: 0.275, area60: 0.413),
    _ConduitData(tradeSize: '1-1/4', metric: '35', id: 1.255, area: 1.237, area40: 0.495, area60: 0.742),
    _ConduitData(tradeSize: '1-1/2', metric: '41', id: 1.476, area: 1.711, area40: 0.684, area60: 1.026),
    _ConduitData(tradeSize: '2', metric: '53', id: 1.913, area: 2.874, area40: 1.150, area60: 1.725),
    _ConduitData(tradeSize: '2-1/2', metric: '63', id: 2.290, area: 4.119, area40: 1.647, area60: 2.471),
    _ConduitData(tradeSize: '3', metric: '78', id: 2.864, area: 6.442, area40: 2.577, area60: 3.865),
    _ConduitData(tradeSize: '3-1/2', metric: '91', id: 3.326, area: 8.688, area40: 3.475, area60: 5.213),
    _ConduitData(tradeSize: '4', metric: '103', id: 3.786, area: 11.258, area40: 4.503, area60: 6.755),
  ],
  'FMC': [
    _ConduitData(tradeSize: '3/8', metric: '12', id: 0.384, area: 0.116, area40: 0.046, area60: 0.069),
    _ConduitData(tradeSize: '1/2', metric: '16', id: 0.635, area: 0.317, area40: 0.127, area60: 0.190),
    _ConduitData(tradeSize: '3/4', metric: '21', id: 0.824, area: 0.533, area40: 0.213, area60: 0.320),
    _ConduitData(tradeSize: '1', metric: '27', id: 1.020, area: 0.817, area40: 0.327, area60: 0.490),
    _ConduitData(tradeSize: '1-1/4', metric: '35', id: 1.275, area: 1.277, area40: 0.511, area60: 0.766),
    _ConduitData(tradeSize: '1-1/2', metric: '41', id: 1.538, area: 1.858, area40: 0.743, area60: 1.115),
    _ConduitData(tradeSize: '2', metric: '53', id: 2.040, area: 3.269, area40: 1.307, area60: 1.961),
  ],
};
