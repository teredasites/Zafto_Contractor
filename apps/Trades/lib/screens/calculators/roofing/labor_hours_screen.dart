import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Labor Hours Calculator - Estimate roofing labor hours
class LaborHoursScreen extends ConsumerStatefulWidget {
  const LaborHoursScreen({super.key});
  @override
  ConsumerState<LaborHoursScreen> createState() => _LaborHoursScreenState();
}

class _LaborHoursScreenState extends ConsumerState<LaborHoursScreen> {
  final _squaresController = TextEditingController(text: '24');
  final _crewSizeController = TextEditingController(text: '3');

  String _roofType = 'Shingles';
  String _complexity = 'Standard';
  bool _includeTearOff = true;

  double? _laborHours;
  double? _hoursPerSquare;
  double? _workDays;
  double? _tearOffHours;
  double? _installHours;

  @override
  void dispose() {
    _squaresController.dispose();
    _crewSizeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final squares = double.tryParse(_squaresController.text);
    final crewSize = int.tryParse(_crewSizeController.text);

    if (squares == null || crewSize == null || crewSize <= 0) {
      setState(() {
        _laborHours = null;
        _hoursPerSquare = null;
        _workDays = null;
        _tearOffHours = null;
        _installHours = null;
      });
      return;
    }

    // Base hours per square by material
    double baseHoursPerSquare;
    switch (_roofType) {
      case 'Shingles':
        baseHoursPerSquare = 1.5;
        break;
      case 'Metal':
        baseHoursPerSquare = 2.5;
        break;
      case 'Tile':
        baseHoursPerSquare = 4.0;
        break;
      case 'Flat/TPO':
        baseHoursPerSquare = 2.0;
        break;
      default:
        baseHoursPerSquare = 1.5;
    }

    // Complexity multiplier
    double complexityFactor;
    switch (_complexity) {
      case 'Simple':
        complexityFactor = 0.8;
        break;
      case 'Standard':
        complexityFactor = 1.0;
        break;
      case 'Complex':
        complexityFactor = 1.3;
        break;
      case 'Very Complex':
        complexityFactor = 1.6;
        break;
      default:
        complexityFactor = 1.0;
    }

    final hoursPerSquare = baseHoursPerSquare * complexityFactor;

    // Tear-off hours (if applicable)
    double tearOffHours = 0;
    if (_includeTearOff) {
      tearOffHours = squares * 0.5 * complexityFactor; // 0.5 hrs/sq base
    }

    // Installation hours
    final installHours = squares * hoursPerSquare;

    // Total labor hours
    final laborHours = tearOffHours + installHours;

    // Work days (8-hour days, adjusted for crew)
    final workDays = laborHours / (crewSize * 8);

    setState(() {
      _laborHours = laborHours;
      _hoursPerSquare = hoursPerSquare;
      _workDays = workDays;
      _tearOffHours = tearOffHours;
      _installHours = installHours;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _squaresController.text = '24';
    _crewSizeController.text = '3';
    setState(() {
      _roofType = 'Shingles';
      _complexity = 'Standard';
      _includeTearOff = true;
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
        title: Text('Labor Hours', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'JOB SPECIFICATIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Squares',
                      unit: 'sq',
                      hint: 'Total squares',
                      controller: _squaresController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Crew Size',
                      unit: 'workers',
                      hint: 'Installers',
                      controller: _crewSizeController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRoofTypeSelector(colors),
              const SizedBox(height: 12),
              _buildComplexitySelector(colors),
              const SizedBox(height: 12),
              _buildTearOffToggle(colors),
              const SizedBox(height: 32),
              if (_laborHours != null) ...[
                _buildSectionHeader(colors, 'LABOR ESTIMATE'),
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
              Icon(LucideIcons.clock, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Labor Hours Calculator',
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
            'Estimate roofing installation labor',
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
    final types = ['Shingles', 'Metal', 'Tile', 'Flat/TPO'];
    return Row(
      children: types.map((type) {
        final isSelected = _roofType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _roofType = type);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: type != types.last ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                type,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComplexitySelector(ZaftoColors colors) {
    final complexities = ['Simple', 'Standard', 'Complex'];
    return Row(
      children: complexities.map((complexity) {
        final isSelected = _complexity == complexity;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _complexity = complexity);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: complexity != complexities.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                complexity,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTearOffToggle(ZaftoColors colors) {
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
          Text('Include Tear-Off', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Switch(
            value: _includeTearOff,
            activeColor: colors.accentPrimary,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _includeTearOff = value);
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
          _buildResultRow(colors, 'Hours per Square', '${_hoursPerSquare!.toStringAsFixed(1)} hrs'),
          const SizedBox(height: 12),
          if (_includeTearOff) ...[
            _buildResultRow(colors, 'Tear-Off Hours', '${_tearOffHours!.toStringAsFixed(0)} hrs'),
            const SizedBox(height: 8),
          ],
          _buildResultRow(colors, 'Install Hours', '${_installHours!.toStringAsFixed(0)} hrs'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL LABOR HOURS', '${_laborHours!.toStringAsFixed(0)} hrs', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'WORK DAYS', '${_workDays!.toStringAsFixed(1)} days', isHighlighted: true),
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
                    Text('Labor Guidelines', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Shingles: 1.5 hrs/sq | Metal: 2.5 hrs/sq', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Tile: 4 hrs/sq | Flat/TPO: 2 hrs/sq', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Tear-off adds ~0.5 hrs/sq', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
