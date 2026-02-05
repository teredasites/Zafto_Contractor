import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Ridge Vent Calculator - Calculate ridge exhaust ventilation
class RidgeVentScreen extends ConsumerStatefulWidget {
  const RidgeVentScreen({super.key});
  @override
  ConsumerState<RidgeVentScreen> createState() => _RidgeVentScreenState();
}

class _RidgeVentScreenState extends ConsumerState<RidgeVentScreen> {
  final _atticAreaController = TextEditingController(text: '1500');
  final _ridgeLengthController = TextEditingController(text: '40');

  String _ventStyle = 'Standard';

  double? _nfaRequired;
  double? _ridgeVentNeeded;
  bool? _ridgeSufficient;
  double? _nfaPerFoot;

  @override
  void dispose() {
    _atticAreaController.dispose();
    _ridgeLengthController.dispose();
    super.dispose();
  }

  void _calculate() {
    final atticArea = double.tryParse(_atticAreaController.text);
    final ridgeLength = double.tryParse(_ridgeLengthController.text);

    if (atticArea == null || ridgeLength == null) {
      setState(() {
        _nfaRequired = null;
        _ridgeVentNeeded = null;
        _ridgeSufficient = null;
        _nfaPerFoot = null;
      });
      return;
    }

    // Total NFA required (1:300 ratio, 50% exhaust)
    // Exhaust NFA = attic area / 300 / 2
    final nfaRequired = atticArea / 300 / 2; // in sq ft
    final nfaRequiredSqIn = nfaRequired * 144;

    // NFA per foot varies by vent style
    double nfaPerFoot;
    switch (_ventStyle) {
      case 'Standard':
        nfaPerFoot = 18; // sq in per lin ft
        break;
      case 'High Profile':
        nfaPerFoot = 24;
        break;
      case 'Shingle-Over':
        nfaPerFoot = 16;
        break;
      default:
        nfaPerFoot = 18;
    }

    // Ridge vent needed
    final ridgeVentNeeded = nfaRequiredSqIn / nfaPerFoot;

    // Check if available ridge is sufficient
    final ridgeSufficient = ridgeLength >= ridgeVentNeeded;

    setState(() {
      _nfaRequired = nfaRequired;
      _ridgeVentNeeded = ridgeVentNeeded;
      _ridgeSufficient = ridgeSufficient;
      _nfaPerFoot = nfaPerFoot;
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
    _ridgeLengthController.text = '40';
    setState(() => _ventStyle = 'Standard');
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
        title: Text('Ridge Vent', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ATTIC & RIDGE'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Attic Area',
                      unit: 'sq ft',
                      hint: 'Floor area',
                      controller: _atticAreaController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Ridge Length',
                      unit: 'ft',
                      hint: 'Available ridge',
                      controller: _ridgeLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'RIDGE VENT STYLE'),
              const SizedBox(height: 12),
              _buildStyleSelector(colors),
              const SizedBox(height: 32),
              if (_nfaRequired != null) ...[
                _buildSectionHeader(colors, 'EXHAUST VENTILATION'),
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
              Icon(LucideIcons.arrowUpFromLine, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Ridge Vent Calculator',
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
            'Calculate ridge exhaust ventilation needs',
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
    final styles = ['Standard', 'High Profile', 'Shingle-Over'];
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
    final statusColor = _ridgeSufficient! ? colors.accentSuccess : colors.accentWarning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _ridgeSufficient! ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _ridgeSufficient! ? 'Ridge Sufficient' : 'Additional Vents Needed',
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildResultRow(colors, 'NFA Required (Exhaust)', '${(_nfaRequired! * 144).toStringAsFixed(0)} sq in'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Vent NFA per Foot', '${_nfaPerFoot!.toStringAsFixed(0)} sq in/ft'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'RIDGE VENT NEEDED', '${_ridgeVentNeeded!.toStringAsFixed(0)} lin ft', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Ridge Available', '${double.tryParse(_ridgeLengthController.text)?.toStringAsFixed(0)} lin ft'),
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
                    Text('NFA by Style', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Standard: 18 sq in/ft', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('High Profile: 24 sq in/ft', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Shingle-Over: 16 sq in/ft', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
