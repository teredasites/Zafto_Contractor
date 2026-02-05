import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Frost Depth Calculator - Footing depth reference
class FrostDepthScreen extends ConsumerStatefulWidget {
  const FrostDepthScreen({super.key});
  @override
  ConsumerState<FrostDepthScreen> createState() => _FrostDepthScreenState();
}

class _FrostDepthScreenState extends ConsumerState<FrostDepthScreen> {
  String _region = 'northeast';

  int? _frostDepth;
  int? _footingDepth;
  String? _notes;

  @override
  void _calculate() {
    int depth;
    String notes;

    switch (_region) {
      case 'south':
        depth = 6;
        notes = 'Minimal frost, check local code';
        break;
      case 'mid_atlantic':
        depth = 24;
        notes = 'Moderate frost penetration';
        break;
      case 'northeast':
        depth = 36;
        notes = 'Deep frost, protect pipes';
        break;
      case 'midwest':
        depth = 42;
        notes = 'Very deep frost zone';
        break;
      case 'mountain':
        depth = 48;
        notes = 'Extreme frost depth';
        break;
      default:
        depth = 36;
        notes = 'Verify with local building dept';
    }

    // Footing should be below frost line + 6"
    final footing = depth + 6;

    setState(() {
      _frostDepth = depth;
      _footingDepth = footing;
      _notes = notes;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); setState(() { _region = 'northeast'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Frost Depth', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'REGION', ['south', 'mid_atlantic'], _region, {'south': 'South', 'mid_atlantic': 'Mid-Atlantic'}, (v) { setState(() => _region = v); _calculate(); }),
            const SizedBox(height: 12),
            _buildSelector(colors, '', ['northeast', 'midwest', 'mountain'], _region, {'northeast': 'Northeast', 'midwest': 'Midwest', 'mountain': 'Mountain'}, (v) { setState(() => _region = v); _calculate(); }),
            const SizedBox(height: 32),
            if (_frostDepth != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('FROST LINE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_frostDepth\"', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Min footing depth', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_footingDepth\"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Notes', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text('$_notes', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right))]),
              ]),
            ),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Always verify with local building department for exact requirements.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 20),
            _buildFrostGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title.isNotEmpty) ...[
        Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 8),
      ],
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildFrostGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL FROST DEPTHS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Florida/Gulf', '0-6\"'),
        _buildTableRow(colors, 'Mid-Atlantic', '18-24\"'),
        _buildTableRow(colors, 'New England', '36-48\"'),
        _buildTableRow(colors, 'Minnesota', '60-80\"'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
