import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Rafter Length Calculator - Calculate common rafter length
class RafterLengthScreen extends ConsumerStatefulWidget {
  const RafterLengthScreen({super.key});
  @override
  ConsumerState<RafterLengthScreen> createState() => _RafterLengthScreenState();
}

class _RafterLengthScreenState extends ConsumerState<RafterLengthScreen> {
  final _runController = TextEditingController(text: '15');
  final _pitchController = TextEditingController(text: '6');
  final _overhangController = TextEditingController(text: '12');

  double? _rafterLength;
  double? _totalLength;
  double? _riseHeight;
  double? _pitchAngle;

  @override
  void dispose() {
    _runController.dispose();
    _pitchController.dispose();
    _overhangController.dispose();
    super.dispose();
  }

  void _calculate() {
    final run = double.tryParse(_runController.text);
    final pitch = double.tryParse(_pitchController.text);
    final overhang = double.tryParse(_overhangController.text);

    if (run == null || pitch == null || overhang == null) {
      setState(() {
        _rafterLength = null;
        _totalLength = null;
        _riseHeight = null;
        _pitchAngle = null;
      });
      return;
    }

    // Pitch factor
    final pitchFactor = math.sqrt(math.pow(pitch / 12, 2) + 1);

    // Rafter length (just the building portion)
    final rafterLength = run * pitchFactor;

    // Overhang length
    final overhangFt = overhang / 12;
    final overhangSlope = overhangFt * pitchFactor;

    // Total rafter length
    final totalLength = rafterLength + overhangSlope;

    // Rise height
    final riseHeight = run * pitch / 12;

    // Pitch angle
    final pitchAngle = math.atan(pitch / 12) * (180 / math.pi);

    setState(() {
      _rafterLength = rafterLength;
      _totalLength = totalLength;
      _riseHeight = riseHeight;
      _pitchAngle = pitchAngle;
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
    _pitchController.text = '6';
    _overhangController.text = '12';
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
        title: Text('Rafter Length', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'RAFTER DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Run',
                      unit: 'ft',
                      hint: 'Horizontal',
                      controller: _runController,
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
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Overhang',
                unit: 'in',
                hint: 'Eave projection',
                controller: _overhangController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_rafterLength != null) ...[
                _buildSectionHeader(colors, 'RAFTER CALCULATIONS'),
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
              Icon(LucideIcons.ruler, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Rafter Length Calculator',
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
            'Calculate common rafter length from run and pitch',
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
          _buildResultRow(colors, 'Rafter Length', '${_rafterLength!.toStringAsFixed(2)} ft'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL LENGTH', '${_totalLength!.toStringAsFixed(2)} ft', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Rise Height', '${_riseHeight!.toStringAsFixed(2)} ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Pitch Angle', '${_pitchAngle!.toStringAsFixed(1)}°'),
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
                    'Add 6-12" to total length for seat cut and ridge shortening when ordering lumber.',
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
