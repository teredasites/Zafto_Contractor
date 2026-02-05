import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Generator + Battery Calculator - Hybrid system sizing
class GeneratorBatteryScreen extends ConsumerStatefulWidget {
  const GeneratorBatteryScreen({super.key});
  @override
  ConsumerState<GeneratorBatteryScreen> createState() => _GeneratorBatteryScreenState();
}

class _GeneratorBatteryScreenState extends ConsumerState<GeneratorBatteryScreen> {
  final _dailyKwhController = TextEditingController(text: '30');
  final _solarKwhController = TextEditingController(text: '20');
  final _batteryKwhController = TextEditingController(text: '13.5');
  final _genKwController = TextEditingController(text: '7');

  double? _shortfall;
  double? _genRuntime;
  double? _fuelGallons;
  String? _recommendation;

  @override
  void dispose() {
    _dailyKwhController.dispose();
    _solarKwhController.dispose();
    _batteryKwhController.dispose();
    _genKwController.dispose();
    super.dispose();
  }

  void _calculate() {
    final dailyKwh = double.tryParse(_dailyKwhController.text);
    final solarKwh = double.tryParse(_solarKwhController.text);
    final batteryKwh = double.tryParse(_batteryKwhController.text);
    final genKw = double.tryParse(_genKwController.text);

    if (dailyKwh == null || solarKwh == null || batteryKwh == null || genKw == null || genKw == 0) {
      setState(() {
        _shortfall = null;
        _genRuntime = null;
        _fuelGallons = null;
        _recommendation = null;
      });
      return;
    }

    // Calculate daily shortfall
    final shortfall = (dailyKwh - solarKwh).clamp(0, double.infinity);

    // Generator runtime to cover shortfall (at ~80% efficiency)
    final genRuntime = shortfall > 0 ? shortfall / (genKw * 0.8) : 0;

    // Fuel consumption (~0.5 gal/hr per 3.5kW - simplified)
    final fuelGallons = genRuntime * (genKw / 7);

    String recommendation;
    if (shortfall == 0) {
      recommendation = 'Solar covers daily needs. Generator for backup only.';
    } else if (genRuntime < 2) {
      recommendation = 'Minimal generator use. Battery helps smooth demand.';
    } else if (genRuntime < 4) {
      recommendation = 'Moderate gen runtime. Consider more solar or battery.';
    } else if (genRuntime < 8) {
      recommendation = 'Significant gen use. Review system sizing.';
    } else {
      recommendation = 'Heavy gen dependency. Increase solar/battery capacity.';
    }

    setState(() {
      _shortfall = shortfall.toDouble();
      _genRuntime = genRuntime.toDouble();
      _fuelGallons = fuelGallons;
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
    _dailyKwhController.text = '30';
    _solarKwhController.text = '20';
    _batteryKwhController.text = '13.5';
    _genKwController.text = '7';
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
        title: Text('Gen + Battery', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ENERGY BALANCE'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Daily Usage',
                      unit: 'kWh',
                      hint: 'Total demand',
                      controller: _dailyKwhController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Solar Production',
                      unit: 'kWh',
                      hint: 'Daily avg',
                      controller: _solarKwhController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'EQUIPMENT'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Battery Capacity',
                      unit: 'kWh',
                      hint: 'Usable',
                      controller: _batteryKwhController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Generator',
                      unit: 'kW',
                      hint: 'Output',
                      controller: _genKwController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_shortfall != null) ...[
                _buildSectionHeader(colors, 'HYBRID ANALYSIS'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildOptimizationTips(colors),
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
              Icon(LucideIcons.plug, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Hybrid System Sizing',
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
            'Balance solar, battery, and generator for off-grid',
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
    final hasShortfall = _shortfall! > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (hasShortfall ? colors.accentWarning : colors.accentSuccess).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Daily Energy Shortfall', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${_shortfall!.toStringAsFixed(1)} kWh',
            style: TextStyle(color: hasShortfall ? colors.accentWarning : colors.accentSuccess, fontSize: 40, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Gen Runtime', '${_genRuntime!.toStringAsFixed(1)} hrs', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Est. Fuel', '${_fuelGallons!.toStringAsFixed(1)} gal', colors.accentInfo),
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

  Widget _buildOptimizationTips(ZaftoColors colors) {
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
          Text('OPTIMIZATION TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildTip(colors, 'Run generator during peak demand (morning/evening)'),
          _buildTip(colors, 'Charge battery to 100% before nightfall'),
          _buildTip(colors, 'Avoid running gen at low load (inefficient)'),
          _buildTip(colors, 'Auto-start gen when battery hits ~20% SOC'),
        ],
      ),
    );
  }

  Widget _buildTip(ZaftoColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, size: 14, color: colors.accentSuccess),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
