import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Roof Load Calculator - Structural load analysis
class RoofLoadCalculatorScreen extends ConsumerStatefulWidget {
  const RoofLoadCalculatorScreen({super.key});
  @override
  ConsumerState<RoofLoadCalculatorScreen> createState() => _RoofLoadCalculatorScreenState();
}

class _RoofLoadCalculatorScreenState extends ConsumerState<RoofLoadCalculatorScreen> {
  final _panelWeightController = TextEditingController(text: '45');
  final _panelAreaController = TextEditingController(text: '21.5');
  final _mountingWeightController = TextEditingController(text: '3');
  final _numPanelsController = TextEditingController(text: '20');
  final _roofCapacityController = TextEditingController(text: '20');

  String _roofType = 'Composition Shingle';

  double? _panelLoadPsf;
  double? _totalSystemWeight;
  double? _totalArea;
  double? _averageLoadPsf;
  double? _safetyMargin;
  String? _recommendation;

  // Typical dead load capacities by roof type (psf)
  final Map<String, double> _roofCapacities = {
    'Composition Shingle': 20.0,
    'Metal Standing Seam': 15.0,
    'Tile (Clay/Concrete)': 25.0,
    'Flat/Built-Up': 15.0,
    'Wood Shake': 12.0,
  };

  List<String> get _roofTypes => _roofCapacities.keys.toList();

  @override
  void dispose() {
    _panelWeightController.dispose();
    _panelAreaController.dispose();
    _mountingWeightController.dispose();
    _numPanelsController.dispose();
    _roofCapacityController.dispose();
    super.dispose();
  }

  void _updateRoofCapacity() {
    if (_roofCapacities.containsKey(_roofType)) {
      _roofCapacityController.text = _roofCapacities[_roofType]!.toStringAsFixed(0);
    }
  }

  void _calculate() {
    final panelWeight = double.tryParse(_panelWeightController.text);
    final panelArea = double.tryParse(_panelAreaController.text);
    final mountingWeight = double.tryParse(_mountingWeightController.text);
    final numPanels = int.tryParse(_numPanelsController.text);
    final roofCapacity = double.tryParse(_roofCapacityController.text);

    if (panelWeight == null || panelArea == null || mountingWeight == null ||
        numPanels == null || roofCapacity == null) {
      setState(() {
        _panelLoadPsf = null;
        _totalSystemWeight = null;
        _totalArea = null;
        _averageLoadPsf = null;
        _safetyMargin = null;
        _recommendation = null;
      });
      return;
    }

    // Panel load per square foot
    final panelLoadPsf = panelWeight / panelArea;

    // Total system weight (panels + mounting hardware)
    final totalPanelWeight = panelWeight * numPanels;
    final totalMountingWeight = mountingWeight * numPanels;
    final totalSystemWeight = totalPanelWeight + totalMountingWeight;

    // Total array area
    final totalArea = panelArea * numPanels;

    // Average load across array footprint
    final averageLoadPsf = totalSystemWeight / totalArea;

    // Safety margin
    final safetyMargin = ((roofCapacity - averageLoadPsf) / roofCapacity) * 100;

    String recommendation;
    if (safetyMargin > 50) {
      recommendation = 'Excellent. Roof can easily support the system with ${safetyMargin.toStringAsFixed(0)}% margin.';
    } else if (safetyMargin > 30) {
      recommendation = 'Good. Adequate safety margin. Proceed with standard installation.';
    } else if (safetyMargin > 10) {
      recommendation = 'Caution. Consider structural engineering review before installation.';
    } else if (safetyMargin > 0) {
      recommendation = 'Warning. Minimal margin. Professional structural assessment required.';
    } else {
      recommendation = 'Exceeds capacity. Structural reinforcement required before installation.';
    }

    setState(() {
      _panelLoadPsf = panelLoadPsf;
      _totalSystemWeight = totalSystemWeight;
      _totalArea = totalArea;
      _averageLoadPsf = averageLoadPsf;
      _safetyMargin = safetyMargin;
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
    _panelWeightController.text = '45';
    _panelAreaController.text = '21.5';
    _mountingWeightController.text = '3';
    _numPanelsController.text = '20';
    setState(() => _roofType = 'Composition Shingle');
    _updateRoofCapacity();
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
        title: Text('Roof Load Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ROOF TYPE'),
              const SizedBox(height: 12),
              _buildRoofTypeSelector(colors),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Roof Capacity',
                unit: 'psf',
                hint: 'Dead load limit',
                controller: _roofCapacityController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PANEL SPECIFICATIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Panel Weight',
                      unit: 'lbs',
                      hint: 'Per panel',
                      controller: _panelWeightController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Panel Area',
                      unit: 'sq ft',
                      hint: 'Per panel',
                      controller: _panelAreaController,
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
                      label: 'Mounting Hardware',
                      unit: 'lbs',
                      hint: 'Per panel',
                      controller: _mountingWeightController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Number of Panels',
                      unit: 'qty',
                      hint: 'Total count',
                      controller: _numPanelsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_averageLoadPsf != null) ...[
                _buildSectionHeader(colors, 'LOAD ANALYSIS'),
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
              Icon(LucideIcons.home, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Roof Load Calculator',
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
            'Verify roof can support solar array weight',
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

  Widget _buildRoofTypeSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _roofType,
          isExpanded: true,
          dropdownColor: colors.bgElevated,
          style: TextStyle(color: colors.textPrimary, fontSize: 16),
          icon: Icon(LucideIcons.chevronDown, color: colors.textSecondary),
          items: _roofTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.selectionClick();
              setState(() => _roofType = value);
              _updateRoofCapacity();
              _calculate();
            }
          },
        ),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final roofCapacity = double.parse(_roofCapacityController.text);
    final isOk = _averageLoadPsf! < roofCapacity;
    final statusColor = _safetyMargin! > 30 ? colors.accentSuccess : (_safetyMargin! > 10 ? colors.accentWarning : colors.accentError);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('System Load', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      '${_averageLoadPsf!.toStringAsFixed(1)}',
                      style: TextStyle(color: statusColor, fontSize: 36, fontWeight: FontWeight.w700),
                    ),
                    Text('psf', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOk ? LucideIcons.check : LucideIcons.alertTriangle,
                  color: statusColor,
                  size: 24,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('Roof Capacity', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      '${roofCapacity.toStringAsFixed(0)}',
                      style: TextStyle(color: colors.textPrimary, fontSize: 36, fontWeight: FontWeight.w600),
                    ),
                    Text('psf', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Safety Margin: ${_safetyMargin!.toStringAsFixed(0)}%',
              style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w600),
            ),
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
                _buildResultRow(colors, 'Total System Weight', '${_totalSystemWeight!.toStringAsFixed(0)} lbs'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Array Footprint', '${_totalArea!.toStringAsFixed(0)} sq ft'),
                const SizedBox(height: 8),
                _buildResultRow(colors, 'Panel Load', '${_panelLoadPsf!.toStringAsFixed(2)} psf'),
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
