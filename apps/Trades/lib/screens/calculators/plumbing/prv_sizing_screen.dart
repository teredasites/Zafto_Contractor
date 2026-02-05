import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Pressure Reducing Valve (PRV) Sizing - Design System v2.6
///
/// Sizes PRVs for water service protection from high street pressure.
/// Required when supply exceeds 80 psi per IPC.
///
/// References: IPC 604.8, Watts/Zurn valve data
class PRVSizingScreen extends ConsumerStatefulWidget {
  const PRVSizingScreen({super.key});
  @override
  ConsumerState<PRVSizingScreen> createState() => _PRVSizingScreenState();
}

class _PRVSizingScreenState extends ConsumerState<PRVSizingScreen> {
  // Inlet pressure (psi)
  double _inletPressure = 100.0;

  // Desired outlet pressure (psi)
  double _outletPressure = 55.0;

  // Peak flow rate (GPM)
  double _flowRate = 25.0;

  // Pipe size (inches)
  String _pipeSize = '3/4';

  // PRV type
  String _prvType = 'standard';

  // Common pipe sizes
  static const List<String> _pipeSizes = ['1/2', '3/4', '1', '1-1/4', '1-1/2', '2'];

  // PRV types with characteristics
  static const Map<String, ({String name, String desc, double maxFlow, double minDrop})> _prvTypes = {
    'standard': (name: 'Standard Direct Acting', desc: 'Residential, simple operation', maxFlow: 35, minDrop: 10),
    'pilot': (name: 'Pilot Operated', desc: 'Commercial, better accuracy', maxFlow: 200, minDrop: 5),
    'cartridge': (name: 'Cartridge Style', desc: 'Easy service, medium flow', maxFlow: 50, minDrop: 8),
    'doubleStage': (name: 'Double Stage', desc: 'Very high inlet pressure', maxFlow: 40, minDrop: 15),
  };

  // PRV sizing by pipe and flow
  static const Map<String, ({double maxGPM, String prvSize})> _sizingData = {
    '1/2': (maxGPM: 15, prvSize: '1/2"'),
    '3/4': (maxGPM: 30, prvSize: '3/4"'),
    '1': (maxGPM: 50, prvSize: '1"'),
    '1-1/4': (maxGPM: 80, prvSize: '1-1/4"'),
    '1-1/2': (maxGPM: 120, prvSize: '1-1/2"'),
    '2': (maxGPM: 200, prvSize: '2"'),
  };

  // Pressure reduction ratio
  double get _reductionRatio {
    if (_outletPressure <= 0) return 0;
    return _inletPressure / _outletPressure;
  }

  // Pressure drop
  double get _pressureDrop {
    return _inletPressure - _outletPressure;
  }

  // Is PRV required per code?
  bool get _prvRequired {
    return _inletPressure > 80;
  }

  // Recommended PRV size
  String get _recommendedSize {
    final data = _sizingData[_pipeSize];
    if (data == null) return '3/4"';

    // If flow exceeds capacity, go up one size
    if (_flowRate > data.maxGPM && _pipeSize != '2') {
      final pipeIndex = _pipeSizes.indexOf(_pipeSize);
      if (pipeIndex < _pipeSizes.length - 1) {
        return _sizingData[_pipeSizes[pipeIndex + 1]]?.prvSize ?? data.prvSize;
      }
    }
    return data.prvSize;
  }

  // Check if double PRV needed (very high pressure)
  bool get _needsDoubleStage {
    return _inletPressure > 150 || _reductionRatio > 3;
  }

  // Estimated pressure loss through PRV at design flow
  double get _estimatedLoss {
    final baseFlow = _sizingData[_pipeSize]?.maxGPM ?? 30;
    final flowRatio = _flowRate / baseFlow;
    return 3 + (flowRatio * flowRatio * 5); // Approximate
  }

