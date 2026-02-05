import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Kitchen Circuit Planner - Design System v2.6
/// Required kitchen circuits per NEC 210.52(B) & 210.11(C)(1)
class KitchenCircuitScreen extends ConsumerStatefulWidget {
  const KitchenCircuitScreen({super.key});
  @override
  ConsumerState<KitchenCircuitScreen> createState() => _KitchenCircuitScreenState();
}

class _KitchenCircuitScreenState extends ConsumerState<KitchenCircuitScreen> {
  String _kitchenType = 'residential'; // residential, commercial
  bool _hasDisposal = true;
  bool _hasDishwasher = true;
  bool _hasRefrigerator = true;
  bool _hasMicrowave = true;
  bool _hasRange = true;
  String _rangeType = 'electric'; // electric, gas
  bool _hasOven = false;
  bool _hasCooktop = false;
  bool _hasInstantHot = false;
  bool _hasTrashCompactor = false;
  int _counterSpaces = 2; // Number of counter spaces requiring receptacles

  // NEC required circuits
  List<Map<String, dynamic>> get _requiredCircuits {
    final circuits = <Map<String, dynamic>>[];

    // NEC 210.11(C)(1) - Two 20A small appliance circuits REQUIRED
    circuits.add({
      'name': 'Small Appliance Circuit #1',
      'wire': '12 AWG',
      'breaker': '20A',
      'type': 'GFCI',
      'code': 'NEC 210.11(C)(1)',
      'required': true,
      'notes': 'Counter receptacles, refrigerator area',
    });
    circuits.add({
      'name': 'Small Appliance Circuit #2',
      'wire': '12 AWG',
      'breaker': '20A',
      'type': 'GFCI',
      'code': 'NEC 210.11(C)(1)',
      'required': true,
      'notes': 'Counter receptacles only',
    });

    // Refrigerator - dedicated circuit recommended
    if (_hasRefrigerator) {
      circuits.add({
        'name': 'Refrigerator',
        'wire': '12 AWG',
        'breaker': '20A',
        'type': 'Dedicated',
        'code': 'NEC 210.52(B)(1) Ex 2',
        'required': false,
        'notes': 'Dedicated circuit recommended, not required',
      });
    }

    // Dishwasher
    if (_hasDishwasher) {
      circuits.add({
        'name': 'Dishwasher',
        'wire': '12 AWG',
        'breaker': '20A',
        'type': 'GFCI',
        'code': 'NEC 422.5',
        'required': true,
        'notes': 'GFCI required within 6 ft of sink',
      });
    }

    // Disposal
    if (_hasDisposal) {
      circuits.add({
        'name': 'Garbage Disposal',
        'wire': '12 AWG',
        'breaker': '20A',
        'type': 'GFCI',
        'code': 'NEC 422.5',
        'required': true,
        'notes': 'Can share with dishwasher if both rated ≤10A',
      });
    }

    // Microwave
    if (_hasMicrowave) {
      circuits.add({
        'name': 'Microwave',
        'wire': '12 AWG',
        'breaker': '20A',
        'type': 'Dedicated',
        'code': 'NEC 210.52(B)',
        'required': false,
        'notes': 'Dedicated circuit recommended for built-in',
      });
    }

    // Range/Oven/Cooktop
    if (_hasRange && _rangeType == 'electric') {
      circuits.add({
        'name': 'Electric Range',
        'wire': '6 AWG (8 AWG for 40A)',
        'breaker': '50A (40A min)',
        'type': 'Dedicated',
        'code': 'NEC 220.55',
        'required': true,
        'notes': '50A 125/250V receptacle typical',
      });
    } else if (_hasRange && _rangeType == 'gas') {
      circuits.add({
        'name': 'Gas Range',
        'wire': '12 AWG',
        'breaker': '20A',
        'type': 'Dedicated',
        'code': 'NEC 210.52(B)',
        'required': true,
        'notes': '120V for ignition/clock/light',
      });
    }

    if (_hasOven && !_hasRange) {
      circuits.add({
        'name': 'Wall Oven',
        'wire': '10 AWG',
        'breaker': '30A',
        'type': 'Dedicated',
        'code': 'NEC 422.10',
        'required': true,
        'notes': 'Size per nameplate',
      });
    }

    if (_hasCooktop && !_hasRange) {
      circuits.add({
        'name': 'Cooktop',
        'wire': '8 AWG',
        'breaker': '40A',
        'type': 'Dedicated',
        'code': 'NEC 422.10',
        'required': true,
        'notes': 'Size per nameplate',
      });
    }

    // Optional appliances
    if (_hasInstantHot) {
      circuits.add({
        'name': 'Instant Hot Water',
        'wire': '12 AWG',
        'breaker': '20A',
        'type': 'GFCI',
        'code': 'NEC 422.5',
        'required': false,
        'notes': 'GFCI if within 6 ft of sink',
      });
    }

    if (_hasTrashCompactor) {
      circuits.add({
        'name': 'Trash Compactor',
        'wire': '12 AWG',
        'breaker': '20A',
        'type': 'Dedicated',
        'code': 'NEC 422.10',
        'required': false,
        'notes': 'Typically dedicated circuit',
      });
    }

    return circuits;
  }

