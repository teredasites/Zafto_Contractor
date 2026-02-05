import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Valley Length Calculator - Calculate valley rafter and flashing length
class ValleyLengthScreen extends ConsumerStatefulWidget {
  const ValleyLengthScreen({super.key});
  @override
  ConsumerState<ValleyLengthScreen> createState() => _ValleyLengthScreenState();
}

class _ValleyLengthScreenState extends ConsumerState<ValleyLengthScreen> {
  final _runController = TextEditingController(text: '15');
  final _mainPitchController = TextEditingController(text: '6');
  final _crossPitchController = TextEditingController(text: '6');

  double? _valleyLength;
  double? _valleyAngle;
  double? _flashingNeeded;
  String? _valleyType;

  @override
  void dispose() {
    _runController.dispose();
    _mainPitchController.dispose();
    _crossPitchController.dispose();
    super.dispose();
  }

  void _calculate() {
    final run = double.tryParse(_runController.text);
    final mainPitch = double.tryParse(_mainPitchController.text);
    final crossPitch = double.tryParse(_crossPitchController.text);

    if (run == null || mainPitch == null || crossPitch == null) {
      setState(() {
        _valleyLength = null;
        _valleyAngle = null;
        _flashingNeeded = null;
        _valleyType = null;
      });
      return;
    }

    // Valley runs at intersection of two roof planes
    // For equal pitches: valley runs at 45° in plan, slopes down
    // Valley factor = sqrt(2 + (pitch/12)²) for equal pitches

    double valleyLength;
    String valleyType;

    if ((mainPitch - crossPitch).abs() < 0.5) {
      // Equal pitch - regular valley
      valleyType = 'Regular (Equal Pitch)';
      final valleyFactor = math.sqrt(2 + math.pow(mainPitch / 12, 2));
      valleyLength = run * valleyFactor;
    } else {
      // Unequal pitch - irregular valley
      valleyType = 'Irregular (Unequal Pitch)';
      // Simplified calculation for unequal pitches
      final avgPitch = (mainPitch + crossPitch) / 2;
      final valleyFactor = math.sqrt(2 + math.pow(avgPitch / 12, 2));
      valleyLength = run * valleyFactor;
    }

    // Valley angle (in plan view from ridge)
    // For equal pitches, valley is at 45° in plan
    final planAngle = mainPitch == crossPitch ? 45.0 :
        math.atan(crossPitch / mainPitch) * (180 / math.pi);

    // Actual valley angle (accounting for slope)
    final valleyAngle = math.atan(mainPitch / 12 / math.sqrt(2)) * (180 / math.pi);

    // Flashing needed (valley length + 1ft overlap each end)
    final flashingNeeded = valleyLength + 2;

    setState(() {
      _valleyLength = valleyLength;
      _valleyAngle = valleyAngle;
      _flashingNeeded = flashingNeeded;
      _valleyType = valleyType;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _runController.text = '15';
    _mainPitchController.text = '6';
    _crossPitchController.text = '6';
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
        title: Text('Valley Length', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'VALLEY DIMENSIONS'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Horizontal Run',
                unit: 'ft',
                hint: 'Plan view length',
                controller: _runController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Main Pitch',
                      unit: '/12',
                      hint: 'Main roof',
                      controller: _mainPitchController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Cross Pitch',
                      unit: '/12',
                      hint: 'Intersecting',
                      controller: _crossPitchController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_valleyLength != null) ...[
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
              Icon(LucideIcons.arrowDownRight, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Valley Length Calculator',
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
            'Calculate valley rafter length and flashing',
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _valleyType!,
              style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          _buildResultRow(colors, 'VALLEY LENGTH', '${_valleyLength!.toStringAsFixed(1)} ft', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Valley Angle', '${_valleyAngle!.toStringAsFixed(1)}°'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Flashing Needed', '${_flashingNeeded!.toStringAsFixed(1)} ft', isHighlighted: true),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, size: 16, color: colors.accentWarning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Valleys are critical leak points. Use proper W-valley metal or woven/closed-cut shingle valley.',
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
