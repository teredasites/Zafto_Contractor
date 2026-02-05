import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Scupper Calculator - Calculate scupper drain sizing and placement
class ScupperScreen extends ConsumerStatefulWidget {
  const ScupperScreen({super.key});
  @override
  ConsumerState<ScupperScreen> createState() => _ScupperScreenState();
}

class _ScupperScreenState extends ConsumerState<ScupperScreen> {
  final _roofAreaController = TextEditingController(text: '5000');
  final _rainfallController = TextEditingController(text: '4');

  String _scupperType = 'Through-Wall';
  String _headHeight = '2"';

  int? _scuppersNeeded;
  String? _recommendedSize;
  double? _flowRate;
  double? _drainageArea;

  @override
  void dispose() {
    _roofAreaController.dispose();
    _rainfallController.dispose();
    super.dispose();
  }

  void _calculate() {
    final roofArea = double.tryParse(_roofAreaController.text);
    final rainfall = double.tryParse(_rainfallController.text);

    if (roofArea == null || rainfall == null) {
      setState(() {
        _scuppersNeeded = null;
        _recommendedSize = null;
        _flowRate = null;
        _drainageArea = null;
      });
      return;
    }

    // Calculate required flow rate (GPM)
    // Q = (Roof Area × Rainfall Rate) / 96.23
    final flowRate = (roofArea * rainfall) / 96.23;

    // Scupper flow capacity based on size and head height
    // Using weir flow equation: Q = 3.33 × L × H^1.5
    // L = scupper width, H = head height
    double headHeightInches;
    switch (_headHeight) {
      case '1"':
        headHeightInches = 1;
        break;
      case '2"':
        headHeightInches = 2;
        break;
      case '3"':
        headHeightInches = 3;
        break;
      case '4"':
        headHeightInches = 4;
        break;
      default:
        headHeightInches = 2;
    }

    // Standard scupper sizes and their capacity
    // 4" × 4": ~30 GPM at 2" head
    // 6" × 6": ~60 GPM at 2" head
    // 8" × 4": ~80 GPM at 2" head
    double scupperCapacity;
    String recommendedSize;

    if (flowRate <= 30) {
      scupperCapacity = (30 * math.pow(headHeightInches / 2, 1.5)).toDouble();
      recommendedSize = '4" × 4"';
    } else if (flowRate <= 60) {
      scupperCapacity = (60 * math.pow(headHeightInches / 2, 1.5)).toDouble();
      recommendedSize = '6" × 6"';
    } else {
      scupperCapacity = (80 * math.pow(headHeightInches / 2, 1.5)).toDouble();
      recommendedSize = '8" × 4"';
    }

    // Number of scuppers needed
    final scuppersNeeded = (flowRate / scupperCapacity).ceil();

    // Drainage area per scupper
    final drainageArea = roofArea / scuppersNeeded;

    setState(() {
      _scuppersNeeded = scuppersNeeded < 2 ? 2 : scuppersNeeded; // Minimum 2 for redundancy
      _recommendedSize = recommendedSize;
      _flowRate = flowRate;
      _drainageArea = drainageArea;
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
    _rainfallController.text = '4';
    setState(() {
      _scupperType = 'Through-Wall';
      _headHeight = '2"';
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
        title: Text('Scupper', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SCUPPER TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 12),
              _buildHeadSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DRAINAGE REQUIREMENTS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Area',
                      unit: 'sq ft',
                      hint: 'Drainage area',
                      controller: _roofAreaController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Rainfall',
                      unit: 'in/hr',
                      hint: 'Design rate',
                      controller: _rainfallController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_scuppersNeeded != null) ...[
                _buildSectionHeader(colors, 'SCUPPER SIZING'),
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
              Icon(LucideIcons.arrowDownFromLine, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Scupper Calculator',
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
            'Calculate scupper sizing and quantity',
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
    final types = ['Through-Wall', 'Overflow'];
    return Row(
      children: types.map((type) {
        final isSelected = _scupperType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _scupperType = type);
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
                    type == 'Through-Wall' ? 'Primary drain' : 'Emergency',
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

  Widget _buildHeadSelector(ZaftoColors colors) {
    final heads = ['1"', '2"', '3"', '4"'];
    return Row(
      children: heads.map((head) {
        final isSelected = _headHeight == head;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _headHeight = head);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: head != heads.last ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                head,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
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
          _buildResultRow(colors, 'Flow Rate Required', '${_flowRate!.toStringAsFixed(0)} GPM'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'SCUPPERS NEEDED', '$_scuppersNeeded', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Recommended Size', _recommendedSize!),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Area Per Scupper', '${_drainageArea!.toStringAsFixed(0)} sq ft'),
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
                    Text('Scupper Guidelines', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Always include overflow scuppers 2" above primary', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Minimum 2 scuppers for redundancy', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Size conductor heads to match', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
