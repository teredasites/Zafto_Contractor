import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wood Shake Calculator - Calculate cedar shake/shingle materials
class WoodShakeScreen extends ConsumerStatefulWidget {
  const WoodShakeScreen({super.key});
  @override
  ConsumerState<WoodShakeScreen> createState() => _WoodShakeScreenState();
}

class _WoodShakeScreenState extends ConsumerState<WoodShakeScreen> {
  final _roofAreaController = TextEditingController(text: '2500');
  final _wasteController = TextEditingController(text: '10');

  String _shakeType = 'Medium';
  String _exposure = '10"';

  double? _squares;
  int? _bundlesNeeded;
  int? _ridgeCaps;
  int? _stainlessNails;

  @override
  void dispose() {
    _roofAreaController.dispose();
    _wasteController.dispose();
    super.dispose();
  }

  void _calculate() {
    final roofArea = double.tryParse(_roofAreaController.text);
    final waste = double.tryParse(_wasteController.text);

    if (roofArea == null || waste == null) {
      setState(() {
        _squares = null;
        _bundlesNeeded = null;
        _ridgeCaps = null;
        _stainlessNails = null;
      });
      return;
    }

    final squares = roofArea / 100;

    // Bundles per square varies by exposure
    // Standard: 4 bundles/square at 10" exposure
    double bundlesPerSquare;
    switch (_exposure) {
      case '7.5"':
        bundlesPerSquare = 5.0;
        break;
      case '10"':
        bundlesPerSquare = 4.0;
        break;
      case '11.5"':
        bundlesPerSquare = 3.5;
        break;
      default:
        bundlesPerSquare = 4.0;
    }

    // Adjust for shake type (heavier shakes = slightly more coverage)
    if (_shakeType == 'Heavy') {
      bundlesPerSquare *= 0.95;
    } else if (_shakeType == 'Light') {
      bundlesPerSquare *= 1.05;
    }

    final wasteFactor = 1 + waste / 100;
    final bundlesNeeded = (squares * bundlesPerSquare * wasteFactor).ceil();

    // Ridge caps: estimate based on perimeter
    // Assume ridge = ~20% of roof area sqrt
    final ridgeLength = roofArea / 50; // rough estimate
    final ridgeCaps = (ridgeLength * 1.1).ceil();

    // Stainless nails: 2 per shake, ~80 shakes per bundle
    final shakesTotal = bundlesNeeded * 80;
    final stainlessNails = (shakesTotal * 2 * 1.1).ceil();

    setState(() {
      _squares = squares;
      _bundlesNeeded = bundlesNeeded;
      _ridgeCaps = ridgeCaps;
      _stainlessNails = stainlessNails;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _roofAreaController.text = '2500';
    _wasteController.text = '10';
    setState(() {
      _shakeType = 'Medium';
      _exposure = '10"';
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
        title: Text('Wood Shake', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SHAKE TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 12),
              _buildExposureSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOF AREA'),
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
                      label: 'Waste',
                      unit: '%',
                      hint: '10% typical',
                      controller: _wasteController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_bundlesNeeded != null) ...[
                _buildSectionHeader(colors, 'MATERIALS NEEDED'),
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
              Icon(LucideIcons.treePine, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Wood Shake Calculator',
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
            'Calculate cedar shakes and shingles',
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
    final types = ['Light', 'Medium', 'Heavy'];
    return Row(
      children: types.map((type) {
        final isSelected = _shakeType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _shakeType = type);
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    type == 'Light' ? '3/8" butt' : (type == 'Medium' ? '1/2" butt' : '3/4" butt'),
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

  Widget _buildExposureSelector(ZaftoColors colors) {
    final exposures = ['7.5"', '10"', '11.5"'];
    return Row(
      children: exposures.map((exp) {
        final isSelected = _exposure == exp;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _exposure = exp);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: exp != exposures.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                exp,
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
          _buildResultRow(colors, 'Roof Squares', _squares!.toStringAsFixed(1)),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'SHAKE BUNDLES', '$_bundlesNeeded', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Ridge/Hip Caps', '$_ridgeCaps lin ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'SS Nails', '$_stainlessNails'),
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
                    Text('Cedar Shake Info', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Min pitch: 4:12 for shakes, 3:12 for shingles', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Use stainless steel or hot-dip galv nails', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Install over breathable underlayment', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
