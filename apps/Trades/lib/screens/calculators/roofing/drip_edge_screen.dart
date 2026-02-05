import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Drip Edge Calculator - Calculate drip edge and trim quantities
class DripEdgeScreen extends ConsumerStatefulWidget {
  const DripEdgeScreen({super.key});
  @override
  ConsumerState<DripEdgeScreen> createState() => _DripEdgeScreenState();
}

class _DripEdgeScreenState extends ConsumerState<DripEdgeScreen> {
  final _eaveController = TextEditingController(text: '120');
  final _rakeController = TextEditingController(text: '80');
  final _wasteController = TextEditingController(text: '5');

  String _dripEdgeType = 'Type D';

  double? _totalLength;
  int? _piecesNeeded;
  int? _nailsNeeded;

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
        _piecesNeeded = null;
        _nailsNeeded = null;
      });
      return;
    }

    // Total length including waste
    final totalLength = (eave + rake) * (1 + waste / 100);

    // Standard drip edge is 10 ft pieces
    final piecesNeeded = (totalLength / 10).ceil();

    // Nails every 12" on eave, every 8" on rake
    final eaveNails = (eave / 1).ceil();
    final rakeNails = (rake * 1.5).ceil(); // More nails on rake
    final nailsNeeded = ((eaveNails + rakeNails) * (1 + waste / 100)).ceil();

    setState(() {
      _totalLength = totalLength;
      _piecesNeeded = piecesNeeded;
      _nailsNeeded = nailsNeeded;
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
    _rakeController.text = '80';
    _wasteController.text = '5';
    setState(() => _dripEdgeType = 'Type D');
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
        title: Text('Drip Edge', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'DRIP EDGE TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOF EDGE LENGTHS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Eave Length',
                      unit: 'ft',
                      hint: 'Bottom edges',
                      controller: _eaveController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Rake Length',
                      unit: 'ft',
                      hint: 'Sloped edges',
                      controller: _rakeController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Waste Factor',
                unit: '%',
                hint: '5% typical',
                controller: _wasteController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_totalLength != null) ...[
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
              Icon(LucideIcons.cornerDownRight, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Drip Edge Calculator',
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
            'Calculate drip edge for eaves and rakes',
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
    final types = ['Type C', 'Type D', 'Type F'];
    return Row(
      children: types.map((type) {
        final isSelected = _dripEdgeType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _dripEdgeType = type);
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
              child: Text(
                type,
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
          _buildResultRow(colors, 'Total Length', '${_totalLength!.toStringAsFixed(0)} ft'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'PIECES NEEDED', '$_piecesNeeded (10 ft)', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Nails Needed', '$_nailsNeeded'),
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
                    Text('Drip Edge Types', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Type C: L-shaped, basic eave', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Type D: T-shaped, most common', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Type F: Extended hem, premium', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
