/// Job Detail Screen - Design System v2.6
/// Full job view with edit, status change, photos

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/business/job.dart';
import '../../services/job_service.dart';
import 'job_create_screen.dart';
import '../invoices/invoice_create_screen.dart';

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
                const SizedBox(height: 16),
                _buildAmountCard(colors),
                if (_job!.notes?.isNotEmpty == true) ...[
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
            const Spacer(),
            if (_job!.scheduledDate != null)
              Row(
                children: [
                  Icon(LucideIcons.calendar, size: 14, color: colors.textTertiary),
                  const SizedBox(width: 4),
                  Text(_formatDate(_job!.scheduledDate!), style: TextStyle(fontSize: 13, color: colors.textTertiary)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(_job!.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        if (_job!.customerName != null) ...[
          const SizedBox(height: 6),
          Text(_job!.customerName!, style: TextStyle(fontSize: 16, color: colors.textSecondary)),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(ZaftoColors colors, JobStatus status) {
    final (color, bgColor, icon) = switch (status) {
      JobStatus.lead => (colors.textTertiary, colors.fillDefault, LucideIcons.inbox),
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
          if (_job!.address != null) _buildDetailRow(colors, LucideIcons.mapPin, 'Address', _job!.address!),
          if (_job!.customerName != null) ...[
            if (_job!.address != null) Divider(height: 24, color: colors.borderSubtle),
            _buildDetailRow(colors, LucideIcons.user, 'Customer', _job!.customerName!),
          ],
          if (_job!.scheduledDate != null) ...[
            Divider(height: 24, color: colors.borderSubtle),
            _buildDetailRow(colors, LucideIcons.calendar, 'Scheduled', _formatDateFull(_job!.scheduledDate!)),
          ],
          if (_job!.completedDate != null) ...[
            Divider(height: 24, color: colors.borderSubtle),
            _buildDetailRow(colors, LucideIcons.checkCircle, 'Completed', _formatDateFull(_job!.completedDate!)),
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
          Text(_job!.notes!, style: TextStyle(fontSize: 14, color: colors.textPrimary, height: 1.5)),
        ],
      ),
    );
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
      JobStatus.lead => [JobStatus.scheduled, JobStatus.cancelled],
      JobStatus.scheduled => [JobStatus.inProgress, JobStatus.cancelled],
      JobStatus.inProgress => [JobStatus.completed],
      JobStatus.completed => [JobStatus.invoiced],
      JobStatus.invoiced => [],
      JobStatus.cancelled => [JobStatus.lead],
    };
  }

  Future<void> _updateStatus(JobStatus newStatus) async {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final updated = _job!.copyWith(
      status: newStatus,
      completedDate: newStatus == JobStatus.completed ? now : _job!.completedDate,
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
