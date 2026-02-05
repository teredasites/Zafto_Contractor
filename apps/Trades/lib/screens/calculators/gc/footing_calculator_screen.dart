import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Footing Calculator - Size from load
class FootingCalculatorScreen extends ConsumerStatefulWidget {
  const FootingCalculatorScreen({super.key});
  @override
  ConsumerState<FootingCalculatorScreen> createState() => _FootingCalculatorScreenState();
}

class _FootingCalculatorScreenState extends ConsumerState<FootingCalculatorScreen> {
  final _loadController = TextEditingController(text: '10000');

  String _soilType = 'Medium';

  String? _footingSize;
  double? _footingArea;
  double? _concreteYards;

  @override
  void dispose() { _loadController.dispose(); super.dispose(); }

  void _calculate() {
    final load = double.tryParse(_loadController.text);

    if (load == null) {
      setState(() { _footingSize = null; _footingArea = null; _concreteYards = null; });
      return;
    }

    // Soil bearing capacity (PSF)
    double soilCapacity;
    switch (_soilType) {
      case 'Soft': soilCapacity = 1000; break;
      case 'Medium': soilCapacity = 2000; break;
      case 'Firm': soilCapacity = 3000; break;
      default: soilCapacity = 2000;
    }

    // Required footing area (sq ft)
    final requiredArea = load / soilCapacity;

    // Square footing size
    final footingSide = (requiredArea * 144).clamp(144, 10000); // in sq inches, min 12"x12"
    final sideInches = (footingSide > 0) ? (footingSide).clamp(12, 100).toDouble() : 12.0;
    final actualSide = (requiredArea > 0) ? (requiredArea.clamp(1, 100) * 12).round() : 12;

    // Standard sizes: 16x16, 20x20, 24x24, 30x30, 36x36
    int standardSize;
    if (requiredArea <= 1.78) standardSize = 16;
    else if (requiredArea <= 2.78) standardSize = 20;
    else if (requiredArea <= 4) standardSize = 24;
    else if (requiredArea <= 6.25) standardSize = 30;
    else if (requiredArea <= 9) standardSize = 36;
    else standardSize = 48;

    final footingSize = '$standardSize" x $standardSize"';
    final footingArea = (standardSize * standardSize) / 144;

    // Concrete (8" thick footing)
    final concreteYards = (footingArea * (8/12)) / 27;

    setState(() { _footingSize = footingSize; _footingArea = footingArea; _concreteYards = concreteYards; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _loadController.text = '10000'; setState(() => _soilType = 'Medium'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Footing Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSoilSelector(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Point Load', unit: 'lbs', hint: 'Load on footing', controller: _loadController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_footingSize != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Text('FOOTING SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text(_footingSize!, style: TextStyle(color: colors.accentPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Footing Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_footingArea!.toStringAsFixed(2)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Concrete (8" thick)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_concreteYards!.toStringAsFixed(3)} yd³', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSoilSelector(ZaftoColors colors) {
    final types = ['Soft', 'Medium', 'Firm'];
    final psf = ['1000 PSF', '2000 PSF', '3000 PSF'];
    return Row(children: List.generate(types.length, (i) {
      final isSelected = _soilType == types[i];
      return Expanded(child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _soilType = types[i]); _calculate(); },
        child: Container(margin: EdgeInsets.only(right: i < 2 ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
          child: Column(children: [
            Text(types[i], style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(psf[i], style: TextStyle(color: isSelected ? Colors.white70 : colors.textTertiary, fontSize: 10)),
          ]),
        ),
      ));
    }));
  }
}
