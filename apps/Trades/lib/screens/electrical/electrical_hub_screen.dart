import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

// Calculators
import '../calculators/ohms_law_screen.dart';
import '../calculators/voltage_drop_screen.dart';
import '../calculators/wire_sizing_screen.dart';
import '../calculators/conduit_fill_screen.dart';
import '../calculators/box_fill_screen.dart';
import '../calculators/motor_fla_screen.dart';
import '../calculators/ampacity_screen.dart';
import '../calculators/conduit_bending_screen.dart';
import '../calculators/dwelling_load_screen.dart';
import '../calculators/transformer_screen.dart';
import '../calculators/grounding_screen.dart';
import '../calculators/power_converter_screen.dart';
import '../calculators/pull_box_screen.dart';
import '../calculators/motor_circuit_screen.dart';
import '../calculators/fault_current_screen.dart';
import '../calculators/commercial_load_screen.dart';
import '../calculators/tap_rule_screen.dart';
import '../calculators/lumen_screen.dart';
import '../calculators/unit_converter_screen.dart';
import '../calculators/raceway_screen.dart';
import '../calculators/parallel_conductor_screen.dart';
import '../calculators/power_factor_screen.dart';
import '../calculators/disconnect_screen.dart';
import '../calculators/generator_sizing_screen.dart';
import '../calculators/ev_charger_screen.dart';
import '../calculators/solar_pv_screen.dart';
import '../calculators/electric_range_screen.dart';
import '../calculators/dryer_circuit_screen.dart';
import '../calculators/water_heater_screen.dart';
import '../calculators/cable_tray_screen.dart';
import '../calculators/lighting_sqft_screen.dart';
import '../calculators/continuous_load_screen.dart';
import '../calculators/motor_inrush_screen.dart';
import '../calculators/mwbc_screen.dart';

// Reference
import '../reference/gfci_afci_screen.dart';
import '../reference/state_adoption_screen.dart';
import '../reference/ampacity_table_screen.dart';
import '../reference/conduit_dimensions_screen.dart';
import '../reference/wire_properties_screen.dart';
import '../reference/formulas_screen.dart';

/// Electrical Hub Screen - Design System v2.6
class ElectricalHubScreen extends ConsumerStatefulWidget {
  const ElectricalHubScreen({super.key});

  @override
  ConsumerState<ElectricalHubScreen> createState() => _ElectricalHubScreenState();
}

