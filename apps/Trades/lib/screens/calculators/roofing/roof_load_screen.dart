import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Roof Load Calculator - Calculate dead and live loads on roof
class RoofLoadScreen extends ConsumerStatefulWidget {
  const RoofLoadScreen({super.key});
  @override
  ConsumerState<RoofLoadScreen> createState() => _RoofLoadScreenState();
}

class _RoofLoadScreenState extends ConsumerState<RoofLoadScreen> {
  final _roofAreaController = TextEditingController(text: '2000');
  final _snowLoadController = TextEditingController(text: '20');

  String _roofingMaterial = 'Asphalt Shingles';
  String _deckType = 'Plywood';

  double? _deadLoad;
  double? _liveLoad;
  double? _totalLoad;
  double? _totalWeight;
  bool? _structureAdequate;

  @override
  void dispose() {
    _roofAreaController.dispose();
    _snowLoadController.dispose();
    super.dispose();
  }

  void _calculate() {
    final roofArea = double.tryParse(_roofAreaController.text);
    final snowLoad = double.tryParse(_snowLoadController.text);

    if (roofArea == null || snowLoad == null) {
      setState(() {
        _deadLoad = null;
        _liveLoad = null;
        _totalLoad = null;
        _totalWeight = null;
        _structureAdequate = null;
      });
      return;
    }

    // Dead load varies by material (PSF)
    double roofingWeight;
    switch (_roofingMaterial) {
      case 'Asphalt Shingles':
        roofingWeight = 2.5;
        break;
      case 'Wood Shakes':
        roofingWeight = 4.0;
        break;
      case 'Clay Tile':
        roofingWeight = 10.0;
        break;
      case 'Concrete Tile':
        roofingWeight = 9.5;
        break;
      case 'Metal':
        roofingWeight = 1.5;
        break;
      case 'Slate':
        roofingWeight = 15.0;
        break;
      default:
        roofingWeight = 2.5;
    }

    // Deck weight (PSF)
    double deckWeight;
    switch (_deckType) {
      case 'Plywood':
        deckWeight = 2.5;
        break;
      case 'OSB':
        deckWeight = 2.0;
        break;
      case 'Skip Sheathing':
        deckWeight = 1.5;
        break;
      default:
        deckWeight = 2.5;
    }

    // Framing, insulation, drywall estimate
    const framingWeight = 5.0; // PSF

    // Total dead load
    final deadLoad = roofingWeight + deckWeight + framingWeight;

    // Live load (snow + construction)
    // Minimum live load is 20 PSF per code
    final liveLoad = snowLoad > 20 ? snowLoad : 20.0;

    // Total design load
    final totalLoad = deadLoad + liveLoad;

    // Total weight on structure
    final totalWeight = totalLoad * roofArea;

    // Check if typical residential framing can handle it
    // Standard residential = 40 PSF total, can go up to 60 with reinforcement
    final structureAdequate = totalLoad <= 40;

    setState(() {
      _deadLoad = deadLoad;
      _liveLoad = liveLoad;
      _totalLoad = totalLoad;
      _totalWeight = totalWeight;
      _structureAdequate = structureAdequate;
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
    _snowLoadController.text = '20';
    setState(() {
      _roofingMaterial = 'Asphalt Shingles';
      _deckType = 'Plywood';
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
        title: Text('Roof Load', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ROOF SPECIFICATIONS'),
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
                      label: 'Snow Load',
                      unit: 'PSF',
                      hint: 'Ground snow',
                      controller: _snowLoadController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMaterialSelector(colors),
              const SizedBox(height: 12),
              _buildDeckSelector(colors),
              const SizedBox(height: 32),
              if (_totalLoad != null) ...[
                _buildSectionHeader(colors, 'LOAD ANALYSIS'),
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
              Icon(LucideIcons.scale, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Roof Load Calculator',
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
            'Calculate dead, live, and total roof loads',
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
    final materials = ['Asphalt Shingles', 'Metal', 'Clay Tile', 'Concrete Tile', 'Wood Shakes', 'Slate'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _roofingMaterial,
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
              setState(() => _roofingMaterial = value);
              _calculate();
            }
          },
        ),
      ),
    );
  }

  Widget _buildDeckSelector(ZaftoColors colors) {
    final decks = ['Plywood', 'OSB', 'Skip Sheathing'];
    return Row(
      children: decks.map((deck) {
        final isSelected = _deckType == deck;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _deckType = deck);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: deck != decks.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                deck,
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

  Widget _buildResultsCard(ZaftoColors colors) {
    final statusColor = _structureAdequate! ? colors.accentSuccess : colors.accentWarning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _structureAdequate! ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _structureAdequate! ? 'Standard Framing OK' : 'Reinforcement May Be Needed',
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildResultRow(colors, 'Dead Load', '${_deadLoad!.toStringAsFixed(1)} PSF'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Live Load', '${_liveLoad!.toStringAsFixed(1)} PSF'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL DESIGN LOAD', '${_totalLoad!.toStringAsFixed(1)} PSF', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Total Weight', '${(_totalWeight! / 1000).toStringAsFixed(1)} kips'),
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
                Text('Asphalt: 2.5 PSF | Metal: 1.5 PSF', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Clay Tile: 10 PSF | Concrete: 9.5 PSF', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Wood Shakes: 4 PSF | Slate: 15 PSF', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
