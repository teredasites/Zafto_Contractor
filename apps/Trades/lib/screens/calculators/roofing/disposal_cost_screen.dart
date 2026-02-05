import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Disposal Cost Calculator - Calculate roofing debris disposal costs
class DisposalCostScreen extends ConsumerStatefulWidget {
  const DisposalCostScreen({super.key});
  @override
  ConsumerState<DisposalCostScreen> createState() => _DisposalCostScreenState();
}

class _DisposalCostScreenState extends ConsumerState<DisposalCostScreen> {
  final _roofSquaresController = TextEditingController(text: '25');
  final _layersController = TextEditingController(text: '2');
  final _dumpsterCostController = TextEditingController(text: '450');

  String _roofingType = 'Asphalt Shingles';

  double? _debrisWeight;
  int? _dumpstersNeeded;
  double? _totalCost;
  double? _tippingFee;

  @override
  void dispose() {
    _roofSquaresController.dispose();
    _layersController.dispose();
    _dumpsterCostController.dispose();
    super.dispose();
  }

  void _calculate() {
    final roofSquares = double.tryParse(_roofSquaresController.text);
    final layers = int.tryParse(_layersController.text);
    final dumpsterCost = double.tryParse(_dumpsterCostController.text);

    if (roofSquares == null || layers == null || dumpsterCost == null) {
      setState(() {
        _debrisWeight = null;
        _dumpstersNeeded = null;
        _totalCost = null;
        _tippingFee = null;
      });
      return;
    }

    // Weight per square varies by material
    double lbsPerSquare;
    switch (_roofingType) {
      case 'Asphalt Shingles':
        lbsPerSquare = 250; // 3-tab ~200, architectural ~350
        break;
      case 'Wood Shake':
        lbsPerSquare = 350;
        break;
      case 'Tile':
        lbsPerSquare = 900;
        break;
      case 'Slate':
        lbsPerSquare = 800;
        break;
      case 'Metal':
        lbsPerSquare = 100;
        break;
      default:
        lbsPerSquare = 250;
    }

    // Total debris weight
    final debrisWeight = roofSquares * layers * lbsPerSquare;

    // Dumpster capacity: 20-yard holds ~3 tons, 30-yard ~4 tons
    // Using 30-yard dumpster (6000 lbs typical capacity)
    final dumpsterCapacity = 6000.0; // lbs
    final dumpstersNeeded = (debrisWeight / dumpsterCapacity).ceil();

    // Estimate tipping fee (additional per ton beyond included weight)
    // Typically $50-80/ton for overage
    final tonsTotal = debrisWeight / 2000;
    final includedTons = dumpstersNeeded * 3.0; // 3 tons included per dumpster
    final overageTons = tonsTotal > includedTons ? tonsTotal - includedTons : 0.0;
    final tippingFee = overageTons * 65; // $65/ton overage

    final totalCost = (dumpstersNeeded * dumpsterCost) + tippingFee;

    setState(() {
      _debrisWeight = debrisWeight;
      _dumpstersNeeded = dumpstersNeeded;
      _totalCost = totalCost;
      _tippingFee = tippingFee;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _roofSquaresController.text = '25';
    _layersController.text = '2';
    _dumpsterCostController.text = '450';
    setState(() => _roofingType = 'Asphalt Shingles');
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
        title: Text('Disposal Cost', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ROOFING MATERIAL'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TEAR-OFF DETAILS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Squares',
                      unit: 'sq',
                      hint: 'Total area',
                      controller: _roofSquaresController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Layers',
                      unit: 'qty',
                      hint: 'Existing layers',
                      controller: _layersController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Dumpster Rental',
                unit: '\$',
                hint: '30-yard typical',
                controller: _dumpsterCostController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_totalCost != null) ...[
                _buildSectionHeader(colors, 'DISPOSAL ESTIMATE'),
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
                'Disposal Cost Calculator',
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
            'Estimate roofing debris disposal costs',
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
    final types = ['Asphalt Shingles', 'Wood Shake', 'Tile', 'Slate', 'Metal'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = _roofingType == type;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _roofingType = type);
            _calculate();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          _buildResultRow(colors, 'Debris Weight', '${(_debrisWeight! / 2000).toStringAsFixed(1)} tons'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'DUMPSTERS NEEDED', '$_dumpstersNeeded', isHighlighted: true),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          if (_tippingFee! > 0) ...[
            _buildResultRow(colors, 'Overage Fee', '\$${_tippingFee!.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
          ],
          _buildResultRow(colors, 'TOTAL DISPOSAL', '\$${_totalCost!.toStringAsFixed(0)}', isHighlighted: true),
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
                    Text('Weight per Square', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Asphalt: 200-350 lbs | Wood: 350 lbs', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Tile: 900 lbs | Slate: 800 lbs', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Metal: 100 lbs per square', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
