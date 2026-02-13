// ZAFTO IICRC S500 Equipment Calculator Screen
// Calculates required dehumidifiers, air movers, air scrubbers per room.
// Phase T4c — Sprint T4: Equipment Deployment + Calculator

import 'package:flutter/material.dart' hide MaterialType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
// Colors used directly from Flutter material palette

// IICRC S500 chart factors
const _dehuChartFactors = <int, double>{1: 40, 2: 40, 3: 30, 4: 25};
const _amFloorDivisors = <int, double>{1: 70, 2: 50, 3: 50, 4: 50};
const _amCeilingDivisors = <int, double>{1: 150, 2: 150, 3: 100, 4: 100};

class _RoomInput {
  String name = '';
  double lengthFt = 0;
  double widthFt = 0;
  double heightFt = 8;
  int waterClass = 2;
}

class _RoomResult {
  final String name;
  final int waterClass;
  final double floorSqft;
  final double wallLf;
  final double cubicFt;
  final int dehuUnits;
  final int amUnits;
  final int scrubberUnits;
  final String dehuFormula;
  final String amFormula;
  final String scrubberFormula;

  const _RoomResult({
    required this.name,
    required this.waterClass,
    required this.floorSqft,
    required this.wallLf,
    required this.cubicFt,
    required this.dehuUnits,
    required this.amUnits,
    required this.scrubberUnits,
    required this.dehuFormula,
    required this.amFormula,
    required this.scrubberFormula,
  });
}

_RoomResult _calculateRoom(_RoomInput room) {
  final floorSqft = room.lengthFt * room.widthFt;
  final wallLf = 2 * (room.lengthFt + room.widthFt);
  final cubicFt = floorSqft * room.heightFt;
  final ceilingSqft = floorSqft;

  // Dehumidifier
  final chartFactor = _dehuChartFactors[room.waterClass] ?? 40.0;
  final ppdNeeded = cubicFt / chartFactor;
  const unitPpd = 70.0;
  final dehuUnits = (ppdNeeded / unitPpd).ceil();

  // Air Movers
  final amFloorDiv = _amFloorDivisors[room.waterClass] ?? 50.0;
  final amCeilDiv = _amCeilingDivisors[room.waterClass] ?? 100.0;
  final amWall = wallLf / 14;
  final amFloor = floorSqft / amFloorDiv;
  final amCeiling = room.waterClass >= 3 ? ceilingSqft / amCeilDiv : 0.0;
  final amTotal = amWall + amFloor + amCeiling;
  final amUnits = amTotal.ceil();

  // Air Scrubber
  const targetAch = 6.0;
  const scrubberCfm = 500.0;
  final cfmNeeded = (cubicFt * targetAch) / 60;
  final scrubberUnits = (cfmNeeded / scrubberCfm).ceil();

  return _RoomResult(
    name: room.name,
    waterClass: room.waterClass,
    floorSqft: floorSqft,
    wallLf: wallLf,
    cubicFt: cubicFt,
    dehuUnits: dehuUnits,
    amUnits: amUnits,
    scrubberUnits: scrubberUnits,
    dehuFormula:
        '${cubicFt.toStringAsFixed(0)} CF / ${chartFactor.toStringAsFixed(0)} = '
        '${ppdNeeded.toStringAsFixed(1)} PPD / ${unitPpd.toStringAsFixed(0)} = $dehuUnits',
    amFormula:
        'Wall: ${amWall.toStringAsFixed(1)} + Floor: ${amFloor.toStringAsFixed(1)}'
        '${amCeiling > 0 ? " + Ceil: ${amCeiling.toStringAsFixed(1)}" : ""} = $amUnits',
    scrubberFormula:
        '${cubicFt.toStringAsFixed(0)} CF x $targetAch ACH / 60 = '
        '${cfmNeeded.toStringAsFixed(0)} CFM / ${scrubberCfm.toStringAsFixed(0)} = $scrubberUnits',
  );
}

class IicrcCalculatorScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String? tpaAssignmentId;

  const IicrcCalculatorScreen({
    super.key,
    required this.jobId,
    this.tpaAssignmentId,
  });

  @override
  ConsumerState<IicrcCalculatorScreen> createState() =>
      _IicrcCalculatorScreenState();
}

class _IicrcCalculatorScreenState extends ConsumerState<IicrcCalculatorScreen> {
  final List<_RoomInput> _rooms = [_RoomInput()];
  List<_RoomResult>? _results;
  bool _showResults = false;

  void _addRoom() {
    setState(() {
      _rooms.add(_RoomInput());
    });
  }

