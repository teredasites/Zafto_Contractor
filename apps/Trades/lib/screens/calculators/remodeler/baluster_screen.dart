import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Baluster Calculator - Spindle/baluster quantity estimation
class BalusterScreen extends ConsumerStatefulWidget {
  const BalusterScreen({super.key});
  @override
  ConsumerState<BalusterScreen> createState() => _BalusterScreenState();
}

class _BalusterScreenState extends ConsumerState<BalusterScreen> {
  final _lengthController = TextEditingController(text: '12');
  final _spacingController = TextEditingController(text: '4');

  String _style = 'square';
  String _pattern = 'single';

  int? _balusters;
  double? _totalLF;
  int? _pairs;

  @override
  void dispose() { _lengthController.dispose(); _spacingController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final spacing = double.tryParse(_spacingController.text) ?? 4;

    // Convert length to inches
    final lengthInches = length * 12;

    // Baluster width varies by style
    double balusterWidth;
    switch (_style) {
      case 'square':
        balusterWidth = 1.25;
        break;
      case 'turned':
        balusterWidth = 1.5;
        break;
      case 'iron':
        balusterWidth = 0.625;
        break;
      default:
        balusterWidth = 1.25;
    }

    // Calculate balusters: (length - baluster width) / (spacing + baluster width) + 1
    final balusters = ((lengthInches - balusterWidth) / (spacing + balusterWidth)).floor() + 1;

    // Pattern multiplier
    int multiplier;
    switch (_pattern) {
      case 'single':
        multiplier = 1;
        break;
      case 'double':
        multiplier = 2;
        break;
      case 'triple':
        multiplier = 3;
        break;
      default:
        multiplier = 1;
    }

    final totalBalusters = balusters * multiplier;

    // Standard baluster height ~32-36"
    final totalLF = totalBalusters * 2.75; // ~33" each

    // Pairs for double pattern
    final pairs = _pattern == 'double' ? balusters : 0;

    setState(() { _balusters = totalBalusters; _totalLF = totalLF; _pairs = pairs; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '12'; _spacingController.text = '4'; setState(() { _style = 'square'; _pattern = 'single'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Balusters', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'STYLE', ['square', 'turned', 'iron'], _style, {'square': 'Square', 'turned': 'Turned', 'iron': 'Iron'}, (v) { setState(() => _style = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'PATTERN', ['single', 'double', 'triple'], _pattern, {'single': 'Single', 'double': 'Double', 'triple': 'Triple'}, (v) { setState(() => _pattern = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Rail Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Max Spacing', unit: 'inches', controller: _spacingController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_balusters != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('BALUSTERS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_balusters', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Linear Feet', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalLF!.toStringAsFixed(1)} lf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_pattern == 'double') ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Pairs', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_pairs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Code: 4\" max spacing (sphere test). Add 10% extra for cuts and breakage.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildStyleTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildStyleTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BALUSTER SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Square wood', '1.25\" x 1.25\"'),
        _buildTableRow(colors, 'Turned wood', '1.25\" - 1.75\"'),
        _buildTableRow(colors, 'Iron round', '5/8\" dia'),
        _buildTableRow(colors, 'Iron square', '1/2\" sq'),
        _buildTableRow(colors, 'Standard length', '32\" - 42\"'),
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
