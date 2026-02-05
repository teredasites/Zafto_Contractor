import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Plywood Deck Calculator - Calculate roof sheathing materials
class PlywoodDeckScreen extends ConsumerStatefulWidget {
  const PlywoodDeckScreen({super.key});
  @override
  ConsumerState<PlywoodDeckScreen> createState() => _PlywoodDeckScreenState();
}

class _PlywoodDeckScreenState extends ConsumerState<PlywoodDeckScreen> {
  final _roofAreaController = TextEditingController(text: '2400');
  final _wasteController = TextEditingController(text: '5');

  String _deckType = 'CDX Plywood';
  String _thickness = '1/2"';

  double? _squares;
  int? _sheetsNeeded;
  double? _boardFeet;
  int? _nailsNeeded;
  double? _totalWeight;

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
        _sheetsNeeded = null;
        _boardFeet = null;
        _nailsNeeded = null;
        _totalWeight = null;
      });
      return;
    }

    final squares = roofArea / 100;
    final areaWithWaste = roofArea * (1 + waste / 100);

    // Sheet coverage: 4×8 = 32 sq ft
    const sheetArea = 32.0;
    final sheetsNeeded = (areaWithWaste / sheetArea).ceil();

    // Board feet (plywood thickness factor)
    double thicknessFactor;
    switch (_thickness) {
      case '3/8"':
        thicknessFactor = 0.375 / 12;
        break;
      case '1/2"':
        thicknessFactor = 0.5 / 12;
        break;
      case '5/8"':
        thicknessFactor = 0.625 / 12;
        break;
      case '3/4"':
        thicknessFactor = 0.75 / 12;
        break;
      default:
        thicknessFactor = 0.5 / 12;
    }
    final boardFeet = areaWithWaste * thicknessFactor;

    // Nails per sheet (8d ring shank, 6" OC edges, 12" OC field)
    const nailsPerSheet = 48;
    final nailsNeeded = sheetsNeeded * nailsPerSheet;

    // Weight per sheet
    double weightPerSheet;
    switch (_deckType) {
      case 'CDX Plywood':
        weightPerSheet = _thickness == '1/2"' ? 48 : (_thickness == '5/8"' ? 60 : 72);
        break;
      case 'OSB':
        weightPerSheet = _thickness == '1/2"' ? 54 : (_thickness == '5/8"' ? 65 : 78);
        break;
      case 'Plywood (Rated)':
        weightPerSheet = _thickness == '1/2"' ? 50 : (_thickness == '5/8"' ? 62 : 75);
        break;
      default:
        weightPerSheet = 50;
    }
    final totalWeight = sheetsNeeded * weightPerSheet;

    setState(() {
      _squares = squares;
      _sheetsNeeded = sheetsNeeded;
      _boardFeet = boardFeet;
      _nailsNeeded = nailsNeeded;
      _totalWeight = totalWeight;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _roofAreaController.text = '2400';
    _wasteController.text = '5';
    setState(() {
      _deckType = 'CDX Plywood';
      _thickness = '1/2"';
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
        title: Text('Roof Deck', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'DECK TYPE'),
              const SizedBox(height: 12),
              _buildDeckTypeSelector(colors),
              const SizedBox(height: 12),
              _buildThicknessSelector(colors),
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
                      hint: '5% typical',
                      controller: _wasteController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_sheetsNeeded != null) ...[
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
              Icon(LucideIcons.squareStack, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Roof Deck Calculator',
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
            'Calculate plywood or OSB sheathing',
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

  Widget _buildDeckTypeSelector(ZaftoColors colors) {
    final types = ['CDX Plywood', 'OSB', 'Plywood (Rated)'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = _deckType == type;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _deckType = type);
            _calculate();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? colors.accentPrimary : colors.bgElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? colors.accentPrimary : colors.borderSubtle,
              ),
            ),
            child: Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : colors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThicknessSelector(ZaftoColors colors) {
    final thicknesses = ['3/8"', '1/2"', '5/8"', '3/4"'];
    return Row(
      children: thicknesses.map((thick) {
        final isSelected = _thickness == thick;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _thickness = thick);
              _calculate();
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
          _buildResultRow(colors, 'SHEETS NEEDED', '$_sheetsNeeded (4×8)', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Nails (8d)', '$_nailsNeeded'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Total Weight', '${_totalWeight!.toStringAsFixed(0)} lbs'),
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
                    Text('Thickness Guide', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('16" OC rafters: 3/8"-1/2" minimum', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('24" OC rafters: 5/8" minimum', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Tile roofs: 3/4" recommended', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
