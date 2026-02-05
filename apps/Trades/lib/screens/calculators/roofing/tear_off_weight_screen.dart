import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Tear-Off Weight Calculator - Estimate debris weight and disposal
class TearOffWeightScreen extends ConsumerStatefulWidget {
  const TearOffWeightScreen({super.key});
  @override
  ConsumerState<TearOffWeightScreen> createState() => _TearOffWeightScreenState();
}

class _TearOffWeightScreenState extends ConsumerState<TearOffWeightScreen> {
  final _squaresController = TextEditingController(text: '24');
  final _layersController = TextEditingController(text: '1');

  String _materialType = 'Asphalt Shingles';
  bool _includeDeck = false;

  double? _debrisWeight;
  double? _dumpsterLoads;
  double? _truckLoads;
  double? _perSquareWeight;

  @override
  void dispose() {
    _squaresController.dispose();
    _layersController.dispose();
    super.dispose();
  }

  void _calculate() {
    final squares = double.tryParse(_squaresController.text);
    final layers = int.tryParse(_layersController.text);

    if (squares == null || layers == null) {
      setState(() {
        _debrisWeight = null;
        _dumpsterLoads = null;
        _truckLoads = null;
        _perSquareWeight = null;
      });
      return;
    }

    // Weight per square by material (lbs)
    double weightPerSquare;
    switch (_materialType) {
      case 'Asphalt Shingles':
        weightPerSquare = 250; // 3-tab: ~230, architectural: ~270
        break;
      case 'Wood Shakes':
        weightPerSquare = 350;
        break;
      case 'Clay Tile':
        weightPerSquare = 1000;
        break;
      case 'Concrete Tile':
        weightPerSquare = 950;
        break;
      case 'Metal':
        weightPerSquare = 150;
        break;
      case 'Slate':
        weightPerSquare = 800;
        break;
      default:
        weightPerSquare = 250;
    }

    // Multiply by layers
    final roofWeight = squares * weightPerSquare * layers;

    // Add deck weight if replacing (plywood ~70 lbs per square)
    double deckWeight = 0;
    if (_includeDeck) {
      deckWeight = squares * 70;
    }

    final debrisWeight = roofWeight + deckWeight;
    final perSquareWeight = debrisWeight / squares;

    // Dumpster sizing: 10-yard holds ~3,000 lbs shingles, 20-yard holds ~6,000 lbs
    final dumpsterLoads = debrisWeight / 6000; // Using 20-yard dumpsters

    // Truck loads: typical dump truck holds 5-8 tons
    final truckLoads = debrisWeight / 12000; // Using 6-ton average

    setState(() {
      _debrisWeight = debrisWeight;
      _dumpsterLoads = dumpsterLoads;
      _truckLoads = truckLoads;
      _perSquareWeight = perSquareWeight;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _squaresController.text = '24';
    _layersController.text = '1';
    setState(() {
      _materialType = 'Asphalt Shingles';
      _includeDeck = false;
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
        title: Text('Tear-Off Weight', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'EXISTING ROOF'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Squares',
                      unit: 'sq',
                      hint: 'Total area',
                      controller: _squaresController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Layers',
                      unit: 'qty',
                      hint: '1-3 typical',
                      controller: _layersController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMaterialSelector(colors),
              const SizedBox(height: 12),
              _buildDeckToggle(colors),
              const SizedBox(height: 32),
              if (_debrisWeight != null) ...[
                _buildSectionHeader(colors, 'DEBRIS ESTIMATE'),
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
              Icon(LucideIcons.trash2, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Tear-Off Weight Calculator',
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
            'Estimate debris weight for disposal planning',
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
    final materials = ['Asphalt Shingles', 'Wood Shakes', 'Clay Tile', 'Concrete Tile', 'Metal', 'Slate'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _materialType,
          isExpanded: true,
          dropdownColor: colors.bgElevated,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          icon: Icon(LucideIcons.chevronDown, color: colors.textSecondary, size: 18),
          items: materials.map((mat) {
            return DropdownMenuItem(value: mat, child: Text(mat));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.selectionClick();
              setState(() => _materialType = value);
              _calculate();
            }
          },
        ),
      ),
    );
  }

  Widget _buildDeckToggle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Include Deck Replacement', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
              Text('+70 lbs per square', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            ],
          ),
          Switch(
            value: _includeDeck,
            activeColor: colors.accentPrimary,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _includeDeck = value);
              _calculate();
            },
          ),
        ],
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
          _buildResultRow(colors, 'Weight per Square', '${_perSquareWeight!.toStringAsFixed(0)} lbs'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL DEBRIS', '${_debrisWeight!.toStringAsFixed(0)} lbs', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Tons', '${(_debrisWeight! / 2000).toStringAsFixed(1)} tons'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, '20-Yard Dumpsters', '${_dumpsterLoads!.ceil()}'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Dump Truck Loads', '${_truckLoads!.ceil()}'),
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
                    Text('Material Weights', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Shingles: 250 lbs/sq | Wood: 350 lbs/sq', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Clay Tile: 1,000 lbs/sq | Concrete: 950 lbs/sq', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Metal: 150 lbs/sq | Slate: 800 lbs/sq', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
