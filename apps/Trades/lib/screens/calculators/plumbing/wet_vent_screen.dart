import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Wet Vent Calculator - Design System v2.6
///
/// Calculates wet vent sizing and validates wet vent configurations.
/// Determines if wet venting is permitted and proper sizing.
///
/// References: IPC 2024 Section 908, UPC Section 908
class WetVentScreen extends ConsumerStatefulWidget {
  const WetVentScreen({super.key});
  @override
  ConsumerState<WetVentScreen> createState() => _WetVentScreenState();
}

class _WetVentScreenState extends ConsumerState<WetVentScreen> {
  // Wet vent type
  String _type = 'vertical'; // 'vertical' or 'horizontal'

  // Fixtures served (wet vented)
  int _lavatories = 1;
  int _bathtubs = 0;
  int _showers = 0;
  int _floorDrains = 0;

  // Wet vent connects to
  String _connectsTo = 'toilet'; // 'toilet', 'bathtub', 'sink'

  // Code reference
  String _code = 'ipc';

  // DFU values
  static const Map<String, double> _dfuValues = {
    'lavatory': 1.0,
    'bathtub': 2.0,
    'shower': 2.0,
    'floorDrain': 2.0,
  };

  // Wet vent sizing per IPC Table 908.2
  static const Map<int, String> _wetVentSize = {
    1: '1-1/2',
    2: '1-1/2',
    4: '2',
    6: '2',
    8: '2-1/2',
    12: '3',
    24: '4',
  };

  double get _totalDfu {
    return (_lavatories * _dfuValues['lavatory']!) +
           (_bathtubs * _dfuValues['bathtub']!) +
           (_showers * _dfuValues['shower']!) +
           (_floorDrains * _dfuValues['floorDrain']!);
  }

  int get _fixtureCount {
    return _lavatories + _bathtubs + _showers + _floorDrains;
  }

  bool get _isValidConfiguration {
    // IPC 908.2 - Wet vent serves only fixtures in same bathroom group
    if (_fixtureCount == 0) return false;

    // Can't wet vent toilet only - need at least one other fixture
    if (_type == 'vertical' && _fixtureCount < 1) return false;

    // Max DFU limits
    if (_totalDfu > 24) return false;

    return true;
  }

  String _calculateWetVentSize() {
    final dfu = _totalDfu.round();

    for (final entry in _wetVentSize.entries) {
      if (entry.key >= dfu) {
        return '${entry.value}"';
      }
    }

    return '4"';
  }

  String get _dryVentSize {
    final dfu = _totalDfu.round();
    if (dfu <= 1) return '1-1/4"';
    if (dfu <= 4) return '1-1/2"';
    if (dfu <= 8) return '2"';
    if (dfu <= 24) return '2-1/2"';
    return '3"';
  }

