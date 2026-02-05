import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Grounding Electrode Calculator - PV system grounding
class GroundingElectrodeScreen extends ConsumerStatefulWidget {
  const GroundingElectrodeScreen({super.key});
  @override
  ConsumerState<GroundingElectrodeScreen> createState() => _GroundingElectrodeScreenState();
}

class _GroundingElectrodeScreenState extends ConsumerState<GroundingElectrodeScreen> {
  String _systemType = 'Separate GES';
  String _groundingMethod = 'Ground Rod';
  final _systemSizeController = TextEditingController(text: '10');

  String? _gecSize;
  String? _requirement;
  List<String>? _notes;

  @override
  void dispose() {
    _systemSizeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final systemSize = double.tryParse(_systemSizeController.text) ?? 10;

    String gecSize;
    String requirement;
    List<String> notes = [];

    if (_systemType == 'Bonded to Building') {
      requirement = 'NEC 690.47(B) - Bond to existing building grounding system';
      gecSize = '#6 AWG copper minimum';
      notes = [
        'Connect to existing grounding electrode system',
        'Bond at service equipment or first disconnect',
        'Most common for residential rooftop systems',
        'Single point of ground reference',
      ];
    } else {
      requirement = 'NEC 690.47(D) - Separate grounding electrode system';

      // GEC sizing based on array size (simplified)
      if (systemSize <= 10) {
        gecSize = '#6 AWG copper';
      } else if (systemSize <= 25) {
        gecSize = '#4 AWG copper';
      } else {
        gecSize = '#2 AWG copper';
      }

      if (_groundingMethod == 'Ground Rod') {
        notes = [
          '5/8" × 8ft copper-clad ground rod minimum',
          'Two rods required if resistance >25 ohms',
          'Rods spaced 6ft apart minimum',
          'Must be bonded to building GES',
        ];
      } else if (_groundingMethod == 'Ufer Ground') {
        notes = [
          '20ft of #4 AWG bare copper in concrete',
          'Rebar cage also acceptable',
          'Very low resistance electrode',
          'Common for ground mount systems',
        ];
      } else {
        notes = [
          'Ground plate must be minimum 2 sq ft',
          'In direct contact with earth',
          'Less common for PV systems',
        ];
      }
    }

    setState(() {
      _gecSize = gecSize;
      _requirement = requirement;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _systemSizeController.text = '10';
    setState(() {
      _systemType = 'Separate GES';
      _groundingMethod = 'Ground Rod';
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
        title: Text('Grounding Electrode', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'GROUNDING APPROACH'),
              const SizedBox(height: 12),
              _buildSystemTypeSelector(colors),
              if (_systemType == 'Separate GES') ...[
                const SizedBox(height: 24),
                _buildSectionHeader(colors, 'ELECTRODE TYPE'),
                const SizedBox(height: 12),
                _buildMethodSelector(colors),
              ],
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SYSTEM SIZE'),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'Array Size',
                unit: 'kW',
                hint: 'DC capacity',
                controller: _systemSizeController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_gecSize != null) ...[
                _buildSectionHeader(colors, 'GROUNDING REQUIREMENTS'),
                const SizedBox(height: 12),
                _buildResultsCard(colors),
                const SizedBox(height: 16),
                _buildNotesCard(colors),
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
              Icon(LucideIcons.anchor, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Grounding Electrode System',
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
            'PV system grounding per NEC 690.47',
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

  Widget _buildSystemTypeSelector(ZaftoColors colors) {
    final types = ['Bonded to Building', 'Separate GES'];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: types.map((type) {
          final isSelected = _systemType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _systemType = type);
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
                      fontSize: 12,
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

  Widget _buildMethodSelector(ZaftoColors colors) {
    final methods = ['Ground Rod', 'Ufer Ground', 'Ground Plate'];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: methods.map((method) {
          final isSelected = _groundingMethod == method;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _groundingMethod = method);
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
                    method,
                    style: TextStyle(
                      color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary,
                      fontSize: 11,
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
          Text('Grounding Electrode Conductor', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            _gecSize!,
            style: TextStyle(color: colors.accentSuccess, fontSize: 28, fontWeight: FontWeight.w700),
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
        ],
      ),
    );
  }

  Widget _buildNotesCard(ZaftoColors colors) {
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
          Text('INSTALLATION NOTES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          ...(_notes ?? []).map((note) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, size: 14, color: colors.accentInfo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(note, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
