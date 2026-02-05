import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Roof Penetration Calculator - Calculate roof penetration sealing materials
class RoofPenetrationScreen extends ConsumerStatefulWidget {
  const RoofPenetrationScreen({super.key});
  @override
  ConsumerState<RoofPenetrationScreen> createState() => _RoofPenetrationScreenState();
}

class _RoofPenetrationScreenState extends ConsumerState<RoofPenetrationScreen> {
  final _pipeBootsController = TextEditingController(text: '3');
  final _exhaustVentsController = TextEditingController(text: '2');
  final _skylightsController = TextEditingController(text: '1');
  final _hvacCurbsController = TextEditingController(text: '0');

  int? _totalPenetrations;
  int? _flashingKits;
  int? _sealantTubes;
  int? _collars;

  @override
  void dispose() {
    _pipeBootsController.dispose();
    _exhaustVentsController.dispose();
    _skylightsController.dispose();
    _hvacCurbsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final pipeBoots = int.tryParse(_pipeBootsController.text) ?? 0;
    final exhaustVents = int.tryParse(_exhaustVentsController.text) ?? 0;
    final skylights = int.tryParse(_skylightsController.text) ?? 0;
    final hvacCurbs = int.tryParse(_hvacCurbsController.text) ?? 0;

    final totalPenetrations = pipeBoots + exhaustVents + skylights + hvacCurbs;

    // Flashing kits (one per penetration type that needs it)
    final flashingKits = exhaustVents + skylights + hvacCurbs;

    // Sealant: 1 tube per 5 penetrations
    final sealantTubes = (totalPenetrations / 5).ceil();

    // Pipe collars/boots
    final collars = pipeBoots;

    setState(() {
      _totalPenetrations = totalPenetrations;
      _flashingKits = flashingKits;
      _sealantTubes = sealantTubes < 1 ? 1 : sealantTubes;
      _collars = collars;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _pipeBootsController.text = '3';
    _exhaustVentsController.text = '2';
    _skylightsController.text = '1';
    _hvacCurbsController.text = '0';
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
        title: Text('Roof Penetration', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'PENETRATION COUNT'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Pipe Boots',
                      unit: 'qty',
                      hint: 'Plumbing vents',
                      controller: _pipeBootsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Exhaust Vents',
                      unit: 'qty',
                      hint: 'Bath/kitchen',
                      controller: _exhaustVentsController,
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
                      label: 'Skylights',
                      unit: 'qty',
                      hint: 'Count',
                      controller: _skylightsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'HVAC Curbs',
                      unit: 'qty',
                      hint: 'Roof units',
                      controller: _hvacCurbsController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_totalPenetrations != null && _totalPenetrations! > 0) ...[
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
              Icon(LucideIcons.circleDot, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Roof Penetration Calculator',
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
            'Calculate flashing and sealing materials',
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
          _buildResultRow(colors, 'TOTAL PENETRATIONS', '$_totalPenetrations', isHighlighted: true),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          if (_collars! > 0)
            _buildResultRow(colors, 'Pipe Boots/Collars', '$_collars'),
          if (_collars! > 0)
            const SizedBox(height: 8),
          if (_flashingKits! > 0)
            _buildResultRow(colors, 'Flashing Kits', '$_flashingKits'),
          if (_flashingKits! > 0)
            const SizedBox(height: 8),
          _buildResultRow(colors, 'Sealant Tubes', '$_sealantTubes'),
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
                    Text('Penetration Tips', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Flash all penetrations per mfr specs', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Use appropriate sealant for material', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Check boots/collars annually', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
