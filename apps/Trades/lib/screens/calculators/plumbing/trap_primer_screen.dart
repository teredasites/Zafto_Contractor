import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Trap Primer Calculator - Design System v2.6
///
/// Sizes trap primers for floor drains and seldom-used fixtures.
/// Prevents trap seal loss from evaporation.
///
/// References: IPC 2024 Section 1002
class TrapPrimerScreen extends ConsumerStatefulWidget {
  const TrapPrimerScreen({super.key});
  @override
  ConsumerState<TrapPrimerScreen> createState() => _TrapPrimerScreenState();
}

class _TrapPrimerScreenState extends ConsumerState<TrapPrimerScreen> {
  // Primer type
  String _primerType = 'pressure';

  // Number of traps to prime
  int _trapCount = 1;

  // Trap size
  String _trapSize = '2';

  // Distribution distance (ft from primer)
  double _maxDistance = 15;

  static const Map<String, ({String desc, int maxTraps, bool needsPressure})> _primerTypes = {
    'pressure': (desc: 'Pressure-Operated', maxTraps: 4, needsPressure: true),
    'electronic': (desc: 'Electronic Timer', maxTraps: 8, needsPressure: false),
    'trap_seal': (desc: 'Trap Seal Primer', maxTraps: 1, needsPressure: true),
    'supply_fitting': (desc: 'Supply Fitting Type', maxTraps: 1, needsPressure: true),
  };

  static const Map<String, ({double tubingSize, double flowRate})> _trapSizes = {
    '2': (tubingSize: 0.5, flowRate: 0.25),
    '3': (tubingSize: 0.5, flowRate: 0.35),
    '4': (tubingSize: 0.5, flowRate: 0.5),
  };

  int get _maxTrapsForType => _primerTypes[_primerType]?.maxTraps ?? 4;
  bool get _exceedsMax => _trapCount > _maxTrapsForType;
  double get _tubeSize => _trapSizes[_trapSize]?.tubingSize ?? 0.5;
  double get _flowPerTrap => _trapSizes[_trapSize]?.flowRate ?? 0.25;

  int get _primersNeeded {
    if (_trapCount <= _maxTrapsForType) return 1;
    return ((_trapCount + _maxTrapsForType - 1) / _maxTrapsForType).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

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
          'Trap Primer',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildPrimerTypeCard(colors),
          const SizedBox(height: 16),
          _buildTrapConfigCard(colors),
          const SizedBox(height: 16),
          _buildDistributionCard(colors),
          const SizedBox(height: 16),
          _buildInstallationCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    final statusColor = _exceedsMax ? colors.accentWarning : colors.accentSuccess;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '$_primersNeeded',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Primer${_primersNeeded != 1 ? 's' : ''} Required',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          if (_exceedsMax) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertTriangle, color: statusColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Multiple Primers Needed',
                    style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Primer Type', _primerTypes[_primerType]?.desc ?? 'Pressure'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Traps to Prime', '$_trapCount'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Max per Primer', '$_maxTrapsForType'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Distribution Tubing', '½" OD'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Flow per Trap', '${_flowPerTrap.toStringAsFixed(2)} GPM'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimerTypeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRIMER TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._primerTypes.entries.map((entry) {
            final isSelected = _primerType == entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _primerType = entry.key;
                    if (_trapCount > entry.value.maxTraps) {
                      _trapCount = entry.value.maxTraps;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.value.desc,
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        'Max ${entry.value.maxTraps} traps',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTrapConfigCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRAP CONFIGURATION',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Number of Traps', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '$_trapCount',
                style: TextStyle(
                  color: _exceedsMax ? colors.accentWarning : colors.accentPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _exceedsMax ? colors.accentWarning : colors.accentPrimary,
              inactiveTrackColor: colors.bgBase,
              thumbColor: _exceedsMax ? colors.accentWarning : colors.accentPrimary,
              trackHeight: 4,
            ),
            child: Slider(
              value: _trapCount.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _trapCount = v.round());
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'TRAP SIZE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _trapSizes.keys.map((size) {
              final isSelected = _trapSize == size;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _trapSize = size);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accentPrimary : colors.bgBase,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$size"',
                          style: TextStyle(
                            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DISTRIBUTION',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Max Distance from Primer', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              Text(
                '${_maxDistance.toStringAsFixed(0)} ft',
                style: TextStyle(color: colors.accentPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.accentPrimary,
              inactiveTrackColor: colors.bgBase,
              thumbColor: colors.accentPrimary,
              trackHeight: 4,
            ),
            child: Slider(
              value: _maxDistance,
              min: 5,
              max: 50,
              divisions: 9,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _maxDistance = v);
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Typical max is 20-25\' per manufacturer specs',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallationCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INSTALLATION REQUIREMENTS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildDimRow(colors, 'Distribution Tubing', '½" OD copper or approved'),
          _buildDimRow(colors, 'Connection', 'Above trap weir'),
          _buildDimRow(colors, 'Frequency', 'Per flush or timed interval'),
          _buildDimRow(colors, 'Water Volume', '${(_flowPerTrap * 0.5).toStringAsFixed(2)} gal per prime'),
          if (_primerTypes[_primerType]?.needsPressure ?? false)
            _buildDimRow(colors, 'Pressure', 'Min 20 PSI water supply'),
        ],
      ),
    );
  }

  Widget _buildDimRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.dot, color: colors.accentPrimary, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: colors.textPrimary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.scale, color: colors.textTertiary, size: 16),
              const SizedBox(width: 8),
              Text(
                'IPC 2024 Section 1002',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• IPC 1002.4: Trap seal protection\n'
            '• Required for floor drains\n'
            '• Prevent sewer gas entry\n'
            '• Electronic or pressure types\n'
            '• Connect above trap weir\n'
            '• ASSE 1018 or 1044 listed',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
