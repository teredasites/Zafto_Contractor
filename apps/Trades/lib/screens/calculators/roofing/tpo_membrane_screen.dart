import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// TPO Membrane Calculator - Calculate TPO roofing materials
class TpoMembraneScreen extends ConsumerStatefulWidget {
  const TpoMembraneScreen({super.key});
  @override
  ConsumerState<TpoMembraneScreen> createState() => _TpoMembraneScreenState();
}

class _TpoMembraneScreenState extends ConsumerState<TpoMembraneScreen> {
  final _roofAreaController = TextEditingController(text: '3000');
  final _parapetLengthController = TextEditingController(text: '200');

  String _thickness = '60 mil';
  String _rollWidth = '10 ft';

  double? _squares;
  int? _rollsNeeded;
  double? _seamLength;
  int? _fastenerPlates;
  double? _weldRodFeet;

  @override
  void dispose() {
    _roofAreaController.dispose();
    _parapetLengthController.dispose();
    super.dispose();
  }

  void _calculate() {
    final roofArea = double.tryParse(_roofAreaController.text);
    final parapetLength = double.tryParse(_parapetLengthController.text);

    if (roofArea == null || parapetLength == null) {
      setState(() {
        _squares = null;
        _rollsNeeded = null;
        _seamLength = null;
        _fastenerPlates = null;
        _weldRodFeet = null;
      });
      return;
    }

    final squares = roofArea / 100;

    // Roll width determines number of seams
    double rollWidthFt;
    switch (_rollWidth) {
      case '6 ft':
        rollWidthFt = 6;
        break;
      case '10 ft':
        rollWidthFt = 10;
        break;
      case '12 ft':
        rollWidthFt = 12;
        break;
      default:
        rollWidthFt = 10;
    }

    // Estimate rolls needed (assume 100 ft roll length)
    final rollCoverage = rollWidthFt * 100; // sq ft per roll
    final fieldRolls = (roofArea * 1.1 / rollCoverage).ceil(); // 10% waste

    // Flashing material (for parapets)
    // Assume 1.5 ft width for wall flashing
    final flashingRolls = (parapetLength * 1.5 / rollCoverage).ceil();

    final rollsNeeded = fieldRolls + flashingRolls;

    // Seam length: based on number of roll widths
    // Seams run the length of the roof
    final roofLength = roofArea / 50; // Rough estimate
    final seamCount = (50 / rollWidthFt).ceil(); // 50 ft assumed width
    final seamLength = roofLength * seamCount;

    // Mechanical fasteners: 1 per sq ft in field
    final fastenerPlates = roofArea.ceil();

    // Weld rod for hot-air welding: ~6" seam overlap
    // 1 ft weld rod per 2 ft of seam
    final weldRodFeet = seamLength / 2;

    setState(() {
      _squares = squares;
      _rollsNeeded = rollsNeeded;
      _seamLength = seamLength;
      _fastenerPlates = fastenerPlates;
      _weldRodFeet = weldRodFeet;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _roofAreaController.text = '3000';
    _parapetLengthController.text = '200';
    setState(() {
      _thickness = '60 mil';
      _rollWidth = '10 ft';
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
        title: Text('TPO Membrane', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'MEMBRANE SPECS'),
              const SizedBox(height: 12),
              _buildThicknessSelector(colors),
              const SizedBox(height: 12),
              _buildWidthSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOF DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Area',
                      unit: 'sq ft',
                      hint: 'Total field',
                      controller: _roofAreaController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Parapet',
                      unit: 'lin ft',
                      hint: 'Total length',
                      controller: _parapetLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_rollsNeeded != null) ...[
                _buildSectionHeader(colors, 'MATERIALS NEEDED'),
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
              Icon(LucideIcons.layers, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'TPO Membrane Calculator',
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
            'Calculate thermoplastic polyolefin roofing',
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

  Widget _buildThicknessSelector(ZaftoColors colors) {
    final thicknesses = ['45 mil', '60 mil', '80 mil'];
    return Row(
      children: thicknesses.map((thick) {
        final isSelected = _thickness == thick;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _thickness = thick);
            },
            child: Container(
              margin: EdgeInsets.only(right: thick != thicknesses.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                thick,
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

  Widget _buildWidthSelector(ZaftoColors colors) {
    final widths = ['6 ft', '10 ft', '12 ft'];
    return Row(
      children: widths.map((width) {
        final isSelected = _rollWidth == width;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _rollWidth = width);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: width != widths.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                width,
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
          _buildResultRow(colors, 'Roof Squares', _squares!.toStringAsFixed(1)),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'MEMBRANE ROLLS', '$_rollsNeeded', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Seam Length', '${_seamLength!.toStringAsFixed(0)} lin ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Fastener Plates', '$_fastenerPlates'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Weld Rod', '${_weldRodFeet!.toStringAsFixed(0)} lin ft'),
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
                    'TPO seams are heat-welded with hot-air gun at 900-1100°F. Use 6" minimum overlap.',
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
