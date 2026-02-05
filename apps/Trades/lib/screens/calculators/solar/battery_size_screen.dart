import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Battery Size Calculator - kWh storage sizing
class BatterySizeScreen extends ConsumerStatefulWidget {
  const BatterySizeScreen({super.key});
  @override
  ConsumerState<BatterySizeScreen> createState() => _BatterySizeScreenState();
}

class _BatterySizeScreenState extends ConsumerState<BatterySizeScreen> {
  final _dailyUsageController = TextEditingController(text: '30');
  final _backupHoursController = TextEditingController(text: '8');
  final _dodController = TextEditingController(text: '80');

  String _useCase = 'Backup';

  double? _essentialLoad;
  double? _usableCapacity;
  double? _totalCapacity;
  String? _recommendation;

  @override
  void dispose() {
    _dailyUsageController.dispose();
    _backupHoursController.dispose();
    _dodController.dispose();
    super.dispose();
  }

  void _calculate() {
    final dailyUsage = double.tryParse(_dailyUsageController.text);
    final backupHours = double.tryParse(_backupHoursController.text);
    final dod = double.tryParse(_dodController.text);

    if (dailyUsage == null || backupHours == null || dod == null || dod == 0) {
      setState(() {
        _essentialLoad = null;
        _usableCapacity = null;
        _totalCapacity = null;
        _recommendation = null;
      });
      return;
    }

    // Essential load during backup (assume 50% for backup, 100% for self-consumption)
    final loadFactor = _useCase == 'Backup' ? 0.5 : 1.0;
    final essentialLoad = dailyUsage * loadFactor;

    // Usable capacity needed = (daily usage × load factor × backup hours) / 24
    final usableCapacity = (essentialLoad * backupHours) / 24;

    // Total capacity = usable / DoD
    final totalCapacity = usableCapacity / (dod / 100);

    String recommendation;
    if (totalCapacity <= 5) {
      recommendation = 'Small battery (Enphase 5P, Powerwall 3)';
    } else if (totalCapacity <= 10) {
      recommendation = 'Medium battery (1x Powerwall, 2x Enphase)';
    } else if (totalCapacity <= 15) {
      recommendation = 'Large system (2x Powerwall or equivalent)';
    } else if (totalCapacity <= 30) {
      recommendation = 'Very large (3+ batteries, whole-home backup)';
    } else {
      recommendation = 'Commercial-scale storage required';
    }

    setState(() {
      _essentialLoad = essentialLoad;
      _usableCapacity = usableCapacity;
      _totalCapacity = totalCapacity;
      _recommendation = recommendation;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _dailyUsageController.text = '30';
    _backupHoursController.text = '8';
    _dodController.text = '80';
    setState(() => _useCase = 'Backup');
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
        title: Text('Battery Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'USE CASE'),
              const SizedBox(height: 12),
              _buildUseCaseSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LOAD & DURATION'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Daily Usage',
                      unit: 'kWh',
                      hint: 'Avg daily',
                      controller: _dailyUsageController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Backup Hours',
                      unit: 'hrs',
                      hint: 'Target duration',
                      controller: _backupHoursController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Depth of Discharge',
                unit: '%',
                hint: '80% typical',
                controller: _dodController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_totalCapacity != null) ...[
                _buildSectionHeader(colors, 'BATTERY SIZING'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildBatteryOptions(colors),
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
                'Energy Storage Sizing',
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
            'Calculate battery capacity for backup or self-consumption',
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

  Widget _buildUseCaseSelector(ZaftoColors colors) {
    final useCases = ['Backup', 'Self-Consumption'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: useCases.map((uc) {
          final isSelected = _useCase == uc;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: uc == useCases.first ? 8 : 0),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _useCase = uc);
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
                      Icon(
                        uc == 'Backup' ? LucideIcons.shieldCheck : LucideIcons.sun,
                        size: 18,
                        color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        uc,
                        style: TextStyle(
                          color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Recommended Battery Capacity', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${_totalCapacity!.toStringAsFixed(1)} kWh',
            style: TextStyle(color: colors.accentPrimary, fontSize: 40, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Usable', '${_usableCapacity!.toStringAsFixed(1)} kWh', colors.accentSuccess),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Essential Load', '${_essentialLoad!.toStringAsFixed(1)} kWh/day', colors.accentInfo),
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
                Icon(LucideIcons.lightbulb, size: 16, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _recommendation!,
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
          Text(value, style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildBatteryOptions(ZaftoColors colors) {
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
          Text('COMMON BATTERY OPTIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildBatteryRow(colors, 'Tesla Powerwall 3', '13.5 kWh'),
          _buildBatteryRow(colors, 'Enphase IQ 5P', '5 kWh'),
          _buildBatteryRow(colors, 'LG RESU Prime', '16 kWh'),
          _buildBatteryRow(colors, 'SolarEdge Home', '9.7 kWh'),
          _buildBatteryRow(colors, 'Generac PWRcell', '9-18 kWh'),
        ],
      ),
    );
  }

  Widget _buildBatteryRow(ZaftoColors colors, String name, String capacity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          Text(capacity, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
