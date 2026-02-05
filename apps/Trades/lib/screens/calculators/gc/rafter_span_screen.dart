import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Rafter Span Tables - Max span lookup
class RafterSpanScreen extends ConsumerStatefulWidget {
  const RafterSpanScreen({super.key});
  @override
  ConsumerState<RafterSpanScreen> createState() => _RafterSpanScreenState();
}

class _RafterSpanScreenState extends ConsumerState<RafterSpanScreen> {
  String _size = '2x8';
  String _spacing = '16';
  String _pitch = '4/12';

  String? _maxSpan;

  @override
  void initState() { super.initState(); _calculate(); }

  void _calculate() {
    // Simplified IRC rafter span table (20 PSF live, 10 PSF dead, SPF #2)
    final spans = {
      '2x6': {'4/12': {'16': '10-6', '24': '8-6'}, '6/12': {'16': '11-0', '24': '9-0'}, '8/12': {'16': '11-6', '24': '9-6'}},
      '2x8': {'4/12': {'16': '14-0', '24': '11-6'}, '6/12': {'16': '14-6', '24': '12-0'}, '8/12': {'16': '15-0', '24': '12-6'}},
      '2x10': {'4/12': {'16': '17-6', '24': '14-6'}, '6/12': {'16': '18-6', '24': '15-0'}, '8/12': {'16': '19-0', '24': '15-6'}},
      '2x12': {'4/12': {'16': '21-0', '24': '17-6'}, '6/12': {'16': '22-0', '24': '18-0'}, '8/12': {'16': '23-0', '24': '19-0'}},
    };
    setState(() => _maxSpan = spans[_size]?[_pitch]?[_spacing] ?? 'N/A');
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Rafter Span Tables', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'RAFTER SIZE', ['2x6', '2x8', '2x10', '2x12'], _size, (v) { setState(() => _size = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'SPACING', ['16', '24'], _spacing, (v) { setState(() => _spacing = v); _calculate(); }, suffix: '" OC'),
            const SizedBox(height: 16),
            _buildSelector(colors, 'ROOF PITCH', ['4/12', '6/12', '8/12'], _pitch, (v) { setState(() => _pitch = v); _calculate(); }),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Text('MAX SPAN', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text(_maxSpan ?? 'N/A', style: TextStyle(color: colors.accentPrimary, fontSize: 36, fontWeight: FontWeight.w700)),
                Text('feet-inches (SPF #2)', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect, {String suffix = ''}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: options.map((o) {
        final isSelected = selected == o;
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text('$o$suffix', style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList()),
    ]);
  }
}
