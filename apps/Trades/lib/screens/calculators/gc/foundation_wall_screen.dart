import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Foundation Wall - Lineal feet and height
class FoundationWallScreen extends ConsumerStatefulWidget {
  const FoundationWallScreen({super.key});
  @override
  ConsumerState<FoundationWallScreen> createState() => _FoundationWallScreenState();
}

class _FoundationWallScreenState extends ConsumerState<FoundationWallScreen> {
  final _perimeterController = TextEditingController(text: '160');
  final _heightController = TextEditingController(text: '8');
  final _thicknessController = TextEditingController(text: '8');

  double? _wallArea;
  double? _concreteYards;
  int? _rebarVertical;
  int? _rebarHorizontal;

  @override
  void dispose() { _perimeterController.dispose(); _heightController.dispose(); _thicknessController.dispose(); super.dispose(); }

  void _calculate() {
    final perimeter = double.tryParse(_perimeterController.text);
    final height = double.tryParse(_heightController.text);
    final thicknessInches = double.tryParse(_thicknessController.text);

    if (perimeter == null || height == null || thicknessInches == null) {
      setState(() { _wallArea = null; _concreteYards = null; _rebarVertical = null; _rebarHorizontal = null; });
      return;
    }

    final thicknessFeet = thicknessInches / 12;
    final wallArea = perimeter * height;
    final concreteYards = (perimeter * height * thicknessFeet) / 27;

    // Rebar: vertical @ 32" OC, horizontal every 16" of height
    final rebarVertical = ((perimeter * 12) / 32).ceil();
    final rebarHorizontal = ((height * 12) / 16).ceil() * ((perimeter / 20).ceil()); // 20' bars

    setState(() { _wallArea = wallArea; _concreteYards = concreteYards; _rebarVertical = rebarVertical; _rebarHorizontal = rebarHorizontal; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _perimeterController.text = '160'; _heightController.text = '8'; _thicknessController.text = '8'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Foundation Wall', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ZaftoInputField(label: 'Perimeter', unit: 'ft', controller: _perimeterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Height', unit: 'ft', controller: _heightController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Thickness', unit: 'inches', controller: _thicknessController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_concreteYards != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('CONCRETE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_concreteYards!.toStringAsFixed(1)} yd³', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wall Area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_wallArea!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Vertical Rebar (#4)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_rebarVertical pcs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Horizontal Rebar (#4)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_rebarHorizontal pcs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
