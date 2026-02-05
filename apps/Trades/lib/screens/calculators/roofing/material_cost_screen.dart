import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Material Cost Calculator - Estimate roofing material costs
class MaterialCostScreen extends ConsumerStatefulWidget {
  const MaterialCostScreen({super.key});
  @override
  ConsumerState<MaterialCostScreen> createState() => _MaterialCostScreenState();
}

class _MaterialCostScreenState extends ConsumerState<MaterialCostScreen> {
  final _squaresController = TextEditingController(text: '24');
  final _bundlePriceController = TextEditingController(text: '35');
  final _underlaymentPriceController = TextEditingController(text: '75');

  String _shingleType = 'Architectural';
  String _underlaymentType = 'Synthetic';

  double? _shingleCost;
  double? _underlaymentCost;
  double? _accessoriesCost;
  double? _totalCost;
  double? _costPerSquare;

  @override
  void dispose() {
    _squaresController.dispose();
    _bundlePriceController.dispose();
    _underlaymentPriceController.dispose();
    super.dispose();
  }

  void _calculate() {
    final squares = double.tryParse(_squaresController.text);
    final bundlePrice = double.tryParse(_bundlePriceController.text);
    final underlaymentPrice = double.tryParse(_underlaymentPriceController.text);

    if (squares == null || bundlePrice == null || underlaymentPrice == null) {
      setState(() {
        _shingleCost = null;
        _underlaymentCost = null;
        _accessoriesCost = null;
        _totalCost = null;
        _costPerSquare = null;
      });
      return;
    }

    // Bundles per square
    int bundlesPerSquare;
    switch (_shingleType) {
      case '3-Tab':
        bundlesPerSquare = 3;
        break;
      case 'Architectural':
        bundlesPerSquare = 4;
        break;
      case 'Premium':
        bundlesPerSquare = 5;
        break;
      default:
        bundlesPerSquare = 4;
    }

    // Shingle cost (add 10% waste)
    final bundlesNeeded = (squares * bundlesPerSquare * 1.1).ceil();
    final shingleCost = bundlesNeeded * bundlePrice;

    // Underlayment coverage per roll
    double underlaymentCoverage;
    switch (_underlaymentType) {
      case '15# Felt':
        underlaymentCoverage = 4; // squares per roll
        break;
      case '30# Felt':
        underlaymentCoverage = 2;
        break;
      case 'Synthetic':
        underlaymentCoverage = 10;
        break;
      default:
        underlaymentCoverage = 4;
    }

    final underlaymentRolls = (squares * 1.1 / underlaymentCoverage).ceil();
    final underlaymentCost = underlaymentRolls * underlaymentPrice;

    // Accessories estimate (drip edge, ridge cap, nails, ice shield, vents)
    // Typically 15-20% of shingle cost
    final accessoriesCost = shingleCost * 0.18;

    final totalCost = shingleCost + underlaymentCost + accessoriesCost;
    final costPerSquare = totalCost / squares;

    setState(() {
      _shingleCost = shingleCost;
      _underlaymentCost = underlaymentCost;
      _accessoriesCost = accessoriesCost;
      _totalCost = totalCost;
      _costPerSquare = costPerSquare;
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
    _bundlePriceController.text = '35';
    _underlaymentPriceController.text = '75';
    setState(() {
      _shingleType = 'Architectural';
      _underlaymentType = 'Synthetic';
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
        title: Text('Material Cost', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ROOF SIZE'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Roof Squares',
                unit: 'sq',
                hint: 'Total squares',
                controller: _squaresController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SHINGLE TYPE & PRICE'),
              const SizedBox(height: 12),
              _buildShingleSelector(colors),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Bundle Price',
                unit: '\$',
                hint: 'Per bundle',
                controller: _bundlePriceController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'UNDERLAYMENT'),
              const SizedBox(height: 12),
              _buildUnderlaymentSelector(colors),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Roll Price',
                unit: '\$',
                hint: 'Per roll',
                controller: _underlaymentPriceController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_totalCost != null) ...[
                _buildSectionHeader(colors, 'COST ESTIMATE'),
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
              Icon(LucideIcons.dollarSign, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Material Cost Calculator',
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
            'Estimate roofing material costs',
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

  Widget _buildShingleSelector(ZaftoColors colors) {
    final types = ['3-Tab', 'Architectural', 'Premium'];
    return Row(
      children: types.map((type) {
        final isSelected = _shingleType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _shingleType = type);
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

  Widget _buildUnderlaymentSelector(ZaftoColors colors) {
    final types = ['15# Felt', '30# Felt', 'Synthetic'];
    return Row(
      children: types.map((type) {
        final isSelected = _underlaymentType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _underlaymentType = type);
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          _buildResultRow(colors, 'Shingles', '\$${_shingleCost!.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Underlayment', '\$${_underlaymentCost!.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Accessories (est)', '\$${_accessoriesCost!.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL MATERIALS', '\$${_totalCost!.toStringAsFixed(0)}', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Cost per Square', '\$${_costPerSquare!.toStringAsFixed(0)}/sq', isHighlighted: true),
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
                    'Accessories include drip edge, ridge cap, nails, ice shield, and vents. Estimate is 18% of shingle cost.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
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
