import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Roof Drain Calculator - Calculate roof drain sizing and quantity
class RoofDrainScreen extends ConsumerStatefulWidget {
  const RoofDrainScreen({super.key});
  @override
  ConsumerState<RoofDrainScreen> createState() => _RoofDrainScreenState();
}

class _RoofDrainScreenState extends ConsumerState<RoofDrainScreen> {
  final _roofAreaController = TextEditingController(text: '10000');
  final _rainfallController = TextEditingController(text: '4');

  String _drainType = 'Standard';

  int? _drainsNeeded;
  String? _recommendedSize;
  double? _flowRate;
  double? _areaPerDrain;

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
        _drainsNeeded = null;
        _recommendedSize = null;
        _flowRate = null;
        _areaPerDrain = null;
      });
      return;
    }

    // Calculate required flow rate (GPM)
    // Q = (Roof Area × Rainfall Rate) / 96.23
    final flowRate = (roofArea * rainfall) / 96.23;

    // Drain capacity by size (GPM at 1" head):
    // 3" drain: ~67 GPM
    // 4" drain: ~144 GPM
    // 5" drain: ~260 GPM
    // 6" drain: ~424 GPM

    double drainCapacity;
    String recommendedSize;

    if (flowRate / 2 <= 67) {
      drainCapacity = 67;
      recommendedSize = '3"';
    } else if (flowRate / 2 <= 144) {
      drainCapacity = 144;
      recommendedSize = '4"';
    } else if (flowRate / 2 <= 260) {
      drainCapacity = 260;
      recommendedSize = '5"';
    } else {
      drainCapacity = 424;
      recommendedSize = '6"';
    }

    // Number of drains needed (minimum 2)
    var drainsNeeded = (flowRate / drainCapacity).ceil();
    if (drainsNeeded < 2) drainsNeeded = 2;

    // Siphonic drains have higher capacity
    if (_drainType == 'Siphonic') {
      drainsNeeded = (drainsNeeded * 0.6).ceil();
      if (drainsNeeded < 2) drainsNeeded = 2;
    }

    // Area per drain
    final areaPerDrain = roofArea / drainsNeeded;

    setState(() {
      _drainsNeeded = drainsNeeded;
      _recommendedSize = recommendedSize;
      _flowRate = flowRate;
      _areaPerDrain = areaPerDrain;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _roofAreaController.text = '10000';
    _rainfallController.text = '4';
    setState(() => _drainType = 'Standard');
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
        title: Text('Roof Drain', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'DRAIN TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'DRAINAGE CALCULATIONS'),
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
              if (_drainsNeeded != null) ...[
                _buildSectionHeader(colors, 'DRAIN REQUIREMENTS'),
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
              Icon(LucideIcons.circle, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Roof Drain Calculator',
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
            'Calculate roof drain sizing and quantity',
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
    final types = ['Standard', 'Siphonic'];
    return Row(
      children: types.map((type) {
        final isSelected = _drainType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _drainType = type);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: type != types.last ? 8 : 0),
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
                    type,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    type == 'Standard' ? 'Gravity flow' : 'High capacity',
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
          _buildResultRow(colors, 'Flow Rate Required', '${_flowRate!.toStringAsFixed(0)} GPM'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'DRAINS NEEDED', '$_drainsNeeded', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Drain Size', _recommendedSize!),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Area Per Drain', '${_areaPerDrain!.toStringAsFixed(0)} sq ft'),
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
                    Text('Drain Guidelines', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Max 10,000 sq ft per drain typical', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Add overflow drains 2" above primary', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Leader size must match drain size', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
