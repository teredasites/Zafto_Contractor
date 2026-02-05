import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pond Pump Calculator - GPH sizing for circulation
class PondPumpScreen extends ConsumerStatefulWidget {
  const PondPumpScreen({super.key});
  @override
  ConsumerState<PondPumpScreen> createState() => _PondPumpScreenState();
}

class _PondPumpScreenState extends ConsumerState<PondPumpScreen> {
  final _gallonsController = TextEditingController(text: '1000');
  final _headController = TextEditingController(text: '3');

  String _pondType = 'fish';

  double? _minGph;
  double? _recommendedGph;
  double? _turnovers;

  @override
  void dispose() { _gallonsController.dispose(); _headController.dispose(); super.dispose(); }

  void _calculate() {
    final gallons = double.tryParse(_gallonsController.text) ?? 1000;
    final headFeet = double.tryParse(_headController.text) ?? 3;

    // Turnover rate depends on pond type
    double turnoversPerHour;
    switch (_pondType) {
      case 'water': turnoversPerHour = 0.5; break; // Water garden
      case 'fish': turnoversPerHour = 1.0; break; // Fish pond
      case 'koi': turnoversPerHour = 2.0; break; // Koi pond
      default: turnoversPerHour = 1.0;
    }

    final minGph = gallons * turnoversPerHour;

    // Add 10% per foot of head
    final headFactor = 1 + (headFeet * 0.1);
    final recommendedGph = minGph * headFactor;

    setState(() {
      _minGph = minGph;
      _recommendedGph = recommendedGph;
      _turnovers = turnoversPerHour;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _gallonsController.text = '1000'; _headController.text = '3'; setState(() { _pondType = 'fish'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Pond Pump', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'POND TYPE', ['water', 'fish', 'koi'], _pondType, {'water': 'Water Garden', 'fish': 'Fish Pond', 'koi': 'Koi Pond'}, (v) { setState(() => _pondType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Pond Volume', unit: 'gallons', controller: _gallonsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Head Height', unit: 'ft', controller: _headController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Head = vertical lift from pump to highest point (waterfall, filter, etc.)', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 32),
            if (_minGph != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RECOMMENDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_recommendedGph!.toStringAsFixed(0)} GPH', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Minimum GPH', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_minGph!.toStringAsFixed(0)} GPH', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Turnovers/hour', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_turnovers!.toStringAsFixed(1)}x', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
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
        Text('TURNOVER RATES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Water garden', '0.5x/hour (plants only)'),
        _buildTableRow(colors, 'Fish pond', '1x/hour'),
        _buildTableRow(colors, 'Koi pond', '2x/hour'),
        _buildTableRow(colors, 'With waterfall', 'Add 100 GPH/inch width'),
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
