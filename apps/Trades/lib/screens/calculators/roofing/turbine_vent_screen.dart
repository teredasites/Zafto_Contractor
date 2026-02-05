import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Turbine Vent Calculator - Calculate wind-powered turbine ventilation
class TurbineVentScreen extends ConsumerStatefulWidget {
  const TurbineVentScreen({super.key});
  @override
  ConsumerState<TurbineVentScreen> createState() => _TurbineVentScreenState();
}

class _TurbineVentScreenState extends ConsumerState<TurbineVentScreen> {
  final _atticAreaController = TextEditingController(text: '1500');

  String _turbineSize = '12"';
  String _windCondition = 'Moderate';

  double? _nfaRequired;
  int? _turbinesNeeded;
  double? _cfmCapacity;

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
        _turbinesNeeded = null;
        _cfmCapacity = null;
      });
      return;
    }

    // NFA required at 1:150 ratio
    final nfaRequired = atticArea / 150 * 144; // in sq inches

    // Turbine CFM ratings (at various wind speeds)
    // 12" turbine: ~300 CFM at 5 mph, ~700 CFM at 15 mph
    // 14" turbine: ~400 CFM at 5 mph, ~900 CFM at 15 mph
    double cfmPerTurbine;
    double nfaPerTurbine;

    switch (_turbineSize) {
      case '12"':
        cfmPerTurbine = _windCondition == 'High' ? 700 : (_windCondition == 'Moderate' ? 500 : 300);
        nfaPerTurbine = 95;
        break;
      case '14"':
        cfmPerTurbine = _windCondition == 'High' ? 900 : (_windCondition == 'Moderate' ? 650 : 400);
        nfaPerTurbine = 130;
        break;
      default:
        cfmPerTurbine = 500;
        nfaPerTurbine = 95;
    }

    // Calculate turbines needed
    final turbinesNeeded = (nfaRequired / nfaPerTurbine).ceil();
    final cfmCapacity = turbinesNeeded * cfmPerTurbine;

    setState(() {
      _nfaRequired = nfaRequired;
      _turbinesNeeded = turbinesNeeded;
      _cfmCapacity = cfmCapacity;
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
      _turbineSize = '12"';
      _windCondition = 'Moderate';
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
        title: Text('Turbine Vent', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'TURBINE SIZE'),
              const SizedBox(height: 12),
              _buildSizeSelector(colors),
              const SizedBox(height: 12),
              _buildWindSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ATTIC AREA'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Attic Floor Area',
                unit: 'sq ft',
                hint: 'Total attic space',
                controller: _atticAreaController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_turbinesNeeded != null) ...[
                _buildSectionHeader(colors, 'TURBINE REQUIREMENTS'),
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
                'Turbine Vent Calculator',
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
            'Calculate wind-powered turbine ventilation',
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

  Widget _buildSizeSelector(ZaftoColors colors) {
    final sizes = ['12"', '14"'];
    return Row(
      children: sizes.map((size) {
        final isSelected = _turbineSize == size;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _turbineSize = size);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: size != sizes.last ? 8 : 0),
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
                    size,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    size == '12"' ? 'Standard' : 'Large',
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

  Widget _buildWindSelector(ZaftoColors colors) {
    final conditions = ['Low', 'Moderate', 'High'];
    return Row(
      children: conditions.map((cond) {
        final isSelected = _windCondition == cond;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _windCondition = cond);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: cond != conditions.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                    cond,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    cond == 'Low' ? '<5 mph' : (cond == 'Moderate' ? '5-10 mph' : '>10 mph'),
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : colors.textTertiary,
                      fontSize: 10,
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
          _buildResultRow(colors, 'NFA Required', '${_nfaRequired!.toStringAsFixed(0)} sq in'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TURBINES NEEDED', '$_turbinesNeeded', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Total CFM Capacity', '${_cfmCapacity!.toStringAsFixed(0)}'),
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
                    Text('Turbine Tips', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Install near ridge for best performance', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Requires adequate soffit intake vents', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('No electricity needed - wind powered', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
            fontSize: isHighlighted ? 20 : 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
