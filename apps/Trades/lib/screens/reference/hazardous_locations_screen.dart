/// Hazardous Locations Reference - Design System v2.6
/// NEC Articles 500-516 classification guide
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/state_preferences_service.dart';
import '../../widgets/expandable_reference_card.dart';

class HazardousLocationsScreen extends ConsumerWidget {
  const HazardousLocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    final necBadge = ref.watch(necEditionBadgeProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Hazardous Locations', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NecEditionBadge(edition: necBadge, colors: colors),
            const SizedBox(height: 16),
            _buildWarning(colors),
            const SizedBox(height: 16),
            _buildClassSystem(colors),
            const SizedBox(height: 16),
            _buildDivisions(colors),
            const SizedBox(height: 16),
            _buildGroups(colors),
            const SizedBox(height: 16),
            _buildZoneSystem(colors),
            const SizedBox(height: 16),
            _buildCommonLocations(colors),
            const SizedBox(height: 16),
            _buildEquipmentMarking(colors),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWarning(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentError.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentError, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 24),
              const SizedBox(width: 10),
              Expanded(child: Text('SPECIALIZED WORK - NEC ARTICLES 500-516', style: TextStyle(color: colors.accentError, fontSize: 14, fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Hazardous location wiring requires specialized training, equipment, and often engineering involvement. Improper installation can cause explosions and death. This is reference info only.',
            style: TextStyle(color: colors.textPrimary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSystem(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Class System (Type of Hazard)', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _classRow('Class I', 'Flammable GASES or VAPORS', 'Gasoline, propane, acetylene, hydrogen', colors.accentError, colors),
          const SizedBox(height: 8),
          _classRow('Class II', 'Combustible DUST', 'Grain, coal, flour, metal dust, plastic dust', colors.accentWarning, colors),
          const SizedBox(height: 8),
          _classRow('Class III', 'Ignitable FIBERS/FLYINGS', 'Cotton, wood chips, textile fibers', colors.accentPrimary, colors),
        ],
      ),
    );
  }

  Widget _classRow(String classType, String hazard, String examples, Color accentColor, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(classType, style: TextStyle(color: accentColor, fontWeight: FontWeight.w700, fontSize: 14)),
          Text(hazard, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
          Text(examples, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildDivisions(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Divisions (Likelihood of Hazard)', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _divRow('Division 1', 'Hazard EXISTS during normal operation', 'More stringent requirements', colors.accentError, colors),
          const SizedBox(height: 8),
          _divRow('Division 2', 'Hazard only during ABNORMAL conditions', 'Less stringent, but still special equipment', colors.accentWarning, colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Example: Spray booth interior = Div 1\nArea around spray booth = Div 2',
              style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divRow(String div, String when, String req, Color accentColor, ZaftoColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(div, style: TextStyle(color: accentColor, fontWeight: FontWeight.w600, fontSize: 11)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(when, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
              Text(req, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroups(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Groups (Specific Materials)', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text('Class I Groups (Gases):', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _groupRow('A', 'Acetylene (most dangerous)', colors),
          _groupRow('B', 'Hydrogen, fuel gases', colors),
          _groupRow('C', 'Ethylene, cyclopropane', colors),
          _groupRow('D', 'Gasoline, propane, natural gas (most common)', colors),
          const SizedBox(height: 12),
          Text('Class II Groups (Dusts):', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _groupRow('E', 'Metal dusts (aluminum, magnesium)', colors),
          _groupRow('F', 'Carbon dusts (coal, charcoal)', colors),
          _groupRow('G', 'Grain, flour, plastic, wood dust', colors),
        ],
      ),
    );
  }

  Widget _groupRow(String group, String materials, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(child: Text(group, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 13))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(materials, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildZoneSystem(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.globe, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text('Zone System (IEC/Alternative)', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text('NEC Articles 505/506 allow Zone classification:', style: TextStyle(color: colors.textPrimary, fontSize: 12)),
          const SizedBox(height: 8),
          _zoneRow('Zone 0', 'Hazard present continuously (>1000 hrs/yr)', colors),
          _zoneRow('Zone 1', 'Hazard likely during normal operation', colors),
          _zoneRow('Zone 2', 'Hazard unlikely except abnormal conditions', colors),
          const SizedBox(height: 10),
          Text('Zone system aligns with international standards. More common in new installations and process industries.', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _zoneRow(String zone, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(zone, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildCommonLocations(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Common Hazardous Locations', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _locRow('Gas stations', 'Class I, Div 1/2, Group D', colors),
          _locRow('Spray booths', 'Class I, Div 1/2, Group D', colors),
          _locRow('Grain elevators', 'Class II, Div 1/2, Group G', colors),
          _locRow('Flour mills', 'Class II, Div 1/2, Group G', colors),
          _locRow('Coal handling', 'Class II, Div 1/2, Group F', colors),
          _locRow('Refineries', 'Class I, various groups', colors),
          _locRow('Chemical plants', 'Class I, various groups', colors),
          _locRow('Wood shops', 'Class II/III, Group G', colors),
          _locRow('Aircraft hangars', 'Class I, Div 2, Group D', colors),
          _locRow('Wastewater plants', 'Class I, Div 1/2, Group D', colors),
        ],
      ),
    );
  }

  Widget _locRow(String location, String classification, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(location, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
          Text(classification, style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEquipmentMarking(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Equipment Marking', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text('Equipment must be listed and marked for:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500, fontSize: 12)),
          const SizedBox(height: 6),
          Text('• Class (I, II, or III)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Division (1 or 2) or Zone (0, 1, 2)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Group (A-G)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Temperature class (T1-T6)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Example marking:\nClass I, Div 1, Groups C & D, T3\n\nMeans: Rated for flammable gases/vapors,\nnormal hazard present, specific gas groups,\nmax surface temp 200°C',
              style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