class _ElectricalHubScreenState extends ConsumerState<ElectricalHubScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _expandedSections = {'Load Calculations', 'Reference Tables'};

  static final List<_Section> _sections = [
    _Section(name: 'Load Calculations', icon: LucideIcons.gauge, items: [
      _Item(name: 'Dwelling Load', subtitle: 'NEC 220 residential service sizing', icon: LucideIcons.home, screen: const DwellingLoadScreen()),
      _Item(name: 'Commercial Load', subtitle: 'NEC 220 commercial/industrial', icon: LucideIcons.building2, screen: const CommercialLoadScreen()),
      _Item(name: 'Lighting by Sq Ft', subtitle: 'NEC 220.12 VA per occupancy', icon: LucideIcons.ruler, screen: const LightingSqftScreen()),
      _Item(name: 'Continuous Load', subtitle: 'NEC 210.20 125% sizing', icon: LucideIcons.timer, screen: const ContinuousLoadScreen()),
      _Item(name: 'Generator Sizing', subtitle: 'Standby & portable generator loads', icon: LucideIcons.power, screen: const GeneratorSizingScreen()),
      _Item(name: 'EV Charger Load', subtitle: 'NEC 625 charging station sizing', icon: LucideIcons.car, screen: const EvChargerScreen()),
      _Item(name: 'Solar / PV System', subtitle: 'NEC 690 array & inverter sizing', icon: LucideIcons.sun, screen: const SolarPvScreen()),
      _Item(name: 'Electric Range', subtitle: 'NEC 220.55 demand factors', icon: LucideIcons.flame, screen: const ElectricRangeScreen()),
      _Item(name: 'Dryer Circuit', subtitle: 'NEC 220.54 branch circuit', icon: LucideIcons.wind, screen: const DryerCircuitScreen()),
      _Item(name: 'Water Heater', subtitle: 'NEC 422 tank & tankless', icon: LucideIcons.droplet, screen: const WaterHeaterScreen()),
      _Item(name: 'Fault Current', subtitle: 'Short circuit point-to-point', icon: LucideIcons.alertTriangle, screen: const FaultCurrentScreen()),
      _Item(name: 'Tap Rules', subtitle: 'NEC 240.21 tap conductor sizing', icon: LucideIcons.gitBranch, screen: const TapRuleScreen()),
    ]),
    _Section(name: 'Wire & Conductors', icon: LucideIcons.zap, items: [
      _Item(name: 'Wire Sizing', subtitle: 'Size by ampacity & application', icon: LucideIcons.ruler, screen: const WireSizingScreen()),
      _Item(name: 'Voltage Drop', subtitle: 'NEC 210.19 / 215.2 (3%/5%)', icon: LucideIcons.trendingDown, screen: const VoltageDropScreen()),
      _Item(name: 'Ampacity Derating', subtitle: 'Temp & conduit fill factors', icon: LucideIcons.thermometer, screen: const AmpacityScreen()),
      _Item(name: 'Grounding & Bonding', subtitle: 'EGC, GEC, bonding jumpers', icon: LucideIcons.zap, screen: const GroundingScreen()),
      _Item(name: 'Parallel Conductors', subtitle: 'NEC 310.10(G) parallel sets', icon: LucideIcons.layers, screen: const ParallelConductorScreen()),
      _Item(name: 'Multi-Wire Branch', subtitle: 'NEC 210.4 shared neutral sizing', icon: LucideIcons.share2, screen: const MwbcScreen()),
    ]),
    _Section(name: 'Conduit & Raceways', icon: LucideIcons.circle, items: [
      _Item(name: 'Conduit Fill', subtitle: 'NEC Chapter 9 fill calculations', icon: LucideIcons.pieChart, screen: const ConduitFillScreen()),
      _Item(name: 'Cable Tray Fill', subtitle: 'NEC 392 tray fill limits', icon: LucideIcons.columns, screen: const CableTrayScreen()),
      _Item(name: 'Raceway Sizing', subtitle: 'Size conduit by wire count', icon: LucideIcons.alignJustify, screen: const RacewayScreen()),
      _Item(name: 'Conduit Bending', subtitle: 'Offset, kick, saddle, 90 deg', icon: LucideIcons.cornerDownRight, screen: const ConduitBendingScreen()),
      _Item(name: 'Box Fill', subtitle: 'NEC 314.16 box volume', icon: LucideIcons.box, screen: const BoxFillScreen()),
      _Item(name: 'Pull Box Sizing', subtitle: 'NEC 314.28 dimensions', icon: LucideIcons.maximize, screen: const PullBoxScreen()),
    ]),
    _Section(name: 'Motors & Equipment', icon: LucideIcons.settings, items: [
      _Item(name: 'Motor FLA', subtitle: 'NEC Tables 430.248/250', icon: LucideIcons.gauge, screen: const MotorFlaScreen()),
      _Item(name: 'Motor Circuit', subtitle: 'Complete motor branch circuit', icon: LucideIcons.cpu, screen: const MotorCircuitScreen()),
      _Item(name: 'Motor Inrush', subtitle: 'NEC 430.251 locked rotor current', icon: LucideIcons.zap, screen: const MotorInrushScreen()),
      _Item(name: 'Transformer Sizing', subtitle: 'kVA and current calculations', icon: LucideIcons.box, screen: const TransformerScreen()),
      _Item(name: 'Disconnect Sizing', subtitle: 'NEC 430.109/110 requirements', icon: LucideIcons.powerOff, screen: const DisconnectScreen()),
      _Item(name: 'Power Factor', subtitle: 'Capacitor kVAR correction', icon: LucideIcons.activity, screen: const PowerFactorScreen()),
    ]),
    _Section(name: 'Power & Conversions', icon: LucideIcons.calculator, items: [
      _Item(name: "Ohm's Law", subtitle: 'Voltage, current, resistance, power', icon: LucideIcons.sigma, screen: const OhmsLawScreen()),
      _Item(name: 'Power Converter', subtitle: 'kW, kVA, amps, HP conversions', icon: LucideIcons.arrowLeftRight, screen: const PowerConverterScreen()),
      _Item(name: 'Unit Converter', subtitle: 'Length, area, temp, wire gauge', icon: LucideIcons.refreshCw, screen: const UnitConverterScreen()),
      _Item(name: 'Lighting / Lumen', subtitle: 'Fixture count by foot-candles', icon: LucideIcons.lightbulb, screen: const LumenScreen()),
    ]),
    _Section(name: 'Reference Tables', icon: LucideIcons.table, items: [
      _Item(name: 'Ampacity Table 310.16', subtitle: 'Conductor ampacity by temp rating', icon: LucideIcons.zap, screen: const AmpacityTableScreen()),
      _Item(name: 'Conduit Dimensions', subtitle: 'Chapter 9 Table 4 - all types', icon: LucideIcons.circle, screen: const ConduitDimensionsScreen()),
      _Item(name: 'Wire Properties', subtitle: 'Chapter 9 Table 8 - area, resistance', icon: LucideIcons.gitCommit, screen: const WirePropertiesScreen()),
      _Item(name: 'Electrical Formulas', subtitle: 'Power, voltage drop, motors', icon: LucideIcons.sigma, screen: const FormulasScreen()),
    ]),
    _Section(name: 'Code Requirements', icon: LucideIcons.scale, items: [
      _Item(name: 'GFCI / AFCI', subtitle: 'NEC 210.8 & 210.12 locations', icon: LucideIcons.shieldCheck, screen: const GfciAfciScreen()),
      _Item(name: 'State NEC Adoption', subtitle: 'Which code version by state', icon: LucideIcons.map, screen: const StateAdoptionScreen()),
    ]),
  ];

  List<_Section> get _filteredSections {
    if (_searchQuery.isEmpty) return _sections;
    final query = _searchQuery.toLowerCase();
    return _sections
        .map((s) => _Section(
              name: s.name,
              icon: s.icon,
              items: s.items.where((i) =>
                  i.name.toLowerCase().contains(query) ||
                  i.subtitle.toLowerCase().contains(query)).toList(),
            ))
        .where((s) => s.items.isNotEmpty)
        .toList();
  }

  int get _totalItems => _sections.fold(0, (sum, s) => sum + s.items.length);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(colors),
          SliverToBoxAdapter(child: _buildSearchBar(colors)),
          if (_filteredSections.isEmpty)
            SliverFillRemaining(child: _buildEmptyState(colors))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSection(colors, _filteredSections[index]),
                childCount: _filteredSections.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildAppBar(ZaftoColors colors) {
    return SliverAppBar(
      backgroundColor: colors.bgBase,
      expandedHeight: 100,
      floating: false,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: colors.fillDefault, borderRadius: BorderRadius.circular(10)),
          child: Icon(LucideIcons.arrowLeft, size: 16, color: colors.textPrimary),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: colors.fillDefault, borderRadius: BorderRadius.circular(7)),
              child: Icon(LucideIcons.zap, color: colors.textPrimary, size: 15),
            ),
            const SizedBox(width: 10),
            Text('Electrical', style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: colors.fillDefault, borderRadius: BorderRadius.circular(4)),
              child: Text('$_totalItems', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(fontSize: 15, color: colors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search calculators & references...',
          hintStyle: TextStyle(color: colors.textTertiary, fontSize: 15),
          prefixIcon: Icon(LucideIcons.search, color: colors.textTertiary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(LucideIcons.x, color: colors.textTertiary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: colors.bgInset,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSection(ZaftoColors colors, _Section section) {
    final isExpanded = _searchQuery.isNotEmpty || _expandedSections.contains(section.name);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (_expandedSections.contains(section.name)) {
                _expandedSections.remove(section.name);
              } else {
                _expandedSections.add(section.name);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: colors.fillDefault, borderRadius: BorderRadius.circular(8)),
                  child: Icon(section.icon, color: colors.textPrimary, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(section.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary, letterSpacing: -0.3)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: colors.fillDefault, borderRadius: BorderRadius.circular(6)),
                  child: Text('${section.items.length}', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(LucideIcons.chevronDown, color: colors.textTertiary, size: 20),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(children: section.items.map((item) => _ItemTile(colors: colors, item: item, onTap: () => _openScreen(item.screen))).toList()),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (_filteredSections.last != section) Divider(color: colors.borderSubtle, height: 24, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildEmptyState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.searchX, color: colors.textTertiary, size: 48),
          const SizedBox(height: 16),
          Text('No results for "$_searchQuery"', style: TextStyle(color: colors.textTertiary, fontSize: 15)),
        ],
      ),
    );
  }

  void _openScreen(Widget screen) {
    HapticFeedback.lightImpact();
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 200),
    ));
  }
}

class _Section {
  final String name;
  final IconData icon;
  final List<_Item> items;
  const _Section({required this.name, required this.icon, required this.items});
}

class _Item {
  final String name;
  final String subtitle;
  final IconData icon;
  final Widget screen;
  const _Item({required this.name, required this.subtitle, required this.icon, required this.screen});
}

class _ItemTile extends StatelessWidget {
  final ZaftoColors colors;
  final _Item item;
  final VoidCallback onTap;
  const _ItemTile({required this.colors, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(60, 10, 16, 10),
        child: Row(
          children: [
            Icon(item.icon, color: colors.textSecondary, size: 18),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary)),
                  const SizedBox(height: 1),
                  Text(item.subtitle, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: colors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}
