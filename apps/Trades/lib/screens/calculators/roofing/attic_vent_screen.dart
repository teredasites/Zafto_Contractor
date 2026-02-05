import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Attic Vent Calculator - Calculate required attic ventilation
class AtticVentScreen extends ConsumerStatefulWidget {
  const AtticVentScreen({super.key});
  @override
  ConsumerState<AtticVentScreen> createState() => _AtticVentScreenState();
}

class _AtticVentScreenState extends ConsumerState<AtticVentScreen> {
  final _atticAreaController = TextEditingController(text: '1500');

  String _ventRatio = '1:150';
  bool _hasVaporBarrier = false;

  double? _nfaRequired;
  double? _intakeNFA;
  double? _exhaustNFA;
  int? _soffitVents;
  int? _ridgeVentFeet;

  @override
  void dispose() {
    _atticAreaController.dispose();
    super.dispose();
  }

  void _calculate() {
    final atticArea = double.tryParse(_atticAreaController.text);

    if (atticArea == null) {
      setState(() {
        _nfaRequired = null;
        _intakeNFA = null;
        _exhaustNFA = null;
        _soffitVents = null;
        _ridgeVentFeet = null;
      });
      return;
    }

    // Calculate required NFA based on ratio
    double nfaRequired;
    if (_ventRatio == '1:150' && !_hasVaporBarrier) {
      nfaRequired = atticArea / 150;
    } else {
      // 1:300 with vapor barrier or balanced ventilation
      nfaRequired = atticArea / 300;
    }

    // 50/50 split between intake and exhaust
    final intakeNFA = nfaRequired / 2;
    final exhaustNFA = nfaRequired / 2;

    // Convert to practical quantities
    // Soffit vents: typical 8"×16" = 65 sq in NFA each
    final soffitVents = (intakeNFA * 144 / 65).ceil(); // Convert sq ft to sq in

    // Ridge vent: typical 18 sq in NFA per linear foot
    final ridgeVentFeet = (exhaustNFA * 144 / 18).ceil();

    setState(() {
      _nfaRequired = nfaRequired;
      _intakeNFA = intakeNFA;
      _exhaustNFA = exhaustNFA;
      _soffitVents = soffitVents;
      _ridgeVentFeet = ridgeVentFeet;
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
    setState(() {
      _ventRatio = '1:150';
      _hasVaporBarrier = false;
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
        title: Text('Attic Ventilation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ATTIC SPECIFICATIONS'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Attic Floor Area',
                unit: 'sq ft',
                hint: 'Ceiling area below',
                controller: _atticAreaController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'VENTILATION REQUIREMENTS'),
              const SizedBox(height: 12),
              _buildRatioSelector(colors),
              const SizedBox(height: 12),
              _buildVaporBarrierToggle(colors),
              const SizedBox(height: 32),
              if (_nfaRequired != null) ...[
                _buildSectionHeader(colors, 'VENTILATION REQUIRED'),
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
              Icon(LucideIcons.wind, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Attic Vent Calculator',
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
            'Calculate required Net Free Area (NFA)',
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

  Widget _buildRatioSelector(ZaftoColors colors) {
    final ratios = ['1:150', '1:300'];
    return Row(
      children: ratios.map((ratio) {
        final isSelected = _ventRatio == ratio;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _ventRatio = ratio);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: ratio != ratios.last ? 12 : 0),
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
                  Text(
                    ratio,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    ratio == '1:150' ? 'Standard' : 'With Vapor Barrier',
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : colors.textTertiary,
                      fontSize: 11,
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

  Widget _buildVaporBarrierToggle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vapor Barrier Present', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
              Text('Reduces required ventilation', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            ],
          ),
          Switch(
            value: _hasVaporBarrier,
            activeColor: colors.accentPrimary,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _hasVaporBarrier = value);
              _calculate();
            },
          ),
        ],
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
          _buildResultRow(colors, 'TOTAL NFA REQUIRED', '${_nfaRequired!.toStringAsFixed(1)} sq ft', isHighlighted: true),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Icon(LucideIcons.arrowDownToLine, color: colors.accentInfo, size: 20),
                          const SizedBox(height: 4),
                          Text('Intake', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                          Text('${_intakeNFA!.toStringAsFixed(2)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 50, color: colors.borderSubtle),
                    Expanded(
                      child: Column(
                        children: [
                          Icon(LucideIcons.arrowUpFromLine, color: colors.accentWarning, size: 20),
                          const SizedBox(height: 4),
                          Text('Exhaust', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                          Text('${_exhaustNFA!.toStringAsFixed(2)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildSectionHeader(colors, 'PRACTICAL SOLUTION'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Soffit Vents (8"×16")', '$_soffitVents vents'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Ridge Vent', '$_ridgeVentFeet lin ft'),
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
                    'Balanced 50/50 intake/exhaust provides best airflow. Never mix ridge vents with power vents.',
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
