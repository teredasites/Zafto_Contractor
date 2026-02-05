import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Power Vent Calculator - Calculate powered attic ventilation
class PowerVentScreen extends ConsumerStatefulWidget {
  const PowerVentScreen({super.key});
  @override
  ConsumerState<PowerVentScreen> createState() => _PowerVentScreenState();
}

class _PowerVentScreenState extends ConsumerState<PowerVentScreen> {
  final _atticAreaController = TextEditingController(text: '1500');
  final _atticHeightController = TextEditingController(text: '8');

  String _roofColor = 'Medium';
  String _climate = 'Moderate';

  double? _cubicFeet;
  int? _cfmRequired;
  int? _ventsNeeded;
  double? _intakeNfa;

  @override
  void dispose() {
    _atticAreaController.dispose();
    _atticHeightController.dispose();
    super.dispose();
  }

  void _calculate() {
    final atticArea = double.tryParse(_atticAreaController.text);
    final atticHeight = double.tryParse(_atticHeightController.text);

    if (atticArea == null || atticHeight == null) {
      setState(() {
        _cubicFeet = null;
        _cfmRequired = null;
        _ventsNeeded = null;
        _intakeNfa = null;
      });
      return;
    }

    // Attic volume (average height for sloped attic)
    final cubicFeet = atticArea * (atticHeight / 2);

    // Air changes per hour based on climate and roof color
    // Hot climate with dark roof needs more ventilation
    double achMultiplier = 10; // baseline 10 ACH

    if (_climate == 'Hot') {
      achMultiplier += 2;
    } else if (_climate == 'Cool') {
      achMultiplier -= 2;
    }

    if (_roofColor == 'Dark') {
      achMultiplier += 2;
    } else if (_roofColor == 'Light') {
      achMultiplier -= 1;
    }

    // CFM = (cubic feet × ACH) / 60
    final cfmRequired = (cubicFeet * achMultiplier / 60).ceil();

    // Standard power vents: 1000-1600 CFM
    // Using 1200 CFM as typical
    final ventsNeeded = (cfmRequired / 1200).ceil();

    // Intake NFA required: 1 sq ft per 300 CFM
    final intakeNfa = cfmRequired / 300 * 144; // in sq inches

    setState(() {
      _cubicFeet = cubicFeet;
      _cfmRequired = cfmRequired;
      _ventsNeeded = ventsNeeded;
      _intakeNfa = intakeNfa;
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
    _atticHeightController.text = '8';
    setState(() {
      _roofColor = 'Medium';
      _climate = 'Moderate';
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
        title: Text('Power Vent', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CONDITIONS'),
              const SizedBox(height: 12),
              _buildRoofColorSelector(colors),
              const SizedBox(height: 12),
              _buildClimateSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ATTIC DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Floor Area',
                      unit: 'sq ft',
                      hint: 'Attic footprint',
                      controller: _atticAreaController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Peak Height',
                      unit: 'ft',
                      hint: 'At ridge',
                      controller: _atticHeightController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_cfmRequired != null) ...[
                _buildSectionHeader(colors, 'VENTILATION REQUIREMENTS'),
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
              Icon(LucideIcons.fan, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Power Vent Calculator',
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
            'Calculate powered attic ventilator sizing',
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

  Widget _buildRoofColorSelector(ZaftoColors colors) {
    final roofColors = ['Light', 'Medium', 'Dark'];
    return Row(
      children: roofColors.map((color) {
        final isSelected = _roofColor == color;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _roofColor = color);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: color != roofColors.last ? 8 : 0),
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
                    color,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Roof',
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

  Widget _buildClimateSelector(ZaftoColors colors) {
    final climates = ['Cool', 'Moderate', 'Hot'];
    return Row(
      children: climates.map((climate) {
        final isSelected = _climate == climate;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _climate = climate);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: climate != climates.last ? 8 : 0),
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
                    climate,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Climate',
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
          _buildResultRow(colors, 'Attic Volume', '${_cubicFeet!.toStringAsFixed(0)} cu ft'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'CFM REQUIRED', '$_cfmRequired', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'POWER VENTS', '$_ventsNeeded', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Intake NFA Needed', '${_intakeNfa!.toStringAsFixed(0)} sq in'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, size: 16, color: colors.accentWarning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ensure adequate intake vents (soffit). Insufficient intake causes negative pressure issues.',
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
