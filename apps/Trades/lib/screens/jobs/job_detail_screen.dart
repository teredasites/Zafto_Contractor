// Job Detail Screen - Design System v2.6
// Full job view with edit, status change, photos

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/job.dart';
import '../../services/job_service.dart';
import '../../services/insurance_claim_service.dart';
import '../../providers/schedule_project_provider.dart';
import '../../providers/schedule_tasks_provider.dart';
import '../../widgets/mini_gantt_widget.dart';
import 'job_create_screen.dart';
import '../invoices/invoice_create_screen.dart';
import '../insurance/claim_detail_screen.dart';
import '../scheduling/schedule_gantt_screen.dart';
import '../messages/chat_screen.dart';
import '../../providers/messaging_provider.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});
  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  Job? _job;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  Future<void> _loadJob() async {
    final service = ref.read(jobServiceProvider);
    final job = await service.getJob(widget.jobId);
    setState(() {
      _job = job;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.bgBase,
        body: Center(child: CircularProgressIndicator(color: colors.accentPrimary)),
      );
    }

    if (_job == null) {
      return Scaffold(
        backgroundColor: colors.bgBase,
        appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0),
        body: Center(child: Text('Job not found', style: TextStyle(color: colors.textSecondary))),
      );
    }

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(colors),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatusSection(colors),
                const SizedBox(height: 20),
                _buildDetailsCard(colors),
                if (_hasContactInfo()) ...[
                  const SizedBox(height: 16),
                  _buildContactCard(colors),
                ],
                if (_job!.jobType != JobType.standard && _job!.hasTypeMetadata) ...[
                  const SizedBox(height: 16),
                  _buildTypeMetadataCard(colors),
                ],
                const SizedBox(height: 16),
                _buildAmountCard(colors),
                const SizedBox(height: 16),
                _buildScheduleCard(colors),
                if (_job!.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  _buildNotesCard(colors),
                ],
                const SizedBox(height: 24),
                _buildActionsSection(colors),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ZaftoColors colors) {
    return SliverAppBar(
      backgroundColor: colors.bgBase,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(icon: Icon(LucideIcons.pencil, color: colors.textSecondary), onPressed: () => _editJob()),
        IconButton(icon: Icon(LucideIcons.moreVertical, color: colors.textSecondary), onPressed: () => _showMoreOptions(colors)),
      ],
    );
  }

  Widget _buildStatusSection(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatusBadge(colors, _job!.status),
            if (_job!.jobType != JobType.standard) ...[
              const SizedBox(width: 8),
              _buildJobTypeBadge(colors, _job!),
            ],
            const Spacer(),
            if (_job!.scheduledStart != null)
              Row(
                children: [
                  Icon(LucideIcons.calendar, size: 14, color: colors.textTertiary),
                  const SizedBox(width: 4),
                  Text(_formatDate(_job!.scheduledStart!), style: TextStyle(fontSize: 13, color: colors.textTertiary)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(_job!.displayTitle, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        if (_job!.customerName.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(_job!.customerName, style: TextStyle(fontSize: 16, color: colors.textSecondary)),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(ZaftoColors colors, JobStatus status) {
    final (color, bgColor, icon) = switch (status) {
      JobStatus.draft => (colors.textTertiary, colors.fillDefault, LucideIcons.inbox),
      JobStatus.dispatched => (colors.accentInfo, colors.accentInfo.withValues(alpha: 0.15), LucideIcons.truck),
      JobStatus.enRoute => (colors.accentInfo, colors.accentInfo.withValues(alpha: 0.15), LucideIcons.navigation),
      JobStatus.onHold => (colors.accentWarning, colors.accentWarning.withValues(alpha: 0.15), LucideIcons.pauseCircle),
      JobStatus.scheduled => (colors.accentInfo, colors.accentInfo.withValues(alpha: 0.15), LucideIcons.calendar),
      JobStatus.inProgress => (colors.accentSuccess, colors.accentSuccess.withValues(alpha: 0.15), LucideIcons.play),
      JobStatus.completed => (colors.accentPrimary, colors.accentPrimary.withValues(alpha: 0.15), LucideIcons.checkCircle),
      JobStatus.invoiced => (colors.accentSuccess, colors.accentSuccess.withValues(alpha: 0.15), LucideIcons.fileText),
      JobStatus.cancelled => (colors.textTertiary, colors.fillDefault, LucideIcons.x),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(_job!.statusLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildJobTypeBadge(ZaftoColors colors, Job job) {
    final (color, icon) = switch (job.jobType) {
      JobType.standard => (colors.accentInfo, LucideIcons.briefcase),
      JobType.insuranceClaim => (const Color(0xFFF59E0B), LucideIcons.shield),
      JobType.warrantyDispatch => (const Color(0xFF8B5CF6), LucideIcons.fileCheck),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(job.jobTypeLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildTypeMetadataCard(ZaftoColors colors) {
    final meta = _job!.typeMetadata;
    final isInsurance = _job!.isInsuranceClaim;
    final accentColor = isInsurance ? const Color(0xFFF59E0B) : const Color(0xFF8B5CF6);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isInsurance ? LucideIcons.shield : LucideIcons.fileCheck, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Text(isInsurance ? 'Insurance Claim' : 'Warranty Dispatch',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          if (isInsurance) ...[
            if (meta['insuranceCompany'] != null) _buildMetaRow(colors, 'Carrier', meta['insuranceCompany'] as String),
            if (meta['claimNumber'] != null) _buildMetaRow(colors, 'Claim #', meta['claimNumber'] as String),
            if (meta['dateOfLoss'] != null) _buildMetaRow(colors, 'Date of Loss', _formatDateStr(meta['dateOfLoss'] as String)),
            if (meta['adjusterName'] != null) _buildMetaRow(colors, 'Adjuster', meta['adjusterName'] as String),
            if (meta['deductible'] != null) _buildMetaRow(colors, 'Deductible', '\$${(meta['deductible'] as num).toStringAsFixed(2)}'),
            if (meta['approvalStatus'] != null) _buildMetaRow(colors, 'Status', (meta['approvalStatus'] as String).toUpperCase()),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  final claimAsync = ref.read(jobClaimProvider(_job!.id));
                  claimAsync.whenData((claim) {
                    if (claim != null && mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ClaimDetailScreen(claimId: claim.id)));
                    }
                  });
                },
                icon: const Icon(LucideIcons.shield, size: 14),
                label: const Text('View Claim', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFF59E0B),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ] else ...[
            if (meta['warrantyCompany'] != null) _buildMetaRow(colors, 'Company', meta['warrantyCompany'] as String),
            if (meta['dispatchNumber'] != null) _buildMetaRow(colors, 'Dispatch #', meta['dispatchNumber'] as String),
            if (meta['authorizationLimit'] != null) _buildMetaRow(colors, 'Auth Limit', '\$${(meta['authorizationLimit'] as num).toStringAsFixed(2)}'),
            if (meta['serviceFee'] != null) _buildMetaRow(colors, 'Service Fee', '\$${(meta['serviceFee'] as num).toStringAsFixed(2)}'),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 12, color: colors.textTertiary))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary))),
        ],
      ),
    );
  }

  String _formatDateStr(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.month}/${d.day}/${d.year}';
  }

  Widget _buildDetailsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        children: [
          if (_job!.address.isNotEmpty) _buildDetailRow(colors, LucideIcons.mapPin, 'Address', _job!.address),
          if (_job!.customerName.isNotEmpty) ...[
            if (_job!.address.isNotEmpty) Divider(height: 24, color: colors.borderSubtle),
            _buildDetailRow(colors, LucideIcons.user, 'Customer', _job!.customerName),
          ],
          if (_job!.scheduledStart != null) ...[
            Divider(height: 24, color: colors.borderSubtle),
            _buildDetailRow(colors, LucideIcons.calendar, 'Scheduled', _formatDateFull(_job!.scheduledStart!)),
          ],
          if (_job!.completedAt != null) ...[
            Divider(height: 24, color: colors.borderSubtle),
            _buildDetailRow(colors, LucideIcons.checkCircle, 'Completed', _formatDateFull(_job!.completedAt!)),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(ZaftoColors colors, IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: colors.fillDefault, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: colors.textTertiary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: colors.textTertiary)),
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ESTIMATED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors.textTertiary, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text('\$${_job!.estimatedAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              ],
            ),
          ),
          if (_job!.actualAmount != null) ...[
            Container(width: 1, height: 40, color: colors.borderSubtle),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACTUAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors.textTertiary, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text('\$${_job!.actualAmount!.toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.accentSuccess)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleCard(ZaftoColors colors) {
    final schedulesAsync = ref.watch(scheduleProjectsByJobProvider(widget.jobId));

    return schedulesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (schedules) {
        if (schedules.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.ganttChart, size: 16, color: colors.accentPrimary),
                    const SizedBox(width: 8),
                    Text('Schedule', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('No schedule linked to this job', style: TextStyle(fontSize: 13, color: colors.textTertiary)),
              ],
            ),
          );
        }

        final schedule = schedules.first;
        final tasksAsync = ref.watch(scheduleTasksProvider(schedule.id));

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.ganttChart, size: 16, color: colors.accentPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(schedule.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary), overflow: TextOverflow.ellipsis),
                  ),
                  Text(
                    '${schedule.overallPercentComplete.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.accentPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: schedule.overallPercentComplete / 100,
                  backgroundColor: colors.fillDefault,
                  valueColor: AlwaysStoppedAnimation(schedule.isComplete ? colors.accentSuccess : colors.accentPrimary),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 10),
              // Mini Gantt
              tasksAsync.when(
                loading: () => SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: colors.accentPrimary))),
                error: (_, __) => const SizedBox.shrink(),
                data: (tasks) => MiniGanttWidget(
                  tasks: tasks.map((t) => MiniGanttTask(
                    id: t.id,
                    name: t.name,
                    start: t.earlyStart ?? t.plannedStart,
                    finish: t.earlyFinish ?? t.plannedFinish,
                    percentComplete: t.percentComplete,
                    isCritical: t.isCritical,
                    isMilestone: t.isMilestone,
                  )).toList(),
                  colors: colors,
                  height: 100,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ScheduleGanttScreen(projectId: schedule.id, projectName: schedule.name),
                  )),
                ),
              ),
              const SizedBox(height: 8),
              // View full schedule button
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ScheduleGanttScreen(projectId: schedule.id, projectName: schedule.name),
                )),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('View Full Schedule', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.accentPrimary)),
                    const SizedBox(width: 4),
                    Icon(LucideIcons.chevronRight, size: 14, color: colors.accentPrimary),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotesCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.fileText, size: 16, color: colors.textTertiary),
              const SizedBox(width: 8),
              Text('Notes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(_job!.description!, style: TextStyle(fontSize: 14, color: colors.textPrimary, height: 1.5)),
        ],
      ),
    );
  }

  // ── Contact & Directions Card ──────────────────────────────
  bool _hasContactInfo() {
    final phone = _job!.customerPhone ?? '';
    final email = _job!.customerEmail ?? '';
    return phone.isNotEmpty || email.isNotEmpty || _job!.address.isNotEmpty;
  }

  Widget _buildContactCard(ZaftoColors colors) {
    final phone = _job!.customerPhone ?? '';
    final email = _job!.customerEmail ?? '';
    final address = _job!.address;
    final fullAddress = _job!.fullAddress;
    final hasPhone = phone.isNotEmpty;
    final hasEmail = email.isNotEmpty;
    final hasAddress = address.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.contact, size: 16, color: colors.accentPrimary),
              const SizedBox(width: 8),
              Text('Quick Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          // Action buttons row
          Row(
            children: [
              if (hasPhone)
                Expanded(
                  child: _buildQuickActionBtn(
                    colors,
                    icon: LucideIcons.phone,
                    label: 'Call',
                    color: colors.accentSuccess,
                    onTap: () => _launchUrl('tel:$phone'),
                  ),
                ),
              if (hasPhone && (hasEmail || hasAddress))
                const SizedBox(width: 8),
              if (hasPhone)
                Expanded(
                  child: _buildQuickActionBtn(
                    colors,
                    icon: LucideIcons.messageSquare,
                    label: 'Text',
                    color: colors.accentInfo,
                    onTap: () => _launchUrl('sms:$phone'),
                  ),
                ),
              if (hasPhone && hasAddress)
                const SizedBox(width: 8),
              if (hasAddress)
                Expanded(
                  child: _buildQuickActionBtn(
                    colors,
                    icon: LucideIcons.navigation,
                    label: 'Directions',
                    color: const Color(0xFF6366F1),
                    onTap: () => _launchDirections(fullAddress),
                  ),
                ),
            ],
          ),
          if (hasEmail) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _launchUrl('mailto:$email'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: colors.fillDefault,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.mail, size: 14, color: colors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      email,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn(
    ZaftoColors colors, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchDirections(String address) async {
    final encoded = Uri.encodeComponent(address);
    // Try Google Maps first, falls back to Apple Maps on iOS
    final googleUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encoded');
    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildActionsSection(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textTertiary, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        _buildStatusButtons(colors),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildActionButton(colors, LucideIcons.fileText, 'Create Invoice', colors.accentInfo, () => _createInvoice())),
            const SizedBox(width: 12),
            Expanded(child: _buildActionButton(colors, LucideIcons.camera, 'Add Photos', colors.textSecondary, () {})),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(colors, LucideIcons.messageSquare, 'Message Team', colors.accentPrimary, () => _openJobChat()),
        ),
      ],
    );
  }

  Widget _buildStatusButtons(ZaftoColors colors) {
    final nextStatuses = _getNextStatuses(_job!.status);
    if (nextStatuses.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: nextStatuses.map((status) {
        final (label, color) = switch (status) {
          JobStatus.scheduled => ('Schedule', colors.accentInfo),
          JobStatus.inProgress => ('Start Work', colors.accentSuccess),
          JobStatus.completed => ('Mark Complete', colors.accentPrimary),
          JobStatus.invoiced => ('Mark Invoiced', colors.accentSuccess),
          JobStatus.cancelled => ('Cancel', colors.textTertiary),
          _ => ('Update', colors.textSecondary),
        };
        return GestureDetector(
          onTap: () => _updateStatus(status),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.isDark ? Colors.black : Colors.white)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(ZaftoColors colors, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary)),
          ],
        ),
      ),
    );
  }

  List<JobStatus> _getNextStatuses(JobStatus current) {
    return switch (current) {
      JobStatus.draft => [JobStatus.scheduled, JobStatus.cancelled],
      JobStatus.scheduled => [JobStatus.dispatched, JobStatus.inProgress, JobStatus.cancelled],
      JobStatus.dispatched => [JobStatus.enRoute, JobStatus.inProgress, JobStatus.cancelled],
      JobStatus.enRoute => [JobStatus.inProgress],
      JobStatus.inProgress => [JobStatus.onHold, JobStatus.completed],
      JobStatus.onHold => [JobStatus.inProgress, JobStatus.cancelled],
      JobStatus.completed => [JobStatus.invoiced],
      JobStatus.invoiced => [],
      JobStatus.cancelled => [JobStatus.draft],
    };
  }

  Future<void> _updateStatus(JobStatus newStatus) async {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final updated = _job!.copyWith(
      status: newStatus,
      completedAt: newStatus == JobStatus.completed ? now : _job!.completedAt,
      updatedAt: now,
    );
    await ref.read(jobsProvider.notifier).updateJob(updated);
    setState(() => _job = updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Job status updated to ${updated.statusLabel}')));
    }
  }

  void _editJob() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push<Job>(
      context,
      MaterialPageRoute(builder: (context) => JobCreateScreen(editJob: _job)),
    );
    if (result != null) {
      setState(() => _job = result);
    }
  }

  void _showMoreOptions(ZaftoColors colors) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOptionTile(colors, LucideIcons.copy, 'Duplicate Job', () {}),
              _buildOptionTile(colors, LucideIcons.share, 'Share Details', () {}),
              _buildOptionTile(colors, LucideIcons.trash2, 'Delete Job', () => _deleteJob(), isDestructive: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(ZaftoColors colors, IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : colors.textSecondary),
      title: Text(label, style: TextStyle(color: isDestructive ? Colors.red : colors.textPrimary)),
      onTap: () { Navigator.pop(context); onTap(); },
    );
  }

  Future<void> _deleteJob() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = ref.read(zaftoColorsProvider);
        return AlertDialog(
          backgroundColor: colors.bgElevated,
          title: Text('Delete Job?', style: TextStyle(color: colors.textPrimary)),
          content: Text('This action cannot be undone.', style: TextStyle(color: colors.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: colors.textSecondary))),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        );
      },
    );
    if (confirm == true) {
      await ref.read(jobsProvider.notifier).deleteJob(widget.jobId);
      if (mounted) Navigator.pop(context);
    }
  }

  void _createInvoice() {
    if (_job == null) return;
    HapticFeedback.mediumImpact();

    // Navigate to invoice creation with job data pre-filled
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceCreateScreen(
          jobId: _job!.id,
          customerName: _job!.customerName,
          prefillAmount: _job!.actualAmount ?? _job!.estimatedAmount,
        ),
      ),
    );
  }

  Future<void> _openJobChat() async {
    if (_job == null) return;
    HapticFeedback.mediumImpact();

    try {
      // Create or find a job-scoped conversation for this job's assigned team
      final jobTitle = _job!.title ?? 'Untitled Job';
      final conv = await ref.read(messagingActionsProvider.notifier).createGroup(
            title: jobTitle,
            participantIds: _job!.assignedUserIds,
            jobId: _job!.id,
          );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conv.id,
              title: jobTitle,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open chat: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return '${date.month}/${date.day}';
  }

  String _formatDateFull(DateTime date) => '${date.month}/${date.day}/${date.year}';
}
