import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Hip Roof Calculator - Calculate hip roof area and materials
class HipRoofScreen extends ConsumerStatefulWidget {
  const HipRoofScreen({super.key});
  @override
  ConsumerState<HipRoofScreen> createState() => _HipRoofScreenState();
}

class _HipRoofScreenState extends ConsumerState<HipRoofScreen> {
  final _lengthController = TextEditingController(text: '50');
  final _widthController = TextEditingController(text: '30');
  final _pitchController = TextEditingController(text: '6');

  double? _roofArea;
  double? _ridgeLength;
  double? _hipLength;
  double? _eaveLength;
  double? _squares;

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _pitchController.dispose();
    super.dispose();
  }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final pitch = double.tryParse(_pitchController.text);

    if (length == null || width == null || pitch == null) {
      setState(() {
        _roofArea = null;
        _ridgeLength = null;
        _hipLength = null;
        _eaveLength = null;
        _squares = null;
      });
      return;
    }

    // Hip roof geometry
    // Ridge length = building length - building width
    final ridgeLength = length - width;
    if (ridgeLength < 0) {
      // Building is wider than long - no ridge, just a pyramid
      setState(() {
        _roofArea = null;
        _ridgeLength = null;
        _hipLength = null;
        _eaveLength = null;
        _squares = null;
      });
      return;
    }

    // Pitch factor
    final pitchFactor = math.sqrt(math.pow(pitch / 12, 2) + 1);

    // Hip rafter factor (diagonal slope)
    // Hip runs at 45° in plan, so horizontal run = width/2 * sqrt(2)
    // Hip factor = sqrt((pitch/12)² + 2)
    final hipFactor = math.sqrt(math.pow(pitch / 12, 2) + 2);

    // Eave length (perimeter)
    final eaveLength = 2 * (length + width);

    // Hip length (4 hips on standard hip roof)
    final horizontalHipRun = (width / 2) * math.sqrt(2);
    final hipLength = horizontalHipRun * hipFactor / math.sqrt(2) * 4;

    // Roof area calculation
    // Two triangular end sections + two trapezoidal side sections
    final halfWidth = width / 2;
    final riseHeight = halfWidth * pitch / 12;

    // Side panels: trapezoid with parallel sides = ridge and eave length
    final sideRakeLength = math.sqrt(math.pow(halfWidth, 2) + math.pow(riseHeight, 2));
    final sideArea = 2 * ((ridgeLength + length) / 2 * sideRakeLength);

    // End panels: triangles
    final endRakeLength = math.sqrt(math.pow(halfWidth, 2) + math.pow(riseHeight, 2));
    final endArea = 2 * (width / 2 * endRakeLength);

    // Total using simplified formula: footprint × pitch factor + adjustment for hip
    final footprint = length * width;
    final roofArea = footprint * pitchFactor;

    final squares = roofArea / 100;

    setState(() {
      _roofArea = roofArea;
      _ridgeLength = ridgeLength;
      _hipLength = hipLength;
      _eaveLength = eaveLength;
      _squares = squares;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _lengthController.text = '50';
    _widthController.text = '30';
    _pitchController.text = '6';
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
        title: Text('Hip Roof', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'BUILDING DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Length',
                      unit: 'ft',
                      hint: 'Building length',
                      controller: _lengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Width',
                      unit: 'ft',
                      hint: 'Building width',
                      controller: _widthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Roof Pitch',
                unit: '/12',
                hint: 'Rise per 12" run',
                controller: _pitchController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_roofArea != null) ...[
                _buildSectionHeader(colors, 'RESULTS'),
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
              Icon(LucideIcons.home, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Hip Roof Calculator',
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
            'Calculate hip roof area, ridge, and hip lengths',
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
          _buildResultRow(colors, 'ROOF AREA', '${_roofArea!.toStringAsFixed(0)} sq ft', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Roofing Squares', _squares!.toStringAsFixed(1), isHighlighted: true),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildSectionHeader(colors, 'COMPONENT LENGTHS'),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Ridge Length', '${_ridgeLength!.toStringAsFixed(1)} ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Total Hip Length', '${_hipLength!.toStringAsFixed(1)} ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Eave Length', '${_eaveLength!.toStringAsFixed(1)} ft'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 16, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hip roofs have 4 sloping sides. Ridge cap needed for ridge + all 4 hips.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
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
            fontSize: isHighlighted ? 18 : 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
