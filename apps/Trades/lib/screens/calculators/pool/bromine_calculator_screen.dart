import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Bromine Calculator for Spas
class BromineCalculatorScreen extends ConsumerStatefulWidget {
  const BromineCalculatorScreen({super.key});
  @override
  ConsumerState<BromineCalculatorScreen> createState() => _BromineCalculatorScreenState();
}

class _BromineCalculatorScreenState extends ConsumerState<BromineCalculatorScreen> {
  final _volumeController = TextEditingController();
  final _currentController = TextEditingController();
  final _targetController = TextEditingController(text: '4');

  double? _tabletsNeeded;
  double? _granularOz;
  String? _note;

  void _calculate() {
    final volume = double.tryParse(_volumeController.text);
    final current = double.tryParse(_currentController.text) ?? 0;
    final target = double.tryParse(_targetController.text);

    if (volume == null || target == null || volume <= 0 || target <= current) {
      setState(() { _tabletsNeeded = null; });
      return;
    }

    final ppmNeeded = target - current;
    // 1 oz bromine granules per 500 gal raises bromine ~5 ppm
    final granularOz = (ppmNeeded / 5) * (volume / 500);
    // 1" tablets for maintenance - typically 1 tablet per 100 gal
    final tablets = volume / 100;

    String note;
    if (target > 6) {
      note = 'High bromine may cause skin irritation. 3-5 ppm recommended.';
    } else if (target < 3) {
      note = 'Low bromine may not sanitize properly. Minimum 3 ppm for spas.';
    } else {
      note = 'Good target range. Test 2-3 times per week.';
    }

    setState(() {
      _tabletsNeeded = tablets;
      _granularOz = granularOz;
      _note = note;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _volumeController.clear();
    _currentController.clear();
    _targetController.text = '4';
    setState(() { _tabletsNeeded = null; });
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _currentController.dispose();
    _targetController.dispose();
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
        title: Text('Bromine Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Spa Volume', unit: 'gal', hint: 'Total gallons', controller: _volumeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Current Bromine', unit: 'ppm', hint: 'Test result', controller: _currentController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target Bromine', unit: 'ppm', hint: '3-5 ppm for spas', controller: _targetController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_tabletsNeeded != null) _buildResultsCard(colors),
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
        Text('Ideal Bromine: 3-5 ppm', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Bromine is more stable than chlorine at high temps', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Granular (boost)', '${_granularOz!.toStringAsFixed(1)} oz', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Tablets (maintain)', '${_tabletsNeeded!.toStringAsFixed(0)} tablets'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_note!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
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
