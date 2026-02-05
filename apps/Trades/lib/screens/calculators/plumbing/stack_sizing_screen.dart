import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Stack Sizing Calculator - Design System v2.6
///
/// Sizes soil and waste stacks based on DFU load and stories.
/// Critical for multi-story drainage systems.
///
/// References: IPC 2024 Table 710.1(1), Table 710.1(2)
class StackSizingScreen extends ConsumerStatefulWidget {
  const StackSizingScreen({super.key});
  @override
  ConsumerState<StackSizingScreen> createState() => _StackSizingScreenState();
}

class _StackSizingScreenState extends ConsumerState<StackSizingScreen> {
  // Total DFU connected to stack
  double _totalDFU = 48.0;

  // Number of stories
  int _stories = 3;

  // Stack type
  String _stackType = 'soil';

  // Branch interval count
  int _branchIntervals = 3;

  // Stack types
  static const Map<String, ({String name, String desc})> _stackTypes = {
    'soil': (name: 'Soil Stack', desc: 'Receives toilet discharge'),
    'waste': (name: 'Waste Stack', desc: 'No toilet discharge'),
    'combined': (name: 'Combined Stack', desc: 'Both soil and waste'),
  };

  // IPC Table 710.1(1) - Stack sizing
  // Max DFU for stack (total) and per branch interval
  static const List<({String size, int maxTotal, int maxBranch, int maxStories})> _stackSizing = [
    (size: '1-1/2"', maxTotal: 2, maxBranch: 1, maxStories: 2),
    (size: '2"', maxTotal: 6, maxBranch: 2, maxStories: 2),
    (size: '2-1/2"', maxTotal: 12, maxBranch: 6, maxStories: 2),
    (size: '3"', maxTotal: 48, maxBranch: 20, maxStories: 8),
    (size: '4"', maxTotal: 240, maxBranch: 90, maxStories: 35),
    (size: '5"', maxTotal: 540, maxBranch: 200, maxStories: 70),
    (size: '6"', maxTotal: 960, maxBranch: 350, maxStories: 100),
    (size: '8"', maxTotal: 2200, maxBranch: 600, maxStories: 100),
    (size: '10"', maxTotal: 3800, maxBranch: 1000, maxStories: 100),
    (size: '12"', maxTotal: 6000, maxBranch: 1500, maxStories: 100),
  ];

  // DFU per floor (approximate)
  double get _dfuPerFloor {
    if (_stories <= 0) return _totalDFU;
    return _totalDFU / _stories;
  }

  // Recommended stack size
  String get _recommendedSize {
    final dfu = _totalDFU.toInt();
    final perBranch = _dfuPerFloor.toInt();

    for (final stack in _stackSizing) {
      // Check both total and per-branch limits
      if (dfu <= stack.maxTotal && perBranch <= stack.maxBranch && _stories <= stack.maxStories) {
        return stack.size;
      }
    }
    return '12" or larger';
  }

  // Get max DFU for recommended size
  int get _maxDFUForSize {
    final size = _recommendedSize;
    for (final stack in _stackSizing) {
      if (stack.size == size) {
        return stack.maxTotal;
      }
    }
    return 1000;
  }

  // Capacity used percentage
  double get _capacityUsed {
    return (_totalDFU / _maxDFUForSize) * 100;
  }

  // Minimum stack size for toilets
  String get _minimumForToilets {
    if (_stackType == 'soil' || _stackType == 'combined') {
      return '3"'; // Minimum for soil stacks
    }
    return '1-1/2"';
  }

