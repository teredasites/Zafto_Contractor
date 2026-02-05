import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Alternator Sizing Calculator - Determine alternator capacity needed
class AlternatorSizingScreen extends ConsumerStatefulWidget {
  const AlternatorSizingScreen({super.key});
  @override
  ConsumerState<AlternatorSizingScreen> createState() => _AlternatorSizingScreenState();
}

class _AlternatorSizingScreenState extends ConsumerState<AlternatorSizingScreen> {
  final _baseLoadController = TextEditingController(text: '35');
  final _additionalLoadController = TextEditingController();
  final _headroomController = TextEditingController(text: '25');

  double? _totalLoad;
  double? _recommendedAlt;

  void _calculate() {
    final baseLoad = double.tryParse(_baseLoadController.text) ?? 35;
    final additionalLoad = double.tryParse(_additionalLoadController.text) ?? 0;
    final headroom = double.tryParse(_headroomController.text) ?? 25;

    final total = baseLoad + additionalLoad;
    final recommended = total * (1 + headroom / 100);

    setState(() {
      _totalLoad = total;
      _recommendedAlt = recommended;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _baseLoadController.text = '35';
    _additionalLoadController.clear();
    _headroomController.text = '25';
    setState(() { _totalLoad = null; });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _baseLoadController.dispose();
    _additionalLoadController.dispose();
    _headroomController.dispose();
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
        title: Text('Alternator Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Base Vehicle Load', unit: 'amps', hint: 'Typical: 30-40A', controller: _baseLoadController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Additional Accessories', unit: 'amps', hint: 'Audio, lights, etc.', controller: _additionalLoadController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Headroom', unit: '%', hint: 'Safety margin', controller: _headroomController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_totalLoad != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildLoadGuideCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Alt Size = Total Load × 1.25', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Alternator rated output is at high RPM - idle output is ~50-60%', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Total Load', '${_totalLoad!.toStringAsFixed(0)} amps'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Recommended Alternator', '${_recommendedAlt!.toStringAsFixed(0)}+ amps', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('At idle (~1000 RPM), output is only 50-60% of rated. Size for adequate idle charging.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildLoadGuideCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON LOADS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildLoadRow(colors, 'Ignition/ECU', '5-10A'),
        _buildLoadRow(colors, 'Fuel pump', '4-8A'),
        _buildLoadRow(colors, 'Headlights (halogen)', '15-20A'),
        _buildLoadRow(colors, 'A/C blower (high)', '15-20A'),
        _buildLoadRow(colors, 'Heated seats', '5-10A ea'),
        _buildLoadRow(colors, 'Aftermarket stereo', '10-50A'),
        _buildLoadRow(colors, 'Competition audio', '50-200A+'),
        _buildLoadRow(colors, 'Winch', '100-400A'),
      ]),
    );
  }

  Widget _buildLoadRow(ZaftoColors colors, String device, String amps) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(device, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(amps, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
