import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Charge Controller Sizing Calculator - Off-grid systems
class ChargeControllerSizingScreen extends ConsumerStatefulWidget {
  const ChargeControllerSizingScreen({super.key});
  @override
  ConsumerState<ChargeControllerSizingScreen> createState() => _ChargeControllerSizingScreenState();
}

class _ChargeControllerSizingScreenState extends ConsumerState<ChargeControllerSizingScreen> {
  final _arrayWattsController = TextEditingController(text: '1000');
  final _batteryVoltageController = TextEditingController(text: '48');
  final _arrayVocController = TextEditingController(text: '45');
  final _arrayIscController = TextEditingController(text: '10.8');
  final _modulesSeriesController = TextEditingController(text: '2');
  final _stringsController = TextEditingController(text: '2');

  String _controllerType = 'MPPT';

  double? _minAmps;
  double? _maxInputVoltage;
  double? _arrayVocTotal;
  String? _recommendation;

  @override
  void dispose() {
    _arrayWattsController.dispose();
    _batteryVoltageController.dispose();
    _arrayVocController.dispose();
    _arrayIscController.dispose();
    _modulesSeriesController.dispose();
    _stringsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final arrayWatts = double.tryParse(_arrayWattsController.text);
    final batteryVoltage = double.tryParse(_batteryVoltageController.text);
    final arrayVoc = double.tryParse(_arrayVocController.text);
    final arrayIsc = double.tryParse(_arrayIscController.text);
    final modulesSeries = int.tryParse(_modulesSeriesController.text);
    final strings = int.tryParse(_stringsController.text);

    if (arrayWatts == null || batteryVoltage == null || arrayVoc == null ||
        arrayIsc == null || modulesSeries == null || strings == null || batteryVoltage == 0) {
      setState(() {
        _minAmps = null;
        _maxInputVoltage = null;
        _arrayVocTotal = null;
        _recommendation = null;
      });
      return;
    }

    // Calculate minimum controller amps
    double minAmps;
    if (_controllerType == 'MPPT') {
      // MPPT: P / Vbat (plus 25% safety)
      minAmps = (arrayWatts / batteryVoltage) * 1.25;
    } else {
      // PWM: Isc × strings × 1.25
      minAmps = arrayIsc * strings * 1.25;
    }

    // Max input voltage (cold weather adjustment)
    final arrayVocTotal = arrayVoc * modulesSeries * 1.14; // 14% temp correction

    String recommendation;
    if (_controllerType == 'MPPT') {
      if (minAmps <= 30) {
        recommendation = 'Small MPPT (30A) - Victron SmartSolar, Epever, etc.';
      } else if (minAmps <= 60) {
        recommendation = 'Medium MPPT (60A) - Victron, Outback, Morningstar.';
      } else if (minAmps <= 100) {
        recommendation = 'Large MPPT (100A) - Consider multiple controllers.';
      } else {
        recommendation = 'Very large system - multiple MPPT controllers needed.';
      }
    } else {
      if (minAmps <= 30) {
        recommendation = 'PWM controller suitable for small systems.';
      } else {
        recommendation = 'Consider MPPT for better efficiency at this size.';
      }
    }

    setState(() {
      _minAmps = minAmps;
      _maxInputVoltage = arrayVocTotal;
      _arrayVocTotal = arrayVocTotal;
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
    _arrayWattsController.text = '1000';
    _batteryVoltageController.text = '48';
    _arrayVocController.text = '45';
    _arrayIscController.text = '10.8';
    _modulesSeriesController.text = '2';
    _stringsController.text = '2';
    setState(() => _controllerType = 'MPPT');
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
        title: Text('Charge Controller', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CONTROLLER TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ARRAY & BATTERY'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Array Watts',
                      unit: 'W',
                      hint: 'Total DC',
                      controller: _arrayWattsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Battery Bank',
                      unit: 'V',
                      hint: '12/24/48',
                      controller: _batteryVoltageController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Module Voc',
                      unit: 'V',
                      hint: 'Open circuit',
                      controller: _arrayVocController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Modules Series',
                      unit: '#',
                      hint: 'Per string',
                      controller: _modulesSeriesController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_minAmps != null) ...[
                _buildSectionHeader(colors, 'CONTROLLER SIZING'),
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
              Icon(LucideIcons.gauge, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Charge Controller Sizing',
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
            'Size MPPT or PWM controller for off-grid systems',
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
    final types = ['MPPT', 'PWM'];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: types.map((type) {
          final isSelected = _controllerType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _controllerType = type);
                _calculate();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    Text(
                      type == 'MPPT' ? 'Higher efficiency' : 'Budget option',
                      style: TextStyle(
                        color: isSelected ? (colors.isDark ? Colors.black : Colors.white).withValues(alpha: 0.7) : colors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Minimum Controller Rating', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${_minAmps!.toStringAsFixed(0)}A',
            style: TextStyle(color: colors.accentSuccess, fontSize: 48, fontWeight: FontWeight.w700),
          ),
          Text(
            '$_controllerType controller',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Max Input Voltage', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    Text('${_maxInputVoltage!.toStringAsFixed(0)}V (with temp correction)',
                        style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
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
                Icon(LucideIcons.lightbulb, size: 16, color: colors.accentInfo),
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
}
