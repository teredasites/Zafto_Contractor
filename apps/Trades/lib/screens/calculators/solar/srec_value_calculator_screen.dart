import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// SREC Value Calculator - Solar renewable energy certificate value
class SrecValueCalculatorScreen extends ConsumerStatefulWidget {
  const SrecValueCalculatorScreen({super.key});
  @override
  ConsumerState<SrecValueCalculatorScreen> createState() => _SrecValueCalculatorScreenState();
}

class _SrecValueCalculatorScreenState extends ConsumerState<SrecValueCalculatorScreen> {
  final _systemSizeController = TextEditingController(text: '8');
  final _annualKwhController = TextEditingController(text: '11000');
  final _srecPriceController = TextEditingController(text: '150');
  final _contractYearsController = TextEditingController(text: '15');
  final _degradationController = TextEditingController(text: '0.5');

  String _selectedState = 'New Jersey';

  double? _annualSrecs;
  double? _year1Value;
  double? _lifetimeValue;
  String? _marketInfo;

  // SREC market data by state
  final Map<String, Map<String, dynamic>> _srecMarkets = {
    'New Jersey': {'price': 185.0, 'trend': 'Stable', 'program': 'SREC-II'},
    'Massachusetts': {'price': 200.0, 'trend': 'Strong', 'program': 'SMART'},
    'Pennsylvania': {'price': 35.0, 'trend': 'Declining', 'program': 'AEPS'},
    'Maryland': {'price': 65.0, 'trend': 'Stable', 'program': 'RPS'},
    'Illinois': {'price': 75.0, 'trend': 'Strong', 'program': 'Illinois Shines'},
    'Ohio': {'price': 8.0, 'trend': 'Low', 'program': 'AEPS'},
    'Washington DC': {'price': 400.0, 'trend': 'Very Strong', 'program': 'RPS'},
  };

  List<String> get _states => _srecMarkets.keys.toList()..sort();

  @override
  void dispose() {
    _systemSizeController.dispose();
    _annualKwhController.dispose();
    _srecPriceController.dispose();
    _contractYearsController.dispose();
    _degradationController.dispose();
    super.dispose();
  }

  void _updateStatePrice() {
    if (_srecMarkets.containsKey(_selectedState)) {
      _srecPriceController.text = _srecMarkets[_selectedState]!['price'].toStringAsFixed(0);
    }
  }

  void _calculate() {
    final systemSize = double.tryParse(_systemSizeController.text);
    final annualKwh = double.tryParse(_annualKwhController.text);
    final srecPrice = double.tryParse(_srecPriceController.text);
    final contractYears = int.tryParse(_contractYearsController.text);
    final degradation = double.tryParse(_degradationController.text);

    if (systemSize == null || annualKwh == null || srecPrice == null ||
        contractYears == null || degradation == null) {
      setState(() {
        _annualSrecs = null;
        _year1Value = null;
        _lifetimeValue = null;
        _marketInfo = null;
      });
      return;
    }

    // 1 SREC = 1,000 kWh (1 MWh)
    final annualSrecs = annualKwh / 1000;
    final year1Value = annualSrecs * srecPrice;

    // Calculate lifetime value with degradation
    double lifetimeValue = 0;
    final d = degradation / 100;

    for (int t = 0; t < contractYears; t++) {
      final yearProduction = annualKwh * (1 - d * t);
      final yearSrecs = yearProduction / 1000;
      lifetimeValue += yearSrecs * srecPrice;
    }

    final marketData = _srecMarkets[_selectedState];
    String marketInfo = 'Market data unavailable for selected state.';
    if (marketData != null) {
      marketInfo = '${marketData['program']} - Market trend: ${marketData['trend']}';
    }

    setState(() {
      _annualSrecs = annualSrecs;
      _year1Value = year1Value;
      _lifetimeValue = lifetimeValue;
      _marketInfo = marketInfo;
    });
  }

  @override
  void initState() {
    super.initState();
    _updateStatePrice();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _systemSizeController.text = '8';
    _annualKwhController.text = '11000';
    _contractYearsController.text = '15';
    _degradationController.text = '0.5';
    setState(() => _selectedState = 'New Jersey');
    _updateStatePrice();
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
        title: Text('SREC Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SREC MARKET'),
              const SizedBox(height: 12),
              _buildStateSelector(colors),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'SREC Price',
                unit: '\$/SREC',
                hint: 'Current price',
                controller: _srecPriceController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SYSTEM'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'System Size',
                      unit: 'kW',
                      hint: 'DC capacity',
                      controller: _systemSizeController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Annual Production',
                      unit: 'kWh',
                      hint: 'Year 1 output',
                      controller: _annualKwhController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Contract Length',
                      unit: 'years',
                      hint: 'SREC term',
                      controller: _contractYearsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Degradation',
                      unit: '%/yr',
                      hint: '0.5% typical',
                      controller: _degradationController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_annualSrecs != null) ...[
                _buildSectionHeader(colors, 'SREC VALUE'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildMarketTable(colors),
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
              Icon(LucideIcons.award, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'SREC Value Calculator',
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
            '1 SREC = 1 MWh (1,000 kWh) of solar production',
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

  Widget _buildStateSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedState,
          isExpanded: true,
          dropdownColor: colors.bgElevated,
          style: TextStyle(color: colors.textPrimary, fontSize: 16),
          icon: Icon(LucideIcons.chevronDown, color: colors.textSecondary),
          items: _states.map((state) {
            return DropdownMenuItem(
              value: state,
              child: Text(state),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.selectionClick();
              setState(() => _selectedState = value);
              _updateStatePrice();
              _calculate();
            }
          },
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
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Annual SRECs Generated', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _annualSrecs!.toStringAsFixed(1),
                style: TextStyle(color: colors.accentPrimary, fontSize: 40, fontWeight: FontWeight.w700),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  ' SRECs/yr',
                  style: TextStyle(color: colors.textSecondary, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Year 1 Value', '\$${_year1Value!.toStringAsFixed(0)}', colors.accentSuccess),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, '${_contractYearsController.text}-Year Total', '\$${(_lifetimeValue! / 1000).toStringAsFixed(1)}k', colors.accentInfo),
              ),
            ],
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
                    _marketInfo!,
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

  Widget _buildStatTile(ZaftoColors colors, String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildMarketTable(ZaftoColors colors) {
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
          Text('SREC MARKET PRICES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          ..._srecMarkets.entries.map((entry) {
            final isSelected = entry.key == _selectedState;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      color: isSelected ? colors.accentPrimary : colors.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  Text(
                    '\$${entry.value['price'].toStringAsFixed(0)}/SREC',
                    style: TextStyle(
                      color: isSelected ? colors.accentPrimary : colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
