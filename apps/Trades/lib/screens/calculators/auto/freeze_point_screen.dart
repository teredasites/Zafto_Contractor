import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Freeze Point Calculator - Antifreeze protection level
class FreezePointScreen extends ConsumerStatefulWidget {
  const FreezePointScreen({super.key});
  @override
  ConsumerState<FreezePointScreen> createState() => _FreezePointScreenState();
}

class _FreezePointScreenState extends ConsumerState<FreezePointScreen> {
  final _glycolPercentController = TextEditingController(text: '50');

  double? _freezePoint;
  String? _protection;

  void _calculate() {
    final glycolPercent = double.tryParse(_glycolPercentController.text);

    if (glycolPercent == null) {
      setState(() { _freezePoint = null; });
      return;
    }

    // Ethylene glycol freeze point approximation
    double freezePoint;
    String protection;

    if (glycolPercent < 20) {
      freezePoint = 32 - (glycolPercent * 1.5);
      protection = 'Minimal protection - increase concentration';
    } else if (glycolPercent <= 30) {
      freezePoint = 32 - (glycolPercent * 2.0);
      protection = 'Light winter protection';
    } else if (glycolPercent <= 40) {
      freezePoint = -10 - ((glycolPercent - 30) * 1.5);
      protection = 'Moderate winter protection';
    } else if (glycolPercent <= 50) {
      freezePoint = -25 - ((glycolPercent - 40) * 1.0);
      protection = 'Good winter protection - typical';
    } else if (glycolPercent <= 60) {
      freezePoint = -35 - ((glycolPercent - 50) * 1.5);
      protection = 'Excellent winter protection';
    } else if (glycolPercent <= 70) {
      freezePoint = -50 - ((glycolPercent - 60) * 0.8);
      protection = 'Maximum protection - extreme cold';
    } else {
      freezePoint = -55;
      protection = 'Too concentrated - reduces cooling efficiency';
    }

    setState(() {
      _freezePoint = freezePoint;
      _protection = protection;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _glycolPercentController.text = '50';
    setState(() { _freezePoint = null; });
  }

  @override
  void dispose() {
    _glycolPercentController.dispose();
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
        title: Text('Freeze Point', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Glycol Concentration', unit: '%', hint: 'Typical 50%', controller: _glycolPercentController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_freezePoint != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildConcentrationGuide(colors),
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
        Text('Freeze protection by glycol %', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('50/50 mix is standard recommendation', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor;
    if (_freezePoint! <= -35) {
      statusColor = colors.accentSuccess;
    } else if (_freezePoint! <= -20) {
      statusColor = colors.accentPrimary;
    } else if (_freezePoint! <= 0) {
      statusColor = colors.warning;
    } else {
      statusColor = colors.error;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('FREEZE POINT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_freezePoint!.toStringAsFixed(0)}°F', style: TextStyle(color: statusColor, fontSize: 48, fontWeight: FontWeight.w700)),
        Text('(${((_freezePoint! - 32) * 5 / 9).toStringAsFixed(0)}°C)', style: TextStyle(color: colors.textSecondary, fontSize: 16)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_protection!, style: TextStyle(color: statusColor, fontSize: 13), textAlign: TextAlign.center),
        ),
      ]),
    );
  }

  Widget _buildConcentrationGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CONCENTRATION REFERENCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildConcRow(colors, '30%', '0°F / -18°C'),
        _buildConcRow(colors, '40%', '-12°F / -24°C'),
        _buildConcRow(colors, '50%', '-34°F / -37°C'),
        _buildConcRow(colors, '60%', '-62°F / -52°C'),
        _buildConcRow(colors, '70%', '-84°F / -64°C'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('Over 70% reduces heat transfer. 50% recommended for most applications.', style: TextStyle(color: colors.warning, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildConcRow(ZaftoColors colors, String concentration, String temp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(concentration, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(temp, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }
}
