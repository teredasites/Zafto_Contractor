// ZAFTO Recurring Service Screen
// Service frequency, agreement tracking, next service dates
// Sprint NICHE1 — Pest control module

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/zafto_colors.dart';
import '../../models/treatment_log.dart';

class RecurringServiceScreen extends ConsumerStatefulWidget {
  const RecurringServiceScreen({super.key});

  @override
  ConsumerState<RecurringServiceScreen> createState() => _RecurringServiceScreenState();
}

class _RecurringServiceScreenState extends ConsumerState<RecurringServiceScreen> {
  List<TreatmentLog> _upcoming = [];
  List<TreatmentLog> _overdue = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('treatment_logs')
          .select()
          .isFilter('deleted_at', null)
          .not('next_service_date', 'is', null)
          .order('next_service_date');

      final all = (data as List).map((r) => TreatmentLog.fromJson(r)).toList();
      final now = DateTime.now();
      _overdue = all.where((l) => l.nextServiceDate != null && l.nextServiceDate!.isBefore(now)).toList();
      _upcoming = all.where((l) => l.nextServiceDate != null && !l.nextServiceDate!.isBefore(now)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<ZaftoColors>()!;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(title: const Text('Recurring Services')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.alertCircle, size: 48, color: colors.textTertiary),
                      const SizedBox(height: 8),
                      Text(_error!, style: TextStyle(color: colors.textSecondary)),
                      TextButton(onPressed: _loadServices, child: const Text('Retry')),
                    ],
                  ),
                )
              : (_overdue.isEmpty && _upcoming.isEmpty)
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.calendarClock, size: 48, color: colors.textTertiary),
                          const SizedBox(height: 8),
                          Text('No recurring services', style: TextStyle(color: colors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Set a next service date when logging treatments',
                              style: TextStyle(fontSize: 12, color: colors.textTertiary)),
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
                              _statCol(colors, '${_overdue.length}', 'Overdue', color: Colors.red),
                              _statCol(colors, '${_upcoming.length}', 'Upcoming', color: Colors.blue),
                              _statCol(colors, '${_overdue.length + _upcoming.length}', 'Total'),
                            ],
                          ),
                        ),

                        // Overdue
                        if (_overdue.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _sectionHeader(colors, 'OVERDUE'),
                          const SizedBox(height: 8),
                          ..._overdue.map((l) => _buildServiceCard(colors, l, isOverdue: true)),
                        ],

                        // Upcoming
                        if (_upcoming.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _sectionHeader(colors, 'UPCOMING'),
                          const SizedBox(height: 8),
                          ..._upcoming.map((l) => _buildServiceCard(colors, l)),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
    );
  }

  Widget _buildServiceCard(ZaftoColors colors, TreatmentLog log, {bool isOverdue = false}) {
    final nextDate = log.nextServiceDate;
    final daysUntil = nextDate != null ? nextDate.difference(DateTime.now()).inDays : 0;

    return Card(
      color: colors.bgInset,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isOverdue ? Colors.red : Colors.blue).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                isOverdue ? LucideIcons.alertTriangle : LucideIcons.calendarClock,
                size: 18,
                color: isOverdue ? Colors.red : Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.serviceType.label,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colors.textPrimary)),
                  Text(log.treatmentType.label,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                  if (log.serviceFrequency != ServiceFrequency.oneTime)
                    Text(log.serviceFrequency.label,
                        style: TextStyle(fontSize: 11, color: colors.textTertiary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (nextDate != null)
                  Text(
                    '${nextDate.month}/${nextDate.day}/${nextDate.year}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOverdue ? Colors.red : colors.textPrimary,
                    ),
                  ),
                Text(
                  isOverdue
                      ? '${daysUntil.abs()} days overdue'
                      : daysUntil == 0
                          ? 'Today'
                          : '$daysUntil days',
                  style: TextStyle(
                    fontSize: 10,
                    color: isOverdue ? Colors.red : colors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCol(ZaftoColors colors, String value, String label, {Color? color}) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: color ?? colors.textPrimary)),
        Text(label, style: TextStyle(fontSize: 11, color: colors.textTertiary)),
      ],
    );
  }

  Widget _sectionHeader(ZaftoColors colors, String label) {
    return Text(label,
        style: TextStyle(
            fontFamily: 'SF Pro Text', fontSize: 11, fontWeight: FontWeight.w600,
            letterSpacing: 0.5, color: colors.textTertiary));
  }
}
