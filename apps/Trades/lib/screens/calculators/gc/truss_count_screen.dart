import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Truss Count Calculator - Trusses needed
class TrussCountScreen extends ConsumerStatefulWidget {
  const TrussCountScreen({super.key});
  @override
  ConsumerState<TrussCountScreen> createState() => _TrussCountScreenState();
}

class _TrussCountScreenState extends ConsumerState<TrussCountScreen> {
  final _lengthController = TextEditingController(text: '40');
  final _spanController = TextEditingController(text: '28');

  String _spacing = '24';

  int? _trussCount;
  int? _gableEnds;
  int? _totalTrusses;

  @override
  void dispose() { _lengthController.dispose(); _spanController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final spacingInches = int.tryParse(_spacing) ?? 24;

    if (length == null) {
      setState(() { _trussCount = null; _gableEnds = null; _totalTrusses = null; });
      return;
    }

    final lengthInches = length * 12;
    final trussCount = (lengthInches / spacingInches).floor() + 1;
    const gableEnds = 2; // Standard gable roof has 2 gable end trusses
    final totalTrusses = trussCount + gableEnds;

    setState(() { _trussCount = trussCount; _gableEnds = gableEnds; _totalTrusses = totalTrusses; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '40'; _spanController.text = '28'; setState(() => _spacing = '24'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Truss Count', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSpacingSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Building Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Truss Span', unit: 'ft', controller: _spanController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_totalTrusses != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSpacingSelector(ZaftoColors colors) {
    return Row(children: ['16', '24'].map((s) {
      final isSelected = _spacing == s;
      return Expanded(child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _spacing = s); _calculate(); },
        child: Container(margin: EdgeInsets.only(right: s == '16' ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
          child: Text('$s" OC', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ));
    }).toList());
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Common Trusses', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_trussCount', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Gable End Trusses', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_gableEnds', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
        const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL TRUSSES', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_totalTrusses', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
      ]),
    );
  }
}
