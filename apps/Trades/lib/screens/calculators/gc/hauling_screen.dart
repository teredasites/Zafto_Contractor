import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Hauling Calculator - Trucking and hauling estimates
class HaulingScreen extends ConsumerStatefulWidget {
  const HaulingScreen({super.key});
  @override
  ConsumerState<HaulingScreen> createState() => _HaulingScreenState();
}

class _HaulingScreenState extends ConsumerState<HaulingScreen> {
  final _volumeController = TextEditingController(text: '100');
  final _distanceController = TextEditingController(text: '10');
  final _pricePerLoadController = TextEditingController(text: '350');

  String _truckType = 'triaxle';
  String _materialType = 'soil';

  int? _truckLoads;
  double? _totalWeight;
  double? _totalCost;
  double? _cycleTime;

  @override
  void dispose() { _volumeController.dispose(); _distanceController.dispose(); _pricePerLoadController.dispose(); super.dispose(); }

  void _calculate() {
    final volume = double.tryParse(_volumeController.text);
    final distance = double.tryParse(_distanceController.text);
    final pricePerLoad = double.tryParse(_pricePerLoadController.text);

    if (volume == null) {
      setState(() { _truckLoads = null; _totalWeight = null; _totalCost = null; _cycleTime = null; });
      return;
    }

    // Truck capacities
    double capacityYards;
    double capacityTons;
    switch (_truckType) {
      case 'single': capacityYards = 8; capacityTons = 10; break;
      case 'tandem': capacityYards = 12; capacityTons = 15; break;
      case 'triaxle': capacityYards = 16; capacityTons = 22; break;
      case 'quad': capacityYards = 18; capacityTons = 26; break;
      default: capacityYards = 16; capacityTons = 22;
    }

    // Material weight per cubic yard
    double lbsPerYard;
    switch (_materialType) {
      case 'soil': lbsPerYard = 2700; break;
      case 'sand': lbsPerYard = 2800; break;
      case 'gravel': lbsPerYard = 2900; break;
      case 'concrete': lbsPerYard = 4000; break;
      case 'asphalt': lbsPerYard = 2400; break;
      default: lbsPerYard = 2700;
    }

    final totalWeight = (volume * lbsPerYard) / 2000; // Convert to tons

    // Determine limiting factor (volume or weight)
    final loadsByVolume = (volume / capacityYards).ceil();
    final loadsByWeight = (totalWeight / capacityTons).ceil();
    final truckLoads = loadsByVolume > loadsByWeight ? loadsByVolume : loadsByWeight;

    // Total cost
    final totalCost = pricePerLoad != null ? truckLoads * pricePerLoad : null;

    // Cycle time estimate (load 15 min + travel + dump 10 min)
    double? cycleTime;
    if (distance != null) {
      final travelTime = (distance / 30) * 60 * 2; // 30 mph avg, round trip, in minutes
      cycleTime = 15 + travelTime + 10; // minutes per cycle
    }

    setState(() { _truckLoads = truckLoads; _totalWeight = totalWeight; _totalCost = totalCost; _cycleTime = cycleTime; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _volumeController.text = '100'; _distanceController.text = '10'; _pricePerLoadController.text = '350'; setState(() { _truckType = 'triaxle'; _materialType = 'soil'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Hauling', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'TRUCK TYPE', ['single', 'tandem', 'triaxle', 'quad'], _truckType, (v) { setState(() => _truckType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'MATERIAL', ['soil', 'sand', 'gravel', 'concrete'], _materialType, (v) { setState(() => _materialType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Volume to Haul', unit: 'yd³', controller: _volumeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Distance', unit: 'miles', controller: _distanceController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Price/Load', unit: '\$', controller: _pricePerLoadController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_truckLoads != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TRUCK LOADS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_truckLoads', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Weight', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalWeight!.toStringAsFixed(1)} tons', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_cycleTime != null) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cycle Time', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_cycleTime!.toStringAsFixed(0)} min', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                if (_totalCost != null) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Hauling Cost', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_totalCost!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getTruckNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getTruckNote() {
    switch (_truckType) {
      case 'single': return 'Single axle: 8-10 yd / 10-12 ton. Good for tight access sites.';
      case 'tandem': return 'Tandem axle: 12-14 yd / 14-18 ton. Standard dump truck.';
      case 'triaxle': return 'Tri-axle: 16-18 yd / 20-24 ton. Most common for bulk hauling.';
      case 'quad': return 'Quad axle: 18-22 yd / 25-30 ton. Maximum legal capacity in most states.';
      default: return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'single': 'Single', 'tandem': 'Tandem', 'triaxle': 'Tri-Axle', 'quad': 'Quad', 'soil': 'Soil', 'sand': 'Sand', 'gravel': 'Gravel', 'concrete': 'Concrete'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
