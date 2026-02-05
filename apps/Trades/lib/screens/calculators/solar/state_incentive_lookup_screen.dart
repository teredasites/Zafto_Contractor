import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// State Incentive Lookup - Solar incentives by state
class StateIncentiveLookupScreen extends ConsumerStatefulWidget {
  const StateIncentiveLookupScreen({super.key});
  @override
  ConsumerState<StateIncentiveLookupScreen> createState() => _StateIncentiveLookupScreenState();
}

class _StateIncentiveLookupScreenState extends ConsumerState<StateIncentiveLookupScreen> {
  final _systemCostController = TextEditingController(text: '25000');
  final _systemSizeController = TextEditingController(text: '8');

  String _selectedState = 'California';

  Map<String, dynamic>? _incentives;
  double? _totalIncentives;
  double? _netCost;

  // State incentive database (simplified)
  final Map<String, Map<String, dynamic>> _stateData = {
    'California': {
      'stateCredit': 0.0, // Percentage
      'rebate': 0.0, // Per watt
      'netMetering': 'NEM 3.0',
      'srec': false,
      'notes': 'NEM 3.0 has lower export rates. Focus on self-consumption.',
    },
    'Arizona': {
      'stateCredit': 0.0,
      'rebate': 0.0,
      'netMetering': 'Full Retail',
      'srec': false,
      'notes': 'Good net metering. Consider peak shaving with battery.',
    },
    'Colorado': {
      'stateCredit': 0.0,
      'rebate': 0.0,
      'netMetering': 'Full Retail',
      'srec': false,
      'notes': 'Some utilities offer additional rebates. Check with local utility.',
    },
    'Connecticut': {
      'stateCredit': 0.0,
      'rebate': 0.0,
      'netMetering': 'Full Retail',
      'srec': false,
      'notes': 'RSIP closed. Check for new programs.',
    },
    'Florida': {
      'stateCredit': 0.0,
      'rebate': 0.0,
      'netMetering': 'Full Retail',
      'srec': false,
      'notes': 'Property tax exemption for solar. No sales tax on systems.',
    },
    'Hawaii': {
      'stateCredit': 0.35, // 35% state credit
      'rebate': 0.0,
      'netMetering': 'NEM+',
      'srec': false,
      'notes': 'Excellent state tax credit. Battery storage recommended.',
    },
    'Illinois': {
      'stateCredit': 0.0,
      'rebate': 0.0,
      'netMetering': 'Full Retail',
      'srec': true,
      'srecValue': 75.0, // Per REC
      'notes': 'Illinois Shines program offers strong SREC payments.',
    },
    'Maryland': {
      'stateCredit': 0.0,
      'rebate': 0.0,
      'netMetering': 'Full Retail',
      'srec': true,
      'srecValue': 65.0,
      'notes': 'Active SREC market. Good long-term returns.',
    },
    'Massachusetts': {
      'stateCredit': 0.15, // 15% credit up to $1000
      'maxCredit': 1000.0,
      'rebate': 0.0,
      'netMetering': 'Full Retail',
      'srec': true,
      'srecValue': 200.0,
      'notes': 'SMART program offers excellent incentives.',
    },
    'Nevada': {
      'stateCredit': 0.0,
      'rebate': 0.0,
      'netMetering': 'Reduced',
      'srec': false,
      'notes': 'Net billing at avoided cost rate. Consider battery.',
    },
    'New Jersey': {
      'stateCredit': 0.0,
      'rebate': 0.0,
      'netMetering': 'Full Retail',
      'srec': true,
      'srecValue': 185.0,
      'notes': 'Strong SREC-II program. 15-year contract available.',
    },
    'New York': {
      'stateCredit': 0.25, // 25% up to $5000
      'maxCredit': 5000.0,
      'rebate': 0.20, // Per watt for residential
      'netMetering': 'Full Retail',
      'srec': false,
      'notes': 'NY-Sun rebates available. Excellent state tax credit.',
    },
    'North Carolina': {
      'stateCredit': 0.0,
      'rebate': 0.0,
      'netMetering': 'Full Retail',
      'srec': false,
      'notes': 'Duke Energy territories may have rebates.',
    },
    'Oregon': {
      'stateCredit': 0.0,
      'rebate': 0.0,
      'netMetering': 'Full Retail',
      'srec': false,
      'notes': 'Solar + Storage rebate available. Check Energy Trust.',
    },
    'Pennsylvania': {
      'stateCredit': 0.0,
      'rebate': 0.0,
      'netMetering': 'Full Retail',
      'srec': true,
      'srecValue': 35.0,
      'notes': 'Active SREC market but lower prices.',
    },
    'Texas': {
      'stateCredit': 0.0,
      'rebate': 0.0,
      'netMetering': 'Varies',
      'srec': false,
      'notes': 'Net metering varies by utility. Check local options.',
    },
    'Washington': {
      'stateCredit': 0.0,
      'rebate': 0.0,
      'netMetering': 'Full Retail',
      'srec': false,
      'notes': 'Sales tax exemption for solar systems.',
    },
  };

