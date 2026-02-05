import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Equipment Grounding Calculator - EGC sizing
class EquipmentGroundingScreen extends ConsumerStatefulWidget {
  const EquipmentGroundingScreen({super.key});
  @override
  ConsumerState<EquipmentGroundingScreen> createState() => _EquipmentGroundingScreenState();
}

class _EquipmentGroundingScreenState extends ConsumerState<EquipmentGroundingScreen> {
  final _ocpdRatingController = TextEditingController(text: '30');
  final _circuitLengthController = TextEditingController(text: '50');

  String _circuitType = 'DC Source';
  String _conductorMaterial = 'Copper';

  String? _egcSize;
  String? _requirement;
  bool? _needsIncrease;

  // EGC sizing table (NEC 250.122)
  final Map<int, String> _copperEgcTable = {
    15: '14',
    20: '12',
    30: '10',
    40: '10',
    60: '10',
    100: '8',
    200: '6',
    300: '4',
    400: '3',
    500: '2',
    600: '1',
    800: '1/0',
    1000: '2/0',
    1200: '3/0',
  };

  @override
  void dispose() {
    _ocpdRatingController.dispose();
    _circuitLengthController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final ocpdRating = int.tryParse(_ocpdRatingController.text);
    final circuitLength = double.tryParse(_circuitLengthController.text);

    if (ocpdRating == null || circuitLength == null) {
      setState(() {
        _egcSize = null;
        _requirement = null;
        _needsIncrease = null;
      });
      return;
    }

    // Find EGC size from table
    String? egcSize;
    for (final entry in _copperEgcTable.entries) {
      if (ocpdRating <= entry.key) {
        egcSize = entry.value;
        break;
      }
    }
    egcSize ??= '4/0';

    // Check if increase needed for long runs (simplified - actual calc per 250.122(B))
    bool needsIncrease = false;
    if (circuitLength > 100 && _circuitType == 'DC Source') {
      needsIncrease = true;
    }

    String requirement;
    if (_circuitType == 'DC Source') {
      requirement = 'NEC 690.43 - Equipment grounding for PV source circuits';
    } else {
      requirement = 'NEC 250.122 - Equipment grounding conductor sizing';
    }

    // Adjust for aluminum
    if (_conductorMaterial == 'Aluminum' && egcSize != null) {
      final sizeOrder = ['14', '12', '10', '8', '6', '4', '3', '2', '1', '1/0', '2/0', '3/0', '4/0'];
      final currentIdx = sizeOrder.indexOf(egcSize);
      if (currentIdx >= 0 && currentIdx < sizeOrder.length - 2) {
        egcSize = sizeOrder[currentIdx + 2]; // Two sizes larger for aluminum
      }
    }

    setState(() {
      _egcSize = egcSize;
      _requirement = requirement;
      _needsIncrease = needsIncrease;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _ocpdRatingController.text = '30';
    _circuitLengthController.text = '50';
    setState(() {
      _circuitType = 'DC Source';
      _conductorMaterial = 'Copper';
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
        title: Text('Equipment Grounding', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'CIRCUIT TYPE'),
              const SizedBox(height: 12),
              _buildCircuitTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'CIRCUIT PARAMETERS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ZaftoInputField(
                      label: 'OCPD Rating',
                      unit: 'A',
                      hint: 'Fuse/breaker',
                      controller: _ocpdRatingController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ZaftoInputField(
                      label: 'Circuit Length',
                      unit: 'ft',
                      hint: 'One-way',
                      controller: _circuitLengthController,
                      onChanged: (_) => _calculate(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMaterialSelector(colors),
              const SizedBox(height: 32),
              if (_egcSize != null) ...[
                _buildSectionHeader(colors, 'EGC SIZE'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildEgcTable(colors),
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
              Icon(LucideIcons.link, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Equipment Grounding Conductor',
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
            'Size EGC per NEC 250.122 and 690.43',
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

  Widget _buildCircuitTypeSelector(ZaftoColors colors) {
    final types = ['DC Source', 'AC Output'];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: types.map((type) {
          final isSelected = _circuitType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _circuitType = type);
                _calculate();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMaterialSelector(ZaftoColors colors) {
    final materials = ['Copper', 'Aluminum'];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: materials.map((material) {
          final isSelected = _conductorMaterial == material;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _conductorMaterial = material);
                _calculate();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentInfo : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    material,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('Minimum EGC Size', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '#$_egcSize AWG',
            style: TextStyle(color: colors.accentSuccess, fontSize: 40, fontWeight: FontWeight.w700),
          ),
          Text(
            _conductorMaterial,
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_requirement!, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
          ),
          if (_needsIncrease!) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
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
                      'Long circuit - verify EGC sizing per 250.122(B)',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEgcTable(ZaftoColors colors) {
    final commonSizes = [15, 20, 30, 60, 100, 200];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEC 250.122 EGC TABLE (COPPER)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          ...commonSizes.map((ocpd) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${ocpd}A OCPD', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                Text('#${_copperEgcTable[ocpd]} AWG', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
