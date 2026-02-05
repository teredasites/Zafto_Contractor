import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Cleanout Placement Calculator - Design System v2.6
///
/// Determines required cleanout locations per IPC/UPC.
/// Helps ensure code-compliant cleanout placement.
///
/// References: IPC 2024 Section 708, UPC Section 707
class CleanoutPlacementScreen extends ConsumerStatefulWidget {
  const CleanoutPlacementScreen({super.key});
  @override
  ConsumerState<CleanoutPlacementScreen> createState() => _CleanoutPlacementScreenState();
}

class _CleanoutPlacementScreenState extends ConsumerState<CleanoutPlacementScreen> {
  // Total run length
  double _runLength = 75;

  // Pipe size
  String _pipeSize = '4';

  // Number of direction changes
  int _directionChanges = 2;

  // Building drain connection
  bool _hasBuildingDrain = true;

  // Stack base
  bool _hasStackBase = true;

  // Code reference
  String _code = 'ipc';

  // Max spacing by pipe size per IPC
  static const Map<String, int> _maxSpacing = {
    '2': 50,
    '3': 50,
    '4': 100,
    '6': 100,
    '8': 100,
  };

  static const List<String> _pipeSizes = ['2', '3', '4', '6', '8'];

  int get _maxCleanoutSpacing => _maxSpacing[_pipeSize] ?? 100;

  int get _cleanoutsForLength {
    if (_runLength <= _maxCleanoutSpacing) return 1;
    return ((_runLength / _maxCleanoutSpacing).ceil());
  }

  int get _cleanoutsForDirectionChanges {
    // Cleanout required at each aggregate change of direction > 135°
    return _directionChanges;
  }

  int get _requiredCleanouts {
    int count = _cleanoutsForLength;
    if (_hasBuildingDrain) count++; // Upper terminal
    if (_hasStackBase) count++; // Base of each stack
    // Direction changes may overlap with spacing cleanouts
    final directionCleanouts = _cleanoutsForDirectionChanges > 0 ? _cleanoutsForDirectionChanges - 1 : 0;
    return count + directionCleanouts;
  }

  List<String> get _requiredLocations {
    final locations = <String>[];

    if (_hasBuildingDrain) {
      locations.add('Upper terminal of building drain');
    }

    if (_hasStackBase) {
      locations.add('Base of each stack');
    }

    // Spacing cleanouts
    if (_runLength > 0) {
      final spacing = _maxCleanoutSpacing;
      locations.add('Every ${spacing}ft max along horizontal run');
    }

    // Direction changes
    if (_directionChanges > 0) {
      locations.add('At each aggregate direction change >135°');
    }

    // Additional requirements
    locations.add('Where building sewer meets building drain');
    if (_code == 'upc') {
      locations.add('At junction of building sewer and public sewer');
    }

    return locations;
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
          'Cleanout Placement',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultCard(colors),
          const SizedBox(height: 16),
          _buildCodeSelector(colors),
          const SizedBox(height: 16),
          _buildPipeSizeCard(colors),
          const SizedBox(height: 16),
          _buildRunLengthCard(colors),
          const SizedBox(height: 16),
          _buildDirectionChangesCard(colors),
          const SizedBox(height: 16),
          _buildOptionsCard(colors),
          const SizedBox(height: 16),
          _buildLocationsCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
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
            '$_requiredCleanouts',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Cleanouts Required (min)',
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
                _buildResultRow(colors, 'Pipe Size', '$_pipeSize"'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Run Length', '${_runLength.toStringAsFixed(0)} ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Max Spacing', '$_maxCleanoutSpacing ft'),
                const SizedBox(height: 10),
                _buildResultRow(colors, 'Direction Changes', '$_directionChanges'),
                Divider(color: colors.borderSubtle, height: 20),
                _buildResultRow(colors, 'Min Cleanouts', '$_requiredCleanouts', highlight: true),
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

  Widget _buildPipeSizeCard(ZaftoColors colors) {
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
            'PIPE SIZE',
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
            children: _pipeSizes.map((size) {
              final isSelected = _pipeSize == size;
              final spacing = _maxSpacing[size] ?? 100;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeSize = size);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$size"',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${spacing}ft max',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black54 : Colors.white70) : colors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRunLengthCard(ZaftoColors colors) {
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
            'TOTAL RUN LENGTH',
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
              Text(
                '${_runLength.toStringAsFixed(0)} ft',
                style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.accentPrimary,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: colors.accentPrimary,
                  ),
                  child: Slider(
                    value: _runLength,
                    min: 0,
                    max: 300,
                    divisions: 60,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _runLength = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Total horizontal drain run',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionChangesCard(ZaftoColors colors) {
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
            'DIRECTION CHANGES (>135° TOTAL)',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(6, (i) {
              final isSelected = _directionChanges == i;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _directionChanges = i);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? colors.accentPrimary : colors.bgBase,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$i',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Count locations where cumulative turns exceed 135°',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard(ZaftoColors colors) {
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
            'SYSTEM COMPONENTS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _buildToggle(colors, 'Building Drain', _hasBuildingDrain, (v) => setState(() => _hasBuildingDrain = v)),
          _buildToggle(colors, 'Stack Base', _hasStackBase, (v) => setState(() => _hasStackBase = v)),
        ],
      ),
    );
  }

  Widget _buildToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? colors.accentPrimary : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: value ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: value
                  ? Icon(LucideIcons.check, color: colors.isDark ? Colors.black : Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationsCard(ZaftoColors colors) {
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
            'REQUIRED LOCATIONS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._requiredLocations.map((location) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.check, color: colors.accentPrimary, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(color: colors.textPrimary, fontSize: 13),
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
                '${_code.toUpperCase()} 2024',
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
            '• IPC 708.1 - Max 100ft for 4"+, 50ft for <4"\n'
            '• Cleanout at upper terminal of building drain\n'
            '• Base of each waste/soil stack\n'
            '• At direction change >135° aggregate\n'
            '• Min 3" for building drain cleanout\n'
            '• Must be accessible',
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
