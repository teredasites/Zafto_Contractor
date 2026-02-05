import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Plate Calculator - Calculate top and bottom plates
class PlateCalculatorScreen extends ConsumerStatefulWidget {
  const PlateCalculatorScreen({super.key});
  @override
  ConsumerState<PlateCalculatorScreen> createState() => _PlateCalculatorScreenState();
}

class _PlateCalculatorScreenState extends ConsumerState<PlateCalculatorScreen> {
  final _wallLengthController = TextEditingController(text: '40');

  bool _doubleTopPlate = true;

  double? _bottomPlate;
  double? _topPlate;
  double? _totalLinearFeet;
  int? _boards8ft;
  int? _boards10ft;
  int? _boards12ft;

  @override
  void dispose() {
    _wallLengthController.dispose();
    super.dispose();
  }

  void _calculate() {
    final wallLength = double.tryParse(_wallLengthController.text);

    if (wallLength == null) {
      setState(() {
        _bottomPlate = null;
        _topPlate = null;
        _totalLinearFeet = null;
        _boards8ft = null;
        _boards10ft = null;
        _boards12ft = null;
      });
      return;
    }

    // Bottom plate: single
    final bottomPlate = wallLength;

    // Top plate: double (typical) or single
    final topPlate = _doubleTopPlate ? wallLength * 2 : wallLength;

    final totalLinearFeet = bottomPlate + topPlate;

    // Board counts (add 10% for waste)
    final withWaste = totalLinearFeet * 1.1;
    final boards8ft = (withWaste / 8).ceil();
    final boards10ft = (withWaste / 10).ceil();
    final boards12ft = (withWaste / 12).ceil();

    setState(() {
      _bottomPlate = bottomPlate;
      _topPlate = topPlate;
      _totalLinearFeet = totalLinearFeet;
      _boards8ft = boards8ft;
      _boards10ft = boards10ft;
      _boards12ft = boards12ft;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _wallLengthController.text = '40';
    setState(() => _doubleTopPlate = true);
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
        title: Text('Plate Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'WALL LENGTH'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Total Wall Length',
                unit: 'ft',
                hint: 'Linear feet of wall',
                controller: _wallLengthController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 16),
              _buildDoubleTopPlateToggle(colors),
              const SizedBox(height: 32),
              if (_totalLinearFeet != null) ...[
                _buildSectionHeader(colors, 'PLATE REQUIREMENTS'),
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
              Icon(LucideIcons.minus, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Plate Calculator',
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
            'Calculate top and bottom wall plates',
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

  Widget _buildDoubleTopPlateToggle(ZaftoColors colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _doubleTopPlate = !_doubleTopPlate);
        _calculate();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(
              _doubleTopPlate ? LucideIcons.checkSquare : LucideIcons.square,
              color: _doubleTopPlate ? colors.accentPrimary : colors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Double Top Plate',
                    style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Required for load-bearing walls',
                    style: TextStyle(color: colors.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          _buildResultRow(colors, 'Bottom Plate', '${_bottomPlate!.toStringAsFixed(1)} ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Top Plate${_doubleTopPlate ? " (double)" : ""}', '${_topPlate!.toStringAsFixed(1)} ft'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL LINEAR FEET', '${_totalLinearFeet!.toStringAsFixed(1)} ft', isHighlighted: true),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Board Count (with 10% waste)', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildResultRow(colors, '8\' boards', '$_boards8ft'),
                const SizedBox(height: 4),
                _buildResultRow(colors, '10\' boards', '$_boards10ft'),
                const SizedBox(height: 4),
                _buildResultRow(colors, '12\' boards', '$_boards12ft'),
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
