import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Load Weight Calculator - Trailer/truck load limits
class LoadWeightScreen extends ConsumerStatefulWidget {
  const LoadWeightScreen({super.key});
  @override
  ConsumerState<LoadWeightScreen> createState() => _LoadWeightScreenState();
}

class _LoadWeightScreenState extends ConsumerState<LoadWeightScreen> {
  final _volumeController = TextEditingController(text: '3');

  String _material = 'topsoil';
  String _vehicle = 'trailer';

  double? _loadWeight;
  double? _vehicleCapacity;
  int? _tripsNeeded;
  bool? _overWeight;

  @override
  void dispose() { _volumeController.dispose(); super.dispose(); }

  void _calculate() {
    final volume = double.tryParse(_volumeController.text) ?? 3;

    // Weight per cubic yard
    double lbsPerCuYd;
    switch (_material) {
      case 'topsoil':
        lbsPerCuYd = 2200;
        break;
      case 'gravel':
        lbsPerCuYd = 2800;
        break;
      case 'mulch':
        lbsPerCuYd = 800;
        break;
      case 'sand':
        lbsPerCuYd = 2700;
        break;
      case 'compost':
        lbsPerCuYd = 1000;
        break;
      default:
        lbsPerCuYd = 2200;
    }

    final loadWeight = volume * lbsPerCuYd;

    // Vehicle capacity
    double capacity;
    switch (_vehicle) {
      case 'pickup':
        capacity = 1500;
        break;
      case 'trailer':
        capacity = 5000;
        break;
      case 'dump_truck':
        capacity = 20000;
        break;
      default:
        capacity = 5000;
    }

    final overWeight = loadWeight > capacity;
    final trips = (loadWeight / capacity).ceil();

    setState(() {
      _loadWeight = loadWeight;
      _vehicleCapacity = capacity;
      _tripsNeeded = trips;
      _overWeight = overWeight;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _volumeController.text = '3'; setState(() { _material = 'topsoil'; _vehicle = 'trailer'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Load Weight', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MATERIAL', ['topsoil', 'gravel', 'sand', 'mulch'], _material, {'topsoil': 'Topsoil', 'gravel': 'Gravel', 'sand': 'Sand', 'mulch': 'Mulch'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, 'VEHICLE', ['pickup', 'trailer', 'dump_truck'], _vehicle, {'pickup': 'Pickup', 'trailer': 'Trailer', 'dump_truck': 'Dump Truck'}, (v) { setState(() => _vehicle = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Volume', unit: 'cu yd', controller: _volumeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_loadWeight != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('LOAD WEIGHT', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_loadWeight! / 1000).toStringAsFixed(1)}K lbs', style: TextStyle(color: _overWeight! ? colors.accentError : colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Vehicle capacity', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_vehicleCapacity! / 1000).toStringAsFixed(1)}K lbs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Trips needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_tripsNeeded', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Status', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_overWeight! ? 'OVER CAPACITY' : 'OK', style: TextStyle(color: _overWeight! ? colors.accentError : colors.accentSuccess, fontSize: 14, fontWeight: FontWeight.w600))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildWeightGuide(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildWeightGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MATERIAL WEIGHTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Topsoil', '~2,200 lbs/cu yd'),
        _buildTableRow(colors, 'Gravel', '~2,800 lbs/cu yd'),
        _buildTableRow(colors, 'Sand', '~2,700 lbs/cu yd'),
        _buildTableRow(colors, 'Mulch', '~600-1,000 lbs/cu yd'),
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
