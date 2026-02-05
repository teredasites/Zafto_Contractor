import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Roof Truss Calculator - Calculate roof truss requirements
class RoofTrussScreen extends ConsumerStatefulWidget {
  const RoofTrussScreen({super.key});
  @override
  ConsumerState<RoofTrussScreen> createState() => _RoofTrussScreenState();
}

class _RoofTrussScreenState extends ConsumerState<RoofTrussScreen> {
  final _buildingLengthController = TextEditingController(text: '40');
  final _buildingWidthController = TextEditingController(text: '30');
  final _pitchController = TextEditingController(text: '6');

  String _spacing = '24"';
  String _trussType = 'Common';

  int? _trussCount;
  double? _trussSpan;
  double? _trussHeight;
  int? _gableEndTrusses;
  double? _heelHeight;

  @override
  void dispose() {
    _buildingLengthController.dispose();
    _buildingWidthController.dispose();
    _pitchController.dispose();
    super.dispose();
  }

  void _calculate() {
    final buildingLength = double.tryParse(_buildingLengthController.text);
    final buildingWidth = double.tryParse(_buildingWidthController.text);
    final pitch = double.tryParse(_pitchController.text);

    if (buildingLength == null || buildingWidth == null || pitch == null) {
      setState(() {
        _trussCount = null;
        _trussSpan = null;
        _trussHeight = null;
        _gableEndTrusses = null;
        _heelHeight = null;
      });
      return;
    }

    // Truss span = building width
    final trussSpan = buildingWidth;

    // Truss height at peak
    final run = buildingWidth / 2;
    final trussHeight = (pitch / 12) * run;

    // Standard heel height (at eave)
    final heelHeight = 3.5 + (pitch / 12) * 3.5; // Varies with pitch

    // Spacing in feet
    double spacingFt;
    switch (_spacing) {
      case '16"':
        spacingFt = 16 / 12;
        break;
      case '24"':
        spacingFt = 2.0;
        break;
      default:
        spacingFt = 2.0;
    }

    // Number of trusses
    final trussCount = (buildingLength / spacingFt).ceil() + 1;

    // Gable end trusses (2 for simple gable)
    final gableEndTrusses = 2;

    setState(() {
      _trussCount = trussCount;
      _trussSpan = trussSpan;
      _trussHeight = trussHeight;
      _gableEndTrusses = gableEndTrusses;
      _heelHeight = heelHeight;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _buildingLengthController.text = '40';
    _buildingWidthController.text = '30';
    _pitchController.text = '6';
    setState(() {
      _spacing = '24"';
      _trussType = 'Common';
    });
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
        title: Text('Roof Truss', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'TRUSS CONFIGURATION'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSpacingSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'BUILDING DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Length',
                      unit: 'ft',
                      hint: 'Building',
                      controller: _buildingLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Width',
                      unit: 'ft',
                      hint: 'Span',
                      controller: _buildingWidthController,
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
              if (_trussCount != null) ...[
                _buildSectionHeader(colors, 'TRUSS REQUIREMENTS'),
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
              Icon(LucideIcons.triangle, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Roof Truss Calculator',
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
            'Calculate truss count and dimensions',
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
    final types = ['Common', 'Scissor', 'Attic'];
    return Row(
      children: types.map((type) {
        final isSelected = _trussType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _trussType = type);
            },
            child: Container(
              margin: EdgeInsets.only(right: type != types.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                type,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpacingSelector(ZaftoColors colors) {
    final spacings = ['16"', '24"'];
    return Row(
      children: spacings.map((spacing) {
        final isSelected = _spacing == spacing;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _spacing = spacing);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: spacing != spacings.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                    spacing,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'On center',
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
          _buildResultRow(colors, 'TRUSSES NEEDED', '$_trussCount', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Gable End Trusses', '$_gableEndTrusses'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Truss Span', '${_trussSpan!.toStringAsFixed(0)} ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Peak Height', '${_trussHeight!.toStringAsFixed(1)} ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Heel Height', '${_heelHeight!.toStringAsFixed(1)}"'),
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
                    'Trusses must be engineered. Get sealed drawings from truss manufacturer.',
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
            fontSize: isHighlighted ? 20 : 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