  // Check if size meets toilet requirements
  bool get _meetsSoilRequirement {
    final sizes = ['1-1/2"', '2"', '2-1/2"', '3"', '4"', '5"', '6"', '8"', '10"', '12"'];
    final recIndex = sizes.indexOf(_recommendedSize);
    final minIndex = sizes.indexOf(_minimumForToilets);
    return recIndex >= minIndex;
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
          'Stack Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildStackTypeCard(colors),
          const SizedBox(height: 16),
          _buildDFUCard(colors),
          const SizedBox(height: 16),
          _buildStoriesCard(colors),
          const SizedBox(height: 16),
          _buildSizingTable(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final actualSize = _meetsSoilRequirement ? _recommendedSize : _minimumForToilets;

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
            actualSize,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Minimum Stack Size',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          if (!_meetsSoilRequirement) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.accentWarning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Increased to $_minimumForToilets min for soil stack',
                style: TextStyle(color: colors.accentWarning, fontSize: 10),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Total DFU', _totalDFU.toStringAsFixed(0)),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'DFU per Floor', _dfuPerFloor.toStringAsFixed(1)),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Stories', _stories.toString()),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Stack Type', _stackTypes[_stackType]?.name ?? 'Soil'),
                Divider(color: colors.borderSubtle, height: 16),
                _buildResultRow(colors, 'Capacity Used', '${_capacityUsed.toStringAsFixed(0)}%', highlight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackTypeCard(ZaftoColors colors) {
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
            'STACK TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._stackTypes.entries.map((entry) {
            final isSelected = _stackType == entry.key;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _stackType = entry.key);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: colors.accentPrimary) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
                      color: isSelected ? colors.accentPrimary : colors.textTertiary,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value.name,
                            style: TextStyle(
                              color: isSelected ? colors.accentPrimary : colors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            entry.value.desc,
                            style: TextStyle(color: colors.textTertiary, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDFUCard(ZaftoColors colors) {
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
            'TOTAL DFU LOAD',
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
                '${_totalDFU.toStringAsFixed(0)} DFU',
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
                    value: _totalDFU,
                    min: 2,
                    max: 500,
                    divisions: 50,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _totalDFU = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Sum of all fixtures draining to this stack',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesCard(ZaftoColors colors) {
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
            'NUMBER OF STORIES',
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
            children: [1, 2, 3, 4, 5, 6, 8, 10].map((stories) {
              final isSelected = _stories == stories;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _stories = stories);
                },
                child: Container(
                  width: 48,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    stories.toString(),
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Floors with fixtures draining to this stack',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSizingTable(ZaftoColors colors) {
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
            'IPC TABLE 710.1(1) - STACKS',
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
              const SizedBox(width: 50),
              Expanded(child: Text('Max Total', style: TextStyle(color: colors.textSecondary, fontSize: 10), textAlign: TextAlign.center)),
              Expanded(child: Text('Per Branch', style: TextStyle(color: colors.textSecondary, fontSize: 10), textAlign: TextAlign.center)),
              Expanded(child: Text('Max Stories', style: TextStyle(color: colors.textSecondary, fontSize: 10), textAlign: TextAlign.center)),
            ],
          ),
          const SizedBox(height: 6),
          ..._stackSizing.take(8).map((stack) {
            final isRecommended = stack.size == _recommendedSize;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isRecommended ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgBase,
                borderRadius: BorderRadius.circular(6),
                border: isRecommended ? Border.all(color: colors.accentPrimary) : null,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      stack.size,
                      style: TextStyle(
                        color: isRecommended ? colors.accentPrimary : colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Text('${stack.maxTotal}', style: TextStyle(color: colors.textSecondary, fontSize: 11), textAlign: TextAlign.center)),
                  Expanded(child: Text('${stack.maxBranch}', style: TextStyle(color: colors.textSecondary, fontSize: 11), textAlign: TextAlign.center)),
                  Expanded(child: Text('${stack.maxStories}', style: TextStyle(color: colors.textSecondary, fontSize: 11), textAlign: TextAlign.center)),
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
                'IPC 2024 Section 710',
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
            '• Table 710.1(1) - Stack sizing\n'
            '• Min 3" for soil stacks (toilets)\n'
            '• Min 1-1/2" for waste stacks\n'
            '• Size for total DFU and per branch\n'
            '• Consider stack offset requirements\n'
            '• Vent sizing depends on stack size',
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
