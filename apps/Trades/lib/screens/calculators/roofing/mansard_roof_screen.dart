import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Mansard Roof Calculator - Four-sided gambrel style roof
class MansardRoofScreen extends ConsumerStatefulWidget {
  const MansardRoofScreen({super.key});
  @override
  ConsumerState<MansardRoofScreen> createState() => _MansardRoofScreenState();
}

class _MansardRoofScreenState extends ConsumerState<MansardRoofScreen> {
  final _lengthController = TextEditingController(text: '40');
  final _widthController = TextEditingController(text: '30');
  final _lowerHeightController = TextEditingController(text: '6');
  final _upperPitchController = TextEditingController(text: '4');

  double? _totalRoofArea;
  double? _lowerSectionArea;
  double? _upperSectionArea;
  double? _squares;

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _lowerHeightController.dispose();
    _upperPitchController.dispose();
    super.dispose();
  }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final lowerHeight = double.tryParse(_lowerHeightController.text);
    final upperPitch = double.tryParse(_upperPitchController.text);

    if (length == null || width == null || lowerHeight == null || upperPitch == null) {
      setState(() {
        _totalRoofArea = null;
        _lowerSectionArea = null;
        _upperSectionArea = null;
        _squares = null;
      });
      return;
    }

    // Mansard roof has 4 steep lower sections and a nearly flat upper section
    // Lower section: typically 70-80 degree angle (very steep)
    // Upper section: low pitch flat or nearly flat

    // Lower section perimeter calculation
    final perimeter = 2 * (length + width);

    // Lower steep section (assume ~75° = very steep, almost vertical)
    // Slope length = height / sin(angle) ≈ height * 1.035 for 75°
    final lowerSlopeLength = lowerHeight * 1.035;
    final lowerSectionArea = perimeter * lowerSlopeLength;

    // Upper flat section
    // Inset from walls by the horizontal run of lower section
    final horizontalInset = lowerHeight * 0.27; // tan(75°) ≈ 3.73, so inset = h/3.73
    final upperLength = length - (2 * horizontalInset);
    final upperWidth = width - (2 * horizontalInset);

    // Upper section with pitch factor
    final upperPitchFactor = math.sqrt(math.pow(upperPitch / 12, 2) + 1);
    final upperFootprint = upperLength * upperWidth;
    final upperSectionArea = upperFootprint * upperPitchFactor;

    final totalRoofArea = lowerSectionArea + upperSectionArea;
    final squares = totalRoofArea / 100;

    setState(() {
      _totalRoofArea = totalRoofArea;
      _lowerSectionArea = lowerSectionArea;
      _upperSectionArea = upperSectionArea;
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
    _lengthController.text = '40';
    _widthController.text = '30';
    _lowerHeightController.text = '6';
    _upperPitchController.text = '4';
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
        title: Text('Mansard Roof', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
                      label: 'Lower Height',
                      unit: 'ft',
                      hint: 'Steep section',
                      controller: _lowerHeightController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Upper Pitch',
                      unit: '/12',
                      hint: 'Flat top pitch',
                      controller: _upperPitchController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
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
              Icon(LucideIcons.building, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Mansard Roof Calculator',
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
            'Four-sided gambrel with steep lower slopes',
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
          _buildResultRow(colors, 'Lower (Steep) Section', '${_lowerSectionArea!.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Upper (Flat) Section', '${_upperSectionArea!.toStringAsFixed(0)} sq ft'),
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
                    'Steep lower sections require special installation techniques and safety equipment.',
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
