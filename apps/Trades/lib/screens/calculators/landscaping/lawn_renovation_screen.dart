import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Lawn Renovation Calculator - Complete renovation materials
class LawnRenovationScreen extends ConsumerStatefulWidget {
  const LawnRenovationScreen({super.key});
  @override
  ConsumerState<LawnRenovationScreen> createState() => _LawnRenovationScreenState();
}

class _LawnRenovationScreenState extends ConsumerState<LawnRenovationScreen> {
  final _areaController = TextEditingController(text: '5000');

  String _method = 'overseed';

  double? _seedLbs;
  double? _starterFertLbs;
  double? _topsoilCuYd;
  double? _pelletizedLimeLbs;
  String? _steps;

  @override
  void dispose() { _areaController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 5000;

    double seedRate;
    double topsoilDepth;
    String steps;

    switch (_method) {
      case 'overseed':
        seedRate = 4; // lbs per 1000
        topsoilDepth = 0; // no topsoil
        steps = 'Aerate, seed, fertilize';
        break;
      case 'slice_seed':
        seedRate = 6;
        topsoilDepth = 0;
        steps = 'Kill weeds, slice, seed, roll';
        break;
      case 'full_reno':
        seedRate = 8;
        topsoilDepth = 0.25; // 3" of topsoil if needed
        steps = 'Kill all, grade, amend, seed';
        break;
      default:
        seedRate = 6;
        topsoilDepth = 0;
        steps = 'Standard renovation';
    }

    final seed = (area / 1000) * seedRate;
    final starterFert = (area / 1000) * 4; // 4 lbs starter per 1000
    final topsoil = topsoilDepth > 0 ? (area * topsoilDepth / 27) : 0.0;
    final lime = (area / 1000) * 40; // 40 lbs lime per 1000 if needed

    setState(() {
      _seedLbs = seed;
      _starterFertLbs = starterFert;
      _topsoilCuYd = topsoil;
      _pelletizedLimeLbs = lime;
      _steps = steps;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '5000'; setState(() { _method = 'overseed'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Lawn Renovation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'METHOD', ['overseed', 'slice_seed', 'full_reno'], _method, {'overseed': 'Overseed', 'slice_seed': 'Slice Seed', 'full_reno': 'Full Reno'}, (v) { setState(() => _method = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Lawn Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_seedLbs != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('MATERIALS NEEDED', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                _buildMaterialRow(colors, 'Grass seed', '${_seedLbs!.toStringAsFixed(1)} lbs'),
                _buildMaterialRow(colors, 'Starter fertilizer', '${_starterFertLbs!.toStringAsFixed(1)} lbs'),
                if (_topsoilCuYd! > 0) _buildMaterialRow(colors, 'Topsoil', '${_topsoilCuYd!.toStringAsFixed(1)} cu yd'),
                _buildMaterialRow(colors, 'Lime (if needed)', '${_pelletizedLimeLbs!.toStringAsFixed(0)} lbs'),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Process', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text('$_steps', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildRenoGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMaterialRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      ]),
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

  Widget _buildRenoGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RENOVATION TIMING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Cool season', 'Late Aug - mid Oct'),
        _buildTableRow(colors, 'Warm season', 'Late spring - early summer'),
        _buildTableRow(colors, 'Soil temp', '50-65°F for cool'),
        _buildTableRow(colors, 'Watering', '2-3× daily until established'),
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
