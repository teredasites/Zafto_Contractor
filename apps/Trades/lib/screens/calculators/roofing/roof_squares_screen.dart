import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Roof Squares Calculator - Convert area to roofing squares
class RoofSquaresScreen extends ConsumerStatefulWidget {
  const RoofSquaresScreen({super.key});
  @override
  ConsumerState<RoofSquaresScreen> createState() => _RoofSquaresScreenState();
}

class _RoofSquaresScreenState extends ConsumerState<RoofSquaresScreen> {
  final _areaController = TextEditingController(text: '2400');
  final _wasteController = TextEditingController(text: '10');

  double? _squares;
  double? _squaresWithWaste;
  int? _bundlesNeeded;

  @override
  void dispose() {
    _areaController.dispose();
    _wasteController.dispose();
    super.dispose();
  }

  void _calculate() {
    final area = double.tryParse(_areaController.text);
    final wastePercent = double.tryParse(_wasteController.text);

    if (area == null || wastePercent == null) {
      setState(() {
        _squares = null;
        _squaresWithWaste = null;
        _bundlesNeeded = null;
      });
      return;
    }

    // 1 square = 100 sq ft
    final squares = area / 100;
    final squaresWithWaste = squares * (1 + wastePercent / 100);

    // Standard: 3 bundles per square
    final bundlesNeeded = (squaresWithWaste * 3).ceil();

    setState(() {
      _squares = squares;
      _squaresWithWaste = squaresWithWaste;
      _bundlesNeeded = bundlesNeeded;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _areaController.text = '2400';
    _wasteController.text = '10';
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
        title: Text('Roof Squares', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
                label: 'Total Roof Area',
                unit: 'sq ft',
                hint: 'Actual roof area',
                controller: _areaController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Waste Factor',
                unit: '%',
                hint: '10-15% typical',
                controller: _wasteController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_squares != null) ...[
                _buildSectionHeader(colors, 'RESULTS'),
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
                'Roof Squares Calculator',
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
            'Convert roof area to roofing squares (100 sq ft)',
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
          _buildResultRow(colors, 'Net Squares', _squares!.toStringAsFixed(1)),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'SQUARES + WASTE', _squaresWithWaste!.toStringAsFixed(1), isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Bundles Needed', '$_bundlesNeeded (3-tab)', isHighlighted: true),
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
                    Text('Bundle Coverage', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('3-Tab Shingles: 3 bundles/square', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                Text('Architectural: 3-4 bundles/square', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                Text('Premium: 4-5 bundles/square', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
