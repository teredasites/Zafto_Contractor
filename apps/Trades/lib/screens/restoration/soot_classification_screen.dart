// ZAFTO Soot Classification Screen
// Soot type identification, affected surfaces per room, cleaning method recommendation
// Sprint REST1 — Fire restoration dedicated tools

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../models/fire_assessment.dart';

class SootClassificationScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String? fireAssessmentId;

  const SootClassificationScreen({
    super.key,
    required this.jobId,
    this.fireAssessmentId,
  });

  @override
  ConsumerState<SootClassificationScreen> createState() =>
      _SootClassificationScreenState();
}

class _SootClassificationScreenState
    extends ConsumerState<SootClassificationScreen> {
  SootType? _selectedType;

  static const _surfaceTypes = [
    'Drywall', 'Wood Trim', 'Ceiling Tile', 'Carpet', 'Hard Floor',
    'Concrete', 'Metal', 'Glass', 'Fabric/Upholstery', 'Plastic',
    'Brick/Stone', 'Laminate', 'Vinyl', 'HVAC Ductwork', 'Electrical',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Soot Classification')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(colors, 'IDENTIFY SOOT TYPE'),
          const SizedBox(height: 8),
          Text(
            'Select the soot type present. Each type requires a different cleaning approach. '
            'If multiple types are present, select "Mixed."',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 16),

          ...SootType.values.map((type) => _buildSootCard(colors, type)),

          if (_selectedType != null) ...[
            const SizedBox(height: 24),
            _sectionHeader(colors, 'CLEANING RECOMMENDATION'),
            const SizedBox(height: 8),
            _buildCleaningInfo(colors, _selectedType!),

            const SizedBox(height: 24),
            _sectionHeader(colors, 'AFFECTED SURFACES CHECKLIST'),
            const SizedBox(height: 8),
            ..._surfaceTypes.map((s) => _buildSurfaceRow(colors, s)),

            const SizedBox(height: 24),
            _sectionHeader(colors, 'SAFETY REMINDERS'),
            const SizedBox(height: 8),
            _safetyCard(colors, 'Always wear appropriate PPE (N95 minimum, P100 for protein/fuel oil)'),
            const SizedBox(height: 8),
            _safetyCard(colors, 'Test cleaning method on small inconspicuous area first'),
            const SizedBox(height: 8),
            _safetyCard(colors, 'Work top-down: ceiling first, then walls, then floor'),
            const SizedBox(height: 8),
            _safetyCard(colors, 'Never use water on dry smoke soot — it smears and sets stains'),
            const SizedBox(height: 8),
            if (_selectedType == SootType.fuelOil)
              _safetyCard(colors, 'Fuel oil soot is hazardous — use solvent-rated gloves and goggles'),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSootCard(ZaftoColors colors, SootType type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? colors.bgInset : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.orange : colors.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 20,
                  color: isSelected ? Colors.orange : colors.textTertiary,
                ),
                const SizedBox(width: 10),
                Text(type.label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: colors.textPrimary)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 4),
              child: Text(type.description,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleaningInfo(ZaftoColors colors, SootType type) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Text('${type.label} — Cleaning Method',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(type.cleaningMethod,
              style: TextStyle(fontSize: 13, color: colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSurfaceRow(ZaftoColors colors, String surface) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: false,
              onChanged: (_) {},
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Text(surface,
              style: TextStyle(fontSize: 13, color: colors.textPrimary)),
        ],
      ),
    );
  }

  Widget _safetyCard(ZaftoColors colors, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.shieldAlert, size: 16, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12, color: colors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(ZaftoColors colors, String label) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'SF Pro Text',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: colors.textTertiary,
      ),
    );
  }
}
