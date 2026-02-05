import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Trench Calculator - Trench excavation and backfill
class TrenchScreen extends ConsumerStatefulWidget {
  const TrenchScreen({super.key});
  @override
  ConsumerState<TrenchScreen> createState() => _TrenchScreenState();
}

class _TrenchScreenState extends ConsumerState<TrenchScreen> {
  final _lengthController = TextEditingController(text: '100');
  final _widthController = TextEditingController(text: '24');
  final _depthController = TextEditingController(text: '48');

  String _trenchType = 'vertical';

  double? _excavationVolume;
  double? _beddingVolume;
  double? _backfillVolume;
  bool? _shoringRequired;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _depthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final widthInches = double.tryParse(_widthController.text);
    final depthInches = double.tryParse(_depthController.text);

    if (length == null || widthInches == null || depthInches == null) {
      setState(() { _excavationVolume = null; _beddingVolume = null; _backfillVolume = null; _shoringRequired = null; });
      return;
    }

    final widthFeet = widthInches / 12;
    final depthFeet = depthInches / 12;

    double excavationVolume;
    switch (_trenchType) {
      case 'vertical':
        excavationVolume = (length * widthFeet * depthFeet) / 27;
        break;
      case 'sloped':
        final topWidth = widthFeet + (depthFeet * 2);
        final avgWidth = (widthFeet + topWidth) / 2;
        excavationVolume = (length * avgWidth * depthFeet) / 27;
        break;
      case 'benched':
        excavationVolume = (length * widthFeet * depthFeet * 1.3) / 27;
        break;
      default:
        excavationVolume = (length * widthFeet * depthFeet) / 27;
    }

    final beddingVolume = (length * widthFeet * 0.5) / 27;
    final backfillVolume = excavationVolume * 0.85;
    final shoringRequired = depthFeet > 5;

    setState(() { _excavationVolume = excavationVolume; _beddingVolume = beddingVolume; _backfillVolume = backfillVolume; _shoringRequired = shoringRequired; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '100'; _widthController.text = '24'; _depthController.text = '48'; setState(() => _trenchType = 'vertical'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Trench', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'TRENCH TYPE', ['vertical', 'sloped', 'benched'], _trenchType, (v) { setState(() => _trenchType = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Trench Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Depth', unit: 'inches', controller: _depthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_excavationVolume != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('EXCAVATION', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_excavationVolume!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Bedding Material', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_beddingVolume!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Backfill Volume', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_backfillVolume!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Shoring Required', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_shoringRequired! ? 'YES' : 'No', style: TextStyle(color: _shoringRequired! ? colors.accentWarning : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _shoringRequired! ? colors.accentWarning.withValues(alpha: 0.1) : colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_shoringRequired! ? 'OSHA: Trenches >5\' deep require protective system (sloping, shoring, or shielding).' : 'Compact backfill in 6-8" lifts. Use select material around utilities.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    final labels = {'vertical': 'Vertical', 'sloped': 'Sloped', 'benched': 'Benched'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o] ?? o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
