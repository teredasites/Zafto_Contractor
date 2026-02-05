import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Grounding Conductor Sizing Calculator - Design System v2.6
class GroundingScreen extends ConsumerStatefulWidget {
  const GroundingScreen({super.key});
  @override
  ConsumerState<GroundingScreen> createState() => _GroundingScreenState();
}

enum GroundingType { egc, gec }

class _GroundingScreenState extends ConsumerState<GroundingScreen> {
  GroundingType _type = GroundingType.egc;
  String _material = 'Copper';
  int _ocpdRating = 20;
  int _serviceConductorSize = 2;
  String? _result;
  String? _necRef;

  static const Map<int, Map<String, String>> _egcTable = {
    15: {'Copper': '14 AWG', 'Aluminum': '12 AWG'}, 20: {'Copper': '12 AWG', 'Aluminum': '10 AWG'}, 30: {'Copper': '10 AWG', 'Aluminum': '8 AWG'},
    40: {'Copper': '10 AWG', 'Aluminum': '8 AWG'}, 60: {'Copper': '10 AWG', 'Aluminum': '8 AWG'}, 100: {'Copper': '8 AWG', 'Aluminum': '6 AWG'},
    200: {'Copper': '6 AWG', 'Aluminum': '4 AWG'}, 300: {'Copper': '4 AWG', 'Aluminum': '2 AWG'}, 400: {'Copper': '3 AWG', 'Aluminum': '1 AWG'},
    500: {'Copper': '2 AWG', 'Aluminum': '1/0 AWG'}, 600: {'Copper': '1 AWG', 'Aluminum': '2/0 AWG'}, 800: {'Copper': '1/0 AWG', 'Aluminum': '3/0 AWG'},
    1000: {'Copper': '2/0 AWG', 'Aluminum': '4/0 AWG'}, 1200: {'Copper': '3/0 AWG', 'Aluminum': '250 kcmil'}, 1600: {'Copper': '4/0 AWG', 'Aluminum': '350 kcmil'},
    2000: {'Copper': '250 kcmil', 'Aluminum': '400 kcmil'}, 2500: {'Copper': '350 kcmil', 'Aluminum': '600 kcmil'}, 3000: {'Copper': '400 kcmil', 'Aluminum': '600 kcmil'},
  };

  static const List<String> _serviceSizes = ['2 AWG or smaller', '1 AWG or 1/0 AWG', '2/0 or 3/0 AWG', '4/0 AWG - 350 kcmil', '400 - 500 kcmil', '600 - 900 kcmil', '1000 - 1750 kcmil', 'Over 1750 kcmil'];

  static const Map<int, Map<String, String>> _gecTable = {
    0: {'Copper': '8 AWG', 'Aluminum': '6 AWG'}, 1: {'Copper': '6 AWG', 'Aluminum': '4 AWG'}, 2: {'Copper': '4 AWG', 'Aluminum': '2 AWG'},
    3: {'Copper': '2 AWG', 'Aluminum': '1/0 AWG'}, 4: {'Copper': '1/0 AWG', 'Aluminum': '3/0 AWG'}, 5: {'Copper': '2/0 AWG', 'Aluminum': '4/0 AWG'},
    6: {'Copper': '3/0 AWG', 'Aluminum': '250 kcmil'}, 7: {'Copper': '3/0 AWG', 'Aluminum': '250 kcmil'},
  };

