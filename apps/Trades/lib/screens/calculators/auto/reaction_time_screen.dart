import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Reaction Time Calculator - Bracket racing analysis
class ReactionTimeScreen extends ConsumerStatefulWidget {
  const ReactionTimeScreen({super.key});
  @override
  ConsumerState<ReactionTimeScreen> createState() => _ReactionTimeScreenState();
}

class _ReactionTimeScreenState extends ConsumerState<ReactionTimeScreen> {
  final _rtController = TextEditingController();
  String _treeType = 'sportsman';

  String? _analysis;
  double? _perfectDiff;

  void _calculate() {
    final rt = double.tryParse(_rtController.text);

    if (rt == null) {
      setState(() { _analysis = null; });
      return;
    }

    final perfectRt = _treeType == 'pro' ? 0.400 : 0.500;
    final diff = rt - perfectRt;

    String analysis;
    if (rt < perfectRt) {
      analysis = 'RED LIGHT! Left ${(perfectRt - rt).toStringAsFixed(3)} sec early';
    } else if (diff <= 0.010) {
      analysis = 'Excellent - near perfect light';
    } else if (diff <= 0.030) {
      analysis = 'Good - competitive reaction';
    } else if (diff <= 0.060) {
      analysis = 'Fair - room for improvement';
    } else if (diff <= 0.100) {
      analysis = 'Slow - practice needed';
    } else {
      analysis = 'Very slow - asleep at the tree';
    }

    setState(() {
      _analysis = analysis;
      _perfectDiff = diff;
    });
  }

  @override
  void dispose() {
    _rtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Reaction Time', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildTreeSelector(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Reaction Time', unit: 'sec', hint: 'From time slip', controller: _rtController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_analysis != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildTipsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTreeSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TREE TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildTreeOption(colors, 'sportsman', 'Sportsman', '.500 full tree')),
          const SizedBox(width: 12),
          Expanded(child: _buildTreeOption(colors, 'pro', 'Pro', '.400 pro tree')),
        ]),
      ]),
    );
  }

  Widget _buildTreeOption(ZaftoColors colors, String value, String label, String desc) {
    final isSelected = _treeType == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _treeType = value; });
        _calculate();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Column(children: [
          Text(label, style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final rt = double.tryParse(_rtController.text) ?? 0;
    final perfectRt = _treeType == 'pro' ? 0.400 : 0.500;

    Color statusColor;
    if (rt < perfectRt) {
      statusColor = colors.error;
    } else if (_perfectDiff! <= 0.020) {
      statusColor = colors.accentSuccess;
    } else if (_perfectDiff! <= 0.050) {
      statusColor = colors.accentPrimary;
    } else {
      statusColor = colors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('REACTION ANALYSIS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        if (rt >= perfectRt)
          Text('+${_perfectDiff!.toStringAsFixed(3)} sec', style: TextStyle(color: statusColor, fontSize: 40, fontWeight: FontWeight.w700))
        else
          Text('RED LIGHT', style: TextStyle(color: colors.error, fontSize: 40, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_analysis!, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ),
      ]),
    );
  }

  Widget _buildTipsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('REACTION TIME TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('• Focus on 2nd yellow, react to 3rd', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Consistent staging depth', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Practice with a practice tree', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Account for rollout (0.030-0.040)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Deep stage = less rollout time', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        _buildRtReference(colors),
      ]),
    );
  }

  Widget _buildRtReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TARGET REACTIONS', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('• Sportsman: .510-.530 (good), .500-.510 (great)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Pro: .410-.430 (good), .400-.410 (great)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
