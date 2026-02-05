import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Synthetic Underlayment Calculator - Calculate synthetic roofing underlayment
class SyntheticUnderlaymentScreen extends ConsumerStatefulWidget {
  const SyntheticUnderlaymentScreen({super.key});
  @override
  ConsumerState<SyntheticUnderlaymentScreen> createState() => _SyntheticUnderlaymentScreenState();
}

class _SyntheticUnderlaymentScreenState extends ConsumerState<SyntheticUnderlaymentScreen> {
  final _roofAreaController = TextEditingController(text: '2500');
  final _wasteController = TextEditingController(text: '10');

  String _productType = 'Standard';
  String _rollSize = '10 Sq';

  double? _squares;
  int? _rollsNeeded;
  int? _capNails;
  double? _tapeFeet;

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
        _rollsNeeded = null;
        _capNails = null;
        _tapeFeet = null;
      });
      return;
    }

    final squares = roofArea / 100;

    // Roll coverage
    double rollCoverage;
    switch (_rollSize) {
      case '4 Sq':
        rollCoverage = 400;
        break;
      case '10 Sq':
        rollCoverage = 1000;
        break;
      default:
        rollCoverage = 1000;
    }

    final wasteFactor = 1 + waste / 100;
    final rollsNeeded = (roofArea * wasteFactor / rollCoverage).ceil();

    // Cap nails: approximately 4 per sq ft of underlayment
    final capNails = (roofArea * 4 * wasteFactor / 1000).ceil(); // In thousands

    // Seam tape: estimate based on roof dimensions
    // Rough estimate: perimeter + seams
    final tapeFeet = roofArea / 50; // Very rough estimate

    setState(() {
      _squares = squares;
      _rollsNeeded = rollsNeeded;
      _capNails = capNails;
      _tapeFeet = tapeFeet;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _roofAreaController.text = '2500';
    _wasteController.text = '10';
    setState(() {
      _productType = 'Standard';
      _rollSize = '10 Sq';
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
        title: Text('Synthetic Underlayment', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'PRODUCT TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSizeSelector(colors),
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
                      hint: '10% typical',
                      controller: _wasteController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_rollsNeeded != null) ...[
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
                'Synthetic Underlayment',
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
            'Calculate synthetic roof underlayment',
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
    final types = ['Standard', 'Premium', 'Peel & Stick'];
    return Row(
      children: types.map((type) {
        final isSelected = _productType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _productType = type);
            },
            child: Container(
              margin: EdgeInsets.only(right: type != types.last ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
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
    final sizes = ['4 Sq', '10 Sq'];
    return Row(
      children: sizes.map((size) {
        final isSelected = _rollSize == size;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _rollSize = size);
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
              child: Column(
                children: [
                  Text(
                    size,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Roll',
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
          _buildResultRow(colors, 'ROLLS NEEDED', '$_rollsNeeded', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Cap Nails', '${_capNails}K'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Seam Tape', '${_tapeFeet!.toStringAsFixed(0)} lin ft'),
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
                    Text('Synthetic vs Felt', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Lighter weight, easier to install', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('UV resistant for longer exposure', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text("Won't absorb water like felt", style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
