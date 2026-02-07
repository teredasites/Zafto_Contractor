import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/daily_log.dart';
import '../../services/daily_log_service.dart';

/// Daily Job Log - One log per job per day with weather, work, issues, crew
class DailyLogScreen extends ConsumerStatefulWidget {
  final String? jobId;

  const DailyLogScreen({super.key, this.jobId});

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form controllers
  final _weatherCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _workCtrl = TextEditingController();
  final _issuesCtrl = TextEditingController();
  final _delaysCtrl = TextEditingController();
  final _visitorsCtrl = TextEditingController();
  final _crewCountCtrl = TextEditingController(text: '1');
  final _hoursCtrl = TextEditingController();
  final _safetyCtrl = TextEditingController();

  DailyLog? _existingLog;
  bool _isLoading = true;
  bool _isSaving = false;
  List<DailyLog> _history = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTodaysLog();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _weatherCtrl.dispose();
    _tempCtrl.dispose();
    _summaryCtrl.dispose();
    _workCtrl.dispose();
    _issuesCtrl.dispose();
    _delaysCtrl.dispose();
    _visitorsCtrl.dispose();
    _crewCountCtrl.dispose();
    _hoursCtrl.dispose();
    _safetyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTodaysLog() async {
    if (widget.jobId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final service = ref.read(dailyLogServiceProvider);
      final existing = await service.getTodaysLog(widget.jobId!);
      final history = await service.getLogsByJob(widget.jobId!);

      if (mounted) {
        if (existing != null) {
          _existingLog = existing;
          _weatherCtrl.text = existing.weather ?? '';
          _tempCtrl.text = existing.temperatureF?.toString() ?? '';
          _summaryCtrl.text = existing.summary;
          _workCtrl.text = existing.workPerformed ?? '';
          _issuesCtrl.text = existing.issues ?? '';
          _delaysCtrl.text = existing.delays ?? '';
          _visitorsCtrl.text = existing.visitors ?? '';
          _crewCountCtrl.text = existing.crewCount.toString();
          _hoursCtrl.text = existing.hoursWorked?.toString() ?? '';
          _safetyCtrl.text = existing.safetyNotes ?? '';
        }
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Daily Log',
            style: TextStyle(
                color: colors.textPrimary, fontWeight: FontWeight.w600)),
        bottom: widget.jobId != null
            ? TabBar(
                controller: _tabController,
                labelColor: colors.accentPrimary,
                unselectedLabelColor: colors.textTertiary,
                indicatorColor: colors.accentPrimary,
                tabs: const [
                  Tab(text: "Today's Log"),
                  Tab(text: 'History'),
                ],
              )
            : null,
      ),
      body: widget.jobId == null
          ? _buildNoJobState(colors)
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLogForm(colors),
                    _buildHistory(colors),
                  ],
                ),
    );
  }

  Widget _buildNoJobState(ZaftoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.clipboardList,
                size: 52, color: colors.textTertiary),
          ),
          const SizedBox(height: 24),
          Text('No job selected',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary)),
          const SizedBox(height: 8),
          Text('Open from a job to create a daily log',
              style: TextStyle(fontSize: 14, color: colors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildLogForm(ZaftoColors colors) {
    final today = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.calendar, size: 18, color: colors.accentPrimary),
                const SizedBox(width: 10),
                Text(today,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary)),
                const Spacer(),
                if (_existingLog != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.accentSuccess.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Saved',
                        style: TextStyle(
                            fontSize: 11,
                            color: colors.accentSuccess,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Weather row
          _buildSectionLabel(colors, 'WEATHER'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildFormField(colors, _weatherCtrl, 'Conditions',
                    hint: 'Sunny, Overcast, Rain...',
                    icon: LucideIcons.cloud),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _buildFormField(colors, _tempCtrl, 'Temp',
                    hint: '72',
                    suffix: '\u00B0F',
                    keyboardType: TextInputType.number),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Summary
          _buildSectionLabel(colors, 'SUMMARY *'),
          const SizedBox(height: 8),
          _buildFormField(colors, _summaryCtrl, 'Brief summary of the day',
              hint: 'Completed rough-in for kitchen and master bath...',
              maxLines: 3),
          const SizedBox(height: 20),

          // Work Performed
          _buildSectionLabel(colors, 'WORK PERFORMED'),
          const SizedBox(height: 8),
          _buildFormField(colors, _workCtrl, 'Detailed work description',
              hint:
                  'Ran 120V circuits to kitchen island, installed 4 outlets...',
              maxLines: 4),
          const SizedBox(height: 20),

          // Issues
          _buildSectionLabel(colors, 'ISSUES / PROBLEMS'),
          const SizedBox(height: 8),
          _buildFormField(colors, _issuesCtrl, 'Issues encountered',
              hint: 'Found moisture in subfloor near dishwasher...',
              maxLines: 3),
          const SizedBox(height: 20),

          // Delays
          _buildSectionLabel(colors, 'DELAYS'),
          const SizedBox(height: 8),
          _buildFormField(colors, _delaysCtrl, 'Delays or downtime',
              hint: 'Waiting 2 hrs for inspector...',
              maxLines: 2),
          const SizedBox(height: 20),

          // Crew & Hours row
          _buildSectionLabel(colors, 'CREW & HOURS'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                    colors, _crewCountCtrl, 'Crew Size',
                    hint: '3',
                    icon: LucideIcons.users,
                    keyboardType: TextInputType.number),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFormField(colors, _hoursCtrl, 'Hours Worked',
                    hint: '8.5',
                    icon: LucideIcons.clock,
                    keyboardType: TextInputType.number),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Visitors
          _buildSectionLabel(colors, 'VISITORS'),
          const SizedBox(height: 8),
          _buildFormField(colors, _visitorsCtrl, 'Visitors on site',
              hint: 'Inspector (John), homeowner stopped by at 2pm'),
          const SizedBox(height: 20),

          // Safety Notes
          _buildSectionLabel(colors, 'SAFETY NOTES'),
          const SizedBox(height: 8),
          _buildFormField(colors, _safetyCtrl, 'Safety observations',
              hint: 'Reminded crew to wear hard hats in garage area...',
              maxLines: 2,
              icon: LucideIcons.shield),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(_isSaving ? null : LucideIcons.save, size: 18),
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : _existingLog != null
                        ? 'Update Log'
                        : 'Save Log',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: colors.isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : () => _saveLog(colors),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHistory(ZaftoColors colors) {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.fileText, size: 48, color: colors.textTertiary),
            const SizedBox(height: 16),
            Text('No logs yet',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary)),
            const SizedBox(height: 8),
            Text('Daily logs will appear here',
                style: TextStyle(fontSize: 14, color: colors.textTertiary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final log = _history[index];
        return _buildHistoryCard(colors, log);
      },
    );
  }

  Widget _buildHistoryCard(ZaftoColors colors, DailyLog log) {
    final dateStr = DateFormat('EEE, MMM d').format(log.logDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.calendar, size: 14, color: colors.accentPrimary),
              const SizedBox(width: 6),
              Text(dateStr,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.accentPrimary)),
              const Spacer(),
              if (log.weather != null)
                Row(
                  children: [
                    Icon(LucideIcons.cloud, size: 12, color: colors.textTertiary),
                    const SizedBox(width: 4),
                    Text(log.weather!,
                        style: TextStyle(
                            fontSize: 12, color: colors.textTertiary)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(log.summary,
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            children: [
              if (log.crewCount > 0) ...[
                Icon(LucideIcons.users, size: 12, color: colors.textTertiary),
                const SizedBox(width: 4),
                Text('${log.crewCount} crew',
                    style:
                        TextStyle(fontSize: 12, color: colors.textTertiary)),
                const SizedBox(width: 12),
              ],
              if (log.hoursWorked != null) ...[
                Icon(LucideIcons.clock, size: 12, color: colors.textTertiary),
                const SizedBox(width: 4),
                Text('${log.hoursWorked}h',
                    style:
                        TextStyle(fontSize: 12, color: colors.textTertiary)),
              ],
              if (log.hasIssues) ...[
                const SizedBox(width: 12),
                Icon(LucideIcons.alertCircle,
                    size: 12, color: colors.accentWarning),
                const SizedBox(width: 4),
                Text('Issues',
                    style: TextStyle(
                        fontSize: 12, color: colors.accentWarning)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORM HELPERS
  // ============================================================

  Widget _buildSectionLabel(ZaftoColors colors, String text) {
    return Text(text,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors.textTertiary,
            letterSpacing: 0.5));
  }

  Widget _buildFormField(
    ZaftoColors colors,
    TextEditingController ctrl,
    String label, {
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? suffix,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(fontSize: 13, color: colors.textTertiary),
        hintStyle: TextStyle(fontSize: 13, color: colors.textTertiary.withOpacity(0.5)),
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: colors.textTertiary)
            : null,
        suffixText: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _saveLog(ZaftoColors colors) async {
    if (_summaryCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Summary is required'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final service = ref.read(dailyLogServiceProvider);

      if (_existingLog != null) {
        // Update existing
        final updated = await service.updateLog(
          _existingLog!.id,
          _existingLog!
              .copyWith(
                weather: _weatherCtrl.text.trim().isNotEmpty
                    ? _weatherCtrl.text.trim()
                    : null,
                temperatureF: int.tryParse(_tempCtrl.text),
                summary: _summaryCtrl.text.trim(),
                workPerformed: _workCtrl.text.trim().isNotEmpty
                    ? _workCtrl.text.trim()
                    : null,
                issues: _issuesCtrl.text.trim().isNotEmpty
                    ? _issuesCtrl.text.trim()
                    : null,
                delays: _delaysCtrl.text.trim().isNotEmpty
                    ? _delaysCtrl.text.trim()
                    : null,
                visitors: _visitorsCtrl.text.trim().isNotEmpty
                    ? _visitorsCtrl.text.trim()
                    : null,
                crewCount: int.tryParse(_crewCountCtrl.text) ?? 1,
                hoursWorked: double.tryParse(_hoursCtrl.text),
                safetyNotes: _safetyCtrl.text.trim().isNotEmpty
                    ? _safetyCtrl.text.trim()
                    : null,
              )
              .toUpdateJson(),
        );
        _existingLog = updated;
      } else {
        // Create new
        final created = await service.createLog(
          jobId: widget.jobId!,
          logDate: DateTime.now(),
          summary: _summaryCtrl.text.trim(),
          weather: _weatherCtrl.text.trim().isNotEmpty
              ? _weatherCtrl.text.trim()
              : null,
          temperatureF: int.tryParse(_tempCtrl.text),
          workPerformed: _workCtrl.text.trim().isNotEmpty
              ? _workCtrl.text.trim()
              : null,
          issues: _issuesCtrl.text.trim().isNotEmpty
              ? _issuesCtrl.text.trim()
              : null,
          delays: _delaysCtrl.text.trim().isNotEmpty
              ? _delaysCtrl.text.trim()
              : null,
          visitors: _visitorsCtrl.text.trim().isNotEmpty
              ? _visitorsCtrl.text.trim()
              : null,
          crewCount: int.tryParse(_crewCountCtrl.text) ?? 1,
          hoursWorked: double.tryParse(_hoursCtrl.text),
          safetyNotes: _safetyCtrl.text.trim().isNotEmpty
              ? _safetyCtrl.text.trim()
              : null,
        );
        _existingLog = created;
      }

      // Reload history
      final history = await service.getLogsByJob(widget.jobId!);

      if (mounted) {
        setState(() {
          _history = history;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Daily log saved'),
            backgroundColor: colors.accentSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save log'),
            backgroundColor: colors.accentError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
