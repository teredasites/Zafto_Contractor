import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Conduit Fill Calculator (Solar) - PV wire fill calculations
class ConduitFillSolarScreen extends ConsumerStatefulWidget {
  const ConduitFillSolarScreen({super.key});
  @override
  ConsumerState<ConduitFillSolarScreen> createState() => _ConduitFillSolarScreenState();
}

class _ConduitFillSolarScreenState extends ConsumerState<ConduitFillSolarScreen> {
  final _wireCountController = TextEditingController(text: '4');

  String _wireSize = '10';
  String _wireType = 'USE-2';
  String _conduitType = 'EMT';
  String _conduitSize = '3/4';

  double? _fillPercent;
  String? _status;
  String? _recommendation;

  // Wire areas in sq inches (with insulation)
  final Map<String, Map<String, double>> _wireAreas = {
    'USE-2': {
      '14': 0.0206, '12': 0.0260, '10': 0.0333, '8': 0.0556,
      '6': 0.0726, '4': 0.1087, '2': 0.1473, '1/0': 0.2223,
    },
    'THWN-2': {
      '14': 0.0097, '12': 0.0133, '10': 0.0211, '8': 0.0366,
      '6': 0.0507, '4': 0.0824, '2': 0.1158, '1/0': 0.1855,
    },
    'PV Wire': {
      '14': 0.0220, '12': 0.0280, '10': 0.0360, '8': 0.0580,
      '6': 0.0760, '4': 0.1130, '2': 0.1530, '1/0': 0.2300,
    },
  };

  // Conduit areas in sq inches
  final Map<String, Map<String, double>> _conduitAreas = {
    'EMT': {
      '1/2': 0.304, '3/4': 0.533, '1': 0.864, '1-1/4': 1.496,
      '1-1/2': 2.036, '2': 3.356, '2-1/2': 5.858, '3': 8.846,
    },
    'PVC': {
      '1/2': 0.285, '3/4': 0.508, '1': 0.832, '1-1/4': 1.453,
      '1-1/2': 1.986, '2': 3.291, '2-1/2': 5.621, '3': 8.522,
    },
    'RMC': {
      '1/2': 0.314, '3/4': 0.549, '1': 0.887, '1-1/4': 1.526,
      '1-1/2': 2.071, '2': 3.408, '2-1/2': 5.858, '3': 8.846,
    },
  };

  @override
  void dispose() {
    _wireCountController.dispose();
    super.dispose();
  }

  void _calculate() {
    final wireCount = int.tryParse(_wireCountController.text);

    if (wireCount == null || wireCount == 0) {
      setState(() {
        _fillPercent = null;
        _status = null;
        _recommendation = null;
      });
      return;
    }

    final wireArea = _wireAreas[_wireType]?[_wireSize] ?? 0.0333;
    final conduitArea = _conduitAreas[_conduitType]?[_conduitSize] ?? 0.533;

    final totalWireArea = wireArea * wireCount;

    // NEC fill limits based on conductor count
    double maxFill;
    if (wireCount == 1) {
      maxFill = 0.53; // 53%
    } else if (wireCount == 2) {
      maxFill = 0.31; // 31%
    } else {
      maxFill = 0.40; // 40%
    }

    final fillPercent = (totalWireArea / conduitArea) * 100;

    String status;
    String recommendation;
    if (fillPercent <= maxFill * 100) {
      status = 'Compliant';
      recommendation = 'Fill is within NEC Chapter 9 limits for $wireCount conductors.';
    } else {
      status = 'Exceeded';
      // Find minimum compliant size
      String? minSize;
      final sizes = ['1/2', '3/4', '1', '1-1/4', '1-1/2', '2', '2-1/2', '3'];
      for (final size in sizes) {
        final area = _conduitAreas[_conduitType]?[size] ?? 0;
        if (area > 0 && (totalWireArea / area) <= maxFill) {
          minSize = size;
          break;
        }
      }
      recommendation = minSize != null
          ? 'Minimum compliant size: $minSize" $_conduitType'
          : 'Consider splitting into multiple conduits.';
    }

    setState(() {
      _fillPercent = fillPercent;
      _status = status;
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
    _wireCountController.text = '4';
    setState(() {
      _wireSize = '10';
      _wireType = 'USE-2';
      _conduitType = 'EMT';
      _conduitSize = '3/4';
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
        title: Text('Conduit Fill', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CONDUCTORS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ZaftoInputField(
                      label: 'Wire Count',
                      unit: '#',
                      hint: 'Number of wires',
                      controller: _wireCountController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: _buildWireTypeDropdown(colors),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildWireSizeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CONDUIT'),
              const SizedBox(height: 12),
              _buildConduitTypeSelector(colors),
              const SizedBox(height: 12),
              _buildConduitSizeSelector(colors),
              const SizedBox(height: 32),
              if (_fillPercent != null) ...[
                _buildSectionHeader(colors, 'FILL CALCULATION'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildFillLimits(colors),
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
              Icon(LucideIcons.pipette, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'PV Conduit Fill',
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
            'Calculate conduit fill per NEC Chapter 9',
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

  Widget _buildWireTypeDropdown(ZaftoColors colors) {
    final types = ['USE-2', 'PV Wire', 'THWN-2'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _wireType,
          isExpanded: true,
          dropdownColor: colors.bgElevated,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          items: types.map((type) => DropdownMenuItem(
            value: type,
            child: Text(type),
          )).toList(),
          onChanged: (value) {
            if (value != null) {
              HapticFeedback.selectionClick();
              setState(() => _wireType = value);
              _calculate();
            }
          },
        ),
      ),
    );
  }

  Widget _buildWireSizeSelector(ZaftoColors colors) {
    final sizes = ['14', '12', '10', '8', '6', '4', '2', '1/0'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: sizes.map((size) {
          final isSelected = _wireSize == size;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _wireSize = size);
              _calculate();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
              ),
              child: Text(
                '#$size',
                style: TextStyle(
                  color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConduitTypeSelector(ZaftoColors colors) {
    final types = ['EMT', 'PVC', 'RMC'];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: types.map((type) {
          final isSelected = _conduitType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _conduitType = type);
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
                    type,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 13,
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

  Widget _buildConduitSizeSelector(ZaftoColors colors) {
    final sizes = ['1/2', '3/4', '1', '1-1/4', '1-1/2', '2'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: sizes.map((size) {
          final isSelected = _conduitSize == size;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _conduitSize = size);
              _calculate();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentInfo : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isSelected ? colors.accentInfo : colors.borderSubtle),
              ),
              child: Text(
                '$size"',
                style: TextStyle(
                  color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isCompliant = _status == 'Compliant';
    final statusColor = isCompliant ? colors.accentSuccess : colors.accentError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Conduit Fill', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '${_fillPercent!.toStringAsFixed(1)}%',
            style: TextStyle(color: statusColor, fontSize: 44, fontWeight: FontWeight.w700),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCompliant ? LucideIcons.checkCircle : LucideIcons.xCircle,
                  size: 14,
                  color: statusColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _status!,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
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

  Widget _buildFillLimits(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEC CHAPTER 9 FILL LIMITS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildLimitRow(colors, '1 conductor', '53%'),
          _buildLimitRow(colors, '2 conductors', '31%'),
          _buildLimitRow(colors, '3+ conductors', '40%'),
        ],
      ),
    );
  }

  Widget _buildLimitRow(ZaftoColors colors, String count, String limit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(count, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          Text(limit, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
