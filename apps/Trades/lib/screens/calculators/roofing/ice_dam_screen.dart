import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Ice Dam Protection Calculator - Calculate ice & water shield coverage
class IceDamScreen extends ConsumerStatefulWidget {
  const IceDamScreen({super.key});
  @override
  ConsumerState<IceDamScreen> createState() => _IceDamScreenState();
}

class _IceDamScreenState extends ConsumerState<IceDamScreen> {
  final _eaveLengthController = TextEditingController(text: '120');
  final _valleyLengthController = TextEditingController(text: '40');
  final _wallLengthController = TextEditingController(text: '30');
  final _overhangController = TextEditingController(text: '12');

  String _climateZone = 'Cold';

  double? _eaveProtection;
  double? _valleyProtection;
  double? _wallProtection;
  double? _totalArea;
  int? _rollsNeeded;

  @override
  void dispose() {
    _eaveLengthController.dispose();
    _valleyLengthController.dispose();
    _wallLengthController.dispose();
    _overhangController.dispose();
    super.dispose();
  }

  void _calculate() {
    final eaveLength = double.tryParse(_eaveLengthController.text);
    final valleyLength = double.tryParse(_valleyLengthController.text);
    final wallLength = double.tryParse(_wallLengthController.text);
    final overhang = double.tryParse(_overhangController.text);

    if (eaveLength == null || valleyLength == null || wallLength == null || overhang == null) {
      setState(() {
        _eaveProtection = null;
        _valleyProtection = null;
        _wallProtection = null;
        _totalArea = null;
        _rollsNeeded = null;
      });
      return;
    }

    // Ice dam protection width (code requirement: 24" past interior wall line)
    // Plus overhang = overhang + 24"
    final overhangFt = overhang / 12;
    double eaveWidth;
    switch (_climateZone) {
      case 'Cold':
        eaveWidth = overhangFt + 3; // 3 ft (36") past exterior wall
        break;
      case 'Severe':
        eaveWidth = overhangFt + 4; // 4 ft for severe climates
        break;
      default:
        eaveWidth = overhangFt + 2; // Minimum 24" past wall
    }

    // Valley protection: full length, 3 ft wide
    const valleyWidth = 3.0;

    // Wall/roof junction: 3 ft up the roof
    const wallWidth = 3.0;

    final eaveProtection = eaveLength * eaveWidth;
    final valleyProtection = valleyLength * valleyWidth;
    final wallProtection = wallLength * wallWidth;

    final totalArea = eaveProtection + valleyProtection + wallProtection;

    // Rolls: typically 75 sq ft per roll (with overlap)
    final rollsNeeded = (totalArea / 65).ceil(); // Account for overlap

    setState(() {
      _eaveProtection = eaveProtection;
      _valleyProtection = valleyProtection;
      _wallProtection = wallProtection;
      _totalArea = totalArea;
      _rollsNeeded = rollsNeeded;
    });
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _eaveLengthController.text = '120';
    _valleyLengthController.text = '40';
    _wallLengthController.text = '30';
    _overhangController.text = '12';
    setState(() => _climateZone = 'Cold');
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
        title: Text('Ice Dam Protection', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CLIMATE ZONE'),
              const SizedBox(height: 12),
              _buildClimateSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'PROTECTION AREAS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Eave Length',
                      unit: 'ft',
                      hint: 'Total eaves',
                      controller: _eaveLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Overhang',
                      unit: 'in',
                      hint: 'Eave depth',
                      controller: _overhangController,
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
                      label: 'Valley Length',
                      unit: 'ft',
                      hint: 'Total valleys',
                      controller: _valleyLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Wall Length',
                      unit: 'ft',
                      hint: 'Roof/wall junctions',
                      controller: _wallLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_totalArea != null) ...[
                _buildSectionHeader(colors, 'ICE & WATER SHIELD'),
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
              Icon(LucideIcons.snowflake, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Ice Dam Protection',
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
            'Calculate ice & water shield membrane coverage',
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

  Widget _buildClimateSelector(ZaftoColors colors) {
    final climates = ['Moderate', 'Cold', 'Severe'];
    return Row(
      children: climates.map((climate) {
        final isSelected = _climateZone == climate;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _climateZone = climate);
              _calculate();
            },
            child: Container(
              margin: EdgeInsets.only(right: climate != climates.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentPrimary : colors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                climate,
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
          _buildResultRow(colors, 'Eave Protection', '${_eaveProtection!.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Valley Protection', '${_valleyProtection!.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Wall Junction', '${_wallProtection!.toStringAsFixed(0)} sq ft'),
          const SizedBox(height: 12),
          Divider(color: colors.borderSubtle),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'TOTAL AREA', '${_totalArea!.toStringAsFixed(0)} sq ft', isHighlighted: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'ROLLS NEEDED', '$_rollsNeeded', isHighlighted: true),
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
                    Text('Code Requirements', style: TextStyle(color: colors.accentInfo, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('IRC R905.2.8.2: Ice barrier extends 24" past interior wall line', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                Text('Cover all eaves, valleys, and penetrations', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
