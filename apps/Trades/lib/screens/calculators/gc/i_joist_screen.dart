import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// I-Joist Selection - TJI sizing
class IJoistScreen extends ConsumerStatefulWidget {
  const IJoistScreen({super.key});
  @override
  ConsumerState<IJoistScreen> createState() => _IJoistScreenState();
}

class _IJoistScreenState extends ConsumerState<IJoistScreen> {
  final _spanController = TextEditingController(text: '18');
  final _floorLengthController = TextEditingController(text: '40');

  String _spacing = '16';

  String? _recommendedDepth;
  String? _series;
  int? _joistCount;

  @override
  void dispose() { _spanController.dispose(); _floorLengthController.dispose(); super.dispose(); }

  void _calculate() {
    final span = double.tryParse(_spanController.text);
    final floorLength = double.tryParse(_floorLengthController.text);
    final spacingInches = int.tryParse(_spacing) ?? 16;

    if (span == null || floorLength == null) {
      setState(() { _recommendedDepth = null; _series = null; _joistCount = null; });
      return;
    }

    // Simplified I-joist sizing (40 PSF live, 10 PSF dead)
    String depth;
    String series;
    if (spacingInches == 16) {
      if (span <= 14) { depth = '9.5"'; series = 'TJI 110'; }
      else if (span <= 17) { depth = '11.875"'; series = 'TJI 210'; }
      else if (span <= 21) { depth = '14"'; series = 'TJI 230'; }
      else if (span <= 24) { depth = '16"'; series = 'TJI 360'; }
      else { depth = '16"+'; series = 'Consult Manufacturer'; }
    } else {
      if (span <= 12) { depth = '9.5"'; series = 'TJI 110'; }
      else if (span <= 15) { depth = '11.875"'; series = 'TJI 210'; }
      else if (span <= 18) { depth = '14"'; series = 'TJI 230'; }
      else if (span <= 21) { depth = '16"'; series = 'TJI 360'; }
      else { depth = '16"+'; series = 'Consult Manufacturer'; }
    }

    final lengthInches = floorLength * 12;
    final joistCount = (lengthInches / spacingInches).floor() + 1;

    setState(() { _recommendedDepth = depth; _series = series; _joistCount = joistCount; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _spanController.text = '18'; _floorLengthController.text = '40'; setState(() => _spacing = '16'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('I-Joist Selection', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSpacingSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Span', unit: 'ft', controller: _spanController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Floor Length', unit: 'ft', controller: _floorLengthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_recommendedDepth != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('I-JOIST DEPTH', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_recommendedDepth!, style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Series', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_series!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Joists Needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_joistCount', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('I-joists require blocking at supports and cannot be notched. Web stiffeners needed at point loads.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
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
}
