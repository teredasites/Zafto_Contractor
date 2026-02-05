import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Battery Bank Calculator - Series/parallel configuration
class BatteryBankScreen extends ConsumerStatefulWidget {
  const BatteryBankScreen({super.key});
  @override
  ConsumerState<BatteryBankScreen> createState() => _BatteryBankScreenState();
}

class _BatteryBankScreenState extends ConsumerState<BatteryBankScreen> {
  final _targetVoltageController = TextEditingController(text: '48');
  final _targetAhController = TextEditingController(text: '200');
  final _batteryVoltageController = TextEditingController(text: '12');
  final _batteryAhController = TextEditingController(text: '100');

  int? _seriesCount;
  int? _parallelCount;
  int? _totalBatteries;
  double? _totalKwh;
  String? _configuration;

  @override
  void dispose() {
    _targetVoltageController.dispose();
    _targetAhController.dispose();
    _batteryVoltageController.dispose();
    _batteryAhController.dispose();
    super.dispose();
  }

  void _calculate() {
    final targetVoltage = double.tryParse(_targetVoltageController.text);
    final targetAh = double.tryParse(_targetAhController.text);
    final batteryVoltage = double.tryParse(_batteryVoltageController.text);
    final batteryAh = double.tryParse(_batteryAhController.text);

    if (targetVoltage == null || targetAh == null || batteryVoltage == null ||
        batteryAh == null || batteryVoltage == 0 || batteryAh == 0) {
      setState(() {
        _seriesCount = null;
        _parallelCount = null;
        _totalBatteries = null;
        _totalKwh = null;
        _configuration = null;
      });
      return;
    }

    // Series for voltage: target / battery voltage
    final seriesCount = (targetVoltage / batteryVoltage).ceil();

    // Parallel for capacity: target Ah / battery Ah
    final parallelCount = (targetAh / batteryAh).ceil();

    final totalBatteries = seriesCount * parallelCount;
    final totalKwh = (seriesCount * batteryVoltage * parallelCount * batteryAh) / 1000;

    String configuration;
    if (seriesCount == 1 && parallelCount == 1) {
      configuration = 'Single battery';
    } else if (seriesCount == 1) {
      configuration = '$parallelCount batteries in parallel';
    } else if (parallelCount == 1) {
      configuration = '$seriesCount batteries in series';
    } else {
      configuration = '${seriesCount}S${parallelCount}P ($seriesCount series × $parallelCount parallel)';
    }

    setState(() {
      _seriesCount = seriesCount;
      _parallelCount = parallelCount;
      _totalBatteries = totalBatteries;
      _totalKwh = totalKwh;
      _configuration = configuration;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _targetVoltageController.text = '48';
    _targetAhController.text = '200';
    _batteryVoltageController.text = '12';
    _batteryAhController.text = '100';
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
        title: Text('Battery Bank', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'TARGET BANK'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'System Voltage',
                      unit: 'V',
                      hint: '12/24/48',
                      controller: _targetVoltageController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Total Capacity',
                      unit: 'Ah',
                      hint: 'Target Ah',
                      controller: _targetAhController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'INDIVIDUAL BATTERY'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Battery Voltage',
                      unit: 'V',
                      hint: 'Per battery',
                      controller: _batteryVoltageController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Battery Capacity',
                      unit: 'Ah',
                      hint: 'Per battery',
                      controller: _batteryAhController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_totalBatteries != null) ...[
                _buildSectionHeader(colors, 'BANK CONFIGURATION'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildWiringGuide(colors),
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
              Icon(LucideIcons.battery, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Battery Bank Calculator',
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
            'Configure series/parallel battery banks for off-grid',
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
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Configuration', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            _configuration!,
            style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Total Batteries', '$_totalBatteries', colors.accentSuccess),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Total Capacity', '${_totalKwh!.toStringAsFixed(2)} kWh', colors.accentInfo),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Series', '$_seriesCount (voltage)', colors.accentWarning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Parallel', '$_parallelCount (capacity)', colors.accentWarning),
              ),
            ],
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

  Widget _buildWiringGuide(ZaftoColors colors) {
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
          Text('WIRING PRINCIPLES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildPrinciple(colors, LucideIcons.arrowRight, 'Series', 'Increases voltage, same Ah', colors.accentPrimary),
          _buildPrinciple(colors, LucideIcons.arrowDown, 'Parallel', 'Increases Ah, same voltage', colors.accentInfo),
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
                    'Use identical batteries (same type, age, capacity) for balanced charging.',
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

  Widget _buildPrinciple(ZaftoColors colors, IconData icon, String title, String description, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(description, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
