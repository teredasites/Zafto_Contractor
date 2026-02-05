import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class MaintenanceScheduleScreen extends ConsumerWidget {
  const MaintenanceScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Maintenance Schedule',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDailyTasks(colors),
            const SizedBox(height: 24),
            _buildWeeklyTasks(colors),
            const SizedBox(height: 24),
            _buildMonthlyTasks(colors),
            const SizedBox(height: 24),
            _buildSeasonalTasks(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTasks(ZaftoColors colors) {
    final tasks = [
      {'task': 'Check water level', 'why': 'Pump damage if too low', 'time': '1 min'},
      {'task': 'Empty skimmer basket', 'why': 'Maintain flow rate', 'time': '2 min'},
      {'task': 'Skim surface debris', 'why': 'Prevent staining, algae', 'time': '5 min'},
      {'task': 'Check pump operation', 'why': 'Catch problems early', 'time': '1 min'},
      {'task': 'Inspect for leaks', 'why': 'Water/chemical loss', 'time': '2 min'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sun, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Daily Tasks',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accentPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('~11 min', style: TextStyle(color: colors.accentPrimary, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tasks.map((t) => _buildTaskRow(colors, t['task']!, t['why']!, t['time']!)),
        ],
      ),
    );
  }

  Widget _buildWeeklyTasks(ZaftoColors colors) {
    final tasks = [
      {'task': 'Test water chemistry', 'why': 'Maintain safe levels', 'time': '10 min'},
      {'task': 'Add chemicals as needed', 'why': 'Balance pH, chlorine', 'time': '5 min'},
      {'task': 'Brush walls and floor', 'why': 'Prevent algae buildup', 'time': '20 min'},
      {'task': 'Vacuum pool', 'why': 'Remove settled debris', 'time': '30 min'},
      {'task': 'Clean pump strainer', 'why': 'Maintain flow rate', 'time': '5 min'},
      {'task': 'Check filter pressure', 'why': 'Know when to clean', 'time': '1 min'},
      {'task': 'Inspect equipment', 'why': 'Catch wear early', 'time': '5 min'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.calendar, color: colors.accentInfo, size: 24),
              const SizedBox(width: 12),
              Text(
                'Weekly Tasks',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accentInfo.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('~75 min', style: TextStyle(color: colors.accentInfo, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tasks.map((t) => _buildTaskRow(colors, t['task']!, t['why']!, t['time']!)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.testTube, color: colors.accentWarning, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Test strips: pH, chlorine, alkalinity. Full test kit monthly.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTasks(ZaftoColors colors) {
    final tasks = [
      {'task': 'Full chemical test', 'why': 'CYA, calcium, TDS', 'time': '15 min'},
      {'task': 'Clean/backwash filter', 'why': 'Restore flow rate', 'time': '30 min'},
      {'task': 'Inspect O-rings/gaskets', 'why': 'Prevent leaks', 'time': '10 min'},
      {'task': 'Check water level sensor', 'why': 'Auto-fill accuracy', 'time': '5 min'},
      {'task': 'Clean tile line', 'why': 'Remove scale buildup', 'time': '20 min'},
      {'task': 'Test safety equipment', 'why': 'GFCI, alarms, covers', 'time': '10 min'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.calendarDays, color: colors.accentWarning, size: 24),
              const SizedBox(width: 12),
              Text(
                'Monthly Tasks',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accentWarning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('~90 min', style: TextStyle(color: colors.accentWarning, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tasks.map((t) => _buildTaskRow(colors, t['task']!, t['why']!, t['time']!)),
        ],
      ),
    );
  }

  Widget _buildSeasonalTasks(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.leaf, color: colors.accentSuccess, size: 24),
              const SizedBox(width: 12),
              Text(
                'Seasonal & Annual',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSeasonCard(colors, 'Spring Opening', [
            'Remove cover, clean and store',
            'Fill pool to proper level',
            'Reconnect equipment',
            'Prime and start pump',
            'Shock treat and balance chemistry',
            'Run filter 24 hours',
          ], LucideIcons.flower),
          const SizedBox(height: 12),
          _buildSeasonCard(colors, 'Fall Closing', [
            'Balance chemistry before closing',
            'Shock and add algaecide',
            'Lower water below skimmer',
            'Blow out plumbing lines',
            'Add antifreeze to lines',
            'Cover pool securely',
          ], LucideIcons.cloud),
          const SizedBox(height: 12),
          _buildSeasonCard(colors, 'Annual Service', [
            'Professional equipment inspection',
            'Replace worn gaskets/O-rings',
            'Lubricate valves and o-rings',
            'Check electrical connections',
            'Acid wash if needed',
            'Replace filter media if due',
          ], LucideIcons.wrench),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Replacement Schedule:', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                _buildReplaceItem(colors, 'Filter cartridge', '1-2 years'),
                _buildReplaceItem(colors, 'Sand media', '5-7 years'),
                _buildReplaceItem(colors, 'DE grids', '7-10 years'),
                _buildReplaceItem(colors, 'Pump motor', '8-12 years'),
                _buildReplaceItem(colors, 'Heater', '10-15 years'),
                _buildReplaceItem(colors, 'Salt cell', '3-7 years'),
                _buildReplaceItem(colors, 'Pool light', '5-10 years'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow(ZaftoColors colors, String task, String why, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(LucideIcons.checkSquare, color: colors.accentSuccess, size: 16),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                Text(why, style: TextStyle(color: colors.textTertiary, fontSize: 9)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(time, style: TextStyle(color: colors.textSecondary, fontSize: 9)),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonCard(ZaftoColors colors, String title, List<String> tasks, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgBase,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.accentSuccess, size: 16),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ...tasks.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: colors.textTertiary, fontSize: 10)),
                Expanded(child: Text(t, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildReplaceItem(ZaftoColors colors, String item, String interval) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(LucideIcons.refreshCw, color: colors.textTertiary, size: 12),
          const SizedBox(width: 6),
          Expanded(child: Text(item, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
          Text(interval, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }
}
