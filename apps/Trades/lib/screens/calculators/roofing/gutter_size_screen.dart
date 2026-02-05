import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Gutter Size Calculator - Determine gutter size for roof drainage
class GutterSizeScreen extends ConsumerStatefulWidget {
  const GutterSizeScreen({super.key});
  @override
  ConsumerState<GutterSizeScreen> createState() => _GutterSizeScreenState();
}

class _GutterSizeScreenState extends ConsumerState<GutterSizeScreen> {
  final _roofAreaController = TextEditingController(text: '1500');
  final _pitchController = TextEditingController(text: '6');

  String _rainfallIntensity = 'Moderate';

  double? _drainageArea;
  double? _flowRate;
  String? _gutterSize;
  String? _downspoutSize;
  int? _downspoutCount;

  @override
  void dispose() {
    _roofAreaController.dispose();
    _pitchController.dispose();
    super.dispose();
  }

  void _calculate() {
    final roofArea = double.tryParse(_roofAreaController.text);
    final pitch = double.tryParse(_pitchController.text);

    if (roofArea == null || pitch == null) {
      setState(() {
        _drainageArea = null;
        _flowRate = null;
        _gutterSize = null;
        _downspoutSize = null;
        _downspoutCount = null;
      });
      return;
    }

    // Calculate drainage area (roof area × pitch factor for wind-driven rain)
    final pitchFactor = math.sqrt(math.pow(pitch / 12, 2) + 1);
    final drainageArea = roofArea * pitchFactor;

    // Rainfall intensity (inches per hour)
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

    // Flow rate in GPM: (Area × Rainfall) / 96.23
    final flowRate = (drainageArea * rainfallRate) / 96.23;

    // Determine gutter size based on drainage area
    String gutterSize;
    String downspoutSize;
    if (drainageArea <= 700) {
      gutterSize = '5" K-Style';
      downspoutSize = '2"×3"';
    } else if (drainageArea <= 1400) {
      gutterSize = '6" K-Style';
      downspoutSize = '3"×4"';
    } else {
      gutterSize = '6" Half-Round';
      downspoutSize = '4" Round';
    }

    // Downspout count: 1 per 35 linear feet of gutter or 1 per 600 sq ft
    final downspoutCount = (drainageArea / 600).ceil();

    setState(() {
      _drainageArea = drainageArea;
      _flowRate = flowRate;
      _gutterSize = gutterSize;
      _downspoutSize = downspoutSize;
      _downspoutCount = downspoutCount;
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
    _pitchController.text = '6';
    setState(() => _rainfallIntensity = 'Moderate');
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
        title: Text('Gutter Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ROOF SPECIFICATIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Area',
                      unit: 'sq ft',
                      hint: 'Footprint',
                      controller: _roofAreaController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Pitch',
                      unit: '/12',
                      hint: 'Rise/run',
                      controller: _pitchController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'RAINFALL INTENSITY'),
              const SizedBox(height: 12),
              _buildIntensitySelector(colors),
              const SizedBox(height: 32),
              if (_gutterSize != null) ...[
                _buildSectionHeader(colors, 'RECOMMENDED SIZING'),
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
              Icon(LucideIcons.droplets, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Gutter Size Calculator',
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
            'Size gutters based on roof drainage',
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

  Widget _buildIntensitySelector(ZaftoColors colors) {
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
          _buildResultRow(colors, 'Drainage Area', '${_drainageArea!.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Flow Rate', '${_flowRate!.toStringAsFixed(1)} GPM'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'GUTTER SIZE', _gutterSize!, isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'DOWNSPOUT SIZE', _downspoutSize!, isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Downspouts Needed', '$_downspoutCount minimum'),
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
                    Text('Sizing Guide', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('5" K-Style: Up to 700 sq ft drainage', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('6" K-Style: 700-1,400 sq ft drainage', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('6" Half-Round: 1,400+ sq ft drainage', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
            fontSize: isHighlighted ? 16 : 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
