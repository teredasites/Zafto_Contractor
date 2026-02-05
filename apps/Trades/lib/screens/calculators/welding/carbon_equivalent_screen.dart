import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Carbon Equivalent Calculator - CE for weldability assessment
class CarbonEquivalentScreen extends ConsumerStatefulWidget {
  const CarbonEquivalentScreen({super.key});
  @override
  ConsumerState<CarbonEquivalentScreen> createState() => _CarbonEquivalentScreenState();
}

class _CarbonEquivalentScreenState extends ConsumerState<CarbonEquivalentScreen> {
  final _carbonController = TextEditingController();
  final _manganeseController = TextEditingController(text: '0');
  final _chromiumController = TextEditingController(text: '0');
  final _molybdenumController = TextEditingController(text: '0');
  final _vanadiumController = TextEditingController(text: '0');
  final _nickelController = TextEditingController(text: '0');
  final _copperController = TextEditingController(text: '0');
  String _formula = 'IIW';

  double? _ce;
  String? _weldability;
  String? _preheatRecommendation;

  void _calculate() {
    final c = double.tryParse(_carbonController.text);
    final mn = double.tryParse(_manganeseController.text) ?? 0;
    final cr = double.tryParse(_chromiumController.text) ?? 0;
    final mo = double.tryParse(_molybdenumController.text) ?? 0;
    final v = double.tryParse(_vanadiumController.text) ?? 0;
    final ni = double.tryParse(_nickelController.text) ?? 0;
    final cu = double.tryParse(_copperController.text) ?? 0;

    if (c == null) {
      setState(() { _ce = null; });
      return;
    }

    double ce;
    if (_formula == 'IIW') {
      // IIW formula: CE = C + Mn/6 + (Cr+Mo+V)/5 + (Ni+Cu)/15
      ce = c + (mn / 6) + ((cr + mo + v) / 5) + ((ni + cu) / 15);
    } else if (_formula == 'Pcm') {
      // Pcm formula: Pcm = C + Si/30 + (Mn+Cu+Cr)/20 + Ni/60 + Mo/15 + V/10 + 5B
      ce = c + (mn / 20) + (cr / 20) + (mo / 15) + (v / 10) + (ni / 60) + (cu / 20);
    } else {
      // AWS D1.1 simplified: CE = C + Mn/6 + (Cr+Mo+V)/5 + (Ni+Cu)/15
      ce = c + (mn / 6) + ((cr + mo + v) / 5) + ((ni + cu) / 15);
    }

    String weldability;
    String preheat;

    if (ce < 0.35) {
      weldability = 'Excellent weldability - no special precautions needed';
      preheat = 'No preheat required (unless thick section)';
    } else if (ce < 0.45) {
      weldability = 'Good weldability - some precautions may be needed';
      preheat = 'Preheat 200-300\u00B0F for thick sections';
    } else if (ce < 0.55) {
      weldability = 'Fair weldability - precautions required';
      preheat = 'Preheat 300-400\u00B0F, use low hydrogen';
    } else {
      weldability = 'Poor weldability - strict procedures required';
      preheat = 'Preheat 400-500\u00B0F, low H2, PWHT may be needed';
    }

    setState(() {
      _ce = ce;
      _weldability = weldability;
      _preheatRecommendation = preheat;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _carbonController.clear();
    _manganeseController.text = '0';
    _chromiumController.text = '0';
    _molybdenumController.text = '0';
    _vanadiumController.text = '0';
    _nickelController.text = '0';
    _copperController.text = '0';
    setState(() { _ce = null; });
  }

  @override
  void dispose() {
    _carbonController.dispose();
    _manganeseController.dispose();
    _chromiumController.dispose();
    _molybdenumController.dispose();
    _vanadiumController.dispose();
    _nickelController.dispose();
    _copperController.dispose();
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
        title: Text('Carbon Equivalent', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildFormulaSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Carbon (C)', unit: '%', hint: 'Required', controller: _carbonController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Mn', unit: '%', hint: '0', controller: _manganeseController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Cr', unit: '%', hint: '0', controller: _chromiumController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Mo', unit: '%', hint: '0', controller: _molybdenumController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'V', unit: '%', hint: '0', controller: _vanadiumController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Ni', unit: '%', hint: '0', controller: _nickelController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Cu', unit: '%', hint: '0', controller: _copperController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_ce != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormulaSelector(ZaftoColors colors) {
    final formulas = ['IIW', 'Pcm', 'AWS'];
    return Wrap(
      spacing: 8,
      children: formulas.map((f) => ChoiceChip(
        label: Text(f),
        selected: _formula == f,
        onSelected: (_) => setState(() { _formula = f; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('CE = C + Mn/6 + (Cr+Mo+V)/5 + (Ni+Cu)/15', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 12)),
        const SizedBox(height: 8),
        Text('Assess steel weldability from chemistry', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Carbon Equivalent', '${_ce!.toStringAsFixed(3)}', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_weldability!, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
              const SizedBox(height: 8),
              Text(_preheatRecommendation!, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 28 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
