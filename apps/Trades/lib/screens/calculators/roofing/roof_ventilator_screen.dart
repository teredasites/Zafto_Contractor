import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Roof Ventilator Calculator - Calculate box vent/static vent requirements
class RoofVentilatorScreen extends ConsumerStatefulWidget {
  const RoofVentilatorScreen({super.key});
  @override
  ConsumerState<RoofVentilatorScreen> createState() => _RoofVentilatorScreenState();
}

class _RoofVentilatorScreenState extends ConsumerState<RoofVentilatorScreen> {
  final _atticAreaController = TextEditingController(text: '1500');

  String _ventSize = 'Standard';
  bool _hasVaporBarrier = false;

  double? _nfaRequired;
  int? _ventsNeeded;
  double? _intakeNfa;

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
        _intakeNfa = null;
      });
      return;
    }

    // NFA required: 1:150 without vapor barrier, 1:300 with
    final ratio = _hasVaporBarrier ? 300 : 150;
    final nfaRequired = (atticArea / ratio) * 144; // sq inches

    // 50% exhaust, 50% intake
    final exhaustNfa = nfaRequired / 2;

    // NFA per box vent
    double nfaPerVent;
    switch (_ventSize) {
      case 'Small':
        nfaPerVent = 50; // ~50 sq in NFA
        break;
      case 'Standard':
        nfaPerVent = 75; // ~75 sq in NFA
        break;
      case 'Large':
        nfaPerVent = 100; // ~100 sq in NFA
        break;
      default:
        nfaPerVent = 75;
    }

    final ventsNeeded = (exhaustNfa / nfaPerVent).ceil();
    final intakeNfa = nfaRequired / 2;

    setState(() {
      _nfaRequired = nfaRequired;
      _ventsNeeded = ventsNeeded;
      _intakeNfa = intakeNfa;
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
      _ventSize = 'Standard';
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
        title: Text('Roof Ventilator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'VENT SIZE'),
              const SizedBox(height: 12),
              _buildSizeSelector(colors),
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
              if (_ventsNeeded != null) ...[
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
              Icon(LucideIcons.square, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Box Vent Calculator',
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
            'Calculate static roof ventilator requirements',
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

  Widget _buildSizeSelector(ZaftoColors colors) {
    final sizes = ['Small', 'Standard', 'Large'];
    return Row(
      children: sizes.map((size) {
        final isSelected = _ventSize == size;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _ventSize = size);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: size != sizes.last ? 8 : 0),
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
                    size,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    size == 'Small' ? '~50 NFA' : (size == 'Standard' ? '~75 NFA' : '~100 NFA'),
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

  Widget _buildVaporBarrierToggle(ZaftoColors colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _hasVaporBarrier = !_hasVaporBarrier);
        _calculate();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
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
          _buildResultRow(colors, 'Total NFA Required', '${_nfaRequired!.toStringAsFixed(0)} sq in'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'BOX VENTS NEEDED', '$_ventsNeeded', isHighlighted: true),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Intake NFA Required', '${_intakeNfa!.toStringAsFixed(0)} sq in'),
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
                    Text('Box Vent Tips', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Install near ridge, evenly spaced', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Don\'t mix with ridge vent', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Balance with soffit intake vents', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
