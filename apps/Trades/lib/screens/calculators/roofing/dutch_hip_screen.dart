import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Dutch Hip Roof Calculator - Calculate Dutch hip (Dutch gable) roof area
class DutchHipScreen extends ConsumerStatefulWidget {
  const DutchHipScreen({super.key});
  @override
  ConsumerState<DutchHipScreen> createState() => _DutchHipScreenState();
}

class _DutchHipScreenState extends ConsumerState<DutchHipScreen> {
  final _lengthController = TextEditingController(text: '40');
  final _widthController = TextEditingController(text: '30');
  final _pitchController = TextEditingController(text: '6');
  final _gableHeightController = TextEditingController(text: '3');

  double? _hipArea;
  double? _gableArea;
  double? _totalArea;
  double? _squares;
  double? _rafterLength;

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _pitchController.dispose();
    _gableHeightController.dispose();
    super.dispose();
  }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final pitch = double.tryParse(_pitchController.text);
    final gableHeight = double.tryParse(_gableHeightController.text);

    if (length == null || width == null || pitch == null || gableHeight == null) {
      setState(() {
        _hipArea = null;
        _gableArea = null;
        _totalArea = null;
        _squares = null;
        _rafterLength = null;
      });
      return;
    }

    // Pitch factor for slope calculations
    final pitchFactor = math.sqrt(math.pow(pitch / 12, 2) + 1);

    // Hip portion (lower section)
    // This is like a regular hip roof
    final run = width / 2;
    final rafterLength = run * pitchFactor;

    // Hip roof area (4 triangular sections meeting at center)
    // Simplified: length * width * pitch factor
    final hipArea = length * width * pitchFactor;

    // Gable portion (vertical triangle at each end)
    // Area = 2 * (base * height / 2)
    final gableWidth = width * 0.6; // Typical Dutch gable width ratio
    final gableArea = 2 * (gableWidth * gableHeight / 2);

    // Total area
    final totalArea = hipArea + gableArea;
    final squares = totalArea / 100;

    setState(() {
      _hipArea = hipArea;
      _gableArea = gableArea;
      _totalArea = totalArea;
      _squares = squares;
      _rafterLength = rafterLength;
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
    _pitchController.text = '6';
    _gableHeightController.text = '3';
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
        title: Text('Dutch Hip Roof', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Pitch',
                      unit: '/12',
                      hint: 'Roof pitch',
                      controller: _pitchController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Gable Height',
                      unit: 'ft',
                      hint: 'Vertical gable',
                      controller: _gableHeightController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_totalArea != null) ...[
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
                'Dutch Hip Calculator',
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
            'Hip roof with vertical gable ends (Dutch gable)',
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
          _buildResultRow(colors, 'Hip Section', '${_hipArea!.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Gable Section', '${_gableArea!.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL AREA', '${_totalArea!.toStringAsFixed(0)} sq ft', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'ROOF SQUARES', _squares!.toStringAsFixed(1), isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Rafter Length', '${_rafterLength!.toStringAsFixed(1)} ft'),
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
                    'Dutch hip combines hip roof benefits with gable ventilation. Add 10-15% waste.',
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