  List<String> get _states => _stateData.keys.toList()..sort();

  @override
  void dispose() {
    _systemCostController.dispose();
    _systemSizeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final systemCost = double.tryParse(_systemCostController.text);
    final systemSize = double.tryParse(_systemSizeController.text);

    if (systemCost == null || systemSize == null) {
      setState(() {
        _incentives = null;
        _totalIncentives = null;
        _netCost = null;
      });
      return;
    }

    final stateData = _stateData[_selectedState]!;

    // Federal ITC (30%)
    final federalItc = systemCost * 0.30;

    // State credit
    double stateCredit = systemCost * (stateData['stateCredit'] as double);
    if (stateData.containsKey('maxCredit')) {
      stateCredit = stateCredit.clamp(0, stateData['maxCredit'] as double);
    }

    // Rebate (per watt)
    final rebate = (stateData['rebate'] as double) * systemSize * 1000;

    // SREC value (first year estimate)
    double srecYear1 = 0;
    if (stateData['srec'] == true) {
      // Estimate ~1200 kWh per kW per year, 1 SREC per 1000 kWh
      final annualSrecs = (systemSize * 1200) / 1000;
      srecYear1 = annualSrecs * (stateData['srecValue'] as double? ?? 0);
    }

    final totalIncentives = federalItc + stateCredit + rebate;
    final netCost = systemCost - totalIncentives;

    setState(() {
      _incentives = {
        'federalItc': federalItc,
        'stateCredit': stateCredit,
        'rebate': rebate,
        'srecYear1': srecYear1,
        'netMetering': stateData['netMetering'],
        'notes': stateData['notes'],
        'hasSrec': stateData['srec'],
      };
      _totalIncentives = totalIncentives;
      _netCost = netCost;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _systemCostController.text = '25000';
    _systemSizeController.text = '8';
    setState(() => _selectedState = 'California');
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
        title: Text('State Incentives', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SELECT STATE'),
              const SizedBox(height: 12),
              _buildStateSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SYSTEM'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'System Cost',
                      unit: '\$',
                      hint: 'Gross price',
                      controller: _systemCostController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'System Size',
                      unit: 'kW',
                      hint: 'DC capacity',
                      controller: _systemSizeController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_incentives != null) ...[
                _buildSectionHeader(colors, 'AVAILABLE INCENTIVES'),
                const SizedBox(height: 12),
                _buildIncentivesCard(colors),
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
              Icon(LucideIcons.mapPin, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'State Incentive Lookup',
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
            'View solar incentives available in your state',
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
              _calculate();
            }
          },
        ),
      ),
    );
  }

  Widget _buildIncentivesCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Federal ITC (30%)', '\$${_incentives!['federalItc'].toStringAsFixed(0)}', colors.accentSuccess),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(
                  colors,
                  'State Credit',
                  _incentives!['stateCredit'] > 0 ? '\$${_incentives!['stateCredit'].toStringAsFixed(0)}' : 'N/A',
                  _incentives!['stateCredit'] > 0 ? colors.accentInfo : colors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  colors,
                  'Rebate',
                  _incentives!['rebate'] > 0 ? '\$${_incentives!['rebate'].toStringAsFixed(0)}' : 'N/A',
                  _incentives!['rebate'] > 0 ? colors.accentPrimary : colors.textTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(
                  colors,
                  'SREC (Year 1)',
                  _incentives!['hasSrec'] ? '\$${_incentives!['srecYear1'].toStringAsFixed(0)}' : 'N/A',
                  _incentives!['hasSrec'] ? colors.accentWarning : colors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Upfront Incentives', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                    Text('\$${_totalIncentives!.toStringAsFixed(0)}', style: TextStyle(color: colors.accentSuccess, fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Net System Cost', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                    Text('\$${_netCost!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.zap, size: 14, color: colors.accentPrimary),
                    const SizedBox(width: 8),
                    Text('Net Metering: ${_incentives!['netMetering']}',
                      style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.info, size: 14, color: colors.accentInfo),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _incentives!['notes'],
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
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
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
