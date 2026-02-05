import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Tapered Insulation Calculator - Calculate tapered insulation for drainage
class TaperedInsulationScreen extends ConsumerStatefulWidget {
  const TaperedInsulationScreen({super.key});
  @override
  ConsumerState<TaperedInsulationScreen> createState() => _TaperedInsulationScreenState();
}

class _TaperedInsulationScreenState extends ConsumerState<TaperedInsulationScreen> {
  final _roofAreaController = TextEditingController(text: '5000');
  final _drainDistanceController = TextEditingController(text: '50');
  final _minThicknessController = TextEditingController(text: '0.5');

  String _slopeRate = '1/8"';
  String _insulationType = 'Polyiso';

  double? _boardFeet;
  double? _averageThickness;
  double? _maxThickness;
  double? _rValueAverage;
  int? _boardsNeeded;

  @override
  void dispose() {
    _roofAreaController.dispose();
    _drainDistanceController.dispose();
    _minThicknessController.dispose();
    super.dispose();
  }

  void _calculate() {
    final roofArea = double.tryParse(_roofAreaController.text);
    final drainDistance = double.tryParse(_drainDistanceController.text);
    final minThickness = double.tryParse(_minThicknessController.text);

    if (roofArea == null || drainDistance == null || minThickness == null) {
      setState(() {
        _boardFeet = null;
        _averageThickness = null;
        _maxThickness = null;
        _rValueAverage = null;
        _boardsNeeded = null;
      });
      return;
    }

    // Slope rate (inches per foot)
    double slopePerFoot;
    switch (_slopeRate) {
      case '1/8"':
        slopePerFoot = 0.125;
        break;
      case '1/4"':
        slopePerFoot = 0.25;
        break;
      case '1/2"':
        slopePerFoot = 0.5;
        break;
      default:
        slopePerFoot = 0.125;
    }

    // Max thickness at high point
    final maxThickness = minThickness + (drainDistance * slopePerFoot);

    // Average thickness (midpoint of taper)
    final averageThickness = (minThickness + maxThickness) / 2;

    // Board feet (area × average thickness in feet)
    final boardFeet = roofArea * (averageThickness / 12);

    // R-value per inch varies by type
    double rPerInch;
    switch (_insulationType) {
      case 'Polyiso':
        rPerInch = 5.6;
        break;
      case 'EPS':
        rPerInch = 3.8;
        break;
      case 'XPS':
        rPerInch = 5.0;
        break;
      default:
        rPerInch = 5.6;
    }

    final rValueAverage = averageThickness * rPerInch;

    // Boards needed (4' × 8' = 32 sq ft per board)
    final boardsNeeded = (roofArea / 32 * 1.1).ceil();

    setState(() {
      _boardFeet = boardFeet;
      _averageThickness = averageThickness;
      _maxThickness = maxThickness;
      _rValueAverage = rValueAverage;
      _boardsNeeded = boardsNeeded;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _roofAreaController.text = '5000';
    _drainDistanceController.text = '50';
    _minThicknessController.text = '0.5';
    setState(() {
      _slopeRate = '1/8"';
      _insulationType = 'Polyiso';
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
        title: Text('Tapered Insulation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'INSULATION TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 12),
              _buildSlopeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOF DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Area',
                      unit: 'sq ft',
                      hint: 'Total area',
                      controller: _roofAreaController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'To Drain',
                      unit: 'ft',
                      hint: 'Max distance',
                      controller: _drainDistanceController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Min Thickness',
                unit: 'in',
                hint: 'At drain',
                controller: _minThicknessController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_boardFeet != null) ...[
                _buildSectionHeader(colors, 'INSULATION REQUIREMENTS'),
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
              Icon(LucideIcons.layers, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Tapered Insulation Calculator',
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
            'Calculate tapered insulation for positive drainage',
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
    final types = ['Polyiso', 'EPS', 'XPS'];
    return Row(
      children: types.map((type) {
        final isSelected = _insulationType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _insulationType = type);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: type != types.last ? 8 : 0),
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
                    type,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    type == 'Polyiso' ? 'R-5.6/in' : (type == 'EPS' ? 'R-3.8/in' : 'R-5.0/in'),
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

  Widget _buildSlopeSelector(ZaftoColors colors) {
    final slopes = ['1/8"', '1/4"', '1/2"'];
    return Row(
      children: slopes.map((slope) {
        final isSelected = _slopeRate == slope;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _slopeRate = slope);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: slope != slopes.last ? 8 : 0),
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
                    slope,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'per foot',
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
          _buildResultRow(colors, 'Max Thickness', '${_maxThickness!.toStringAsFixed(1)}"'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Average Thickness', '${_averageThickness!.toStringAsFixed(1)}"'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'BOARD FEET', '${_boardFeet!.toStringAsFixed(0)} BF', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Boards (4×8)', '$_boardsNeeded'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Avg R-Value', 'R-${_rValueAverage!.toStringAsFixed(1)}'),
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
                    Text('Tapered Tips', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('1/8"/ft slope = 1% grade (minimum)', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Add cover board for membrane protection', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Order shop drawings from manufacturer', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