  static const List<int> _ocpdRatings = [15, 20, 30, 40, 60, 100, 200, 300, 400, 500, 600, 800, 1000, 1200, 1600, 2000, 2500, 3000];

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Grounding', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildTypeSelector(colors),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'CONDUCTOR MATERIAL'),
            const SizedBox(height: 12),
            _buildMaterialSelector(colors),
            const SizedBox(height: 24),
            if (_type == GroundingType.egc) _buildEgcInputs(colors),
            if (_type == GroundingType.gec) _buildGecInputs(colors),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary, foregroundColor: colors.isDark ? Colors.black : Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('SIZE CONDUCTOR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ),
            const SizedBox(height: 24),
            if (_result != null) _buildResult(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() { _type = GroundingType.egc; _result = null; }); },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: _type == GroundingType.egc ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Text('EGC', style: TextStyle(color: _type == GroundingType.egc ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w700, fontSize: 16)),
              Text('250.122', style: TextStyle(color: _type == GroundingType.egc ? Colors.white70 : colors.textTertiary, fontSize: 11)),
            ]),
          ),
        )),
        Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() { _type = GroundingType.gec; _result = null; }); },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: _type == GroundingType.gec ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Text('GEC', style: TextStyle(color: _type == GroundingType.gec ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w700, fontSize: 16)),
              Text('250.66', style: TextStyle(color: _type == GroundingType.gec ? Colors.white70 : colors.textTertiary, fontSize: 11)),
            ]),
          ),
        )),
      ]),
    );
  }

  Widget _buildMaterialSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Row(children: ['Copper', 'Aluminum'].map((m) {
        final isSelected = m == _material;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _material = m); },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
            child: Text(m.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildEgcInputs(ZaftoColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _buildSectionHeader(colors, 'OVERCURRENT PROTECTION'),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
        child: Row(children: [
          Expanded(child: Text('OCPD Rating', style: TextStyle(color: colors.textSecondary))),
          DropdownButton<int>(value: _ocpdRating, dropdownColor: colors.bgElevated, underline: const SizedBox(), style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600), items: _ocpdRatings.map((r) => DropdownMenuItem(value: r, child: Text('$r A'))).toList(), onChanged: (v) => setState(() => _ocpdRating = v!)),
        ]),
      ),
      const SizedBox(height: 8),
      _buildInfoCard(colors, 'NEC 250.122', 'Equipment Grounding Conductor sizing based on rating of upstream overcurrent protective device.'),
    ]);
  }

  Widget _buildGecInputs(ZaftoColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _buildSectionHeader(colors, 'SERVICE CONDUCTOR SIZE'),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
        child: DropdownButton<int>(value: _serviceConductorSize, dropdownColor: colors.bgElevated, underline: const SizedBox(), isExpanded: true, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500), items: List.generate(_serviceSizes.length, (i) => DropdownMenuItem(value: i, child: Text(_serviceSizes[i]))), onChanged: (v) => setState(() => _serviceConductorSize = v!)),
      ),
      const SizedBox(height: 8),
      _buildInfoCard(colors, 'NEC 250.66', 'Grounding Electrode Conductor sizing based on largest ungrounded service-entrance conductor.'),
    ]);
  }

  Widget _buildInfoCard(ZaftoColors colors, String title, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(LucideIcons.info, color: colors.accentPrimary, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 2),
          Text(text, style: TextStyle(color: colors.accentPrimary.withValues(alpha: 0.8), fontSize: 11)),
        ])),
      ]),
    );
  }

  Widget _buildResult(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3))),
      child: Column(children: [
        Icon(_type == GroundingType.egc ? LucideIcons.plug : LucideIcons.home, color: colors.accentSuccess, size: 32),
        const SizedBox(height: 12),
        Text(_result!, style: TextStyle(color: colors.accentSuccess, fontSize: 32, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(_type == GroundingType.egc ? 'Equipment Grounding Conductor' : 'Grounding Electrode Conductor', style: TextStyle(color: colors.textTertiary)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(LucideIcons.bookOpen, color: colors.accentPrimary, size: 16),
            const SizedBox(width: 8),
            Text(_necRef!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }

  void _calculate() {
    if (_type == GroundingType.egc) {
      final sizing = _egcTable[_ocpdRating];
      if (sizing != null) setState(() { _result = sizing[_material]; _necRef = 'Table 250.122'; });
    } else {
      final sizing = _gecTable[_serviceConductorSize];
      if (sizing != null) setState(() { _result = sizing[_material]; _necRef = 'Table 250.66'; });
    }
  }
}
