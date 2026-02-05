/// Rough-In Checklist - Design System v2.6
/// Residential and commercial rough-in requirements
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/state_preferences_service.dart';
import '../../widgets/expandable_reference_card.dart';

class RoughInChecklistScreen extends ConsumerStatefulWidget {
  const RoughInChecklistScreen({super.key});
  @override
  ConsumerState<RoughInChecklistScreen> createState() => _RoughInChecklistScreenState();
}

class _RoughInChecklistScreenState extends ConsumerState<RoughInChecklistScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('Rough-In Checklist', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.accentPrimary,
          indicatorWeight: 3,
          labelColor: colors.accentPrimary,
          unselectedLabelColor: colors.textTertiary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'Residential'),
            Tab(text: 'Commercial'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: NecEditionBadge(edition: necBadge, colors: colors),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildResidentialChecklist(colors),
                _buildCommercialChecklist(colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidentialChecklist(ZaftoColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Service & Panel', [
            'Service entrance sized correctly (100A, 200A, etc)',
            'Meter base installed at correct height (5-6 ft center)',
            'Main panel location accessible (not in bathroom/closet)',
            'Working clearance: 30" wide × 36" deep × 78" high',
            'Panel height: max 6\'7" to top breaker',
            'Grounding electrode system complete (rods, ufer, etc)',
            'GEC sized per Table 250.66',
            'Main bonding jumper installed',
          ], colors),
          _buildSection('Branch Circuits - Kitchen', [
            '2 × 20A small appliance circuits (countertop)',
            '1 × 20A refrigerator circuit (dedicated)',
            '1 × 20A dishwasher circuit',
            '1 × 20A disposal circuit (or switched)',
            '1 × 40A or 50A range circuit',
            'GFCI within 6ft of sink',
            'Receptacles every 4ft along countertop, no point >2ft away',
            'Island/peninsula: min 1 receptacle per island',
          ], colors),
          _buildSection('Branch Circuits - Bathroom', [
            '20A circuit (can serve multiple bathrooms)',
            'Cannot serve other room types',
            'GFCI required on all receptacles',
            'Receptacle within 3ft of each sink',
            'Exhaust fan on general lighting or separate circuit',
          ], colors),
          _buildSection('Branch Circuits - Bedrooms', [
            'AFCI protection required',
            'Receptacle every 12ft along wall',
            'No point more than 6ft from receptacle',
            'Smoke detector (hardwired, interconnected)',
          ], colors),
          _buildSection('Branch Circuits - Other', [
            'Laundry: 20A dedicated circuit (GFCI if within 6ft of sink)',
            'Dryer: 30A 240V circuit',
            'Garage: min 1 receptacle, GFCI protected',
            'Outdoor: GFCI, weatherproof covers (in-use type)',
            'HVAC: Per nameplate, dedicated circuit',
            'Water heater: Sized per nameplate',
          ], colors),
          _buildSection('Lighting', [
            'Switch-controlled lighting each habitable room',
            'Switched receptacle acceptable in living areas',
            '3-way switches for rooms with 2+ entrances',
            'Exterior: Front door, rear door, garage',
            'Stairways: 3-way at each level',
            'Hallways >10ft: switch at each end',
          ], colors),
          _buildSection('Smoke/CO Detectors', [
            'Inside each bedroom',
            'Outside bedrooms within 21ft of door',
            'Each level including basement',
            'All interconnected (when one alarms, all alarm)',
            'Hardwired with battery backup',
            'CO detector if fuel-burning or attached garage',
          ], colors),
          _buildSection('Box Fill', [
            '14 AWG = 2.0 cu in per conductor',
            '12 AWG = 2.25 cu in per conductor',
            '10 AWG = 2.5 cu in per conductor',
            'Ground counts as 1 wire (largest)',
            'Device counts as 2 wires (largest)',
            'Cable clamps = 1 wire',
          ], colors),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCommercialChecklist(ZaftoColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Service & Distribution', [
            'Service sized per load calculation',
            'Demand factor applied correctly',
            'Working clearances: Table 110.26(A)',
            'Dedicated electrical room if >1200A',
            'GFP required 150V+, 1000A+ services',
            'Emergency disconnect accessible from outside',
            'Directory of circuits at each panel',
          ], colors),
          _buildSection('Branch Circuits - General', [
            'Receptacles: 180 VA per outlet',
            'General lighting: per Table 220.12',
            '20A circuits max 10 outlets (commercial)',
            '15A circuits max 8 outlets (commercial)',
            'Continuous loads: 125% (80% of breaker)',
          ], colors),
          _buildSection('GFCI Requirements', [
            'Bathrooms',
            'Rooftops',
            'Kitchens/wet bar sinks',
            'Within 6ft of sinks',
            'Indoor wet/damp locations',
            'Locker rooms with showers',
            'Garages, service bays',
          ], colors),
          _buildSection('Emergency & Standby', [
            'Emergency circuits on separate raceways',
            'Emergency panel supplied by generator/UPS',
            'Exit signs on emergency circuit',
            'Egress lighting on emergency circuit',
            'Fire alarm on dedicated circuit',
            'Transfer switch properly installed',
          ], colors),
          _buildSection('Lighting', [
            'Meet energy code (IECC/ASHRAE 90.1)',
            'Occupancy sensors where required',
            'Daylight harvesting if applicable',
            'Emergency egress lighting (90 min backup)',
            'Exit signs at required locations',
          ], colors),
          _buildSection('Fire Alarm', [
            'NFPA 72 compliant',
            'Dedicated circuit(s)',
            'Proper conductor sizing',
            'Supervision of circuits',
            'NAC (notification appliance) circuits sized correctly',
          ], colors),
          _buildSection('Special Systems', [
            'Data/communication pathways roughed in',
            'Fire alarm conduits',
            'Security system conduits',
            'AV system conduits',
            'Low voltage separated from line voltage',
          ], colors),
          _buildSection('Grounding & Bonding', [
            'Building steel bonded',
            'Metal water pipe bonded',
            'Structural steel bonded',
            'Telecommunications grounding',
            'Equipotential bonding (pools, etc)',
          ], colors),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...items.map((item) => _checkItem(item, colors)),
        ],
      ),
    );
  }

  Widget _checkItem(String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.square, color: colors.textTertiary, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }
}
