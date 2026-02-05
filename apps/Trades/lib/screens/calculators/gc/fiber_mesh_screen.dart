import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fiber Mesh Calculator - Concrete fiber reinforcement
class FiberMeshScreen extends ConsumerStatefulWidget {
  const FiberMeshScreen({super.key});
  @override
  ConsumerState<FiberMeshScreen> createState() => _FiberMeshScreenState();
}

class _FiberMeshScreenState extends ConsumerState<FiberMeshScreen> {
  final _volumeController = TextEditingController(text: '5');

  String _fiberType = 'synthetic';
  String _dosageRate = 'standard';

  double? _fiberWeight;
  int? _bags1lb;
  int? _bags2lb;
  double? _costEstimate;

  @override
  void dispose() { _volumeController.dispose(); super.dispose(); }

  void _calculate() {
    final cubicYards = double.tryParse(_volumeController.text);

    if (cubicYards == null) {
      setState(() { _fiberWeight = null; _bags1lb = null; _bags2lb = null; _costEstimate = null; });
      return;
    }

    // Dosage rates in lbs per cubic yard
    double dosagePerYard;
    switch (_fiberType) {
      case 'synthetic':
        switch (_dosageRate) {
          case 'light': dosagePerYard = 1.0; break;
          case 'standard': dosagePerYard = 1.5; break;
          case 'heavy': dosagePerYard = 3.0; break;
          default: dosagePerYard = 1.5;
        }
        break;
      case 'steel':
        switch (_dosageRate) {
          case 'light': dosagePerYard = 25; break;
          case 'standard': dosagePerYard = 40; break;
          case 'heavy': dosagePerYard = 60; break;
          default: dosagePerYard = 40;
        }
        break;
      case 'glass':
        switch (_dosageRate) {
          case 'light': dosagePerYard = 0.5; break;
          case 'standard': dosagePerYard = 1.0; break;
          case 'heavy': dosagePerYard = 1.5; break;
          default: dosagePerYard = 1.0;
        }
        break;
      default:
        dosagePerYard = 1.5;
    }

    final fiberWeight = cubicYards * dosagePerYard;
    final bags1lb = fiberWeight.ceil();
    final bags2lb = (fiberWeight / 2).ceil();

    // Cost estimate (synthetic ~$8/lb, steel ~$1/lb, glass ~$15/lb)
    double costPerLb;
    switch (_fiberType) {
      case 'synthetic': costPerLb = 8.0; break;
      case 'steel': costPerLb = 1.0; break;
      case 'glass': costPerLb = 15.0; break;
      default: costPerLb = 8.0;
    }
    final costEstimate = fiberWeight * costPerLb;

    setState(() { _fiberWeight = fiberWeight; _bags1lb = bags1lb; _bags2lb = bags2lb; _costEstimate = costEstimate; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _volumeController.text = '5'; setState(() { _fiberType = 'synthetic'; _dosageRate = 'standard'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Fiber Mesh', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'FIBER TYPE', ['synthetic', 'steel', 'glass'], _fiberType, (v) { setState(() => _fiberType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'DOSAGE RATE', ['light', 'standard', 'heavy'], _dosageRate, (v) { setState(() => _dosageRate = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Concrete Volume', unit: 'yd³', controller: _volumeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_fiberWeight != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('FIBER REQUIRED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_fiberWeight!.toStringAsFixed(1)} lbs', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('1-lb Bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_bags1lb', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('2-lb Bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_bags2lb', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Est. Material Cost', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_costEstimate!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getFiberNote(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _getFiberNote() {
    switch (_fiberType) {
      case 'synthetic':
        return 'Synthetic fibers reduce plastic shrinkage cracking. Add to mix truck, mix 5+ minutes.';
      case 'steel':
        return 'Steel fibers increase impact resistance and load capacity. Not for exposed surfaces.';
      case 'glass':
        return 'AR glass fibers for GFRC and precast. Alkali-resistant coating required.';
      default:
        return '';
    }
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        final label = o[0].toUpperCase() + o.substring(1);
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
