import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Post Sizing Calculator - Load to post size
class PostSizingScreen extends ConsumerStatefulWidget {
  const PostSizingScreen({super.key});
  @override
  ConsumerState<PostSizingScreen> createState() => _PostSizingScreenState();
}

class _PostSizingScreenState extends ConsumerState<PostSizingScreen> {
  final _tributaryController = TextEditingController(text: '100');
  final _heightController = TextEditingController(text: '8');

  String _stories = '1';

  String? _postSize;
  int? _loadLbs;

  @override
  void dispose() { _tributaryController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final tributaryArea = double.tryParse(_tributaryController.text);
    final height = double.tryParse(_heightController.text);
    final stories = int.tryParse(_stories) ?? 1;

    if (tributaryArea == null || height == null) {
      setState(() { _postSize = null; _loadLbs = null; });
      return;
    }

    // Load = tributary area x 50 PSF (floor) + 10 PSF (dead) x stories
    final load = (tributaryArea * 60 * stories).round();

    // Post sizing based on IRC Table R502.5 (simplified)
    // 4x4 up to ~4000 lbs @ 8', 6x6 up to ~12000 lbs
    String postSize;
    if (height <= 8) {
      if (load <= 4000) postSize = '4x4';
      else if (load <= 8000) postSize = '4x6';
      else if (load <= 12000) postSize = '6x6';
      else postSize = 'Steel/Engineering';
    } else if (height <= 10) {
      if (load <= 3000) postSize = '4x4';
      else if (load <= 6000) postSize = '4x6';
      else if (load <= 10000) postSize = '6x6';
      else postSize = 'Steel/Engineering';
    } else {
      if (load <= 2500) postSize = '4x4';
      else if (load <= 5000) postSize = '4x6';
      else if (load <= 8000) postSize = '6x6';
      else postSize = 'Steel/Engineering';
    }

    setState(() { _postSize = postSize; _loadLbs = load; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _tributaryController.text = '100'; _heightController.text = '8'; setState(() => _stories = '1'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Post Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildStoriesSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Tributary Area', unit: 'sq ft', controller: _tributaryController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Post Height', unit: 'ft', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_postSize != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Text('RECOMMENDED POST', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text(_postSize!, style: TextStyle(color: colors.accentPrimary, fontSize: 32, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Calculated Load', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_loadLbs!.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} lbs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Based on IRC Table R502.5 for #2 SPF lumber. Verify bearing and footing size.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
