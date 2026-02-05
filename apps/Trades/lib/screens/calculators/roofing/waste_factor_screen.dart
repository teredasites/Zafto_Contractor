import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Waste Factor Calculator - Determine appropriate waste percentage
class WasteFactorScreen extends ConsumerStatefulWidget {
  const WasteFactorScreen({super.key});
  @override
  ConsumerState<WasteFactorScreen> createState() => _WasteFactorScreenState();
}

class _WasteFactorScreenState extends ConsumerState<WasteFactorScreen> {
  final _netAreaController = TextEditingController(text: '2400');

  String _roofComplexity = 'Standard';
  String _material = 'Shingles';
  bool _hasValleys = true;
  bool _hasHips = false;
  bool _hasDormers = false;

  double? _wastePercent;
  double? _grossArea;
  double? _wasteAmount;

  @override
  void dispose() {
    _netAreaController.dispose();
    super.dispose();
  }

  void _calculate() {
    final netArea = double.tryParse(_netAreaController.text);

    if (netArea == null) {
      setState(() {
        _wastePercent = null;
        _grossArea = null;
        _wasteAmount = null;
      });
      return;
    }

    // Base waste by complexity
    double baseWaste;
    switch (_roofComplexity) {
      case 'Simple':
        baseWaste = 5.0;
        break;
      case 'Standard':
        baseWaste = 10.0;
        break;
      case 'Complex':
        baseWaste = 15.0;
        break;
      case 'Very Complex':
        baseWaste = 20.0;
        break;
      default:
        baseWaste = 10.0;
    }

    // Material adjustment
    double materialAdjust;
    switch (_material) {
      case 'Shingles':
        materialAdjust = 0.0;
        break;
      case 'Metal Panels':
        materialAdjust = -2.0; // Less waste with custom lengths
        break;
      case 'Tile':
        materialAdjust = 3.0; // More breakage
        break;
      case 'Slate':
        materialAdjust = 5.0; // Cutting/breakage
        break;
      default:
        materialAdjust = 0.0;
    }

    // Feature adjustments
    double featureWaste = 0;
    if (_hasValleys) featureWaste += 2.0;
    if (_hasHips) featureWaste += 3.0;
    if (_hasDormers) featureWaste += 3.0;

    // Total waste percentage
    final wastePercent = baseWaste + materialAdjust + featureWaste;
    final grossArea = netArea * (1 + wastePercent / 100);
    final wasteAmount = grossArea - netArea;

    setState(() {
      _wastePercent = wastePercent;
      _grossArea = grossArea;
      _wasteAmount = wasteAmount;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _netAreaController.text = '2400';
    setState(() {
      _roofComplexity = 'Standard';
      _material = 'Shingles';
      _hasValleys = true;
      _hasHips = false;
      _hasDormers = false;
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
        title: Text('Waste Factor', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ROOF AREA'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Net Roof Area',
                unit: 'sq ft',
                hint: 'Measured area',
                controller: _netAreaController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOF COMPLEXITY'),
              const SizedBox(height: 12),
              _buildComplexitySelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'MATERIAL TYPE'),
              const SizedBox(height: 12),
              _buildMaterialSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOF FEATURES'),
              const SizedBox(height: 12),
              _buildFeatureToggles(colors),
              const SizedBox(height: 32),
              if (_wastePercent != null) ...[
                _buildSectionHeader(colors, 'RECOMMENDED WASTE'),
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
              Icon(LucideIcons.percent, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Waste Factor Calculator',
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
            'Determine appropriate material waste %',
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

  Widget _buildComplexitySelector(ZaftoColors colors) {
    final complexities = ['Simple', 'Standard', 'Complex', 'Very Complex'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: complexities.map((complexity) {
        final isSelected = _roofComplexity == complexity;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _roofComplexity = complexity);
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
              complexity,
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

  Widget _buildMaterialSelector(ZaftoColors colors) {
    final materials = ['Shingles', 'Metal Panels', 'Tile', 'Slate'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: materials.map((material) {
        final isSelected = _material == material;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _material = material);
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
              material,
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

  Widget _buildFeatureToggles(ZaftoColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          _buildToggleRow(colors, 'Valleys', _hasValleys, (val) {
            setState(() => _hasValleys = val);
            _calculate();
          }),
          Divider(color: colors.borderSubtle, height: 1),
          _buildToggleRow(colors, 'Hips', _hasHips, (val) {
            setState(() => _hasHips = val);
            _calculate();
          }),
          Divider(color: colors.borderSubtle, height: 1),
          _buildToggleRow(colors, 'Dormers', _hasDormers, (val) {
            setState(() => _hasDormers = val);
            _calculate();
          }),
        ],
      ),
    );
  }

  Widget _buildToggleRow(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Switch(
            value: value,
            activeColor: colors.accentPrimary,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              onChanged(val);
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
          _buildResultRow(colors, 'WASTE FACTOR', '${_wastePercent!.toStringAsFixed(0)}%', isHighlighted: true),
          const SizedBox(height: 16),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 16),
          _buildResultRow(colors, 'Net Area', '${double.tryParse(_netAreaController.text)?.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Waste Amount', '${_wasteAmount!.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'ORDER AMOUNT', '${_grossArea!.toStringAsFixed(0)} sq ft', isHighlighted: true),
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
                    Text('Waste Guidelines', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Simple gable: 5-7% | Standard: 10-12%', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Complex hips/valleys: 15-18%', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Cut-up with dormers: 20%+', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
