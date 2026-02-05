import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Roof Coating Calculator - Calculate coating materials for flat roofs
class RoofCoatingScreen extends ConsumerStatefulWidget {
  const RoofCoatingScreen({super.key});
  @override
  ConsumerState<RoofCoatingScreen> createState() => _RoofCoatingScreenState();
}

class _RoofCoatingScreenState extends ConsumerState<RoofCoatingScreen> {
  final _roofAreaController = TextEditingController(text: '3000');
  final _coatsController = TextEditingController(text: '2');

  String _coatingType = 'Elastomeric';

  double? _squares;
  double? _gallonsNeeded;
  double? _fiveGallonBuckets;
  double? _materialCost;

  @override
  void dispose() {
    _roofAreaController.dispose();
    _coatsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final roofArea = double.tryParse(_roofAreaController.text);
    final coats = int.tryParse(_coatsController.text);

    if (roofArea == null || coats == null) {
      setState(() {
        _squares = null;
        _gallonsNeeded = null;
        _fiveGallonBuckets = null;
        _materialCost = null;
      });
      return;
    }

    final squares = roofArea / 100;

    // Coverage rate varies by coating type (sq ft per gallon)
    double coverageRate;
    double costPerGallon;
    switch (_coatingType) {
      case 'Elastomeric':
        coverageRate = 100; // 100 sq ft/gal
        costPerGallon = 45;
        break;
      case 'Silicone':
        coverageRate = 80;
        costPerGallon = 75;
        break;
      case 'Acrylic':
        coverageRate = 125;
        costPerGallon = 35;
        break;
      case 'Polyurethane':
        coverageRate = 60;
        costPerGallon = 90;
        break;
      default:
        coverageRate = 100;
        costPerGallon = 45;
    }

    // Total gallons needed for all coats
    final gallonsPerCoat = roofArea / coverageRate;
    final gallonsNeeded = gallonsPerCoat * coats;

    // 5-gallon buckets
    final fiveGallonBuckets = (gallonsNeeded / 5).ceil().toDouble();

    // Material cost estimate
    final materialCost = fiveGallonBuckets * 5 * costPerGallon;

    setState(() {
      _squares = squares;
      _gallonsNeeded = gallonsNeeded;
      _fiveGallonBuckets = fiveGallonBuckets;
      _materialCost = materialCost;
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
    _coatsController.text = '2';
    setState(() => _coatingType = 'Elastomeric');
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
        title: Text('Roof Coating', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'COATING TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'APPLICATION'),
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
                      label: 'Coats',
                      unit: 'qty',
                      hint: '2 recommended',
                      controller: _coatsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_gallonsNeeded != null) ...[
                _buildSectionHeader(colors, 'COATING MATERIALS'),
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
              Icon(LucideIcons.paintBucket, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Roof Coating Calculator',
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
            'Calculate coating materials for flat roofs',
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
    final types = ['Elastomeric', 'Silicone', 'Acrylic', 'Polyurethane'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = _coatingType == type;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _coatingType = type);
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
                fontSize: 13,
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
          _buildResultRow(colors, 'Roof Squares', _squares!.toStringAsFixed(1)),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL GALLONS', '${_gallonsNeeded!.toStringAsFixed(0)} gal', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, '5-GAL BUCKETS', '${_fiveGallonBuckets!.toStringAsFixed(0)}', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Est. Material Cost', '\$${_materialCost!.toStringAsFixed(0)}'),
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
                    Text('Coverage Rates', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Elastomeric: 100 sq ft/gal', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Silicone: 80 sq ft/gal', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Acrylic: 125 sq ft/gal', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
