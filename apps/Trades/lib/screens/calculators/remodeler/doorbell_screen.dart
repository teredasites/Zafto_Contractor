import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Doorbell Calculator - Doorbell installation materials estimation
class DoorbellScreen extends ConsumerStatefulWidget {
  const DoorbellScreen({super.key});
  @override
  ConsumerState<DoorbellScreen> createState() => _DoorbellScreenState();
}

class _DoorbellScreenState extends ConsumerState<DoorbellScreen> {
  final _buttonCountController = TextEditingController(text: '1');
  final _wireDistanceController = TextEditingController(text: '30');

  String _type = 'wired';
  String _chimeType = 'digital';

  double? _wireFeet;
  int? _transformers;
  int? _chimes;
  int? _buttons;

  @override
  void dispose() { _buttonCountController.dispose(); _wireDistanceController.dispose(); super.dispose(); }

  void _calculate() {
    final buttonCount = int.tryParse(_buttonCountController.text) ?? 1;
    final wireDistance = double.tryParse(_wireDistanceController.text) ?? 30;

    // Wire needed (bell wire 18-20 AWG)
    // From transformer to chime + chime to button(s)
    double wireFeet;
    if (_type == 'wired') {
      // Transformer to chime ~10', chime to button = wireDistance, add 20% extra
      wireFeet = (10 + wireDistance * buttonCount) * 1.2;
    } else {
      wireFeet = 0;
    }

    // Components
    final transformers = _type == 'wired' ? 1 : 0;
    final chimes = 1;
    final buttons = buttonCount;

    setState(() { _wireFeet = wireFeet; _transformers = transformers; _chimes = chimes; _buttons = buttons; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _buttonCountController.text = '1'; _wireDistanceController.text = '30'; setState(() { _type = 'wired'; _chimeType = 'digital'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Doorbell', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'TYPE', ['wired', 'wireless', 'video'], _type, {'wired': 'Wired', 'wireless': 'Wireless', 'video': 'Video'}, (v) { setState(() => _type = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'CHIME TYPE', ['mechanical', 'digital', 'smart'], _chimeType, {'mechanical': 'Mechanical', 'digital': 'Digital', 'smart': 'Smart'}, (v) { setState(() => _chimeType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Door Buttons', unit: 'qty', controller: _buttonCountController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Wire Run', unit: 'feet', controller: _wireDistanceController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_buttons != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('COMPONENTS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_buttons button${_buttons! > 1 ? 's' : ''}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Chime Unit', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_chimes', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_type == 'wired') ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Transformer', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_transformers', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Bell Wire (18 AWG)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_wireFeet!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getTypeTip(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSpecsTable(colors),
          ]),
        ),
      ),
    );
  }

  String _getTypeTip() {
    switch (_type) {
      case 'wired':
        return 'Standard transformer: 16V 10VA. Mount at junction box. Use thermostat wire or bell wire.';
      case 'wireless':
        return 'Battery-powered button. Receiver plugs into outlet. Range typically 150-300 feet.';
      case 'video':
        return 'Video doorbells need WiFi and may need existing doorbell wiring or plug-in transformer.';
      default:
        return 'Button height: 42-48\" from floor. Illuminate button area for visibility.';
    }
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

  Widget _buildSpecsTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DOORBELL SPECS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Transformer voltage', '16V or 24V'),
        _buildTableRow(colors, 'Wire gauge', '18-20 AWG'),
        _buildTableRow(colors, 'Button height', '42-48\" AFF'),
        _buildTableRow(colors, 'Video resolution', '1080p minimum'),
        _buildTableRow(colors, 'Wireless range', '150-300 ft'),
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
