import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Ice & Water Shield Calculator - Calculate ice dam protection underlayment
class IceWaterShieldScreen extends ConsumerStatefulWidget {
  const IceWaterShieldScreen({super.key});
  @override
  ConsumerState<IceWaterShieldScreen> createState() => _IceWaterShieldScreenState();
}

class _IceWaterShieldScreenState extends ConsumerState<IceWaterShieldScreen> {
  final _eaveLengthController = TextEditingController(text: '150');
  final _eaveWidthController = TextEditingController(text: '3');
  final _valleyLengthController = TextEditingController(text: '40');

  bool _includeValleys = true;
  bool _includeRake = false;

  double? _eaveArea;
  double? _valleyArea;
  double? _totalArea;
  int? _rollsNeeded;

  @override
  void dispose() {
    _eaveLengthController.dispose();
    _eaveWidthController.dispose();
    _valleyLengthController.dispose();
    super.dispose();
  }

  void _calculate() {
    final eaveLength = double.tryParse(_eaveLengthController.text);
    final eaveWidth = double.tryParse(_eaveWidthController.text);
    final valleyLength = double.tryParse(_valleyLengthController.text);

    if (eaveLength == null || eaveWidth == null || valleyLength == null) {
      setState(() {
        _eaveArea = null;
        _valleyArea = null;
        _totalArea = null;
        _rollsNeeded = null;
      });
      return;
    }

    // Eave coverage area
    final eaveArea = eaveLength * eaveWidth;

    // Valley coverage (3' wide typical)
    double valleyArea = 0;
    if (_includeValleys) {
      valleyArea = valleyLength * 3;
    }

    // Rake edges (if included, estimate 20% of eave length)
    double rakeArea = 0;
    if (_includeRake) {
      rakeArea = eaveLength * 0.2 * 3; // 3' wide
    }

    final totalArea = (eaveArea + valleyArea + rakeArea) * 1.1; // 10% waste

    // Roll coverage: typically 36" × 75' = 225 sq ft, or 36" × 66.6' = 200 sq ft
    final rollCoverage = 200.0;
    final rollsNeeded = (totalArea / rollCoverage).ceil();

    setState(() {
      _eaveArea = eaveArea;
      _valleyArea = valleyArea + rakeArea;
      _totalArea = totalArea;
      _rollsNeeded = rollsNeeded;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _eaveLengthController.text = '150';
    _eaveWidthController.text = '3';
    _valleyLengthController.text = '40';
    setState(() {
      _includeValleys = true;
      _includeRake = false;
    });
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
        title: Text('Ice & Water Shield', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'COVERAGE AREAS'),
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
                      label: 'Width Up',
                      unit: 'ft',
                      hint: '2-3 ft typical',
                      controller: _eaveWidthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Valley Length',
                unit: 'ft',
                hint: 'All valleys',
                controller: _valleyLengthController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 16),
              _buildToggle(colors, 'Include Valleys', _includeValleys, (val) {
                setState(() => _includeValleys = val);
                _calculate();
              }),
              const SizedBox(height: 8),
              _buildToggle(colors, 'Include Rake Edges', _includeRake, (val) {
                setState(() => _includeRake = val);
                _calculate();
              }),
              const SizedBox(height: 32),
              if (_rollsNeeded != null) ...[
                _buildSectionHeader(colors, 'MATERIALS NEEDED'),
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
              Icon(LucideIcons.snowflake, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Ice & Water Shield Calculator',
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
            'Calculate self-adhered underlayment',
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

  Widget _buildToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
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
              value ? LucideIcons.checkSquare : LucideIcons.square,
              color: value ? colors.accentPrimary : colors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
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
          _buildResultRow(colors, 'Eave Area', '${_eaveArea!.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Valley/Rake Area', '${_valleyArea!.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL AREA', '${_totalArea!.toStringAsFixed(0)} sq ft', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'ROLLS NEEDED', '$_rollsNeeded', isHighlighted: true),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.info, size: 16, color: colors.accentInfo),
                    const SizedBox(width: 8),
                    Text('Code Requirements', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('IRC: 24" past interior wall line', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Typically 3\' up from eave', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Required in snow regions', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
