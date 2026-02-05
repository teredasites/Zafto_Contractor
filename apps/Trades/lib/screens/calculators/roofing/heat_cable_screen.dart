import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Heat Cable Calculator - Calculate roof de-icing heat cable
class HeatCableScreen extends ConsumerStatefulWidget {
  const HeatCableScreen({super.key});
  @override
  ConsumerState<HeatCableScreen> createState() => _HeatCableScreenState();
}

class _HeatCableScreenState extends ConsumerState<HeatCableScreen> {
  final _eaveLengthController = TextEditingController(text: '60');
  final _valleyLengthController = TextEditingController(text: '20');
  final _gutterLengthController = TextEditingController(text: '60');
  final _downspoutsController = TextEditingController(text: '4');
  final _downspoutHeightController = TextEditingController(text: '10');

  bool _includeGutters = true;

  double? _eavePattern;
  double? _valleyLength;
  double? _gutterLength;
  double? _downspoutLength;
  double? _totalLength;
  double? _wattsRequired;

  @override
  void dispose() {
    _eaveLengthController.dispose();
    _valleyLengthController.dispose();
    _gutterLengthController.dispose();
    _downspoutsController.dispose();
    _downspoutHeightController.dispose();
    super.dispose();
  }

  void _calculate() {
    final eaveLength = double.tryParse(_eaveLengthController.text);
    final valleyLength = double.tryParse(_valleyLengthController.text);
    final gutterLength = double.tryParse(_gutterLengthController.text);
    final downspouts = int.tryParse(_downspoutsController.text);
    final downspoutHeight = double.tryParse(_downspoutHeightController.text);

    if (eaveLength == null || valleyLength == null || gutterLength == null ||
        downspouts == null || downspoutHeight == null) {
      setState(() {
        _eavePattern = null;
        _valleyLength = null;
        _gutterLength = null;
        _downspoutLength = null;
        _totalLength = null;
        _wattsRequired = null;
      });
      return;
    }

    // Eave pattern: zigzag pattern typically uses 2-3x the eave length
    // Standard: 12" loops with 18" between peaks
    final eavePattern = eaveLength * 2.5;

    // Valley: run up and back
    final valleyTotal = valleyLength * 2;

    // Gutter length (single run)
    final gutterTotal = _includeGutters ? gutterLength : 0.0;

    // Downspouts (run down and back up)
    final downspoutTotal = _includeGutters ? (downspouts * downspoutHeight * 2) : 0.0;

    final totalLength = eavePattern + valleyTotal + gutterTotal + downspoutTotal;

    // Watts: typically 5-8 watts per linear foot
    final wattsRequired = totalLength * 7; // 7 W/ft average

    setState(() {
      _eavePattern = eavePattern;
      _valleyLength = valleyTotal;
      _gutterLength = gutterTotal;
      _downspoutLength = downspoutTotal;
      _totalLength = totalLength;
      _wattsRequired = wattsRequired;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _eaveLengthController.text = '60';
    _valleyLengthController.text = '20';
    _gutterLengthController.text = '60';
    _downspoutsController.text = '4';
    _downspoutHeightController.text = '10';
    setState(() => _includeGutters = true);
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Heat Cable', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary),
            onPressed: _clearAll,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOF EDGES'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Eave Length',
                      unit: 'ft',
                      hint: 'Total eaves',
                      controller: _eaveLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Valleys',
                      unit: 'ft',
                      hint: 'Total length',
                      controller: _valleyLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildGutterToggle(colors),
              if (_includeGutters) ...[
                const SizedBox(height: 12),
                ZaftoInputField(
                  label: 'Gutter Length',
                  unit: 'ft',
                  hint: 'Total gutters',
                  controller: _gutterLengthController,
                  onChanged: (_) => _calculate(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ZaftoInputField(
                        label: 'Downspouts',
                        unit: 'qty',
                        hint: 'Count',
                        controller: _downspoutsController,
                        onChanged: (_) => _calculate(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ZaftoInputField(
                        label: 'Height',
                        unit: 'ft',
                        hint: 'Each',
                        controller: _downspoutHeightController,
                        onChanged: (_) => _calculate(),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              if (_totalLength != null) ...[
                _buildSectionHeader(colors, 'CABLE REQUIREMENTS'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.thermometer, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Heat Cable Calculator',
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Calculate roof de-icing heat cable length',
            style: TextStyle(color: colors.textTertiary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(
      title,
      style: TextStyle(
        color: colors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildGutterToggle(ZaftoColors colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _includeGutters = !_includeGutters);
        _calculate();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(
              _includeGutters ? LucideIcons.checkSquare : LucideIcons.square,
              color: _includeGutters ? colors.accentPrimary : colors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Include Gutters & Downspouts',
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          _buildResultRow(colors, 'Eave Pattern', '${_eavePattern!.toStringAsFixed(0)} ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Valleys', '${_valleyLength!.toStringAsFixed(0)} ft'),
          if (_includeGutters) ...[
            const SizedBox(height: 8),
            _buildResultRow(colors, 'Gutters', '${_gutterLength!.toStringAsFixed(0)} ft'),
            const SizedBox(height: 8),
            _buildResultRow(colors, 'Downspouts', '${_downspoutLength!.toStringAsFixed(0)} ft'),
          ],
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL CABLE', '${_totalLength!.toStringAsFixed(0)} ft', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Power Required', '${(_wattsRequired! / 1000).toStringAsFixed(1)} kW'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.zap, size: 16, color: colors.accentWarning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ensure adequate electrical circuit capacity. May need dedicated breaker.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: isHighlighted ? colors.accentPrimary : colors.textPrimary,
            fontSize: isHighlighted ? 18 : 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
