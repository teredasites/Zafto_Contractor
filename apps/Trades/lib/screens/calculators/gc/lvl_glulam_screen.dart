import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// LVL/Glulam Sizing - Engineered lumber selection
class LvlGlulamScreen extends ConsumerStatefulWidget {
  const LvlGlulamScreen({super.key});
  @override
  ConsumerState<LvlGlulamScreen> createState() => _LvlGlulamScreenState();
}

class _LvlGlulamScreenState extends ConsumerState<LvlGlulamScreen> {
  final _spanController = TextEditingController(text: '16');
  final _tributaryController = TextEditingController(text: '12');

  String _loadType = 'Floor';
  String _stories = '1';

  String? _recommendedSize;
  String? _beamType;
  String? _note;

  @override
  void dispose() { _spanController.dispose(); _tributaryController.dispose(); super.dispose(); }

  void _calculate() {
    final span = double.tryParse(_spanController.text);
    final tributary = double.tryParse(_tributaryController.text);

    if (span == null || tributary == null) {
      setState(() { _recommendedSize = null; _beamType = null; _note = null; });
      return;
    }

    // Simplified sizing (actual sizing requires engineering)
    final load = tributary * (_loadType == 'Floor' ? 50 : 30); // PSF x tributary
    final stories = int.tryParse(_stories) ?? 1;
    final totalLoad = load * stories;

    String size;
    String type;
    String note;

    if (span <= 10 && totalLoad < 400) {
      size = '3.5" x 9.25"'; type = 'LVL'; note = '1.75" x 9.25" x 2 ply';
    } else if (span <= 14 && totalLoad < 600) {
      size = '3.5" x 11.875"'; type = 'LVL'; note = '1.75" x 11.875" x 2 ply';
    } else if (span <= 18 && totalLoad < 800) {
      size = '5.25" x 11.875"'; type = 'LVL'; note = '1.75" x 11.875" x 3 ply';
    } else if (span <= 24) {
      size = '5.125" x 12"'; type = 'Glulam'; note = '24F-V4 or similar';
    } else {
      size = 'Engineering Required'; type = 'Glulam/Steel'; note = 'Consult structural engineer';
    }

    setState(() { _recommendedSize = size; _beamType = type; _note = note; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _spanController.text = '16'; _tributaryController.text = '12'; setState(() { _loadType = 'Floor'; _stories = '1'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('LVL/Glulam Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'LOAD TYPE', ['Floor', 'Roof'], _loadType, (v) { setState(() => _loadType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'STORIES ABOVE', ['1', '2', '3'], _stories, (v) { setState(() => _stories = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Span', unit: 'ft', controller: _spanController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Tributary', unit: 'ft', controller: _tributaryController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_recommendedSize != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Text('RECOMMENDED SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text(_recommendedSize!, style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(_beamType!, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Text(_note!, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    Icon(LucideIcons.alertTriangle, size: 16, color: colors.accentWarning),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Always verify with manufacturer tables or engineer.', style: TextStyle(color: colors.textSecondary, fontSize: 11))),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(o, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }
}
