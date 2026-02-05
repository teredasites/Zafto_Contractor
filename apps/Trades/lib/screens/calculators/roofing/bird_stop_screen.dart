import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Bird Stop Calculator - Calculate bird stop/closure strip materials
class BirdStopScreen extends ConsumerStatefulWidget {
  const BirdStopScreen({super.key});
  @override
  ConsumerState<BirdStopScreen> createState() => _BirdStopScreenState();
}

class _BirdStopScreenState extends ConsumerState<BirdStopScreen> {
  final _eaveLengthController = TextEditingController(text: '100');
  final _ridgeLengthController = TextEditingController(text: '50');

  String _panelProfile = 'Corrugated';
  String _closureType = 'Foam';

  double? _eaveClosures;
  double? _ridgeClosures;
  double? _totalClosures;
  int? _sealantTubes;

  @override
  void dispose() {
    _eaveLengthController.dispose();
    _ridgeLengthController.dispose();
    super.dispose();
  }

  void _calculate() {
    final eaveLength = double.tryParse(_eaveLengthController.text);
    final ridgeLength = double.tryParse(_ridgeLengthController.text);

    if (eaveLength == null || ridgeLength == null) {
      setState(() {
        _eaveClosures = null;
        _ridgeClosures = null;
        _totalClosures = null;
        _sealantTubes = null;
      });
      return;
    }

    // Closure strips typically come in 3' lengths
    final closureLength = 3.0;

    // Eave closures (outside and inside)
    final eaveClosures = (eaveLength * 2 / closureLength).ceil() * 1.1;

    // Ridge closures (both sides)
    final ridgeClosures = (ridgeLength * 2 / closureLength).ceil() * 1.1;

    final totalClosures = eaveClosures + ridgeClosures;

    // Sealant: approximately 20 lin ft per tube
    final sealantTubes = ((eaveLength * 2 + ridgeLength * 2) / 20).ceil();

    setState(() {
      _eaveClosures = eaveClosures;
      _ridgeClosures = ridgeClosures;
      _totalClosures = totalClosures;
      _sealantTubes = sealantTubes;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _eaveLengthController.text = '100';
    _ridgeLengthController.text = '50';
    setState(() {
      _panelProfile = 'Corrugated';
      _closureType = 'Foam';
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
        title: Text('Bird Stop', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CLOSURE TYPE'),
              const SizedBox(height: 12),
              _buildProfileSelector(colors),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ROOF DIMENSIONS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Eave Length',
                      unit: 'ft',
                      hint: 'Both eaves',
                      controller: _eaveLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Ridge Length',
                      unit: 'ft',
                      hint: 'Total ridge',
                      controller: _ridgeLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_totalClosures != null) ...[
                _buildSectionHeader(colors, 'CLOSURE REQUIREMENTS'),
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
              Icon(LucideIcons.bird, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Bird Stop Calculator',
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
            'Calculate closure strips for metal roofing',
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

  Widget _buildProfileSelector(ZaftoColors colors) {
    final profiles = ['Corrugated', 'R-Panel', 'Standing Seam'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: profiles.map((profile) {
        final isSelected = _panelProfile == profile;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _panelProfile = profile);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? colors.accentPrimary : colors.bgElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? colors.accentPrimary : colors.borderSubtle,
              ),
            ),
            child: Text(
              profile,
              style: TextStyle(
                color: isSelected ? Colors.white : colors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    final types = ['Foam', 'Solid', 'Vented'];
    return Row(
      children: types.map((type) {
        final isSelected = _closureType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _closureType = type);
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
                    type == 'Foam' ? 'Standard' : (type == 'Solid' ? 'No airflow' : 'Allows air'),
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
          _buildResultRow(colors, 'Eave Closures', '${_eaveClosures!.toStringAsFixed(0)} pcs'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Ridge Closures', '${_ridgeClosures!.toStringAsFixed(0)} pcs'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL CLOSURES', '${_totalClosures!.toStringAsFixed(0)}', isHighlighted: true),
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
                    Text('Closure Tips', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Match closure profile to panel profile', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Inside closure: Prevents uplift', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Outside closure: Blocks pests', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
