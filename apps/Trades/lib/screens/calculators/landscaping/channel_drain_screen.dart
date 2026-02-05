import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Channel Drain Calculator - Trench drain sizing
class ChannelDrainScreen extends ConsumerStatefulWidget {
  const ChannelDrainScreen({super.key});
  @override
  ConsumerState<ChannelDrainScreen> createState() => _ChannelDrainScreenState();
}

class _ChannelDrainScreenState extends ConsumerState<ChannelDrainScreen> {
  final _lengthController = TextEditingController(text: '20');
  final _drainageWidthController = TextEditingController(text: '15');

  String _loadClass = 'a';

  int? _channelCount;
  double? _flowCapacity;
  String? _recommendedWidth;
  String? _grateType;

  @override
  void dispose() { _lengthController.dispose(); _drainageWidthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 20;
    final drainageWidth = double.tryParse(_drainageWidthController.text) ?? 15;

    // Area draining to channel (one side only typically)
    final drainageArea = length * drainageWidth;

    // Flow calculation: assume 2 in/hr rainfall
    // Q = A × 0.04 GPM per sq ft (simplified)
    final flowGpm = drainageArea * 0.04;

    // Channel sections (typically 39" or 1 meter each)
    final sections = (length * 12 / 39).ceil();

    // Recommended channel width based on flow
    String channelWidth;
    String grateType;
    if (flowGpm < 30) {
      channelWidth = '4\"';
    } else if (flowGpm < 60) {
      channelWidth = '6\"';
    } else {
      channelWidth = '8\"+';
    }

    // Grate type based on load class
    switch (_loadClass) {
      case 'a':
        grateType = 'Plastic/Decorative';
        break;
      case 'b':
        grateType = 'Galvanized Steel';
        break;
      case 'c':
        grateType = 'Ductile Iron';
        break;
      case 'd':
        grateType = 'Heavy Duty Iron';
        break;
      default:
        grateType = 'Galvanized Steel';
    }

    setState(() {
      _channelCount = sections;
      _flowCapacity = flowGpm;
      _recommendedWidth = channelWidth;
      _grateType = grateType;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '20'; _drainageWidthController.text = '15'; setState(() { _loadClass = 'a'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Channel Drain', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'LOAD CLASS', ['a', 'b', 'c', 'd'], _loadClass, {'a': 'A (Foot)', 'b': 'B (Light)', 'c': 'C (Vehicle)', 'd': 'D (Heavy)'}, (v) { setState(() => _loadClass = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Channel Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Drainage Width', unit: 'ft', controller: _drainageWidthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_channelCount != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('CHANNEL SECTIONS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_channelCount', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Flow capacity', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_flowCapacity!.toStringAsFixed(1)} GPM', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Recommended width', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_recommendedWidth', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Grate type', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_grateType', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildChannelGuide(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildChannelGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LOAD CLASSES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Class A', 'Pedestrian only'),
        _buildTableRow(colors, 'Class B', 'Light vehicles'),
        _buildTableRow(colors, 'Class C', 'Standard vehicles'),
        _buildTableRow(colors, 'Class D', 'Heavy trucks'),
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
