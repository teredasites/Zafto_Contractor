import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Shed Roof Calculator - Calculate single-slope (lean-to) roof area
class ShedRoofScreen extends ConsumerStatefulWidget {
  const ShedRoofScreen({super.key});
  @override
  ConsumerState<ShedRoofScreen> createState() => _ShedRoofScreenState();
}

class _ShedRoofScreenState extends ConsumerState<ShedRoofScreen> {
  final _lengthController = TextEditingController(text: '20');
  final _runController = TextEditingController(text: '12');
  final _pitchController = TextEditingController(text: '4');

  double? _roofArea;
  double? _squares;
  double? _rafterLength;
  double? _rise;

  @override
  void dispose() {
    _lengthController.dispose();
    _runController.dispose();
    _pitchController.dispose();
    super.dispose();
  }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final run = double.tryParse(_runController.text);
    final pitch = double.tryParse(_pitchController.text);

    if (length == null || run == null || pitch == null) {
      setState(() {
        _roofArea = null;
        _squares = null;
        _rafterLength = null;
        _rise = null;
      });
      return;
    }

    // Calculate rise from pitch
    final rise = (pitch / 12) * run;

    // Pitch factor
    final pitchFactor = math.sqrt(math.pow(pitch / 12, 2) + 1);

    // Rafter length (actual slope distance)
    final rafterLength = run * pitchFactor;

    // Roof area = length × rafter length
    final roofArea = length * rafterLength;
    final squares = roofArea / 100;

    setState(() {
      _roofArea = roofArea;
      _squares = squares;
      _rafterLength = rafterLength;
      _rise = rise;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _lengthController.text = '20';
    _runController.text = '12';
    _pitchController.text = '4';
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
        title: Text('Shed Roof', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ROOF DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Length',
                      unit: 'ft',
                      hint: 'Ridge length',
                      controller: _lengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Run',
                      unit: 'ft',
                      hint: 'Horizontal',
                      controller: _runController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Pitch',
                unit: '/12',
                hint: 'Roof slope',
                controller: _pitchController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_roofArea != null) ...[
                _buildSectionHeader(colors, 'ROOF CALCULATIONS'),
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
                'Shed Roof Calculator',
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
            'Single-slope lean-to roof calculations',
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
          _buildResultRow(colors, 'ROOF SQUARES', _squares!.toStringAsFixed(2), isHighlighted: true),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Rafter Length', '${_rafterLength!.toStringAsFixed(1)} ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Total Rise', '${_rise!.toStringAsFixed(1)} ft'),
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
                    Text('Shed Roof Tips', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Min pitch 1/4:12 for drainage', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Common for additions, porches, sheds', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Add 10% waste for materials', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
