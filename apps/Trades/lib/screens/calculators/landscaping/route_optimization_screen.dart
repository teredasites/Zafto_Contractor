import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Route Optimization Calculator - Daily route efficiency
class RouteOptimizationScreen extends ConsumerStatefulWidget {
  const RouteOptimizationScreen({super.key});
  @override
  ConsumerState<RouteOptimizationScreen> createState() => _RouteOptimizationScreenState();
}

class _RouteOptimizationScreenState extends ConsumerState<RouteOptimizationScreen> {
  final _stopsController = TextEditingController(text: '12');
  final _avgTimeController = TextEditingController(text: '35');
  final _driveTimeController = TextEditingController(text: '10');
  final _dayHoursController = TextEditingController(text: '8');

  double? _productiveHours;
  double? _driveHours;
  double? _efficiency;
  int? _maxStops;
  double? _utilizationPct;

  @override
  void dispose() { _stopsController.dispose(); _avgTimeController.dispose(); _driveTimeController.dispose(); _dayHoursController.dispose(); super.dispose(); }

  void _calculate() {
    final stops = double.tryParse(_stopsController.text) ?? 12;
    final avgTimeMin = double.tryParse(_avgTimeController.text) ?? 35;
    final driveTimeMin = double.tryParse(_driveTimeController.text) ?? 10;
    final dayHours = double.tryParse(_dayHoursController.text) ?? 8;

    final productiveMin = stops * avgTimeMin;
    final driveMin = stops * driveTimeMin;
    final totalMin = productiveMin + driveMin;

    final productiveHrs = productiveMin / 60;
    final driveHrs = driveMin / 60;
    final efficiency = (productiveMin / totalMin) * 100;

    final dayMinutes = dayHours * 60;
    final maxStops = (dayMinutes / (avgTimeMin + driveTimeMin)).floor();
    final utilization = (totalMin / dayMinutes) * 100;

    setState(() {
      _productiveHours = productiveHrs;
      _driveHours = driveHrs;
      _efficiency = efficiency;
      _maxStops = maxStops;
      _utilizationPct = utilization > 100 ? 100 : utilization;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _stopsController.text = '12'; _avgTimeController.text = '35'; _driveTimeController.text = '10'; _dayHoursController.text = '8'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final isEfficient = (_efficiency ?? 0) >= 75;
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Route Optimization', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Daily Stops', unit: 'stops', controller: _stopsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Avg Job Time', unit: 'min', controller: _avgTimeController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Drive Between', unit: 'min', controller: _driveTimeController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Work Day', unit: 'hrs', controller: _dayHoursController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_efficiency != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('ROUTE EFFICIENCY', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_efficiency!.toStringAsFixed(0)}%', style: TextStyle(color: isEfficient ? colors.accentSuccess : colors.accentWarning, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Productive time', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_productiveHours!.toStringAsFixed(1)} hrs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Drive time', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_driveHours!.toStringAsFixed(1)} hrs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Max stops/day', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_maxStops', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Day utilization', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_utilizationPct!.toStringAsFixed(0)}%', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildRouteGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildRouteGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('OPTIMIZATION TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Target efficiency', '75-80%'),
        _buildTableRow(colors, 'Cluster routes', 'Same neighborhood'),
        _buildTableRow(colors, 'Schedule tight', 'Same day each week'),
        _buildTableRow(colors, 'Reduce drive', '<10 min between'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
