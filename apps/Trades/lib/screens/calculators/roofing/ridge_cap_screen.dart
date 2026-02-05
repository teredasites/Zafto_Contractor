import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Ridge Cap Calculator - Calculate ridge cap shingles and materials
class RidgeCapScreen extends ConsumerStatefulWidget {
  const RidgeCapScreen({super.key});
  @override
  ConsumerState<RidgeCapScreen> createState() => _RidgeCapScreenState();
}

class _RidgeCapScreenState extends ConsumerState<RidgeCapScreen> {
  final _ridgeController = TextEditingController(text: '40');
  final _hipController = TextEditingController(text: '60');
  final _wasteController = TextEditingController(text: '10');

  String _ridgeType = 'Standard';

  double? _totalLength;
  int? _bundlesNeeded;
  int? _piecesNeeded;
  int? _nailsNeeded;

  @override
  void dispose() {
    _ridgeController.dispose();
    _hipController.dispose();
    _wasteController.dispose();
    super.dispose();
  }

  void _calculate() {
    final ridge = double.tryParse(_ridgeController.text);
    final hip = double.tryParse(_hipController.text);
    final waste = double.tryParse(_wasteController.text);

    if (ridge == null || hip == null || waste == null) {
      setState(() {
        _totalLength = null;
        _bundlesNeeded = null;
        _piecesNeeded = null;
        _nailsNeeded = null;
      });
      return;
    }

    // Total linear feet including waste
    final totalLength = (ridge + hip) * (1 + waste / 100);

    // Coverage varies by type
    double coveragePerBundle;
    int piecesPerBundle;
    switch (_ridgeType) {
      case 'Standard':
        coveragePerBundle = 20; // 20 lin ft per bundle
        piecesPerBundle = 30;
        break;
      case 'High Profile':
        coveragePerBundle = 20;
        piecesPerBundle = 25;
        break;
      case 'Hip & Ridge':
        coveragePerBundle = 25; // Covers 25 lin ft
        piecesPerBundle = 30;
        break;
      default:
        coveragePerBundle = 20;
        piecesPerBundle = 30;
    }

    final bundlesNeeded = (totalLength / coveragePerBundle).ceil();
    final piecesNeeded = (totalLength * piecesPerBundle / coveragePerBundle).ceil();

    // 2 nails per cap piece
    final nailsNeeded = piecesNeeded * 2;

    setState(() {
      _totalLength = totalLength;
      _bundlesNeeded = bundlesNeeded;
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
    _ridgeController.text = '40';
    _hipController.text = '60';
    _wasteController.text = '10';
    setState(() => _ridgeType = 'Standard');
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
        title: Text('Ridge Cap', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'RIDGE CAP TYPE'),
              const SizedBox(height: 12),
              _buildTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LINEAR FEET'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Ridge',
                      unit: 'ft',
                      hint: 'Ridge length',
                      controller: _ridgeController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Hips',
                      unit: 'ft',
                      hint: 'Total hip length',
                      controller: _hipController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Waste Factor',
                unit: '%',
                hint: '10% typical',
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
              Icon(LucideIcons.moveHorizontal, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Ridge Cap Calculator',
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
            'Calculate ridge cap for ridges and hips',
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
    final types = ['Standard', 'High Profile', 'Hip & Ridge'];
    return Row(
      children: types.map((type) {
        final isSelected = _ridgeType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _ridgeType = type);
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
                  fontSize: 11,
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
          _buildResultRow(colors, 'Total Length', '${_totalLength!.toStringAsFixed(0)} lin ft'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'BUNDLES NEEDED', '$_bundlesNeeded', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Cap Pieces', '$_piecesNeeded'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Nails Needed', '$_nailsNeeded'),
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
                    'Standard bundle covers ~20 lin ft. Use matching manufacturer ridge cap for warranty.',
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
            fontSize: isHighlighted ? 20 : 14,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