  int get _totalCircuits => _requiredCircuits.length;
  int get _requiredCircuitCount => _requiredCircuits.where((c) => c['required'] == true).length;

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
        title: Text('Kitchen Circuit Planner', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAppliancesCard(colors),
          const SizedBox(height: 16),
          _buildRangeCard(colors),
          const SizedBox(height: 16),
          _buildOptionalCard(colors),
          const SizedBox(height: 20),
          _buildSummaryCard(colors),
          const SizedBox(height: 16),
          _buildCircuitListCard(colors),
          const SizedBox(height: 16),
          _buildReceptacleCard(colors),
          const SizedBox(height: 16),
          _buildCodeReference(colors),
        ],
      ),
    );
  }

  Widget _buildAppliancesCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STANDARD APPLIANCES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildToggle(colors, 'Refrigerator', _hasRefrigerator, (v) => setState(() => _hasRefrigerator = v)),
          _buildToggle(colors, 'Dishwasher', _hasDishwasher, (v) => setState(() => _hasDishwasher = v)),
          _buildToggle(colors, 'Garbage Disposal', _hasDisposal, (v) => setState(() => _hasDisposal = v)),
          _buildToggle(colors, 'Microwave (Built-in)', _hasMicrowave, (v) => setState(() => _hasMicrowave = v)),
        ],
      ),
    );
  }

  Widget _buildRangeCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COOKING EQUIPMENT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildToggle(colors, 'Range/Stove', _hasRange, (v) => setState(() {
            _hasRange = v;
            if (v) {
              _hasOven = false;
              _hasCooktop = false;
            }
          })),
          if (_hasRange) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTypeOption(colors, 'electric', 'Electric')),
                const SizedBox(width: 12),
                Expanded(child: _buildTypeOption(colors, 'gas', 'Gas')),
              ],
            ),
          ],
          if (!_hasRange) ...[
            const SizedBox(height: 8),
            _buildToggle(colors, 'Wall Oven (separate)', _hasOven, (v) => setState(() => _hasOven = v)),
            _buildToggle(colors, 'Cooktop (separate)', _hasCooktop, (v) => setState(() => _hasCooktop = v)),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeOption(ZaftoColors colors, String value, String label) {
    final isSelected = _rangeType == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _rangeType = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionalCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OPTIONAL APPLIANCES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildToggle(colors, 'Instant Hot Water Dispenser', _hasInstantHot, (v) => setState(() => _hasInstantHot = v)),
          _buildToggle(colors, 'Trash Compactor', _hasTrashCompactor, (v) => setState(() => _hasTrashCompactor = v)),
        ],
      ),
    );
  }

  Widget _buildToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colors.accentPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text('TOTAL CIRCUITS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          Text(
            '$_totalCircuits',
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
            ),
          ),
          Text('circuits', style: TextStyle(color: colors.textSecondary, fontSize: 15)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('$_requiredCircuitCount', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                    Text('Required', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                  ],
                ),
                Container(width: 1, height: 40, color: colors.borderSubtle),
                Column(
                  children: [
                    Text('${_totalCircuits - _requiredCircuitCount}', style: TextStyle(color: colors.textSecondary, fontSize: 24, fontWeight: FontWeight.w700)),
                    Text('Recommended', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircuitListCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CIRCUIT SCHEDULE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 16),
          ..._requiredCircuits.map((circuit) => _buildCircuitRow(colors, circuit)),
        ],
      ),
    );
  }

  Widget _buildCircuitRow(ZaftoColors colors, Map<String, dynamic> circuit) {
    final isRequired = circuit['required'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgBase,
        borderRadius: BorderRadius.circular(8),
        border: isRequired ? Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  circuit['name'],
                  style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isRequired ? colors.accentPrimary.withValues(alpha: 0.15) : colors.bgElevated,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isRequired ? 'Required' : 'Recommended',
                  style: TextStyle(
                    color: isRequired ? colors.accentPrimary : colors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildCircuitSpec(colors, circuit['wire'], LucideIcons.plug),
              const SizedBox(width: 16),
              _buildCircuitSpec(colors, circuit['breaker'], LucideIcons.toggleRight),
              const SizedBox(width: 16),
              _buildCircuitSpec(colors, circuit['type'], LucideIcons.shieldCheck),
            ],
          ),
          const SizedBox(height: 6),
          Text(circuit['notes'], style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          Text(circuit['code'], style: TextStyle(color: colors.textTertiary, fontSize: 10, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildCircuitSpec(ZaftoColors colors, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: colors.textTertiary),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildReceptacleCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.plug, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Text('RECEPTACLE REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          _buildRequirement(colors, 'Counter 12"+ wide', 'Receptacle within 24" of each end'),
          _buildRequirement(colors, 'Counter spacing', 'Max 48" between receptacles'),
          _buildRequirement(colors, 'Island/Peninsula', 'At least one receptacle required'),
          _buildRequirement(colors, 'Wall counters', 'Receptacle every 4 ft of counter'),
          _buildRequirement(colors, 'GFCI protection', 'All countertop receptacles'),
          _buildRequirement(colors, 'Behind range', 'Receptacle not required'),
        ],
      ),
    );
  }

  Widget _buildRequirement(ZaftoColors colors, String title, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.checkCircle2, color: Colors.green, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: colors.textPrimary, fontSize: 13),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: detail, style: TextStyle(color: colors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeReference(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.bookOpen, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Text('NEC CODE REFERENCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'NEC 210.11(C)(1) - Minimum two 20A small appliance circuits required.\n\n'
            'NEC 210.52(B) - Receptacle outlets in kitchen and dining areas shall be supplied by 20A small appliance circuits.\n\n'
            'NEC 210.8(A)(6) - GFCI protection required for all kitchen receptacles serving countertops.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
