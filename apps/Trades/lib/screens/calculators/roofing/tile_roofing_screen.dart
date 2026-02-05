import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Tile Roofing Calculator - Estimate roof tiles and materials
class TileRoofingScreen extends ConsumerStatefulWidget {
  const TileRoofingScreen({super.key});
  @override
  ConsumerState<TileRoofingScreen> createState() => _TileRoofingScreenState();
}

class _TileRoofingScreenState extends ConsumerState<TileRoofingScreen> {
  final _areaController = TextEditingController(text: '2500');
  final _wasteController = TextEditingController(text: '10');

  String _tileType = 'Concrete';

  double? _squares;
  int? _tilesNeeded;
  double? _weight;
  int? _battensNeeded;
  double? _underlayment;

  @override
  void dispose() {
    _areaController.dispose();
    _wasteController.dispose();
    super.dispose();
  }

  void _calculate() {
    final area = double.tryParse(_areaController.text);
    final waste = double.tryParse(_wasteController.text);

    if (area == null || waste == null) {
      setState(() {
        _squares = null;
        _tilesNeeded = null;
        _weight = null;
        _battensNeeded = null;
        _underlayment = null;
      });
      return;
    }

    final squares = area / 100;
    final areaWithWaste = area * (1 + waste / 100);

    // Tiles per square and weight vary by type
    int tilesPerSquare;
    double weightPerSquare; // lbs
    switch (_tileType) {
      case 'Concrete':
        tilesPerSquare = 90; // S-tiles
        weightPerSquare = 900;
        break;
      case 'Clay':
        tilesPerSquare = 100; // Spanish tiles
        weightPerSquare = 1000;
        break;
      case 'Slate':
        tilesPerSquare = 175; // 12" × 24" slates
        weightPerSquare = 750;
        break;
      default:
        tilesPerSquare = 90;
        weightPerSquare = 900;
    }

    final tilesNeeded = (squares * tilesPerSquare * (1 + waste / 100)).ceil();
    final weight = squares * weightPerSquare;

    // Battens: typically 1×2 at 14" spacing for tiles
    final battensNeeded = (area / 14 * 12).ceil(); // Linear feet of battens

    // Underlayment (typically 2 layers for tile)
    final underlayment = areaWithWaste / 100; // In squares/rolls

    setState(() {
      _squares = squares;
      _tilesNeeded = tilesNeeded;
      _weight = weight;
      _battensNeeded = battensNeeded;
      _underlayment = underlayment;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _areaController.text = '2500';
    _wasteController.text = '10';
    setState(() => _tileType = 'Concrete');
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
        title: Text('Tile Roofing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'TILE TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
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
                      controller: _areaController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Waste',
                      unit: '%',
                      hint: '10-15%',
                      controller: _wasteController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_tilesNeeded != null) ...[
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
              Icon(LucideIcons.layoutGrid, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Tile Roofing Calculator',
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
            'Estimate tiles, battens, and structural load',
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
    final types = ['Concrete', 'Clay', 'Slate'];
    return Row(
      children: types.map((type) {
        final isSelected = _tileType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _tileType = type);
              _calculate();
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
          _buildResultRow(colors, 'Roofing Squares', _squares!.toStringAsFixed(1)),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TILES NEEDED', '$_tilesNeeded', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Batten (lin ft)', '$_battensNeeded'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Underlayment', '${_underlayment!.toStringAsFixed(1)} rolls'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL WEIGHT', '${_weight!.toStringAsFixed(0)} lbs', isHighlighted: true),
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
                    'Tile roofs are heavy (9-10 lbs/sq ft). Verify roof structure can support the load.',
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
