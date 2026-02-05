import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Underlayment Calculator - Calculate roofing underlayment
class UnderlaymentScreen extends ConsumerStatefulWidget {
  const UnderlaymentScreen({super.key});
  @override
  ConsumerState<UnderlaymentScreen> createState() => _UnderlaymentScreenState();
}

class _UnderlaymentScreenState extends ConsumerState<UnderlaymentScreen> {
  final _areaController = TextEditingController(text: '2400');
  final _iceShieldController = TextEditingController(text: '150');
  final _wasteController = TextEditingController(text: '10');

  String _feltType = 'Synthetic';

  double? _squares;
  int? _feltRolls;
  int? _iceShieldRolls;
  int? _capNails;
  int? _staples;

  @override
  void dispose() {
    _areaController.dispose();
    _iceShieldController.dispose();
    _wasteController.dispose();
    super.dispose();
  }

  void _calculate() {
    final area = double.tryParse(_areaController.text);
    final iceShieldArea = double.tryParse(_iceShieldController.text);
    final waste = double.tryParse(_wasteController.text);

    if (area == null || iceShieldArea == null || waste == null) {
      setState(() {
        _squares = null;
        _feltRolls = null;
        _iceShieldRolls = null;
        _capNails = null;
        _staples = null;
      });
      return;
    }

    final squares = area / 100;
    final areaWithWaste = area * (1 + waste / 100);
    final iceShieldWithWaste = iceShieldArea * (1 + waste / 100);

    // Coverage varies by type
    double feltCoverage; // sq ft per roll
    switch (_feltType) {
      case '15# Felt':
        feltCoverage = 400; // 4 squares
        break;
      case '30# Felt':
        feltCoverage = 200; // 2 squares
        break;
      case 'Synthetic':
        feltCoverage = 1000; // 10 squares
        break;
      default:
        feltCoverage = 400;
    }

    // Subtract ice shield area from felt area
    final feltArea = areaWithWaste - iceShieldWithWaste;
    final feltRolls = (feltArea / feltCoverage).ceil();

    // Ice & water shield: 75 sq ft per roll (typical)
    final iceShieldRolls = (iceShieldWithWaste / 75).ceil();

    // Fasteners: cap nails for felt (1 per sq ft), staples for synthetic (1 per 2 sq ft)
    int capNails = 0;
    int staples = 0;
    if (_feltType == 'Synthetic') {
      staples = (areaWithWaste / 2).ceil();
    } else {
      capNails = areaWithWaste.ceil();
    }

    setState(() {
      _squares = squares;
      _feltRolls = feltRolls;
      _iceShieldRolls = iceShieldRolls;
      _capNails = capNails;
      _staples = staples;
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
    _iceShieldController.text = '150';
    _wasteController.text = '10';
    setState(() => _feltType = 'Synthetic');
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
        title: Text('Underlayment', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'UNDERLAYMENT TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'AREA COVERAGE'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Total Roof Area',
                unit: 'sq ft',
                hint: 'Full roof area',
                controller: _areaController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Ice Shield Area',
                      unit: 'sq ft',
                      hint: 'Eaves, valleys',
                      controller: _iceShieldController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Waste',
                      unit: '%',
                      hint: '10%',
                      controller: _wasteController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_feltRolls != null) ...[
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
                'Underlayment Calculator',
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
            'Calculate felt, synthetic, and ice shield',
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
    final types = ['15# Felt', '30# Felt', 'Synthetic'];
    return Row(
      children: types.map((type) {
        final isSelected = _feltType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _feltType = type);
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
          _buildResultRow(colors, 'Roof Squares', _squares!.toStringAsFixed(1)),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'UNDERLAYMENT ROLLS', '$_feltRolls', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Ice & Water Shield', '$_iceShieldRolls rolls'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          if (_capNails! > 0)
            _buildResultRow(colors, 'Cap Nails', '$_capNails'),
          if (_staples! > 0)
            _buildResultRow(colors, 'Staples', '$_staples'),
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
                    Text('Coverage per Roll', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('15# Felt: 400 sq ft (4 squares)', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('30# Felt: 200 sq ft (2 squares)', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Synthetic: 1,000 sq ft (10 squares)', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Ice Shield: 75 sq ft per roll', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
