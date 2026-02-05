import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Beam Span Calculator - Simplified beam sizing
class BeamSpanScreen extends ConsumerStatefulWidget {
  const BeamSpanScreen({super.key});
  @override
  ConsumerState<BeamSpanScreen> createState() => _BeamSpanScreenState();
}

class _BeamSpanScreenState extends ConsumerState<BeamSpanScreen> {
  final _spanController = TextEditingController(text: '10');
  final _tributaryController = TextEditingController(text: '8');

  String _stories = '1';

  String? _beamSize;
  String? _beamType;

  @override
  void dispose() { _spanController.dispose(); _tributaryController.dispose(); super.dispose(); }

  void _calculate() {
    final span = double.tryParse(_spanController.text);
    final tributary = double.tryParse(_tributaryController.text);
    final stories = int.tryParse(_stories) ?? 1;

    if (span == null || tributary == null) {
      setState(() { _beamSize = null; _beamType = null; });
      return;
    }

    // Simplified beam sizing based on span and load
    // Load = tributary x 50 PSF (floor) x stories
    final load = tributary * 50 * stories;

    String beamSize;
    String beamType;

    if (span <= 6 && load < 300) {
      beamSize = '(2) 2x8'; beamType = 'Built-up';
    } else if (span <= 8 && load < 400) {
      beamSize = '(2) 2x10'; beamType = 'Built-up';
    } else if (span <= 10 && load < 500) {
      beamSize = '(2) 2x12'; beamType = 'Built-up';
    } else if (span <= 12 && load < 600) {
      beamSize = '(3) 2x12'; beamType = 'Built-up';
    } else if (span <= 14) {
      beamSize = '3.5" x 11.875"'; beamType = 'LVL (2-ply)';
    } else if (span <= 18) {
      beamSize = '5.25" x 11.875"'; beamType = 'LVL (3-ply)';
    } else {
      beamSize = 'See Engineer'; beamType = 'Steel/Glulam';
    }

    setState(() { _beamSize = beamSize; _beamType = beamType; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _spanController.text = '10'; _tributaryController.text = '8'; setState(() => _stories = '1'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Beam Span', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildStoriesSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Beam Span', unit: 'ft', controller: _spanController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Tributary', unit: 'ft', hint: 'Joist span ÷ 2', controller: _tributaryController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_beamSize != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Text('RECOMMENDED BEAM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text(_beamSize!, style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(_beamType!, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    Icon(LucideIcons.alertTriangle, size: 16, color: colors.accentWarning),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Simplified sizing. Verify with span tables or engineer for actual loads.', style: TextStyle(color: colors.textSecondary, fontSize: 11))),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildStoriesSelector(ZaftoColors colors) {
    final options = ['1', '2', '3'];
    return Row(children: options.map((s) {
      final isSelected = _stories == s;
      return Expanded(child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); setState(() => _stories = s); _calculate(); },
        child: Container(margin: EdgeInsets.only(right: s != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
          child: Text('$s Story', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ));
    }).toList());
  }
}
