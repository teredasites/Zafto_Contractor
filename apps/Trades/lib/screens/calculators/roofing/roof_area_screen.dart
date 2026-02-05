import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Roof Area Calculator - Calculate total roof area from footprint and pitch
class RoofAreaScreen extends ConsumerStatefulWidget {
  const RoofAreaScreen({super.key});
  @override
  ConsumerState<RoofAreaScreen> createState() => _RoofAreaScreenState();
}

class _RoofAreaScreenState extends ConsumerState<RoofAreaScreen> {
  final _lengthController = TextEditingController(text: '40');
  final _widthController = TextEditingController(text: '30');
  final _pitchController = TextEditingController(text: '6');

  double? _footprintArea;
  double? _pitchFactor;
  double? _roofArea;
  double? _roofSquares;

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
        _footprintArea = null;
        _pitchFactor = null;
        _roofArea = null;
        _roofSquares = null;
      });
      return;
    }

    // Calculate footprint area
    final footprintArea = length * width;

    // Calculate pitch factor (rise/run ratio)
    // Pitch factor = sqrt(rise² + run²) / run = sqrt((pitch/12)² + 1)
    final pitchFactor = _getPitchFactor(pitch);

    // Total roof area = footprint × pitch factor
    final roofArea = footprintArea * pitchFactor;

    // Squares = area / 100 (1 square = 100 sq ft)
    final roofSquares = roofArea / 100;

    setState(() {
      _footprintArea = footprintArea;
      _pitchFactor = pitchFactor;
      _roofArea = roofArea;
      _roofSquares = roofSquares;
    });
  }

  double _getPitchFactor(double pitch) {
    // Common pitch factors
    final pitchFactors = {
      0: 1.000,
      1: 1.003,
      2: 1.014,
      3: 1.031,
      4: 1.054,
      5: 1.083,
      6: 1.118,
      7: 1.158,
      8: 1.202,
      9: 1.250,
      10: 1.302,
      11: 1.357,
      12: 1.414,
      14: 1.537,
      16: 1.667,
      18: 1.803,
    };

    // Use lookup or calculate
    if (pitchFactors.containsKey(pitch.round())) {
      return pitchFactors[pitch.round()]!;
    }

    // Calculate: sqrt((pitch/12)² + 1)
    return math.sqrt(math.pow(pitch / 12, 2) + 1);
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
        title: Text('Roof Area', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
                'Roof Area Calculator',
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
            'Calculate total roof area from footprint and pitch',
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
          _buildResultRow(colors, 'Footprint Area', '${_footprintArea!.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Pitch Factor', _pitchFactor!.toStringAsFixed(3)),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL ROOF AREA', '${_roofArea!.toStringAsFixed(0)} sq ft', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Roofing Squares', _roofSquares!.toStringAsFixed(1), isHighlighted: true),
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
                    '1 roofing square = 100 sq ft. Add 10-15% for waste.',
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
