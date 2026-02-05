import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Backup Duration Calculator - Hours of backup power
class BackupDurationScreen extends ConsumerStatefulWidget {
  const BackupDurationScreen({super.key});
  @override
  ConsumerState<BackupDurationScreen> createState() => _BackupDurationScreenState();
}

class _BackupDurationScreenState extends ConsumerState<BackupDurationScreen> {
  final _batteryKwhController = TextEditingController(text: '13.5');
  final _loadKwController = TextEditingController(text: '2');
  final _dodController = TextEditingController(text: '90');
  final _efficiencyController = TextEditingController(text: '90');

  double? _usableCapacity;
  double? _backupHours;
  String? _scenario;

  @override
  void dispose() {
    _batteryKwhController.dispose();
    _loadKwController.dispose();
    _dodController.dispose();
    _efficiencyController.dispose();
    super.dispose();
  }

  void _calculate() {
    final batteryKwh = double.tryParse(_batteryKwhController.text);
    final loadKw = double.tryParse(_loadKwController.text);
    final dod = double.tryParse(_dodController.text);
    final efficiency = double.tryParse(_efficiencyController.text);

    if (batteryKwh == null || loadKw == null || dod == null || efficiency == null || loadKw == 0) {
      setState(() {
        _usableCapacity = null;
        _backupHours = null;
        _scenario = null;
      });
      return;
    }

    // Usable capacity = Total × DoD × Round-trip efficiency
    final usableCapacity = batteryKwh * (dod / 100) * (efficiency / 100);

    // Backup hours = Usable capacity / Load
    final backupHours = usableCapacity / loadKw;

    String scenario;
    if (backupHours < 4) {
      scenario = 'Short-term outage coverage';
    } else if (backupHours < 8) {
      scenario = 'Overnight backup capability';
    } else if (backupHours < 24) {
      scenario = 'Extended outage protection';
    } else {
      scenario = 'Multi-day resilience';
    }

    setState(() {
      _usableCapacity = usableCapacity;
      _backupHours = backupHours;
      _scenario = scenario;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _batteryKwhController.text = '13.5';
    _loadKwController.text = '2';
    _dodController.text = '90';
    _efficiencyController.text = '90';
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
        title: Text('Backup Duration', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'BATTERY SYSTEM'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Battery Capacity',
                      unit: 'kWh',
                      hint: 'Total nameplate',
                      controller: _batteryKwhController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Backup Load',
                      unit: 'kW',
                      hint: 'Average draw',
                      controller: _loadKwController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'EFFICIENCY FACTORS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Depth of Discharge',
                      unit: '%',
                      hint: '80-100%',
                      controller: _dodController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Round-Trip Eff.',
                      unit: '%',
                      hint: '85-95%',
                      controller: _efficiencyController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_backupHours != null) ...[
                _buildSectionHeader(colors, 'BACKUP DURATION'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildLoadExamples(colors),
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
          Text(
            'Hours = (kWh × DoD × Eff) ÷ kW',
            style: TextStyle(
              color: colors.accentPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Calculate how long battery will power essential loads',
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
    final hours = _backupHours!;
    final isGood = hours >= 8;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isGood ? colors.accentSuccess : colors.accentWarning).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Estimated Backup Time', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hours.toStringAsFixed(1),
                style: TextStyle(color: isGood ? colors.accentSuccess : colors.accentWarning, fontSize: 48, fontWeight: FontWeight.w700),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  ' hours',
                  style: TextStyle(color: colors.textSecondary, fontSize: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: (isGood ? colors.accentSuccess : colors.accentWarning).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _scenario!,
              style: TextStyle(color: isGood ? colors.accentSuccess : colors.accentWarning, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(colors, 'Usable Capacity', '${_usableCapacity!.toStringAsFixed(2)} kWh'),
          _buildStatRow(colors, 'Average Load', '${_loadKwController.text} kW'),
        ],
      ),
    );
  }

  Widget _buildStatRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 13)),
          Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLoadExamples(ZaftoColors colors) {
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
          Text('TYPICAL BACKUP LOADS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildLoadRow(colors, 'Refrigerator', '0.1-0.2 kW'),
          _buildLoadRow(colors, 'Lights (LED)', '0.05-0.1 kW'),
          _buildLoadRow(colors, 'Router/Modem', '0.02 kW'),
          _buildLoadRow(colors, 'Phone chargers', '0.02 kW'),
          _buildLoadRow(colors, 'Sump pump', '0.5-1 kW'),
          _buildLoadRow(colors, 'AC unit (small)', '1-2 kW'),
        ],
      ),
    );
  }

  Widget _buildLoadRow(ZaftoColors colors, String appliance, String load) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(appliance, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          Text(load, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
