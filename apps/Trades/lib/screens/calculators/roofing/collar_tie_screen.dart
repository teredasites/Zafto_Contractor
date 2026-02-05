import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Collar Tie Calculator - Calculate collar tie/rafter tie requirements
class CollarTieScreen extends ConsumerStatefulWidget {
  const CollarTieScreen({super.key});
  @override
  ConsumerState<CollarTieScreen> createState() => _CollarTieScreenState();
}

class _CollarTieScreenState extends ConsumerState<CollarTieScreen> {
  final _roofLengthController = TextEditingController(text: '40');
  final _rafterSpacingController = TextEditingController(text: '24');
  final _spanController = TextEditingController(text: '24');

  String _tieType = 'Collar Tie';
  String _lumber = '2×4';

  int? _tiesNeeded;
  double? _tieLength;
  int? _boardFeet;

  @override
  void dispose() {
    _roofLengthController.dispose();
    _rafterSpacingController.dispose();
    _spanController.dispose();
    super.dispose();
  }

  void _calculate() {
    final roofLength = double.tryParse(_roofLengthController.text);
    final rafterSpacing = double.tryParse(_rafterSpacingController.text);
    final span = double.tryParse(_spanController.text);

    if (roofLength == null || rafterSpacing == null || span == null) {
      setState(() {
        _tiesNeeded = null;
        _tieLength = null;
        _boardFeet = null;
      });
      return;
    }

    // Number of rafter pairs
    final rafterPairs = (roofLength * 12 / rafterSpacing).ceil() + 1;

    // Collar ties: typically 1/3 down from ridge (every rafter pair or every other)
    // Rafter ties: at bottom of rafters
    int tiesNeeded;
    double tieLength;

    if (_tieType == 'Collar Tie') {
      // Collar ties at upper 1/3 of rafter
      // Length = span × 1/3 (approximate)
      tieLength = span / 3;
      // Code often requires collar ties at every other rafter pair (4' max spacing)
      tiesNeeded = rafterPairs;
    } else {
      // Rafter ties (ceiling joists) at full span
      tieLength = span;
      tiesNeeded = rafterPairs;
    }

    // Board feet calculation
    double thickness;
    double width;
    switch (_lumber) {
      case '2×4':
        thickness = 1.5;
        width = 3.5;
        break;
      case '2×6':
        thickness = 1.5;
        width = 5.5;
        break;
      case '2×8':
        thickness = 1.5;
        width = 7.25;
        break;
      default:
        thickness = 1.5;
        width = 3.5;
    }

    final boardFeet = (tiesNeeded * tieLength * thickness * width / 144).ceil();

    setState(() {
      _tiesNeeded = tiesNeeded;
      _tieLength = tieLength;
      _boardFeet = boardFeet;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _roofLengthController.text = '40';
    _rafterSpacingController.text = '24';
    _spanController.text = '24';
    setState(() {
      _tieType = 'Collar Tie';
      _lumber = '2×4';
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
        title: Text('Collar Tie', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'TIE TYPE & LUMBER'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 12),
              _buildLumberSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOF DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Roof Length',
                      unit: 'ft',
                      hint: 'Ridge length',
                      controller: _roofLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Rafter Spacing',
                      unit: 'in',
                      hint: '16" or 24"',
                      controller: _rafterSpacingController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Building Span',
                unit: 'ft',
                hint: 'Wall to wall',
                controller: _spanController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_tiesNeeded != null) ...[
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
              Icon(LucideIcons.minus, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Collar Tie Calculator',
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
            'Calculate collar ties and rafter ties',
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
    final types = ['Collar Tie', 'Rafter Tie'];
    return Row(
      children: types.map((type) {
        final isSelected = _tieType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _tieType = type);
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
                    type == 'Collar Tie' ? 'Upper 1/3' : 'At ceiling',
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

  Widget _buildLumberSelector(ZaftoColors colors) {
    final lumber = ['2×4', '2×6', '2×8'];
    return Row(
      children: lumber.map((size) {
        final isSelected = _lumber == size;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _lumber = size);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: size != lumber.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                size,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 14,
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
          _buildResultRow(colors, 'TIES NEEDED', '$_tiesNeeded', isHighlighted: true),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Tie Length', '${_tieLength!.toStringAsFixed(1)} ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Board Feet', '$_boardFeet BF'),
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
                    Text('Code Requirements', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Collar ties: Max 4\' o.c., upper 1/3 of rafter', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Rafter ties: Required to resist thrust', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Min 3 nails per connection (10d)', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
