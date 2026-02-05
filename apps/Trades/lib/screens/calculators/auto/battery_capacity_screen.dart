import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Battery Capacity Calculator - EV battery capacity and range
class BatteryCapacityScreen extends ConsumerStatefulWidget {
  const BatteryCapacityScreen({super.key});
  @override
  ConsumerState<BatteryCapacityScreen> createState() => _BatteryCapacityScreenState();
}

class _BatteryCapacityScreenState extends ConsumerState<BatteryCapacityScreen> {
  final _capacityController = TextEditingController();
  final _efficiencyController = TextEditingController();
  final _usableController = TextEditingController();

  double? _estimatedRange;
  double? _usableCapacity;

  void _calculate() {
    final capacity = double.tryParse(_capacityController.text);
    final efficiency = double.tryParse(_efficiencyController.text);
    final usablePercent = double.tryParse(_usableController.text) ?? 90;

    if (capacity == null) {
      setState(() { _estimatedRange = null; });
      return;
    }

    final usableCapacity = capacity * (usablePercent / 100);

    // Efficiency in Wh/mile or mi/kWh
    double? range;
    if (efficiency != null && efficiency > 0) {
      // If efficiency < 10, assume mi/kWh; otherwise Wh/mi
      if (efficiency < 10) {
        range = usableCapacity * efficiency;
      } else {
        range = (usableCapacity * 1000) / efficiency;
      }
    }

    setState(() {
      _usableCapacity = usableCapacity;
      _estimatedRange = range;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _capacityController.clear();
    _efficiencyController.clear();
    _usableController.clear();
    setState(() { _estimatedRange = null; });
  }

  @override
  void dispose() {
    _capacityController.dispose();
    _efficiencyController.dispose();
    _usableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Battery Capacity', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildInfoCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Total Battery Capacity', unit: 'kWh', hint: 'Gross capacity', controller: _capacityController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Usable Percentage', unit: '%', hint: 'Default 90', controller: _usableController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Efficiency', unit: 'mi/kWh', hint: '3-4 typical', controller: _efficiencyController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_usableCapacity != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildEvReference(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Icon(LucideIcons.battery, color: colors.accentPrimary, size: 32),
        const SizedBox(height: 8),
        Text('Range = Usable Capacity × Efficiency', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 12)),
        const SizedBox(height: 8),
        Text('Calculate EV range from battery capacity', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('BATTERY ANALYSIS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Usable Capacity', '${_usableCapacity!.toStringAsFixed(1)} kWh'),
        if (_estimatedRange != null) ...[
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Estimated Range', '${_estimatedRange!.toStringAsFixed(0)} miles'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Text('Highway Range (75% efficiency)', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              Text('~${(_estimatedRange! * 0.75).toStringAsFixed(0)} miles', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
        const SizedBox(height: 12),
        Text('Real range varies with speed, temperature, and driving style', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildEvReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON EV BATTERIES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildEvRow(colors, 'Tesla Model 3 LR', '82 kWh'),
        _buildEvRow(colors, 'Tesla Model Y', '75 kWh'),
        _buildEvRow(colors, 'Ford Mustang Mach-E', '68-91 kWh'),
        _buildEvRow(colors, 'Chevy Bolt', '65 kWh'),
        _buildEvRow(colors, 'Rivian R1T', '135 kWh'),
        _buildEvRow(colors, 'Lucid Air', '112-118 kWh'),
        const SizedBox(height: 8),
        Text('Usable capacity is typically 90-95% of gross', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildEvRow(ZaftoColors colors, String vehicle, String capacity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(vehicle, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(capacity, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }
}
