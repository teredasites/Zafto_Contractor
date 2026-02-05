import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Ventilation Setbacks Calculator - HVAC and vent clearances
class VentilationSetbacksScreen extends ConsumerStatefulWidget {
  const VentilationSetbacksScreen({super.key});
  @override
  ConsumerState<VentilationSetbacksScreen> createState() => _VentilationSetbacksScreenState();
}

class _VentilationSetbacksScreenState extends ConsumerState<VentilationSetbacksScreen> {
  final _exhaustDiameterController = TextEditingController(text: '4');
  final _combustionDiameterController = TextEditingController(text: '6');
  final _hvacUnitWidthController = TextEditingController(text: '36');

  bool _hasExhaustVent = true;
  bool _hasCombustionVent = true;
  bool _hasHvacUnit = true;
  bool _hasSkylight = false;

  Map<String, double>? _setbacks;
  double? _totalExclusionArea;
  String? _recommendation;

  @override
  void dispose() {
    _exhaustDiameterController.dispose();
    _combustionDiameterController.dispose();
    _hvacUnitWidthController.dispose();
    super.dispose();
  }

  void _calculate() {
    final exhaustDiameter = double.tryParse(_exhaustDiameterController.text);
    final combustionDiameter = double.tryParse(_combustionDiameterController.text);
    final hvacUnitWidth = double.tryParse(_hvacUnitWidthController.text);

    if (exhaustDiameter == null || combustionDiameter == null || hvacUnitWidth == null) {
      setState(() {
        _setbacks = null;
        _totalExclusionArea = null;
        _recommendation = null;
      });
      return;
    }

    Map<String, double> setbacks = {};
    double totalArea = 0;

    // Exhaust vent setbacks (plumbing vents, kitchen exhaust)
    // Typically 18" clearance minimum
    if (_hasExhaustVent) {
      final setback = 18.0; // inches
      setbacks['Exhaust Vent'] = setback;
      // Circular exclusion zone
      final radius = (exhaustDiameter / 2 + setback) / 12; // convert to feet
      totalArea += 3.14159 * radius * radius;
    }

    // Combustion vent setbacks (furnace, water heater)
    // IRC requires 3 ft clearance for Type B vents
    if (_hasCombustionVent) {
      final setback = 36.0; // inches (3 ft)
      setbacks['Combustion Vent'] = setback;
      final radius = (combustionDiameter / 2 + setback) / 12;
      totalArea += 3.14159 * radius * radius;
    }

    // HVAC unit setbacks
    // Typically 3 ft service clearance all sides
    if (_hasHvacUnit) {
      final setback = 36.0; // inches
      setbacks['HVAC Unit'] = setback;
      final unitSize = hvacUnitWidth / 12; // feet
      totalArea += (unitSize + 6) * (unitSize + 6); // 3 ft clearance each side
    }

    // Skylight setbacks
    // Typically 18" for maintenance access
    if (_hasSkylight) {
      const setback = 18.0;
      setbacks['Skylight'] = setback;
      totalArea += 16; // Assume 4x4 exclusion zone
    }

    String recommendation;
    if (totalArea > 100) {
      recommendation = 'Significant roof obstructions. Careful array layout needed.';
    } else if (totalArea > 50) {
      recommendation = 'Moderate obstructions. Plan panel layout around equipment.';
    } else if (totalArea > 20) {
      recommendation = 'Minor obstructions. Standard installation practices apply.';
    } else {
      recommendation = 'Minimal obstructions. Array layout should be straightforward.';
    }

    setState(() {
      _setbacks = setbacks;
      _totalExclusionArea = totalArea;
      _recommendation = recommendation;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _exhaustDiameterController.text = '4';
    _combustionDiameterController.text = '6';
    _hvacUnitWidthController.text = '36';
    setState(() {
      _hasExhaustVent = true;
      _hasCombustionVent = true;
      _hasHvacUnit = true;
      _hasSkylight = false;
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
        title: Text('Ventilation Setbacks', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ROOF EQUIPMENT'),
              const SizedBox(height: 12),
              _buildEquipmentToggle(colors, 'Exhaust Vent', 'Plumbing, kitchen exhaust', _hasExhaustVent, (v) {
                setState(() => _hasExhaustVent = v);
                _calculate();
              }),
              if (_hasExhaustVent) ...[
                const SizedBox(height: 12),
                ZaftoInputField(
                  label: 'Exhaust Vent Diameter',
                  unit: 'in',
                  hint: 'Pipe diameter',
                  controller: _exhaustDiameterController,
                  onChanged: (_) => _calculate(),
                ),
              ],
              const SizedBox(height: 12),
              _buildEquipmentToggle(colors, 'Combustion Vent', 'Furnace, water heater', _hasCombustionVent, (v) {
                setState(() => _hasCombustionVent = v);
                _calculate();
              }),
              if (_hasCombustionVent) ...[
                const SizedBox(height: 12),
                ZaftoInputField(
                  label: 'Combustion Vent Diameter',
                  unit: 'in',
                  hint: 'B-vent diameter',
                  controller: _combustionDiameterController,
                  onChanged: (_) => _calculate(),
                ),
              ],
              const SizedBox(height: 12),
              _buildEquipmentToggle(colors, 'HVAC Unit', 'Rooftop condenser/package unit', _hasHvacUnit, (v) {
                setState(() => _hasHvacUnit = v);
                _calculate();
              }),
              if (_hasHvacUnit) ...[
                const SizedBox(height: 12),
                ZaftoInputField(
                  label: 'HVAC Unit Width',
                  unit: 'in',
                  hint: 'Largest dimension',
                  controller: _hvacUnitWidthController,
                  onChanged: (_) => _calculate(),
                ),
              ],
              const SizedBox(height: 12),
              _buildEquipmentToggle(colors, 'Skylight', 'Operable or fixed', _hasSkylight, (v) {
                setState(() => _hasSkylight = v);
                _calculate();
              }),
              const SizedBox(height: 32),
              if (_setbacks != null) ...[
                _buildSectionHeader(colors, 'SETBACK REQUIREMENTS'),
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
                'Ventilation Setbacks',
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
            'Calculate clearances from vents and HVAC equipment',
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

  Widget _buildEquipmentToggle(ZaftoColors colors, String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? colors.accentPrimary.withValues(alpha: 0.3) : colors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
            activeColor: colors.accentPrimary,
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
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('Total Exclusion Area', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                Text(
                  '${_totalExclusionArea!.toStringAsFixed(0)} sq ft',
                  style: TextStyle(color: colors.accentInfo, fontSize: 36, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('REQUIRED SETBACKS', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 12),
                ..._setbacks!.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.arrowRight, size: 14, color: colors.accentPrimary),
                          const SizedBox(width: 8),
                          Text(entry.key, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                        ],
                      ),
                      Text('${entry.value.toStringAsFixed(0)}"', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
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
                    _recommendation!,
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

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.accentWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.bookOpen, size: 14, color: colors.accentWarning),
              const SizedBox(width: 8),
              Text('CODE REFERENCES', style: TextStyle(color: colors.accentWarning, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
          Text('IRC G2427.6: 3 ft from Type B vents', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          Text('IMC 401.4: 10 ft from intake vents', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          Text('NFPA 70: 3 ft service clearance', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
