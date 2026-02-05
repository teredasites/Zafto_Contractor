import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Ground Fault Protection Calculator - GFP requirements
class GroundFaultProtectionScreen extends ConsumerStatefulWidget {
  const GroundFaultProtectionScreen({super.key});
  @override
  ConsumerState<GroundFaultProtectionScreen> createState() => _GroundFaultProtectionScreenState();
}

class _GroundFaultProtectionScreenState extends ConsumerState<GroundFaultProtectionScreen> {
  String _systemType = 'Grounded';
  String _arrayType = 'Rooftop';
  final _systemVoltageController = TextEditingController(text: '600');

  bool? _gfpRequired;
  String? _tripThreshold;
  String? _requirement;
  List<String>? _notes;

  @override
  void dispose() {
    _systemVoltageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final systemVoltage = double.tryParse(_systemVoltageController.text) ?? 600;

    bool gfpRequired;
    String tripThreshold;
    String requirement;
    List<String> notes = [];

    if (_systemType == 'Ungrounded') {
      gfpRequired = false;
      tripThreshold = 'N/A';
      requirement = 'NEC 690.35 - Ungrounded systems exempt from GFP';
      notes = [
        'Must have ground fault indication (not protection)',
        'All conductors treated as ungrounded',
        'Common with transformer-less inverters',
      ];
    } else {
      // Grounded system
      gfpRequired = true;

      if (_arrayType == 'Ground Mount' && systemVoltage > 50) {
        tripThreshold = '5A max (dc ground fault detection)';
        requirement = 'NEC 690.41 - Ground fault detection required';
      } else {
        tripThreshold = '1A typical for residential';
        requirement = 'NEC 690.41 - GFP required for grounded DC systems';
      }

      notes = [
        'GFP built into most string inverters',
        'Detects faults between current-carrying and grounded conductors',
        'Must interrupt or provide indication of fault',
        'Fire safety requirement per 690.41',
      ];
    }

    setState(() {
      _gfpRequired = gfpRequired;
      _tripThreshold = tripThreshold;
      _requirement = requirement;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _systemVoltageController.text = '600';
    setState(() {
      _systemType = 'Grounded';
      _arrayType = 'Rooftop';
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
        title: Text('Ground Fault Protection', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'SYSTEM GROUNDING'),
              const SizedBox(height: 12),
              _buildSystemTypeSelector(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'ARRAY TYPE'),
              const SizedBox(height: 12),
              _buildArrayTypeSelector(colors),
              const SizedBox(height: 12),
              ZaftoInputField(
                label: 'System Voltage',
                unit: 'V',
                hint: 'Max DC voltage',
                controller: _systemVoltageController,
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 32),
              if (_gfpRequired != null) ...[
                _buildSectionHeader(colors, 'GFP REQUIREMENTS'),
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
              Icon(LucideIcons.shield, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Ground Fault Protection',
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
            'Determine GFP requirements per NEC 690.41',
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
    final types = ['Grounded', 'Ungrounded'];
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

  Widget _buildArrayTypeSelector(ZaftoColors colors) {
    final types = ['Rooftop', 'Ground Mount'];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: types.map((type) {
          final isSelected = _arrayType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _arrayType = type);
                _calculate();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentInfo : Colors.transparent,
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

  Widget _buildResultsCard(ZaftoColors colors) {
    final statusColor = _gfpRequired! ? colors.accentWarning : colors.accentInfo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _gfpRequired! ? LucideIcons.shieldCheck : LucideIcons.shieldOff,
                color: statusColor,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                _gfpRequired! ? 'GFP REQUIRED' : 'GFP NOT REQUIRED',
                style: TextStyle(color: statusColor, fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_requirement!, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                if (_gfpRequired!) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Trip Threshold', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                      Text(_tripThreshold!, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ],
            ),
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
          Text('KEY POINTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
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