  void _removeRoom(int index) {
    if (_rooms.length <= 1) return;
    setState(() {
      _rooms.removeAt(index);
    });
  }

  void _calculate() {
    // Validate
    for (final room in _rooms) {
      if (room.name.trim().isEmpty) {
        _showSnackBar('All rooms need a name');
        return;
      }
      if (room.lengthFt <= 0 || room.widthFt <= 0 || room.heightFt <= 0) {
        _showSnackBar('Room "${room.name}": valid dimensions required');
        return;
      }
    }

    setState(() {
      _results = _rooms.map(_calculateRoom).toList();
      _showResults = true;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IICRC Equipment Calculator'),
        actions: [
          if (_showResults)
            IconButton(
              icon: const Icon(LucideIcons.edit3),
              tooltip: 'Edit Rooms',
              onPressed: () => setState(() => _showResults = false),
            ),
        ],
      ),
      body: _showResults && _results != null
          ? _buildResults()
          : _buildInputForm(),
    );
  }

  Widget _buildInputForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.info, size: 18, color: Colors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'IICRC S500 formulas calculate equipment needs based on room dimensions and water damage classification.',
                  style: TextStyle(fontSize: 13, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Room cards
        ..._rooms.asMap().entries.map((entry) {
          final idx = entry.key;
          final room = entry.value;
          return _buildRoomCard(idx, room);
        }),

        // Add room button
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _addRoom,
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text('Add Room'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 16),

        // Calculate button
        FilledButton.icon(
          onPressed: _calculate,
          icon: const Icon(LucideIcons.calculator, size: 18),
          label: const Text('Calculate Equipment'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRoomCard(int index, _RoomInput room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Room ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const Spacer(),
                if (_rooms.length > 1)
                  IconButton(
                    icon: Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                    onPressed: () => _removeRoom(index),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: room.name,
              decoration: const InputDecoration(
                labelText: 'Room Name',
                hintText: 'Living Room',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => room.name = v,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: room.lengthFt > 0 ? room.lengthFt.toString() : '',
                    decoration: const InputDecoration(
                      labelText: 'Length (ft)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => room.lengthFt = double.tryParse(v) ?? 0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: room.widthFt > 0 ? room.widthFt.toString() : '',
                    decoration: const InputDecoration(
                      labelText: 'Width (ft)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => room.widthFt = double.tryParse(v) ?? 0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: room.heightFt.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Height (ft)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => room.heightFt = double.tryParse(v) ?? 8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: room.waterClass,
              decoration: const InputDecoration(
                labelText: 'Water Class (IICRC S500)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Class 1 — Least affected')),
                DropdownMenuItem(value: 2, child: Text('Class 2 — Significant')),
                DropdownMenuItem(value: 3, child: Text('Class 3 — Most severe')),
                DropdownMenuItem(value: 4, child: Text('Class 4 — Specialty')),
              ],
              onChanged: (v) {
                if (v != null) room.waterClass = v;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final results = _results!;
    final totalDehu = results.fold<int>(0, (s, r) => s + r.dehuUnits);
    final totalAm = results.fold<int>(0, (s, r) => s + r.amUnits);
    final totalScrubber = results.fold<int>(0, (s, r) => s + r.scrubberUnits);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Totals
        Row(
          children: [
            Expanded(
              child: _totalCard(
                'Dehumidifiers',
                totalDehu.toString(),
                LucideIcons.droplets,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _totalCard(
                'Air Movers',
                totalAm.toString(),
                LucideIcons.wind,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _totalCard(
                'Air Scrubbers',
                totalScrubber.toString(),
                LucideIcons.fan,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Room details
        ...results.map((r) => _resultCard(r)),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _totalCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _resultCard(_RoomResult r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _classColor(r.waterClass).withValues(alpha: 0.15),
          child: Text(
            'C${r.waterClass}',
            style: TextStyle(
              color: _classColor(r.waterClass),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${r.floorSqft.toStringAsFixed(0)} SF | ${r.cubicFt.toStringAsFixed(0)} CF',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _miniChip('${r.dehuUnits}D', Colors.blue),
            const SizedBox(width: 4),
            _miniChip('${r.amUnits}AM', Colors.green),
            const SizedBox(width: 4),
            _miniChip('${r.scrubberUnits}AS', Colors.purple),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _formulaRow('Dehu', r.dehuFormula, Colors.blue),
                _formulaRow('Air Movers', r.amFormula, Colors.green),
                _formulaRow('Scrubbers', r.scrubberFormula, Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formulaRow(String label, String formula, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(
              formula,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Color _classColor(int waterClass) {
    switch (waterClass) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.amber;
      case 3:
        return Colors.red;
      case 4:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
