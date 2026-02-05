import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Sprinkler Zone Calculator - Zone design
class SprinklerZoneScreen extends ConsumerStatefulWidget {
  const SprinklerZoneScreen({super.key});
  @override
  ConsumerState<SprinklerZoneScreen> createState() => _SprinklerZoneScreenState();
}

class _SprinklerZoneScreenState extends ConsumerState<SprinklerZoneScreen> {
  final _areaController = TextEditingController(text: '5000');
  final _gpmController = TextEditingController(text: '10');

  String _headType = 'rotor';

  int? _headsNeeded;
  int? _zonesNeeded;
  double? _gpmPerZone;
  int? _headsPerZone;

  @override
  void dispose() { _areaController.dispose(); _gpmController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 5000;
    final availableGpm = double.tryParse(_gpmController.text) ?? 10;

    // Coverage and GPM per head type
    double coverageSqFt;
    double gpmPerHead;
    switch (_headType) {
      case 'rotor':
        coverageSqFt = 900; // 30' radius, 60% overlap
        gpmPerHead = 3.0;
        break;
      case 'spray':
        coverageSqFt = 144; // 12' radius
        gpmPerHead = 1.5;
        break;
      case 'mp_rotor':
        coverageSqFt = 225; // 15' radius
        gpmPerHead = 0.5;
        break;
      default:
        coverageSqFt = 900;
        gpmPerHead = 3.0;
    }

    final totalHeads = (area / coverageSqFt).ceil();
    final totalGpm = totalHeads * gpmPerHead;

    // Calculate zones based on available GPM
    final zones = (totalGpm / availableGpm).ceil();
    final headsPerZone = (totalHeads / zones).ceil();
    final gpmPerZone = headsPerZone * gpmPerHead;

    setState(() {
      _headsNeeded = totalHeads;
      _zonesNeeded = zones;
      _gpmPerZone = gpmPerZone;
      _headsPerZone = headsPerZone;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '5000'; _gpmController.text = '10'; setState(() { _headType = 'rotor'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Sprinkler Zones', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'HEAD TYPE', ['rotor', 'spray', 'mp_rotor'], _headType, {'rotor': 'Rotor', 'spray': 'Spray', 'mp_rotor': 'MP Rotor'}, (v) { setState(() => _headType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Lawn Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Available Flow', unit: 'GPM', controller: _gpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_zonesNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('ZONES NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_zonesNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total heads', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_headsNeeded', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Heads per zone', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~$_headsPerZone', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('GPM per zone', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gpmPerZone!.toStringAsFixed(1)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildZoneGuide(colors),
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

  Widget _buildZoneGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('HEAD SPECIFICATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Rotor', "25-50' radius, 2-4 GPM"),
        _buildTableRow(colors, 'Spray', "8-15' radius, 1-2 GPM"),
        _buildTableRow(colors, 'MP Rotor', "8-30' radius, 0.4-1 GPM"),
        _buildTableRow(colors, 'Overlap', '50-60% head-to-head'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
