import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Gutter Slope Calculator - Calculate proper gutter pitch for drainage
class GutterSlopeScreen extends ConsumerStatefulWidget {
  const GutterSlopeScreen({super.key});
  @override
  ConsumerState<GutterSlopeScreen> createState() => _GutterSlopeScreenState();
}

class _GutterSlopeScreenState extends ConsumerState<GutterSlopeScreen> {
  final _gutterLengthController = TextEditingController(text: '40');
  final _slopeController = TextEditingController(text: '0.5');

  String _downspoutLocation = 'One End';

  double? _totalDrop;
  double? _dropPerFoot;
  String? _highEndHeight;
  String? _lowEndHeight;

  @override
  void dispose() {
    _gutterLengthController.dispose();
    _slopeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final gutterLength = double.tryParse(_gutterLengthController.text);
    final slope = double.tryParse(_slopeController.text);

    if (gutterLength == null || slope == null) {
      setState(() {
        _totalDrop = null;
        _dropPerFoot = null;
        _highEndHeight = null;
        _lowEndHeight = null;
      });
      return;
    }

    // Slope in inches per 10 feet is standard measurement
    // Convert to inches per foot
    final dropPerFoot = slope / 10;

    double effectiveLength;
    if (_downspoutLocation == 'One End') {
      // All slope goes one direction
      effectiveLength = gutterLength;
    } else if (_downspoutLocation == 'Center') {
      // Slope from both ends toward center
      effectiveLength = gutterLength / 2;
    } else {
      // Both ends (slope toward both ends from center high point)
      effectiveLength = gutterLength / 2;
    }

    final totalDrop = effectiveLength * dropPerFoot;

    // Height example (assuming 3" gutter at low end)
    final lowEnd = 3.0;
    final highEnd = lowEnd + totalDrop;

    setState(() {
      _totalDrop = totalDrop;
      _dropPerFoot = dropPerFoot;
      _highEndHeight = '${highEnd.toStringAsFixed(2)}"';
      _lowEndHeight = '${lowEnd.toStringAsFixed(2)}"';
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _gutterLengthController.text = '40';
    _slopeController.text = '0.5';
    setState(() => _downspoutLocation = 'One End');
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
        title: Text('Gutter Slope', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'DOWNSPOUT LOCATION'),
              const SizedBox(height: 12),
              _buildLocationSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'GUTTER SPECIFICATIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Gutter Length',
                      unit: 'ft',
                      hint: 'Run length',
                      controller: _gutterLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Slope',
                      unit: '"/10ft',
                      hint: '0.5" typical',
                      controller: _slopeController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_totalDrop != null) ...[
                _buildSectionHeader(colors, 'SLOPE CALCULATIONS'),
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
              Icon(LucideIcons.arrowDownRight, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Gutter Slope Calculator',
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
            'Calculate proper gutter pitch for drainage',
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

  Widget _buildLocationSelector(ZaftoColors colors) {
    final locations = ['One End', 'Center', 'Both Ends'];
    return Row(
      children: locations.map((loc) {
        final isSelected = _downspoutLocation == loc;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _downspoutLocation = loc);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: loc != locations.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                loc,
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
          _buildResultRow(colors, 'TOTAL DROP', '${_totalDrop!.toStringAsFixed(2)}"', isHighlighted: true),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Drop Per Foot', '${_dropPerFoot!.toStringAsFixed(3)}"'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'High End Height', _highEndHeight!),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Low End Height', _lowEndHeight!),
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
                    Text('Gutter Slope Tips', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Standard slope: 1/2" per 10 feet', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Max run: 40 ft per downspout', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Use level & string line to set slope', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