  List<String> get _requirements {
    final reqs = <String>[];

    reqs.add('Fixtures must be on same floor level');
    reqs.add('All fixtures must be within same bathroom group');
    reqs.add('Wet vent connects to drain at or below fixture being vented');

    if (_type == 'vertical') {
      reqs.add('Vertical wet vent serves fixtures above it');
      reqs.add('Min 1-1/2" vent size for lavatory');
    } else {
      reqs.add('Horizontal wet vent must slope toward drain');
      reqs.add('Max developed length per IPC Table 906.1');
    }

    if (_connectsTo == 'toilet') {
      reqs.add('Min 3" wet vent when connected to WC');
    }

    return reqs;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final wetVentSize = _calculateWetVentSize();

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
          'Wet Vent Calculator',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors, wetVentSize),
          const SizedBox(height: 16),
          _buildCodeSelector(colors),
          const SizedBox(height: 16),
          _buildTypeCard(colors),
          const SizedBox(height: 16),
          _buildFixturesCard(colors),
          const SizedBox(height: 16),
          _buildConnectionCard(colors),
          const SizedBox(height: 16),
          _buildRequirementsCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors, String wetVentSize) {
    final isValid = _isValidConfiguration;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isValid
              ? colors.accentPrimary.withValues(alpha: 0.2)
              : colors.accentError.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          if (!isValid) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.accentError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Invalid Configuration',
                    style: TextStyle(color: colors.accentError, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            wetVentSize,
            style: TextStyle(
              color: isValid ? colors.accentPrimary : colors.textTertiary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Wet Vent Size',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Type', _type == 'vertical' ? 'Vertical' : 'Horizontal'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Fixtures', '$_fixtureCount'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Total DFU', _totalDfu.toStringAsFixed(1)),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Wet Vent Size', wetVentSize, highlight: true),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Dry Vent Size', _dryVentSize),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeSelector(ZaftoColors colors) {
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
            'CODE REFERENCE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _code = 'ipc');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _code == 'ipc' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'IPC 2024',
                        style: TextStyle(
                          color: _code == 'ipc'
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _code = 'upc');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _code == 'upc' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'UPC 2024',
                        style: TextStyle(
                          color: _code == 'upc'
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(ZaftoColors colors) {
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
            'WET VENT TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _type = 'vertical');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _type == 'vertical' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.arrowUp,
                          color: _type == 'vertical'
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vertical',
                          style: TextStyle(
                            color: _type == 'vertical'
                                ? (colors.isDark ? Colors.black : Colors.white)
                                : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _type = 'horizontal');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _type == 'horizontal' ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.arrowRight,
                          color: _type == 'horizontal'
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.textPrimary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Horizontal',
                          style: TextStyle(
                            color: _type == 'horizontal'
                                ? (colors.isDark ? Colors.black : Colors.white)
                                : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFixturesCard(ZaftoColors colors) {
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
            'FIXTURES BEING WET VENTED',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildFixtureRow(colors, 'Lavatories', _lavatories, (v) => setState(() => _lavatories = v), dfu: 1),
          _buildFixtureRow(colors, 'Bathtubs', _bathtubs, (v) => setState(() => _bathtubs = v), dfu: 2),
          _buildFixtureRow(colors, 'Showers', _showers, (v) => setState(() => _showers = v), dfu: 2),
          _buildFixtureRow(colors, 'Floor Drains', _floorDrains, (v) => setState(() => _floorDrains = v), dfu: 2),
        ],
      ),
    );
  }

  Widget _buildFixtureRow(ZaftoColors colors, String label, int count, Function(int) onChanged, {required int dfu}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                ),
                Text(
                  '$dfu DFU each',
                  style: TextStyle(color: colors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (count > 0) onChanged(count - 1);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(LucideIcons.minus, color: colors.textSecondary, size: 18),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '$count',
                  style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (count < 10) onChanged(count + 1);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.accentPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(LucideIcons.plus, color: colors.isDark ? Colors.black : Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(ZaftoColors colors) {
    final connections = [
      (value: 'toilet', label: 'Toilet (WC)'),
      (value: 'bathtub', label: 'Bathtub/Shower'),
      (value: 'sink', label: 'Kitchen Sink'),
    ];

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
            'WET VENT CONNECTS TO',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: connections.map((conn) {
              final isSelected = _connectsTo == conn.value;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _connectsTo = conn.value);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    conn.label,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

  Widget _buildRequirementsCard(ZaftoColors colors) {
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
            'WET VENT REQUIREMENTS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._requirements.map((req) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.checkCircle, color: colors.accentPrimary, size: 14),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      req,
                      style: TextStyle(color: colors.textPrimary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: highlight ? colors.accentPrimary : colors.textPrimary,
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
          ),
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
                '${_code.toUpperCase()} 2024 Section 908',
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
            '• Wet vent = drain pipe that also serves as vent\n'
            '• IPC 908.2 - Vertical wet venting\n'
            '• IPC 908.3 - Horizontal wet venting\n'
            '• Min 2" when receiving WC discharge\n'
            '• Table 908.2 for sizing by DFU\n'
            '• Not permitted for all configurations',
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
