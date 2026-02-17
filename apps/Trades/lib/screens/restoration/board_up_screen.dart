// ZAFTO Board-Up / Emergency Securing Screen
// Emergency board-up documentation, openings secured, materials used, photos
// Sprint REST1 — Fire restoration dedicated tools

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/zafto_colors.dart';
import '../../models/fire_assessment.dart';

class BoardUpScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String fireAssessmentId;

  const BoardUpScreen({
    super.key,
    required this.jobId,
    required this.fireAssessmentId,
  });

  @override
  ConsumerState<BoardUpScreen> createState() => _BoardUpScreenState();
}

class _BoardUpScreenState extends ConsumerState<BoardUpScreen> {
  List<BoardUpEntry> _entries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('fire_assessments')
          .select('board_up_entries')
          .eq('id', widget.fireAssessmentId)
          .single();

      final raw = data['board_up_entries'] as List? ?? [];
      _entries = raw
          .whereType<Map<String, dynamic>>()
          .map((m) => BoardUpEntry.fromJson(m))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addEntry() async {
    final result = await _showAddDialog();
    if (result == null) return;

    final entry = BoardUpEntry(
      openingType: result['opening_type'] as String,
      location: result['location'] as String,
      material: result['material'] as String?,
      dimensions: result['dimensions'] as String?,
      securedAt: DateTime.now(),
    );

    _entries.add(entry);
    await _saveEntries();
  }

  Future<void> _saveEntries() async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('fire_assessments').update({
        'board_up_entries': _entries.map((e) => e.toJson()).toList(),
      }).eq('id', widget.fireAssessmentId);

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _removeEntry(int index) async {
    _entries.removeAt(index);
    await _saveEntries();
  }

  Future<Map<String, dynamic>?> _showAddDialog() {
    String openingType = 'window';
    final locationCtrl = TextEditingController();
    final materialCtrl = TextEditingController();
    final dimensionsCtrl = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).extension<ZaftoColors>()!;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Add Board-Up Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: openingType,
                      decoration: const InputDecoration(
                          labelText: 'Opening Type', isDense: true),
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      dropdownColor: colors.bgInset,
                      items: const [
                        DropdownMenuItem(value: 'window', child: Text('Window')),
                        DropdownMenuItem(value: 'door', child: Text('Door')),
                        DropdownMenuItem(value: 'roof', child: Text('Roof')),
                        DropdownMenuItem(value: 'wall', child: Text('Wall')),
                        DropdownMenuItem(value: 'garage', child: Text('Garage')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => openingType = v ?? 'window'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: locationCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Location',
                          hintText: 'e.g., Front bedroom, south side',
                          isDense: true),
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: materialCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Material Used',
                          hintText: 'e.g., 1/2" OSB + 2x4 frame',
                          isDense: true),
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: dimensionsCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Dimensions',
                          hintText: 'e.g., 3x4 ft',
                          isDense: true),
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    if (locationCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx, {
                      'opening_type': openingType,
                      'location': locationCtrl.text.trim(),
                      'material': materialCtrl.text.trim().isEmpty
                          ? null
                          : materialCtrl.text.trim(),
                      'dimensions': dimensionsCtrl.text.trim().isEmpty
                          ? null
                          : dimensionsCtrl.text.trim(),
                    });
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    // Stats
    final windows = _entries.where((e) => e.openingType == 'window').length;
    final doors = _entries.where((e) => e.openingType == 'door').length;
    final roofs = _entries.where((e) => e.openingType == 'roof').length;
    final other = _entries.length - windows - doors - roofs;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Board-Up / Securing')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEntry,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.alertCircle,
                          size: 48, color: colors.textTertiary),
                      const SizedBox(height: 8),
                      Text(_error!,
                          style: TextStyle(color: colors.textSecondary)),
                      TextButton(
                          onPressed: _loadEntries,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Stats
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.bgInset,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statCol(colors, '$windows', 'Windows'),
                          _statCol(colors, '$doors', 'Doors'),
                          _statCol(colors, '$roofs', 'Roof'),
                          _statCol(colors, '$other', 'Other'),
                          _statCol(colors, '${_entries.length}', 'Total'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Material reference
                    _sectionHeader(colors, 'MATERIAL REFERENCE'),
                    const SizedBox(height: 8),
                    _refRow(colors, 'Standard window (up to 4x4 ft)', '1/2" OSB + 2x4 frame'),
                    _refRow(colors, 'Large window (over 4x4 ft)', '1/2" OSB + 2x4 frame, may need bracing'),
                    _refRow(colors, 'Door', '3/4" plywood + 2x4 brace, padlock hasp'),
                    _refRow(colors, 'Roof tarp (up to 20x30)', '6 mil poly + 2x4 battens + roofing screws'),
                    _refRow(colors, 'Roof tarp (over 20x30)', 'Heavy-duty tarp + full batten system'),

                    const SizedBox(height: 24),

                    // Entries
                    _sectionHeader(colors, 'SECURED OPENINGS'),
                    const SizedBox(height: 8),

                    if (_entries.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(LucideIcons.shield,
                                  size: 48, color: colors.textTertiary),
                              const SizedBox(height: 8),
                              Text('No board-ups documented',
                                  style: TextStyle(
                                      color: colors.textSecondary)),
                              const SizedBox(height: 4),
                              Text('Tap + to add an entry',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textTertiary)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...List.generate(_entries.length, (i) {
                        final entry = _entries[i];
                        return Card(
                          color: colors.bgInset,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(_openingIcon(entry.openingType),
                                        size: 18, color: colors.textSecondary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${_openingLabel(entry.openingType)} — ${entry.location}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: colors.textPrimary),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          size: 18, color: Colors.red.shade300),
                                      onPressed: () => _removeEntry(i),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                if (entry.material != null ||
                                    entry.dimensions != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (entry.material != null)
                                        Text(entry.material!,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: colors.textSecondary)),
                                      if (entry.material != null &&
                                          entry.dimensions != null)
                                        Text(' | ',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: colors.textTertiary)),
                                      if (entry.dimensions != null)
                                        Text(entry.dimensions!,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: colors.textSecondary)),
                                    ],
                                  ),
                                ],
                                if (entry.securedAt != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Secured: ${entry.securedAt!.month}/${entry.securedAt!.day}/${entry.securedAt!.year} ${entry.securedAt!.hour}:${entry.securedAt!.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: colors.textTertiary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 80),
                  ],
                ),
    );
  }

  IconData _openingIcon(String type) {
    switch (type) {
      case 'window':
        return LucideIcons.maximize2;
      case 'door':
        return LucideIcons.doorOpen;
      case 'roof':
        return LucideIcons.home;
      case 'wall':
        return LucideIcons.square;
      case 'garage':
        return LucideIcons.warehouse;
      default:
        return LucideIcons.shield;
    }
  }

  String _openingLabel(String type) {
    switch (type) {
      case 'window':
        return 'Window';
      case 'door':
        return 'Door';
      case 'roof':
        return 'Roof';
      case 'wall':
        return 'Wall';
      case 'garage':
        return 'Garage';
      default:
        return 'Other';
    }
  }

  Widget _statCol(ZaftoColors colors, String value, String label) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: colors.textPrimary)),
        Text(label,
            style: TextStyle(fontSize: 11, color: colors.textTertiary)),
      ],
    );
  }

  Widget _refRow(ZaftoColors colors, String title, String material) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 13, color: colors.textTertiary),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text: '$title: ',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary)),
                  TextSpan(
                      text: material,
                      style: TextStyle(
                          fontSize: 12, color: colors.textSecondary)),
                ],
              ),
            ),
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
