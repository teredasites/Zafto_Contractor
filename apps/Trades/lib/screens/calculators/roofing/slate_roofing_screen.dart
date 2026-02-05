import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Slate Roofing Calculator - Calculate slate tiles and accessories
class SlateRoofingScreen extends ConsumerStatefulWidget {
  const SlateRoofingScreen({super.key});
  @override
  ConsumerState<SlateRoofingScreen> createState() => _SlateRoofingScreenState();
}

class _SlateRoofingScreenState extends ConsumerState<SlateRoofingScreen> {
  final _roofAreaController = TextEditingController(text: '2000');
  final _wasteController = TextEditingController(text: '15');

  String _slateSize = '12×24';
  String _exposure = 'Standard';

  double? _squares;
  int? _slatesNeeded;
  double? _weightLbs;
  int? _copperNails;

  @override
  void dispose() {
    _roofAreaController.dispose();
    _wasteController.dispose();
    super.dispose();
  }

  void _calculate() {
    final roofArea = double.tryParse(_roofAreaController.text);
    final waste = double.tryParse(_wasteController.text);

    if (roofArea == null || waste == null) {
      setState(() {
        _squares = null;
        _slatesNeeded = null;
        _weightLbs = null;
        _copperNails = null;
      });
      return;
    }

    final squares = roofArea / 100;

    // Slates per square varies by size
    int slatesPerSquare;
    double weightPerSquare; // lbs
    switch (_slateSize) {
      case '10×20':
        slatesPerSquare = 98;
        weightPerSquare = 700;
        break;
      case '12×24':
        slatesPerSquare = 67;
        weightPerSquare = 800;
        break;
      case '14×24':
        slatesPerSquare = 57;
        weightPerSquare = 900;
        break;
      case '16×24':
        slatesPerSquare = 50;
        weightPerSquare = 1000;
        break;
      default:
        slatesPerSquare = 67;
        weightPerSquare = 800;
    }

    // Adjust for exposure
    if (_exposure == 'Reduced') {
      slatesPerSquare = (slatesPerSquare * 1.15).ceil();
    }

    // Calculate totals with waste
    final wasteFactor = 1 + waste / 100;
    final slatesNeeded = (squares * slatesPerSquare * wasteFactor).ceil();
    final weightLbs = squares * weightPerSquare;

    // Copper nails: 2 per slate + 10%
    final copperNails = (slatesNeeded * 2 * 1.1).ceil();

    setState(() {
      _squares = squares;
      _slatesNeeded = slatesNeeded;
      _weightLbs = weightLbs;
      _copperNails = copperNails;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _roofAreaController.text = '2000';
    _wasteController.text = '15';
    setState(() {
      _slateSize = '12×24';
      _exposure = 'Standard';
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
        title: Text('Slate Roofing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SLATE SIZE'),
              const SizedBox(height: 12),
              _buildSizeSelector(colors),
              const SizedBox(height: 12),
              _buildExposureSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOF AREA'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Area',
                      unit: 'sq ft',
                      hint: 'Total area',
                      controller: _roofAreaController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Waste',
                      unit: '%',
                      hint: '15% typical',
                      controller: _wasteController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_slatesNeeded != null) ...[
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
                'Slate Roofing Calculator',
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
            'Calculate natural slate tiles and accessories',
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

  Widget _buildSizeSelector(ZaftoColors colors) {
    final sizes = ['10×20', '12×24', '14×24', '16×24'];
    return Row(
      children: sizes.map((size) {
        final isSelected = _slateSize == size;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _slateSize = size);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: size != sizes.last ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                size,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExposureSelector(ZaftoColors colors) {
    final exposures = ['Standard', 'Reduced'];
    return Row(
      children: exposures.map((exp) {
        final isSelected = _exposure == exp;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _exposure = exp);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: exp != exposures.last ? 8 : 0),
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
                    exp,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    exp == 'Standard' ? 'Normal overlap' : 'Extra overlap',
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
          _buildResultRow(colors, 'Roof Squares', _squares!.toStringAsFixed(1)),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'SLATES NEEDED', '$_slatesNeeded', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Copper Nails', '$_copperNails'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Roof Weight', '${_weightLbs!.toStringAsFixed(0)} lbs'),
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
                    'Verify structure can support slate weight (700-1000 lbs/sq). Min pitch 4:12.',
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
