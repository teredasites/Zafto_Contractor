import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Carport Sizing Calculator - Solar carport design
class CarportSizingScreen extends ConsumerStatefulWidget {
  const CarportSizingScreen({super.key});
  @override
  ConsumerState<CarportSizingScreen> createState() => _CarportSizingScreenState();
}

class _CarportSizingScreenState extends ConsumerState<CarportSizingScreen> {
  final _parkingSpacesController = TextEditingController(text: '10');
  final _spaceWidthController = TextEditingController(text: '9');
  final _spaceLengthController = TextEditingController(text: '18');
  final _clearanceController = TextEditingController(text: '14');
  final _tiltAngleController = TextEditingController(text: '5');

  String _configuration = 'Single Row';
  String _orientation = 'North-South';

  int? _panelCount;
  double? _systemSize;
  double? _canopyArea;
  double? _steelWeight;
  double? _estimatedCost;
  String? _recommendation;

  @override
  void dispose() {
    _parkingSpacesController.dispose();
    _spaceWidthController.dispose();
    _spaceLengthController.dispose();
    _clearanceController.dispose();
    _tiltAngleController.dispose();
    super.dispose();
  }

  void _calculate() {
    final parkingSpaces = int.tryParse(_parkingSpacesController.text);
    final spaceWidth = double.tryParse(_spaceWidthController.text);
    final spaceLength = double.tryParse(_spaceLengthController.text);
    final clearance = double.tryParse(_clearanceController.text);
    final tiltAngle = double.tryParse(_tiltAngleController.text);

    if (parkingSpaces == null || spaceWidth == null || spaceLength == null ||
        clearance == null || tiltAngle == null) {
      setState(() {
        _panelCount = null;
        _systemSize = null;
        _canopyArea = null;
        _steelWeight = null;
        _estimatedCost = null;
        _recommendation = null;
      });
      return;
    }

    // Canopy dimensions based on configuration
    double canopyWidth;
    double canopyLength;
    int rows;

    switch (_configuration) {
      case 'Single Row':
        canopyWidth = spaceLength;
        canopyLength = spaceWidth * parkingSpaces;
        rows = 1;
        break;
      case 'Double Row':
        canopyWidth = spaceLength * 2 + 2; // 2' drive aisle
        canopyLength = spaceWidth * (parkingSpaces / 2).ceil();
        rows = 2;
        break;
      case 'T-Structure':
        canopyWidth = spaceLength * 2;
        canopyLength = spaceWidth * (parkingSpaces / 2).ceil();
        rows = 2;
        break;
      default:
        canopyWidth = spaceLength;
        canopyLength = spaceWidth * parkingSpaces;
        rows = 1;
    }

    // Canopy area
    final canopyArea = canopyWidth * canopyLength;

    // Panel sizing
    // Standard panel ~77" x 40" = 21.4 sq ft
    // Account for gaps and framing (~85% coverage)
    const panelAreaSqFt = 21.4;
    const coverageRatio = 0.85;
    final panelCount = (canopyArea * coverageRatio / panelAreaSqFt).floor();

    // System size (assuming 400W panels)
    const wattsPerPanel = 400;
    final systemSize = (panelCount * wattsPerPanel) / 1000; // kW

    // Steel weight estimate
    // Typical carport: 3-5 lbs/sqft for structure
    final steelWeight = canopyArea * 4;

    // Cost estimate
    // Carport solar typically $3.50-5.00/W installed
    final estimatedCost = systemSize * 4000;

    String recommendation;
    if (clearance < 10) {
      recommendation = 'Warning: Minimum clearance for vehicles is typically 10 ft.';
    } else if (systemSize / parkingSpaces < 3) {
      recommendation = 'Good density: ~${(systemSize / parkingSpaces).toStringAsFixed(1)} kW per space.';
    } else if (systemSize / parkingSpaces < 5) {
      recommendation = 'Excellent coverage: ~${(systemSize / parkingSpaces).toStringAsFixed(1)} kW per space.';
    } else {
      recommendation = 'High density system. Verify structural requirements.';
    }

    setState(() {
      _panelCount = panelCount;
      _systemSize = systemSize;
      _canopyArea = canopyArea;
      _steelWeight = steelWeight;
      _estimatedCost = estimatedCost;
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
    _parkingSpacesController.text = '10';
    _spaceWidthController.text = '9';
    _spaceLengthController.text = '18';
    _clearanceController.text = '14';
    _tiltAngleController.text = '5';
    setState(() {
      _configuration = 'Single Row';
      _orientation = 'North-South';
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
        title: Text('Carport Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CONFIGURATION'),
              const SizedBox(height: 12),
              _buildConfigSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PARKING'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Parking Spaces',
                      unit: 'qty',
                      hint: 'Total',
                      controller: _parkingSpacesController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Space Width',
                      unit: 'ft',
                      hint: '9\' std',
                      controller: _spaceWidthController,
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
                      label: 'Space Length',
                      unit: 'ft',
                      hint: '18\' std',
                      controller: _spaceLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Clearance',
                      unit: 'ft',
                      hint: '14\' min',
                      controller: _clearanceController,
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
                      label: 'Tilt Angle',
                      unit: 'deg',
                      hint: '5-10',
                      controller: _tiltAngleController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildOrientationSelector(colors)),
                ],
              ),
              const SizedBox(height: 32),
              if (_systemSize != null) ...[
                _buildSectionHeader(colors, 'CARPORT DESIGN'),
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
              Icon(LucideIcons.car, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Solar Carport Sizing',
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
            'Design solar canopy for parking areas',
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

  Widget _buildConfigSelector(ZaftoColors colors) {
    final configs = ['Single Row', 'Double Row', 'T-Structure'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: configs.map((config) {
          final isSelected = _configuration == config;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _configuration = config);
                _calculate();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    config,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrientationSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _orientation,
          isExpanded: true,
          dropdownColor: colors.bgElevated,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          icon: Icon(LucideIcons.chevronDown, color: colors.textSecondary, size: 18),
          items: ['North-South', 'East-West'].map((orient) {
            return DropdownMenuItem(value: orient, child: Text(orient));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.selectionClick();
              setState(() => _orientation = value);
              _calculate();
            }
          },
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
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('System Size', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _systemSize!.toStringAsFixed(1),
                style: TextStyle(color: colors.accentSuccess, fontSize: 48, fontWeight: FontWeight.w700),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  ' kW DC',
                  style: TextStyle(color: colors.textSecondary, fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(colors, 'Panels', '$_panelCount', colors.accentPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatTile(colors, 'Canopy Area', '${_canopyArea!.toStringAsFixed(0)} sq ft', colors.accentInfo),
              ),
            ],
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
                _buildResultRow(colors, 'Est. Steel Weight', '${(_steelWeight! / 1000).toStringAsFixed(1)} tons'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Est. Cost', '\$${(_estimatedCost! / 1000).toStringAsFixed(0)}k'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'kW per Space', '${(_systemSize! / int.parse(_parkingSpacesController.text)).toStringAsFixed(1)} kW'),
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

  Widget _buildStatTile(ZaftoColors colors, String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
