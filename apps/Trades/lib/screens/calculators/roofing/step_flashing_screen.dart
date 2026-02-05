import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Step Flashing Calculator - Calculate step flashing for roof-wall intersections
class StepFlashingScreen extends ConsumerStatefulWidget {
  const StepFlashingScreen({super.key});
  @override
  ConsumerState<StepFlashingScreen> createState() => _StepFlashingScreenState();
}

class _StepFlashingScreenState extends ConsumerState<StepFlashingScreen> {
  final _lengthController = TextEditingController(text: '20');
  final _exposureController = TextEditingController(text: '5');
  final _wasteController = TextEditingController(text: '10');

  String _material = 'Aluminum';
  String _size = '4×4';

  int? _piecesNeeded;
  double? _sheetMetalSqFt;
  int? _roofingNails;

  @override
  void dispose() {
    _lengthController.dispose();
    _exposureController.dispose();
    _wasteController.dispose();
    super.dispose();
  }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final exposure = double.tryParse(_exposureController.text);
    final waste = double.tryParse(_wasteController.text);

    if (length == null || exposure == null || waste == null) {
      setState(() {
        _piecesNeeded = null;
        _sheetMetalSqFt = null;
        _roofingNails = null;
      });
      return;
    }

    // Convert length to inches
    final lengthInches = length * 12;

    // Pieces needed = length / exposure
    final wasteFactor = 1 + waste / 100;
    final piecesNeeded = ((lengthInches / exposure) * wasteFactor).ceil();

    // Sheet metal if fabricating
    // Step flashing size (e.g., 4×4, 5×7)
    double flashingWidth;
    double flashingHeight;
    switch (_size) {
      case '4×4':
        flashingWidth = 4;
        flashingHeight = 4;
        break;
      case '5×7':
        flashingWidth = 5;
        flashingHeight = 7;
        break;
      case '6×8':
        flashingWidth = 6;
        flashingHeight = 8;
        break;
      default:
        flashingWidth = 4;
        flashingHeight = 4;
    }

    // Piece dimensions: each piece is width × (height + height) unfolded
    // Typical piece is 8" tall when unfolded (4" on roof, 4" on wall)
    final pieceArea = flashingWidth * (flashingHeight * 2);
    final sheetMetalSqFt = (piecesNeeded * pieceArea) / 144;

    // Nails: 2 per piece
    final roofingNails = piecesNeeded * 2;

    setState(() {
      _piecesNeeded = piecesNeeded;
      _sheetMetalSqFt = sheetMetalSqFt;
      _roofingNails = roofingNails;
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
    _exposureController.text = '5';
    _wasteController.text = '10';
    setState(() {
      _material = 'Aluminum';
      _size = '4×4';
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
        title: Text('Step Flashing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'FLASHING SPECS'),
              const SizedBox(height: 12),
              _buildMaterialSelector(colors),
              const SizedBox(height: 12),
              _buildSizeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'MEASUREMENTS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Run Length',
                      unit: 'ft',
                      hint: 'Slope distance',
                      controller: _lengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Exposure',
                      unit: 'in',
                      hint: 'Shingle exp.',
                      controller: _exposureController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Waste Factor',
                unit: '%',
                hint: '10% typical',
                controller: _wasteController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_piecesNeeded != null) ...[
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
                'Step Flashing Calculator',
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
            'Calculate step flashing for sidewall intersections',
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

  Widget _buildMaterialSelector(ZaftoColors colors) {
    final materials = ['Aluminum', 'Galvanized', 'Copper', 'Lead'];
    return Row(
      children: materials.map((mat) {
        final isSelected = _material == mat;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _material = mat);
            },
            child: Container(
              margin: EdgeInsets.only(right: mat != materials.last ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                mat,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSizeSelector(ZaftoColors colors) {
    final sizes = ['4×4', '5×7', '6×8'];
    return Row(
      children: sizes.map((size) {
        final isSelected = _size == size;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _size = size);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: size != sizes.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                '$size"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 14,
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
          _buildResultRow(colors, 'STEP PIECES', '$_piecesNeeded', isHighlighted: true),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Sheet Metal', '${_sheetMetalSqFt!.toStringAsFixed(1)} sq ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Roofing Nails', '$_roofingNails'),
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
                    Text('Installation Tips', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Install one piece per shingle course', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Overlap each piece by 2" minimum', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Counter flashing covers step flashing', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
