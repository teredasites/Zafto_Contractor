import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Dethatching Calculator - Equipment time and debris estimate
class DethatchingScreen extends ConsumerStatefulWidget {
  const DethatchingScreen({super.key});
  @override
  ConsumerState<DethatchingScreen> createState() => _DethatchingScreenState();
}

class _DethatchingScreenState extends ConsumerState<DethatchingScreen> {
  final _areaController = TextEditingController(text: '10000');
  final _rateController = TextEditingController(text: '20');

  String _equipment = 'power';
  String _thatchLevel = 'moderate';

  double? _timeHours;
  double? _debrisCuYd;
  double? _price;

  @override
  void dispose() { _areaController.dispose(); _rateController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 10000;
    final ratePerK = double.tryParse(_rateController.text) ?? 20;

    // Coverage rate (sq ft per hour)
    double sqftPerHour;
    switch (_equipment) {
      case 'rake': sqftPerHour = 500; break;
      case 'power': sqftPerHour = 5000; break;
      case 'vertical': sqftPerHour = 8000; break;
      default: sqftPerHour = 5000;
    }

    // Debris per 1000 sq ft (cubic feet)
    double debrisPerK;
    switch (_thatchLevel) {
      case 'light': debrisPerK = 2; break;
      case 'moderate': debrisPerK = 5; break;
      case 'heavy': debrisPerK = 10; break;
      default: debrisPerK = 5;
    }

    final timeHours = area / sqftPerHour;
    final debrisCuFt = (area / 1000) * debrisPerK;
    final debrisCuYd = debrisCuFt / 27;
    final price = (area / 1000) * ratePerK;

    setState(() {
      _timeHours = timeHours;
      _debrisCuYd = debrisCuYd;
      _price = price;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '10000'; _rateController.text = '20'; setState(() { _equipment = 'power'; _thatchLevel = 'moderate'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Dethatching', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'EQUIPMENT', ['rake', 'power', 'vertical'], _equipment, {'rake': 'Manual Rake', 'power': 'Power Rake', 'vertical': 'Verticutter'}, (v) { setState(() => _equipment = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'THATCH LEVEL', ['light', 'moderate', 'heavy'], _thatchLevel, {'light': 'Light (<0.5")', 'moderate': 'Moderate (0.5-1")', 'heavy': 'Heavy (>1")'}, (v) { setState(() => _thatchLevel = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Lawn Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Price Rate', unit: '\$/1000 sq ft', controller: _rateController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_timeHours != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('EST. TIME', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_timeHours!.toStringAsFixed(1)} hrs', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Debris estimate', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_debrisCuYd!.toStringAsFixed(1)} cu yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Suggested price', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('\$${_price!.toStringAsFixed(0)}', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildThatchGuide(colors),
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

  Widget _buildThatchGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('THATCH GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Healthy thatch', '0.25-0.5"'),
        _buildTableRow(colors, 'Needs dethatching', '>0.5"'),
        _buildTableRow(colors, 'Cool season', 'Early fall'),
        _buildTableRow(colors, 'Warm season', 'Late spring'),
        _buildTableRow(colors, 'Follow with', 'Overseed + fertilize'),
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
