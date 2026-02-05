import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Flashing Calculator - Estimate flashing materials needed
class FlashingScreen extends ConsumerStatefulWidget {
  const FlashingScreen({super.key});
  @override
  ConsumerState<FlashingScreen> createState() => _FlashingScreenState();
}

class _FlashingScreenState extends ConsumerState<FlashingScreen> {
  final _chimneyCountController = TextEditingController(text: '1');
  final _skylightCountController = TextEditingController(text: '0');
  final _pipeCountController = TextEditingController(text: '3');
  final _valleyLengthController = TextEditingController(text: '30');
  final _wallLengthController = TextEditingController(text: '20');

  double? _valleyFlashing;
  double? _stepFlashing;
  int? _pipeBoots;
  int? _chimneyKits;
  int? _skylightKits;
  double? _totalCost;

  @override
  void dispose() {
    _chimneyCountController.dispose();
    _skylightCountController.dispose();
    _pipeCountController.dispose();
    _valleyLengthController.dispose();
    _wallLengthController.dispose();
    super.dispose();
  }

  void _calculate() {
    final chimneyCount = int.tryParse(_chimneyCountController.text);
    final skylightCount = int.tryParse(_skylightCountController.text);
    final pipeCount = int.tryParse(_pipeCountController.text);
    final valleyLength = double.tryParse(_valleyLengthController.text);
    final wallLength = double.tryParse(_wallLengthController.text);

    if (chimneyCount == null || skylightCount == null || pipeCount == null ||
        valleyLength == null || wallLength == null) {
      setState(() {
        _valleyFlashing = null;
        _stepFlashing = null;
        _pipeBoots = null;
        _chimneyKits = null;
        _skylightKits = null;
        _totalCost = null;
      });
      return;
    }

    // Valley flashing (add 10% for overlap)
    final valleyFlashing = valleyLength * 1.1;

    // Step flashing pieces (one every 5" of wall length)
    final stepFlashing = (wallLength * 12 / 5).ceil().toDouble();

    // Pipe boots
    final pipeBoots = pipeCount;

    // Chimney kits
    final chimneyKits = chimneyCount;

    // Skylight kits
    final skylightKits = skylightCount;

    // Rough cost estimate
    // Valley: $3/ft, Step: $1 each, Pipe boot: $15, Chimney: $75, Skylight: $50
    final totalCost = (valleyFlashing * 3) + (stepFlashing * 1) +
        (pipeBoots * 15) + (chimneyKits * 75) + (skylightKits * 50);

    setState(() {
      _valleyFlashing = valleyFlashing;
      _stepFlashing = stepFlashing;
      _pipeBoots = pipeBoots;
      _chimneyKits = chimneyKits;
      _skylightKits = skylightKits;
      _totalCost = totalCost;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _chimneyCountController.text = '1';
    _skylightCountController.text = '0';
    _pipeCountController.text = '3';
    _valleyLengthController.text = '30';
    _wallLengthController.text = '20';
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
        title: Text('Flashing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'PENETRATIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Chimneys',
                      unit: 'qty',
                      hint: 'Count',
                      controller: _chimneyCountController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Skylights',
                      unit: 'qty',
                      hint: 'Count',
                      controller: _skylightCountController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Vent Pipes',
                unit: 'qty',
                hint: 'Plumbing vents',
                controller: _pipeCountController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LINEAR FLASHING'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Valley',
                      unit: 'ft',
                      hint: 'Total length',
                      controller: _valleyLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Wall Abutment',
                      unit: 'ft',
                      hint: 'Step flashing',
                      controller: _wallLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_valleyFlashing != null) ...[
                _buildSectionHeader(colors, 'FLASHING MATERIALS'),
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
              Icon(LucideIcons.shield, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Flashing Calculator',
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
            'Estimate flashing materials for all penetrations',
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
          _buildResultRow(colors, 'Valley Flashing', '${_valleyFlashing!.toStringAsFixed(0)} lin ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Step Flashing', '${_stepFlashing!.toStringAsFixed(0)} pieces'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Pipe Boots', '$_pipeBoots'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Chimney Kits', '$_chimneyKits'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Skylight Kits', '$_skylightKits'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'EST. MATERIAL COST', '\$${_totalCost!.toStringAsFixed(0)}', isHighlighted: true),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, size: 16, color: colors.accentWarning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Proper flashing is critical. Most roof leaks occur at penetrations and transitions.',
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
