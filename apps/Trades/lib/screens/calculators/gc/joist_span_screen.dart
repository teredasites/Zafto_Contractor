import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Joist Span Tables - Max span by species
class JoistSpanScreen extends ConsumerStatefulWidget {
  const JoistSpanScreen({super.key});
  @override
  ConsumerState<JoistSpanScreen> createState() => _JoistSpanScreenState();
}

class _JoistSpanScreenState extends ConsumerState<JoistSpanScreen> {
  String _size = '2x10';
  String _spacing = '16';
  String _species = 'SPF';

  String? _maxSpan;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final spans = {
      '2x8': {'SPF': {'12': '13-1', '16': '11-11', '24': '10-5'}, 'DF': {'12': '14-2', '16': '12-11', '24': '11-0'}, 'SYP': {'12': '13-7', '16': '12-4', '24': '10-2'}},
      '2x10': {'SPF': {'12': '16-9', '16': '15-2', '24': '12-4'}, 'DF': {'12': '18-0', '16': '16-1', '24': '13-3'}, 'SYP': {'12': '17-5', '16': '15-10', '24': '13-1'}},
      '2x12': {'SPF': {'12': '20-3', '16': '17-7', '24': '14-4'}, 'DF': {'12': '21-7', '16': '19-1', '24': '15-7'}, 'SYP': {'12': '21-0', '16': '19-1', '24': '15-7'}},
    };
    setState(() => _maxSpan = spans[_size]?[_species]?[_spacing] ?? 'N/A');
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Joist Span Tables', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSelector(colors, 'JOIST SIZE', ['2x8', '2x10', '2x12'], _size, (v) { setState(() => _size = v); _calculate(); }),
              const SizedBox(height: 16),
              _buildSelector(colors, 'SPACING', ['12', '16', '24'], _spacing, (v) { setState(() => _spacing = v); _calculate(); }, suffix: '" OC'),
              const SizedBox(height: 16),
              _buildSelector(colors, 'SPECIES', ['SPF', 'DF', 'SYP'], _species, (v) { setState(() => _species = v); _calculate(); }),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
                child: Column(
                  children: [
                    Text('MAX SPAN', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Text(_maxSpan ?? 'N/A', style: TextStyle(color: colors.accentPrimary, fontSize: 36, fontWeight: FontWeight.w700)),
                    Text('feet-inches', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Function(String) onSelect, {String suffix = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Row(
          children: options.map((o) {
            final isSelected = selected == o;
            return Expanded(
              child: GestureDetector(
                onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
                child: Container(
                  margin: EdgeInsets.only(right: o != options.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
                  child: Text('$o$suffix', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
