import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Slope Conversion Calculator - Convert between pitch, angle, and percentage
class SlopeConversionScreen extends ConsumerStatefulWidget {
  const SlopeConversionScreen({super.key});
  @override
  ConsumerState<SlopeConversionScreen> createState() => _SlopeConversionScreenState();
}

class _SlopeConversionScreenState extends ConsumerState<SlopeConversionScreen> {
  final _inputController = TextEditingController(text: '6');

  String _inputType = 'Pitch';

  double? _pitch;
  double? _angle;
  double? _percentage;
  double? _ratio;
  double? _pitchFactor;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _calculate() {
    final input = double.tryParse(_inputController.text);

    if (input == null) {
      setState(() {
        _pitch = null;
        _angle = null;
        _percentage = null;
        _ratio = null;
        _pitchFactor = null;
      });
      return;
    }

    double pitch;
    double angle;
    double percentage;

    switch (_inputType) {
      case 'Pitch':
        // Input is pitch (X/12)
        pitch = input;
        angle = math.atan(input / 12) * (180 / math.pi);
        percentage = (input / 12) * 100;
        break;
      case 'Angle':
        // Input is angle in degrees
        angle = input;
        pitch = math.tan(input * math.pi / 180) * 12;
        percentage = math.tan(input * math.pi / 180) * 100;
        break;
      case 'Percentage':
        // Input is percentage
        percentage = input;
        pitch = (input / 100) * 12;
        angle = math.atan(input / 100) * (180 / math.pi);
        break;
      default:
        pitch = input;
        angle = math.atan(input / 12) * (180 / math.pi);
        percentage = (input / 12) * 100;
    }

    // Ratio (rise : run, normalized to 1)
    final ratio = pitch / 12;

    // Pitch factor
    final pitchFactor = math.sqrt(math.pow(pitch / 12, 2) + 1);

    setState(() {
      _pitch = pitch;
      _angle = angle;
      _percentage = percentage;
      _ratio = ratio;
      _pitchFactor = pitchFactor;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _inputController.text = '6';
    setState(() => _inputType = 'Pitch');
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
        title: Text('Slope Conversion', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'INPUT TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ENTER VALUE'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: _inputType,
                unit: _inputType == 'Pitch' ? '/12' : (_inputType == 'Angle' ? '°' : '%'),
                hint: 'Enter value',
                controller: _inputController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_pitch != null) ...[
                _buildSectionHeader(colors, 'CONVERSIONS'),
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
              Icon(LucideIcons.arrowRightLeft, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Slope Conversion',
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
            'Convert between pitch, angle, and percentage',
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

  Widget _buildTypeSelector(ZaftoColors colors) {
    final types = ['Pitch', 'Angle', 'Percentage'];
    return Row(
      children: types.map((type) {
        final isSelected = _inputType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _inputType = type);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: type != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    type == 'Pitch' ? 'X/12' : (type == 'Angle' ? 'degrees' : '%'),
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : colors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
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
          _buildResultRow(colors, 'PITCH', '${_pitch!.toStringAsFixed(2)}/12', isHighlighted: _inputType != 'Pitch'),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'ANGLE', '${_angle!.toStringAsFixed(1)}°', isHighlighted: _inputType != 'Angle'),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'PERCENTAGE', '${_percentage!.toStringAsFixed(1)}%', isHighlighted: _inputType != 'Percentage'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Rise : Run', '${_ratio!.toStringAsFixed(3)} : 1'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Pitch Factor', _pitchFactor!.toStringAsFixed(3)),
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
                    Text('Quick Reference', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Flat: 0-2/12 | Low: 2-4/12 | Standard: 4-9/12', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Steep: 9-12/12 | Very Steep: >12/12', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
