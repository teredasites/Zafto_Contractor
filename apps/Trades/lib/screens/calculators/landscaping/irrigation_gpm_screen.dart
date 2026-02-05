import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Irrigation GPM Calculator - Water supply capacity
class IrrigationGpmScreen extends ConsumerStatefulWidget {
  const IrrigationGpmScreen({super.key});
  @override
  ConsumerState<IrrigationGpmScreen> createState() => _IrrigationGpmScreenState();
}

class _IrrigationGpmScreenState extends ConsumerState<IrrigationGpmScreen> {
  final _bucketController = TextEditingController(text: '5');
  final _secondsController = TextEditingController(text: '20');
  final _psiController = TextEditingController(text: '50');

  String _pipeSize = '0.75';

  double? _gpm;
  double? _gph;
  int? _maxHeads;
  int? _zones;

  @override
  void dispose() { _bucketController.dispose(); _secondsController.dispose(); _psiController.dispose(); super.dispose(); }

  void _calculate() {
    final bucketGal = double.tryParse(_bucketController.text) ?? 5;
    final seconds = double.tryParse(_secondsController.text) ?? 20;

    if (seconds <= 0) {
      setState(() { _gpm = null; });
      return;
    }

    // GPM from bucket test
    final gpm = (bucketGal / seconds) * 60;
    final gph = gpm * 60;

    // Max heads based on ~3 GPM per rotor, ~1.5 GPM per spray
    final maxHeads = (gpm / 3).floor();

    // Recommended zones (design for 75% of available GPM)
    final usableGpm = gpm * 0.75;
    final avgZoneGpm = 10.0; // Average zone uses ~10 GPM
    final zones = (usableGpm / avgZoneGpm).ceil().clamp(1, 99);

    setState(() {
      _gpm = gpm;
      _gph = gph;
      _maxHeads = maxHeads;
      _zones = zones;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _bucketController.text = '5'; _secondsController.text = '20'; _psiController.text = '50'; setState(() { _pipeSize = '0.75'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Irrigation GPM', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('BUCKET TEST METHOD', style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Fill a bucket from your hose bib and time it.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ]),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Bucket Size', unit: 'gal', controller: _bucketController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Fill Time', unit: 'sec', controller: _secondsController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Static Pressure', unit: 'PSI', controller: _psiController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_gpm != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('FLOW RATE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gpm!.toStringAsFixed(1)} GPM', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Gallons per hour', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gph!.toStringAsFixed(0)} GPH', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Max rotor heads/zone', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_maxHeads heads', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Suggested zones', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_zones zones', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Design zones for 75% of available GPM to account for pressure loss.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildGpmChart(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildGpmChart(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TYPICAL FLOW RATES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '3/4" service', '8-12 GPM'),
        _buildTableRow(colors, '1" service', '15-22 GPM'),
        _buildTableRow(colors, '1.5" service', '30-50 GPM'),
        _buildTableRow(colors, 'Well pump', '5-15 GPM'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildTableRow(colors, 'Spray head', '1-2 GPM'),
        _buildTableRow(colors, 'Rotor head', '2-4 GPM'),
        _buildTableRow(colors, 'Impact head', '3-5 GPM'),
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
