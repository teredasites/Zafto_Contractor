import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fountain Pump Calculator - GPH for water features
class FountainPumpScreen extends ConsumerStatefulWidget {
  const FountainPumpScreen({super.key});
  @override
  ConsumerState<FountainPumpScreen> createState() => _FountainPumpScreenState();
}

class _FountainPumpScreenState extends ConsumerState<FountainPumpScreen> {
  final _heightController = TextEditingController(text: '3');
  final _widthController = TextEditingController(text: '12');

  String _fountainType = 'spout';

  double? _gphNeeded;
  int? _tubingSize;

  @override
  void dispose() { _heightController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final heightFt = double.tryParse(_heightController.text) ?? 3;
    final widthIn = double.tryParse(_widthController.text) ?? 12;

    double baseGph;
    switch (_fountainType) {
      case 'spout': // Simple spout/bubbler
        baseGph = 100;
        break;
      case 'tier': // Multi-tier
        baseGph = 200;
        break;
      case 'spill': // Spillway/weir
        // 150 GPH per inch of spillway width
        baseGph = widthIn * 150;
        break;
      case 'waterfall': // Waterfall
        // 150 GPH per inch width, plus head
        baseGph = widthIn * 150;
        break;
      default:
        baseGph = 100;
    }

    // Add head height (lose ~10% per foot of lift)
    final headFactor = 1 + (heightFt * 0.15);
    final gphNeeded = baseGph * headFactor;

    // Tubing size based on GPH
    int tubingSize;
    if (gphNeeded < 120) {
      tubingSize = 3; // 3/8"
    } else if (gphNeeded < 350) {
      tubingSize = 5; // 1/2"
    } else if (gphNeeded < 700) {
      tubingSize = 6; // 5/8"
    } else if (gphNeeded < 1000) {
      tubingSize = 7; // 3/4"
    } else {
      tubingSize = 10; // 1"
    }

    setState(() {
      _gphNeeded = gphNeeded;
      _tubingSize = tubingSize;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _heightController.text = '3'; _widthController.text = '12'; setState(() { _fountainType = 'spout'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Fountain Pump', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'FOUNTAIN TYPE', ['spout', 'tier', 'spill', 'waterfall'], _fountainType, {'spout': 'Spout', 'tier': 'Tier', 'spill': 'Spillway', 'waterfall': 'Waterfall'}, (v) { setState(() => _fountainType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Head Height', unit: 'ft', controller: _heightController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Spill Width', unit: 'in', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Spillways/waterfalls: 150 GPH per inch of width for sheet flow.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 32),
            if (_gphNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PUMP SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gphNeeded!.toStringAsFixed(0)} GPH', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tubing size', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_tubingSize! / 8}"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPumpGuide(colors),
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

  Widget _buildPumpGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PUMP SIZING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Small bubbler', '50-150 GPH'),
        _buildTableRow(colors, 'Tier fountain', '200-500 GPH'),
        _buildTableRow(colors, 'Small waterfall', '500-1500 GPH'),
        _buildTableRow(colors, 'Large waterfall', '2000+ GPH'),
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
