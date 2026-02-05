import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Gable Vent Calculator - Calculate gable end ventilation requirements
class GableVentScreen extends ConsumerStatefulWidget {
  const GableVentScreen({super.key});
  @override
  ConsumerState<GableVentScreen> createState() => _GableVentScreenState();
}

class _GableVentScreenState extends ConsumerState<GableVentScreen> {
  final _atticAreaController = TextEditingController(text: '1500');

  String _ventStyle = 'Rectangular';
  bool _hasVaporBarrier = false;

  double? _nfaRequired;
  int? _ventsNeeded;
  String? _recommendedSize;

  @override
  void dispose() {
    _atticAreaController.dispose();
    super.dispose();
  }

  void _calculate() {
    final atticArea = double.tryParse(_atticAreaController.text);

    if (atticArea == null) {
      setState(() {
        _nfaRequired = null;
        _ventsNeeded = null;
        _recommendedSize = null;
      });
      return;
    }

    // NFA (Net Free Area) requirements
    // 1:150 ratio without vapor barrier, 1:300 with vapor barrier
    final ratio = _hasVaporBarrier ? 300 : 150;
    final nfaRequired = (atticArea / ratio) * 144; // Convert to sq inches

    // Each gable (2 gables) gets half the ventilation
    final nfaPerGable = nfaRequired / 2;

    // Standard gable vent sizes and their NFA:
    // 12×12: ~50 sq in NFA
    // 14×24: ~120 sq in NFA
    // 18×24: ~150 sq in NFA
    // 22×28: ~200 sq in NFA

    int ventsNeeded;
    String recommendedSize;

    if (_ventStyle == 'Rectangular') {
      if (nfaPerGable <= 50) {
        ventsNeeded = 2;
        recommendedSize = '12×12"';
      } else if (nfaPerGable <= 120) {
        ventsNeeded = 2;
        recommendedSize = '14×24"';
      } else if (nfaPerGable <= 150) {
        ventsNeeded = 2;
        recommendedSize = '18×24"';
      } else {
        ventsNeeded = 2;
        recommendedSize = '22×28"';
      }
    } else if (_ventStyle == 'Triangle') {
      // Triangular vents: 24" base ~100 sq in NFA
      ventsNeeded = 2;
      recommendedSize = '24" base triangle';
    } else {
      // Round/octagon: 22" ~80 sq in NFA
      ventsNeeded = 2;
      recommendedSize = '22" octagon';
    }

    setState(() {
      _nfaRequired = nfaRequired;
      _ventsNeeded = ventsNeeded;
      _recommendedSize = recommendedSize;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _atticAreaController.text = '1500';
    setState(() {
      _ventStyle = 'Rectangular';
      _hasVaporBarrier = false;
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
        title: Text('Gable Vent', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'VENT STYLE'),
              const SizedBox(height: 12),
              _buildStyleSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ATTIC SPECIFICATIONS'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Attic Floor Area',
                unit: 'sq ft',
                hint: 'Total attic space',
                controller: _atticAreaController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 12),
              _buildVaporBarrierToggle(colors),
              const SizedBox(height: 32),
              if (_nfaRequired != null) ...[
                _buildSectionHeader(colors, 'VENTILATION REQUIREMENTS'),
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
              Icon(LucideIcons.wind, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Gable Vent Calculator',
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
            'Calculate gable end ventilation sizing',
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

  Widget _buildStyleSelector(ZaftoColors colors) {
    final styles = ['Rectangular', 'Triangle', 'Octagon'];
    return Row(
      children: styles.map((style) {
        final isSelected = _ventStyle == style;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _ventStyle = style);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: style != styles.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                style,
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

  Widget _buildVaporBarrierToggle(ZaftoColors colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _hasVaporBarrier = !_hasVaporBarrier);
        _calculate();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(
              _hasVaporBarrier ? LucideIcons.checkSquare : LucideIcons.square,
              color: _hasVaporBarrier ? colors.accentPrimary : colors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vapor Barrier Present',
                    style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Allows 1:300 ratio instead of 1:150',
                    style: TextStyle(color: colors.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          _buildResultRow(colors, 'TOTAL NFA REQUIRED', '${_nfaRequired!.toStringAsFixed(0)} sq in', isHighlighted: true),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Gable Vents Needed', '$_ventsNeeded'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Recommended Size', _recommendedSize!),
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
                    Text('Gable Vent Info', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('NFA = Net Free Area (actual airflow)', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Install one vent on each gable end', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Works best with soffit vents', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
