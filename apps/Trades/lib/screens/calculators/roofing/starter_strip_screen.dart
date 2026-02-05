import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Starter Strip Calculator - Calculate starter strip for eaves and rakes
class StarterStripScreen extends ConsumerStatefulWidget {
  const StarterStripScreen({super.key});
  @override
  ConsumerState<StarterStripScreen> createState() => _StarterStripScreenState();
}

class _StarterStripScreenState extends ConsumerState<StarterStripScreen> {
  final _eaveController = TextEditingController(text: '120');
  final _rakeController = TextEditingController(text: '60');
  final _wasteController = TextEditingController(text: '5');

  bool _includeRakes = false;

  double? _totalLength;
  int? _rollsNeeded;
  int? _bundlesNeeded;

  @override
  void dispose() {
    _eaveController.dispose();
    _rakeController.dispose();
    _wasteController.dispose();
    super.dispose();
  }

  void _calculate() {
    final eave = double.tryParse(_eaveController.text);
    final rake = double.tryParse(_rakeController.text);
    final waste = double.tryParse(_wasteController.text);

    if (eave == null || rake == null || waste == null) {
      setState(() {
        _totalLength = null;
        _rollsNeeded = null;
        _bundlesNeeded = null;
      });
      return;
    }

    // Total length needed
    double totalLength = eave;
    if (_includeRakes) {
      totalLength += rake;
    }
    totalLength *= (1 + waste / 100);

    // Starter strip coverage
    // Roll: typically 120 lin ft per roll
    // Bundle (cut shingles): ~100 lin ft per bundle
    final rollsNeeded = (totalLength / 120).ceil();
    final bundlesNeeded = (totalLength / 100).ceil();

    setState(() {
      _totalLength = totalLength;
      _rollsNeeded = rollsNeeded;
      _bundlesNeeded = bundlesNeeded;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _eaveController.text = '120';
    _rakeController.text = '60';
    _wasteController.text = '5';
    setState(() => _includeRakes = false);
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
        title: Text('Starter Strip', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'EDGE LENGTHS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Eave Length',
                      unit: 'ft',
                      hint: 'All eaves',
                      controller: _eaveController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Rake Length',
                      unit: 'ft',
                      hint: 'All rakes',
                      controller: _rakeController,
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
                      label: 'Waste Factor',
                      unit: '%',
                      hint: '5% typical',
                      controller: _wasteController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Container()),
                ],
              ),
              const SizedBox(height: 12),
              _buildRakeToggle(colors),
              const SizedBox(height: 32),
              if (_totalLength != null) ...[
                _buildSectionHeader(colors, 'STARTER STRIP NEEDED'),
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
                'Starter Strip Calculator',
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
            'Calculate starter strip for eaves and optional rakes',
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

  Widget _buildRakeToggle(ZaftoColors colors) {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Include Rake Edges', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
              Text('Premium installation method', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            ],
          ),
          Switch(
            value: _includeRakes,
            activeColor: colors.accentPrimary,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _includeRakes = value);
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
          _buildResultRow(colors, 'TOTAL LENGTH', '${_totalLength!.toStringAsFixed(0)} lin ft', isHighlighted: true),
          const SizedBox(height: 16),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 16),
          _buildSectionHeader(colors, 'OPTION 1: STARTER ROLL'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Rolls Needed', '$_rollsNeeded (120 ft/roll)'),
          const SizedBox(height: 16),
          _buildSectionHeader(colors, 'OPTION 2: CUT SHINGLES'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Bundles Needed', '$_bundlesNeeded (~100 ft/bundle)'),
          const SizedBox(height: 16),
          Container(
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
                    'Starter strip provides adhesive strip at eave edge. Use manufacturer\'s starter for best warranty coverage.',
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
