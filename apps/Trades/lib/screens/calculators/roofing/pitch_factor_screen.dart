import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pitch Factor Calculator - Convert roof pitch to multiplier
class PitchFactorScreen extends ConsumerStatefulWidget {
  const PitchFactorScreen({super.key});
  @override
  ConsumerState<PitchFactorScreen> createState() => _PitchFactorScreenState();
}

class _PitchFactorScreenState extends ConsumerState<PitchFactorScreen> {
  final _pitchController = TextEditingController(text: '6');

  double? _pitchFactor;
  double? _roofAngle;
  String? _roofType;

  @override
  void dispose() {
    _pitchController.dispose();
    super.dispose();
  }

  void _calculate() {
    final pitch = double.tryParse(_pitchController.text);

    if (pitch == null || pitch < 0) {
      setState(() {
        _pitchFactor = null;
        _roofAngle = null;
        _roofType = null;
      });
      return;
    }

    // Calculate pitch factor: sqrt((pitch/12)² + 1)
    final pitchFactor = math.sqrt(math.pow(pitch / 12, 2) + 1);

    // Calculate angle in degrees: atan(pitch/12) * (180/π)
    final roofAngle = math.atan(pitch / 12) * (180 / math.pi);

    // Determine roof type classification
    String roofType;
    if (pitch < 2) {
      roofType = 'Flat/Low Slope';
    } else if (pitch < 4) {
      roofType = 'Low Slope';
    } else if (pitch < 9) {
      roofType = 'Conventional';
    } else if (pitch < 12) {
      roofType = 'Steep';
    } else {
      roofType = 'Very Steep';
    }

    setState(() {
      _pitchFactor = pitchFactor;
      _roofAngle = roofAngle;
      _roofType = roofType;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
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
        title: Text('Pitch Factor', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ROOF PITCH'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Pitch',
                unit: '/12',
                hint: 'Rise per 12" run',
                controller: _pitchController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_pitchFactor != null) ...[
                _buildSectionHeader(colors, 'RESULTS'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildReferenceTable(colors),
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
              Icon(LucideIcons.triangle, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Pitch Factor Calculator',
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
            'Convert roof pitch to area multiplier',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _roofType!,
              style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          _buildResultRow(colors, 'PITCH FACTOR', _pitchFactor!.toStringAsFixed(3), isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Roof Angle', '${_roofAngle!.toStringAsFixed(1)}°'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.calculator, size: 16, color: colors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Roof Area = Footprint × ${_pitchFactor!.toStringAsFixed(3)}',
                    style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceTable(ZaftoColors colors) {
    final pitchData = [
      {'pitch': '2/12', 'factor': '1.014', 'angle': '9.5°'},
      {'pitch': '4/12', 'factor': '1.054', 'angle': '18.4°'},
      {'pitch': '6/12', 'factor': '1.118', 'angle': '26.6°'},
      {'pitch': '8/12', 'factor': '1.202', 'angle': '33.7°'},
      {'pitch': '10/12', 'factor': '1.302', 'angle': '39.8°'},
      {'pitch': '12/12', 'factor': '1.414', 'angle': '45.0°'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REFERENCE TABLE', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                children: [
                  Text('Pitch', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                  Text('Factor', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                  Text('Angle', style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
              ...pitchData.map((row) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(row['pitch']!, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(row['factor']!, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(row['angle']!, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
                  ),
                ],
              )),
            ],
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
