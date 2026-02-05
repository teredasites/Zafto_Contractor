import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Langelier Saturation Index (LSI) Calculator
class SaturationIndexScreen extends ConsumerStatefulWidget {
  const SaturationIndexScreen({super.key});
  @override
  ConsumerState<SaturationIndexScreen> createState() => _SaturationIndexScreenState();
}

class _SaturationIndexScreenState extends ConsumerState<SaturationIndexScreen> {
  final _phController = TextEditingController();
  final _tempController = TextEditingController(text: '80');
  final _chController = TextEditingController();
  final _taController = TextEditingController();
  final _tdsController = TextEditingController(text: '1000');

  double? _lsi;
  String? _assessment;
  String? _recommendation;

  void _calculate() {
    final ph = double.tryParse(_phController.text);
    final temp = double.tryParse(_tempController.text);
    final ch = double.tryParse(_chController.text);
    final ta = double.tryParse(_taController.text);
    final tds = double.tryParse(_tdsController.text);

    if (ph == null || temp == null || ch == null || ta == null || tds == null) {
      setState(() { _lsi = null; });
      return;
    }

    // LSI = pH + TF + CF + AF - TDSF
    // Temperature factor
    final tf = _getTempFactor(temp);
    // Calcium factor (log10 of CH)
    final cf = math.log(ch) / math.ln10;
    // Alkalinity factor (log10 of TA)
    final af = math.log(ta) / math.ln10;
    // TDS factor
    final tdsf = _getTdsFactor(tds);

    // pH of saturation
    final pHs = (9.3 + af + cf) - (tf + tdsf);
    final lsi = ph - pHs;

    String assessment;
    String recommendation;
    if (lsi < -0.5) {
      assessment = 'Corrosive - water is aggressive';
      recommendation = 'Raise pH, calcium, or alkalinity';
    } else if (lsi < -0.3) {
      assessment = 'Slightly corrosive';
      recommendation = 'Minor adjustment recommended';
    } else if (lsi <= 0.3) {
      assessment = 'Balanced - ideal range';
      recommendation = 'Water is properly balanced';
    } else if (lsi <= 0.5) {
      assessment = 'Slightly scale-forming';
      recommendation = 'Minor adjustment recommended';
    } else {
      assessment = 'Scale-forming - deposits likely';
      recommendation = 'Lower pH, calcium, or alkalinity';
    }

    setState(() {
      _lsi = lsi;
      _assessment = assessment;
      _recommendation = recommendation;
    });
  }

  double _getTempFactor(double temp) {
    // Approximate temperature factor
    if (temp <= 32) return 0.0;
    if (temp <= 37) return 0.1;
    if (temp <= 46) return 0.2;
    if (temp <= 53) return 0.3;
    if (temp <= 60) return 0.4;
    if (temp <= 66) return 0.5;
    if (temp <= 76) return 0.6;
    if (temp <= 84) return 0.7;
    if (temp <= 94) return 0.8;
    if (temp <= 105) return 0.9;
    return 1.0;
  }

  double _getTdsFactor(double tds) {
    if (tds <= 100) return 12.0;
    if (tds <= 400) return 12.1;
    if (tds <= 800) return 12.2;
    if (tds <= 1200) return 12.3;
    return 12.4;
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _phController.clear();
    _tempController.text = '80';
    _chController.clear();
    _taController.clear();
    _tdsController.text = '1000';
    setState(() { _lsi = null; });
  }

  @override
  void dispose() {
    _phController.dispose();
    _tempController.dispose();
    _chController.dispose();
    _taController.dispose();
    _tdsController.dispose();
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
        title: Text('Saturation Index', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'pH', unit: '', hint: 'Current pH', controller: _phController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Temperature', unit: 'F', hint: 'Water temp', controller: _tempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Calcium Hardness', unit: 'ppm', hint: 'CH test result', controller: _chController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Total Alkalinity', unit: 'ppm', hint: 'TA test result', controller: _taController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'TDS', unit: 'ppm', hint: '1000 typical', controller: _tdsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_lsi != null) _buildResultsCard(colors),
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
        Text('LSI = pH - pHs', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Ideal LSI: -0.3 to +0.3', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color lsiColor;
    if (_lsi!.abs() <= 0.3) {
      lsiColor = Colors.green;
    } else if (_lsi!.abs() <= 0.5) {
      lsiColor = Colors.orange;
    } else {
      lsiColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('LSI', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          Text(_lsi!.toStringAsFixed(2), style: TextStyle(color: lsiColor, fontSize: 32, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: lsiColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text(_assessment!, style: TextStyle(color: lsiColor, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}
