import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wheelbarrow Trips Calculator - Estimate haul trips
class WheelbarrowTripsScreen extends ConsumerStatefulWidget {
  const WheelbarrowTripsScreen({super.key});
  @override
  ConsumerState<WheelbarrowTripsScreen> createState() => _WheelbarrowTripsScreenState();
}

class _WheelbarrowTripsScreenState extends ConsumerState<WheelbarrowTripsScreen> {
  final _cuYdController = TextEditingController(text: '3');
  final _distanceController = TextEditingController(text: '100');

  String _wheelbarrowSize = '6';
  String _loadLevel = 'full';

  int? _trips;
  double? _totalMinutes;
  double? _totalWeight;

  @override
  void dispose() { _cuYdController.dispose(); _distanceController.dispose(); super.dispose(); }

  void _calculate() {
    final cuYd = double.tryParse(_cuYdController.text) ?? 3;
    final distance = double.tryParse(_distanceController.text) ?? 100;

    // Wheelbarrow capacity (cu ft)
    double capacityCuFt;
    switch (_wheelbarrowSize) {
      case '4': capacityCuFt = 4; break;
      case '6': capacityCuFt = 6; break;
      case '8': capacityCuFt = 8; break;
      default: capacityCuFt = 6;
    }

    // Load level adjustment
    double loadFactor;
    switch (_loadLevel) {
      case 'half': loadFactor = 0.5; break;
      case 'full': loadFactor = 0.75; break; // Practical full, not heaping
      case 'heaped': loadFactor = 1.0; break;
      default: loadFactor = 0.75;
    }

    final effectiveCapacity = capacityCuFt * loadFactor;
    final cuFt = cuYd * 27;
    final trips = (cuFt / effectiveCapacity).ceil();

    // Time: ~2-3 min per 100 ft round trip with loading
    final roundTrip = distance * 2;
    final minutesPerTrip = 2 + (roundTrip / 100); // Base 2 min + travel
    final totalMinutes = trips * minutesPerTrip;

    // Weight estimate (assuming mulch ~400 lbs/cu yd)
    final totalWeight = cuYd * 400;

    setState(() {
      _trips = trips;
      _totalMinutes = totalMinutes;
      _totalWeight = totalWeight;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _cuYdController.text = '3'; _distanceController.text = '100'; setState(() { _wheelbarrowSize = '6'; _loadLevel = 'full'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Wheelbarrow Trips', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'WHEELBARROW SIZE', ['4', '6', '8'], _wheelbarrowSize, {'4': '4 cu ft', '6': '6 cu ft', '8': '8 cu ft'}, (v) { setState(() => _wheelbarrowSize = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'LOAD LEVEL', ['half', 'full', 'heaped'], _loadLevel, {'half': 'Half', 'full': 'Full', 'heaped': 'Heaped'}, (v) { setState(() => _loadLevel = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Material', unit: 'cu yd', controller: _cuYdController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Distance', unit: 'ft', controller: _distanceController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_trips != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TRIPS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_trips', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Est. time', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalMinutes!.toStringAsFixed(0)} min', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total weight (mulch)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalWeight!.toStringAsFixed(0)} lbs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTips(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildTips(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MATERIAL WEIGHTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Mulch', '~400 lbs/cu yd'),
        _buildTableRow(colors, 'Compost', '~600 lbs/cu yd'),
        _buildTableRow(colors, 'Topsoil', '~1,000 lbs/cu yd'),
        _buildTableRow(colors, 'Gravel', '~2,700 lbs/cu yd'),
        _buildTableRow(colors, 'Sand', '~2,500 lbs/cu yd'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
