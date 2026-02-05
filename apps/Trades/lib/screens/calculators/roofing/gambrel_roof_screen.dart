import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Gambrel Roof Calculator - Barn-style roof with two slopes per side
class GambrelRoofScreen extends ConsumerStatefulWidget {
  const GambrelRoofScreen({super.key});
  @override
  ConsumerState<GambrelRoofScreen> createState() => _GambrelRoofScreenState();
}

class _GambrelRoofScreenState extends ConsumerState<GambrelRoofScreen> {
  final _lengthController = TextEditingController(text: '40');
  final _widthController = TextEditingController(text: '30');
  final _lowerPitchController = TextEditingController(text: '18');
  final _upperPitchController = TextEditingController(text: '6');
  final _breakPointController = TextEditingController(text: '60');

  double? _totalRoofArea;
  double? _lowerArea;
  double? _upperArea;
  double? _squares;
  double? _ridgeLength;

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _lowerPitchController.dispose();
    _upperPitchController.dispose();
    _breakPointController.dispose();
    super.dispose();
  }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final lowerPitch = double.tryParse(_lowerPitchController.text);
    final upperPitch = double.tryParse(_upperPitchController.text);
    final breakPoint = double.tryParse(_breakPointController.text);

    if (length == null || width == null || lowerPitch == null ||
        upperPitch == null || breakPoint == null) {
      setState(() {
        _totalRoofArea = null;
        _lowerArea = null;
        _upperArea = null;
        _squares = null;
        _ridgeLength = null;
      });
      return;
    }

    // Gambrel has two slopes on each side (4 total surfaces)
    // Break point is percentage of total width where slope changes
    final halfWidth = width / 2;
    final lowerHorizontalRun = halfWidth * (breakPoint / 100);
    final upperHorizontalRun = halfWidth - lowerHorizontalRun;

    // Pitch factors
    final lowerPitchFactor = math.sqrt(math.pow(lowerPitch / 12, 2) + 1);
    final upperPitchFactor = math.sqrt(math.pow(upperPitch / 12, 2) + 1);

    // Slope lengths
    final lowerSlopeLength = lowerHorizontalRun * lowerPitchFactor;
    final upperSlopeLength = upperHorizontalRun * upperPitchFactor;

    // Areas (two sides)
    final lowerArea = 2 * length * lowerSlopeLength;
    final upperArea = 2 * length * upperSlopeLength;
    final totalRoofArea = lowerArea + upperArea;

    final squares = totalRoofArea / 100;
    final ridgeLength = length;

    setState(() {
      _totalRoofArea = totalRoofArea;
      _lowerArea = lowerArea;
      _upperArea = upperArea;
      _squares = squares;
      _ridgeLength = ridgeLength;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _lengthController.text = '40';
    _widthController.text = '30';
    _lowerPitchController.text = '18';
    _upperPitchController.text = '6';
    _breakPointController.text = '60';
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
        title: Text('Gambrel Roof', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
                      hint: 'Ridge direction',
                      controller: _lengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Width',
                      unit: 'ft',
                      hint: 'Span direction',
                      controller: _widthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SLOPE CONFIGURATION'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Lower Pitch',
                      unit: '/12',
                      hint: 'Steep section',
                      controller: _lowerPitchController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Upper Pitch',
                      unit: '/12',
                      hint: 'Shallow section',
                      controller: _upperPitchController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Break Point',
                unit: '%',
                hint: 'Lower slope % of width',
                controller: _breakPointController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_totalRoofArea != null) ...[
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
              Icon(LucideIcons.warehouse, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Gambrel Roof Calculator',
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
            'Barn-style roof with two slopes per side',
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
          _buildResultRow(colors, 'TOTAL ROOF AREA', '${_totalRoofArea!.toStringAsFixed(0)} sq ft', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Roofing Squares', _squares!.toStringAsFixed(1), isHighlighted: true),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Lower Slope Area', '${_lowerArea!.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Upper Slope Area', '${_upperArea!.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Ridge Length', '${_ridgeLength!.toStringAsFixed(1)} ft'),
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
                    'Gambrel roofs maximize headroom. Typical break at 60% of width with 18/12 lower and 6/12 upper pitch.',
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
