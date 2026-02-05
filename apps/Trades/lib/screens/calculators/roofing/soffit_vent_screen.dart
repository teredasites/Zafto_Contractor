import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Soffit Vent Calculator - Calculate soffit intake ventilation
class SoffitVentScreen extends ConsumerStatefulWidget {
  const SoffitVentScreen({super.key});
  @override
  ConsumerState<SoffitVentScreen> createState() => _SoffitVentScreenState();
}

class _SoffitVentScreenState extends ConsumerState<SoffitVentScreen> {
  final _atticAreaController = TextEditingController(text: '1500');
  final _soffitLengthController = TextEditingController(text: '120');

  String _ventType = 'Individual';

  double? _nfaRequired;
  int? _individualVents;
  double? _continuousVent;
  double? _nfaPerFoot;

  @override
  void dispose() {
    _atticAreaController.dispose();
    _soffitLengthController.dispose();
    super.dispose();
  }

  void _calculate() {
    final atticArea = double.tryParse(_atticAreaController.text);
    final soffitLength = double.tryParse(_soffitLengthController.text);

    if (atticArea == null || soffitLength == null) {
      setState(() {
        _nfaRequired = null;
        _individualVents = null;
        _continuousVent = null;
        _nfaPerFoot = null;
      });
      return;
    }

    // Total NFA required (1:300 ratio, 50% intake)
    // Intake NFA = attic area / 300 / 2
    final nfaRequired = atticArea / 300 / 2; // in sq ft

    // Convert to sq inches for vent sizing
    final nfaRequiredSqIn = nfaRequired * 144;

    // Individual vents: typical 8"×16" = ~65 sq in NFA each
    final individualVents = (nfaRequiredSqIn / 65).ceil();

    // Continuous soffit vent: ~9 sq in NFA per linear foot
    final continuousVent = nfaRequiredSqIn / 9;

    // NFA per foot of soffit (what's available)
    final nfaPerFoot = nfaRequiredSqIn / soffitLength;

    setState(() {
      _nfaRequired = nfaRequired;
      _individualVents = individualVents;
      _continuousVent = continuousVent;
      _nfaPerFoot = nfaPerFoot;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _atticAreaController.text = '1500';
    _soffitLengthController.text = '120';
    setState(() => _ventType = 'Individual');
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
        title: Text('Soffit Vents', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ATTIC & SOFFIT'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Attic Area',
                      unit: 'sq ft',
                      hint: 'Floor area',
                      controller: _atticAreaController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Soffit Length',
                      unit: 'ft',
                      hint: 'Total perimeter',
                      controller: _soffitLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'VENT TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 32),
              if (_nfaRequired != null) ...[
                _buildSectionHeader(colors, 'INTAKE VENTILATION'),
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
              Icon(LucideIcons.arrowDownToLine, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Soffit Vent Calculator',
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
            'Calculate intake ventilation at soffits',
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

  Widget _buildTypeSelector(ZaftoColors colors) {
    final types = ['Individual', 'Continuous'];
    return Row(
      children: types.map((type) {
        final isSelected = _ventType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _ventType = type);
            },
            child: Container(
              margin: EdgeInsets.only(right: type != types.last ? 12 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    type == 'Individual' ? LucideIcons.layoutGrid : LucideIcons.minus,
                    size: 20,
                    color: isSelected ? Colors.white : colors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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
          _buildResultRow(colors, 'NFA Required (Intake)', '${(_nfaRequired! * 144).toStringAsFixed(0)} sq in'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'NFA per Foot', '${_nfaPerFoot!.toStringAsFixed(1)} sq in/ft'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          if (_ventType == 'Individual') ...[
            _buildResultRow(colors, 'INDIVIDUAL VENTS', '$_individualVents (8"×16")', isHighlighted: true),
            const SizedBox(height: 8),
            Text(
              'Standard 8"×16" vent = ~65 sq in NFA',
              style: TextStyle(color: colors.textTertiary, fontSize: 11),
            ),
          ] else ...[
            _buildResultRow(colors, 'CONTINUOUS VENT', '${_continuousVent!.toStringAsFixed(0)} lin ft', isHighlighted: true),
            const SizedBox(height: 8),
            Text(
              'Standard continuous vent = ~9 sq in NFA per foot',
              style: TextStyle(color: colors.textTertiary, fontSize: 11),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 16, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Intake at soffits should equal or exceed exhaust at ridge for balanced ventilation.',
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
