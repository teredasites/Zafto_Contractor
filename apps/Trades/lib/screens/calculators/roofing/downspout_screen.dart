import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Downspout Calculator - Size and count downspouts for drainage
class DownspoutScreen extends ConsumerStatefulWidget {
  const DownspoutScreen({super.key});
  @override
  ConsumerState<DownspoutScreen> createState() => _DownspoutScreenState();
}

class _DownspoutScreenState extends ConsumerState<DownspoutScreen> {
  final _roofAreaController = TextEditingController(text: '1500');
  final _gutterRunController = TextEditingController(text: '40');

  String _rainfallIntensity = 'Moderate';
  String _downspoutSize = '2×3';

  double? _flowRate;
  int? _downspoutsNeeded;
  double? _drainagePerDS;
  double? _maxGutterRun;

  @override
  void dispose() {
    _roofAreaController.dispose();
    _gutterRunController.dispose();
    super.dispose();
  }

  void _calculate() {
    final roofArea = double.tryParse(_roofAreaController.text);
    final gutterRun = double.tryParse(_gutterRunController.text);

    if (roofArea == null || gutterRun == null) {
      setState(() {
        _flowRate = null;
        _downspoutsNeeded = null;
        _drainagePerDS = null;
        _maxGutterRun = null;
      });
      return;
    }

    // Rainfall rate (in/hr)
    double rainfallRate;
    switch (_rainfallIntensity) {
      case 'Light':
        rainfallRate = 2.0;
        break;
      case 'Moderate':
        rainfallRate = 4.0;
        break;
      case 'Heavy':
        rainfallRate = 6.0;
        break;
      default:
        rainfallRate = 4.0;
    }

    // Flow rate (GPM) = Area × Rainfall / 96.23
    final flowRate = roofArea * rainfallRate / 96.23;

    // Downspout capacity (GPM)
    double dsCapacity;
    switch (_downspoutSize) {
      case '2×3':
        dsCapacity = 600.0 / 96.23; // ~6.2 GPM for 2×3
        break;
      case '3×4':
        dsCapacity = 1200.0 / 96.23; // ~12.5 GPM for 3×4
        break;
      case '4 Round':
        dsCapacity = 1500.0 / 96.23; // ~15.6 GPM for 4" round
        break;
      default:
        dsCapacity = 600.0 / 96.23;
    }

    // Also consider max drainage area per downspout
    double maxAreaPerDS;
    switch (_downspoutSize) {
      case '2×3':
        maxAreaPerDS = 600;
        break;
      case '3×4':
        maxAreaPerDS = 1200;
        break;
      case '4 Round':
        maxAreaPerDS = 1500;
        break;
      default:
        maxAreaPerDS = 600;
    }

    // Downspouts needed (by area and by run)
    final byArea = (roofArea / maxAreaPerDS).ceil();
    final byRun = (gutterRun / 35).ceil(); // Max 35 ft run to downspout
    final downspoutsNeeded = math.max(byArea, byRun);

    final drainagePerDS = roofArea / downspoutsNeeded;
    final maxGutterRun = gutterRun / downspoutsNeeded;

    setState(() {
      _flowRate = flowRate;
      _downspoutsNeeded = downspoutsNeeded;
      _drainagePerDS = drainagePerDS;
      _maxGutterRun = maxGutterRun;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _roofAreaController.text = '1500';
    _gutterRunController.text = '40';
    setState(() {
      _rainfallIntensity = 'Moderate';
      _downspoutSize = '2×3';
    });
    _calculate();
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
        title: Text('Downspouts', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary),
            onPressed: _clearAll,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DRAINAGE AREA'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Area',
                      unit: 'sq ft',
                      hint: 'Drainage area',
                      controller: _roofAreaController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Gutter Run',
                      unit: 'ft',
                      hint: 'Total length',
                      controller: _gutterRunController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CONDITIONS'),
              const SizedBox(height: 12),
              _buildRainfallSelector(colors),
              const SizedBox(height: 12),
              _buildSizeSelector(colors),
              const SizedBox(height: 32),
              if (_downspoutsNeeded != null) ...[
                _buildSectionHeader(colors, 'DOWNSPOUT REQUIREMENTS'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.arrowDown, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Downspout Calculator',
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Calculate downspout size and quantity',
            style: TextStyle(color: colors.textTertiary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
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

  Widget _buildRainfallSelector(ZaftoColors colors) {
    final intensities = ['Light', 'Moderate', 'Heavy'];
    return Row(
      children: intensities.map((intensity) {
        final isSelected = _rainfallIntensity == intensity;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _rainfallIntensity = intensity);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: intensity != intensities.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                intensity,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSizeSelector(ZaftoColors colors) {
    final sizes = ['2×3', '3×4', '4 Round'];
    return Row(
      children: sizes.map((size) {
        final isSelected = _downspoutSize == size;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _downspoutSize = size);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: size != sizes.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                size,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          _buildResultRow(colors, 'Flow Rate', '${_flowRate!.toStringAsFixed(1)} GPM'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'DOWNSPOUTS NEEDED', '$_downspoutsNeeded', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Area per Downspout', '${_drainagePerDS!.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Max Gutter Run', '${_maxGutterRun!.toStringAsFixed(0)} ft'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.info, size: 16, color: colors.accentInfo),
                    const SizedBox(width: 8),
                    Text('Downspout Capacity', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('2×3: 600 sq ft drainage area', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('3×4: 1,200 sq ft drainage area', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('4" Round: 1,500 sq ft drainage area', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: isHighlighted ? colors.accentPrimary : colors.textPrimary,
            fontSize: isHighlighted ? 20 : 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