  String get _typeRecommendation {
    if (_needsDoubleStage) return 'Double Stage recommended for high reduction';
    if (_flowRate > 50) return 'Pilot Operated recommended for high flow';
    if (_inletPressure > 120) return 'Consider Pilot Operated for accuracy';
    return 'Standard Direct Acting adequate';
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
          'PRV Sizing',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResultsCard(colors),
          const SizedBox(height: 16),
          _buildPressureCard(colors),
          const SizedBox(height: 16),
          _buildFlowCard(colors),
          const SizedBox(height: 16),
          _buildPipeSizeCard(colors),
          const SizedBox(height: 16),
          _buildPRVTypeCard(colors),
          const SizedBox(height: 16),
          _buildInstallationNotes(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
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
            _recommendedSize,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text(
            'Recommended PRV Size',
            style: TextStyle(color: colors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _prvRequired ? colors.accentError.withValues(alpha: 0.2) : colors.accentSuccess.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _prvRequired ? 'PRV REQUIRED (> 80 psi)' : 'PRV Optional (< 80 psi)',
              style: TextStyle(
                color: _prvRequired ? colors.accentError : colors.accentSuccess,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildResultRow(colors, 'Inlet Pressure', '${_inletPressure.toStringAsFixed(0)} psi'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Outlet Setting', '${_outletPressure.toStringAsFixed(0)} psi'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Pressure Drop', '${_pressureDrop.toStringAsFixed(0)} psi'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Reduction Ratio', '${_reductionRatio.toStringAsFixed(1)}:1'),
                Divider(color: colors.borderSubtle, height: 16),
                _buildResultRow(colors, 'Est. Loss @ Flow', '${_estimatedLoss.toStringAsFixed(1)} psi', highlight: true),
              ],
            ),
          ),
          if (_needsDoubleStage) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.accentWarning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'High reduction: Consider two PRVs in series',
                      style: TextStyle(color: colors.accentWarning, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPressureCard(ZaftoColors colors) {
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
            'PRESSURE',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inlet (Street)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_inletPressure.toStringAsFixed(0)} psi', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.accentPrimary,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: colors.accentPrimary,
                  ),
                  child: Slider(
                    value: _inletPressure,
                    min: 50,
                    max: 200,
                    divisions: 30,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _inletPressure = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outlet (Desired)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_outletPressure.toStringAsFixed(0)} psi', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.accentPrimary,
                    inactiveTrackColor: colors.bgBase,
                    thumbColor: colors.accentPrimary,
                  ),
                  child: Slider(
                    value: _outletPressure,
                    min: 25,
                    max: 80,
                    divisions: 11,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _outletPressure = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Typical outlet: 50-60 psi residential, 45-55 psi commercial',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowCard(ZaftoColors colors) {
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
            'PEAK FLOW RATE',
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
                '${_flowRate.toStringAsFixed(0)} GPM',
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
                    value: _flowRate,
                    min: 5,
                    max: 150,
                    divisions: 29,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _flowRate = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          Text(
            'From water service sizing calculation',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
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
              String label;
              if (size == '1-1/4') {
                label = '1-1/4"';
              } else if (size == '1-1/2') {
                label = '1-1/2"';
              } else {
                label = '$size"';
              }
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _pipeSize = size);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : colors.bgBase,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
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
          const SizedBox(height: 8),
          Text(
            'Service line pipe size at PRV location',
            style: TextStyle(color: colors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildPRVTypeCard(ZaftoColors colors) {
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
            'PRV TYPE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._prvTypes.entries.map((entry) {
            final isSelected = _prvType == entry.key;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _prvType = entry.key);
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
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _typeRecommendation,
              style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallationNotes(ZaftoColors colors) {
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
          _buildCheckItem(colors, 'Install after meter, before distribution'),
          _buildCheckItem(colors, 'Expansion tank required downstream'),
          _buildCheckItem(colors, 'Strainer recommended upstream'),
          _buildCheckItem(colors, 'Accessible for adjustment/service'),
          _buildCheckItem(colors, 'Install horizontally or per manufacturer'),
          _buildCheckItem(colors, 'Bypass for maintenance (optional)'),
        ],
      ),
    );
  }

  Widget _buildCheckItem(ZaftoColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
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
                'IPC 2024 Section 604.8',
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
            '• 604.8 - PRV required when > 80 psi\n'
            '• Max static pressure: 80 psi (IPC)\n'
            '• Set outlet 10-20% below max\n'
            '• Expansion tank required (607.3)\n'
            '• Relief valve if no expansion tank\n'
            '• Test annually for proper operation',
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
