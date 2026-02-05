import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Federal ITC Calculator - Tax credit calculation
class FederalItcScreen extends ConsumerStatefulWidget {
  const FederalItcScreen({super.key});
  @override
  ConsumerState<FederalItcScreen> createState() => _FederalItcScreenState();
}

class _FederalItcScreenState extends ConsumerState<FederalItcScreen> {
  final _systemCostController = TextEditingController(text: '30000');
  final _batteryCostController = TextEditingController(text: '0');

  String _selectedYear = '2024-2032';
  double? _totalCost;
  double? _itcRate;
  double? _creditAmount;
  String? _notes;

  final Map<String, double> _itcRates = {
    '2024-2032': 30,
    '2033': 26,
    '2034': 22,
  };

  @override
  void dispose() {
    _systemCostController.dispose();
    _batteryCostController.dispose();
    super.dispose();
  }

  void _calculate() {
    final systemCost = double.tryParse(_systemCostController.text);
    final batteryCost = double.tryParse(_batteryCostController.text);

    if (systemCost == null || batteryCost == null) {
      setState(() {
        _totalCost = null;
        _itcRate = null;
        _creditAmount = null;
        _notes = null;
      });
      return;
    }

    final totalCost = systemCost + batteryCost;
    final itcRate = _itcRates[_selectedYear] ?? 30;
    final creditAmount = totalCost * (itcRate / 100);

    String notes;
    if (_selectedYear == '2024-2032') {
      notes = 'IRA extended 30% ITC through 2032. Battery storage qualifies even without solar.';
    } else if (_selectedYear == '2033') {
      notes = 'ITC steps down to 26% in 2033.';
    } else {
      notes = 'ITC steps down to 22% in 2034. Plan accordingly.';
    }

    setState(() {
      _totalCost = totalCost;
      _itcRate = itcRate;
      _creditAmount = creditAmount;
      _notes = notes;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _systemCostController.text = '30000';
    _batteryCostController.text = '0';
    setState(() => _selectedYear = '2024-2032');
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
        title: Text('Federal ITC', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'PROJECT COST'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Solar System Cost',
                unit: '\$',
                hint: 'Panels + inverter + labor',
                controller: _systemCostController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Battery Storage Cost',
                unit: '\$',
                hint: 'Optional - also qualifies',
                controller: _batteryCostController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'INSTALLATION YEAR'),
              const SizedBox(height: 12),
              _buildYearSelector(colors),
              const SizedBox(height: 32),
              if (_creditAmount != null) ...[
                _buildSectionHeader(colors, 'TAX CREDIT'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildQualificationInfo(colors),
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
              Icon(LucideIcons.landmark, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Investment Tax Credit',
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
            'Federal tax credit reduces your income tax liability',
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

  Widget _buildYearSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: _itcRates.entries.map((e) {
          final isSelected = _selectedYear == e.key;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: e.key != _itcRates.keys.last ? 8 : 0),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedYear = e.key);
                  _calculate();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      Text(
                        e.key,
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${e.value.toInt()}%',
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Federal Tax Credit', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '\$${_creditAmount!.toStringAsFixed(0)}',
            style: TextStyle(color: colors.accentSuccess, fontSize: 44, fontWeight: FontWeight.w700),
          ),
          Text(
            '${_itcRate!.toInt()}% of \$${_totalCost!.toStringAsFixed(0)}',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
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
                    _notes!,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualificationInfo(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildCheckItem(colors, 'System must be new (not used)'),
          _buildCheckItem(colors, 'Installed at US residence/business'),
          _buildCheckItem(colors, 'You must own the system (not lease)'),
          _buildCheckItem(colors, 'Must have tax liability to claim'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.alertTriangle, size: 14, color: colors.accentWarning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is a tax credit, not a refund. You must owe taxes to benefit. Excess can be carried forward.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(ZaftoColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(LucideIcons.check, size: 14, color: colors.accentSuccess),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }
}
