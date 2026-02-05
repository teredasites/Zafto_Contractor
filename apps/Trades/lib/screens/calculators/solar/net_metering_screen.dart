import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Net Metering Calculator - Bill credits calculation
class NetMeteringScreen extends ConsumerStatefulWidget {
  const NetMeteringScreen({super.key});
  @override
  ConsumerState<NetMeteringScreen> createState() => _NetMeteringScreenState();
}

class _NetMeteringScreenState extends ConsumerState<NetMeteringScreen> {
  final _monthlyUsageController = TextEditingController(text: '1000');
  final _solarProductionController = TextEditingController(text: '1200');
  final _buyRateController = TextEditingController(text: '0.15');
  final _sellRateController = TextEditingController(text: '0.15');
  final _connectionFeeController = TextEditingController(text: '15');

  String _netMeteringType = 'Full Retail';

  double? _netEnergy;
  double? _billCredit;
  double? _finalBill;
  String? _explanation;

  @override
  void dispose() {
    _monthlyUsageController.dispose();
    _solarProductionController.dispose();
    _buyRateController.dispose();
    _sellRateController.dispose();
    _connectionFeeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final monthlyUsage = double.tryParse(_monthlyUsageController.text);
    final solarProduction = double.tryParse(_solarProductionController.text);
    final buyRate = double.tryParse(_buyRateController.text);
    var sellRate = double.tryParse(_sellRateController.text);
    final connectionFee = double.tryParse(_connectionFeeController.text);

    if (monthlyUsage == null || solarProduction == null || buyRate == null ||
        sellRate == null || connectionFee == null) {
      setState(() {
        _netEnergy = null;
        _billCredit = null;
        _finalBill = null;
        _explanation = null;
      });
      return;
    }

    // Adjust sell rate based on net metering type
    if (_netMeteringType == 'Avoided Cost') {
      sellRate = buyRate * 0.4; // ~40% of retail
    } else if (_netMeteringType == 'NEM 3.0 (CA)') {
      sellRate = buyRate * 0.25; // ~25% of retail
    }

    // Calculate net energy
    final netEnergy = solarProduction - monthlyUsage;

    double finalBill;
    double billCredit;
    String explanation;

    if (netEnergy >= 0) {
      // Net exporter - earned credit
      billCredit = netEnergy * sellRate!;
      finalBill = connectionFee; // Just pay connection fee
      explanation = 'Net exporter: ${netEnergy.toStringAsFixed(0)} kWh credit rolls forward or pays out.';
    } else {
      // Net importer - pay for difference
      billCredit = 0;
      final netPurchase = netEnergy.abs();
      finalBill = connectionFee + (netPurchase * buyRate);
      explanation = 'Net importer: Pay for ${netPurchase.toStringAsFixed(0)} kWh from grid.';
    }

    setState(() {
      _netEnergy = netEnergy;
      _billCredit = billCredit;
      _finalBill = finalBill;
      _explanation = explanation;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _monthlyUsageController.text = '1000';
    _solarProductionController.text = '1200';
    _buyRateController.text = '0.15';
    _sellRateController.text = '0.15';
    _connectionFeeController.text = '15';
    setState(() => _netMeteringType = 'Full Retail');
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
        title: Text('Net Metering', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'NET METERING TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ENERGY'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Monthly Usage',
                      unit: 'kWh',
                      hint: 'From grid',
                      controller: _monthlyUsageController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Solar Production',
                      unit: 'kWh',
                      hint: 'Generated',
                      controller: _solarProductionController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'RATES'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Buy Rate',
                      unit: '\$/kWh',
                      hint: 'Grid purchase',
                      controller: _buyRateController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Connection Fee',
                      unit: '\$',
                      hint: 'Monthly',
                      controller: _connectionFeeController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_netEnergy != null) ...[
                _buildSectionHeader(colors, 'NET METERING RESULT'),
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
              Icon(LucideIcons.arrowLeftRight, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Net Metering',
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
            'Calculate bill credits for excess solar production',
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
    final types = ['Full Retail', 'Avoided Cost', 'NEM 3.0 (CA)'];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: types.map((type) {
          final isSelected = _netMeteringType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _netMeteringType = type);
                _calculate();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
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
    final isNetPositive = _netEnergy! >= 0;
    final statusColor = isNetPositive ? colors.accentSuccess : colors.accentInfo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Net Energy', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${_netEnergy! >= 0 ? '+' : ''}${_netEnergy!.toStringAsFixed(0)} kWh',
            style: TextStyle(color: statusColor, fontSize: 40, fontWeight: FontWeight.w700),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isNetPositive ? 'Net Exporter' : 'Net Importer',
              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Bill Credit', '\$${_billCredit!.toStringAsFixed(2)}', colors.accentSuccess),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Final Bill', '\$${_finalBill!.toStringAsFixed(2)}', colors.accentPrimary),
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
                    _explanation!,
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
}
