/// Customer Detail Screen - Design System v2.6
/// View customer info, jobs, invoices history

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/customer.dart';
import '../../models/job.dart';
import '../../models/invoice.dart';
import '../../services/customer_service.dart';
import '../../services/job_service.dart';
import '../../services/invoice_service.dart';
import '../../core/supabase_client.dart';
import '../jobs/job_detail_screen.dart';
import '../jobs/job_create_screen.dart';
import '../invoices/invoice_detail_screen.dart';
import 'customer_create_screen.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});
  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  Customer? _customer;
  List<Job> _jobs = [];
  List<Invoice> _invoices = [];
  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final customerService = ref.read(customerServiceProvider);
    final jobService = ref.read(jobServiceProvider);
    final invoiceService = ref.read(invoiceServiceProvider);

    final customer = await customerService.getCustomer(widget.customerId);
    final allJobs = await jobService.getAllJobs();
    final allInvoices = await invoiceService.getAllInvoices();

    // Filter jobs and invoices by customer ID (with name fallback for legacy data)
    final customerJobs = allJobs.where((j) =>
        j.customerId == widget.customerId ||
        (j.customerId == null && j.customerName == customer?.name)).toList();
    final customerInvoices = allInvoices.where((i) =>
        i.customerId == widget.customerId ||
        (i.customerId == null && i.customerName == customer?.name)).toList();

    // Load maintenance predictions for this customer
    List<Map<String, dynamic>> predictions = [];
    try {
      final predRes = await supabase
          .from('maintenance_predictions')
          .select('*, home_equipment(name, manufacturer)')
          .eq('customer_id', widget.customerId)
          .isFilter('deleted_at', null)
          .neq('outreach_status', 'completed')
          .order('predicted_date')
          .limit(5);
      predictions = List<Map<String, dynamic>>.from(predRes as List);
    } catch (_) {
      // Predictions table may not exist yet — graceful degradation
    }

    setState(() {
      _customer = customer;
      _jobs = customerJobs;
      _invoices = customerInvoices;
      _predictions = predictions;
      _isLoading = false;
    });
  }

  double get _totalRevenue => _invoices.where((i) => i.isPaid).fold(0, (sum, i) => sum + i.total);
  double get _outstanding => _invoices.where((i) => !i.isPaid && i.status != InvoiceStatus.voided).fold(0, (sum, i) => sum + i.total);

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    if (_isLoading) return Scaffold(backgroundColor: colors.bgBase, body: Center(child: CircularProgressIndicator(color: colors.accentPrimary)));
    if (_customer == null) return Scaffold(backgroundColor: colors.bgBase, appBar: AppBar(backgroundColor: colors.bgBase), body: Center(child: Text('Customer not found', style: TextStyle(color: colors.textSecondary))));

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(colors),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeader(colors),
                const SizedBox(height: 20),
                _buildContactCard(colors),
                const SizedBox(height: 16),
                _buildStatsCard(colors),
                const SizedBox(height: 24),
                _buildSectionHeader(colors, 'JOBS', _jobs.length),
                const SizedBox(height: 12),
                if (_jobs.isEmpty) _buildEmptySection(colors, 'No jobs yet', LucideIcons.briefcase)
                else ..._jobs.take(3).map((j) => _buildJobItem(colors, j)),
                if (_jobs.length > 3) _buildSeeAllButton(colors, 'See all ${_jobs.length} jobs', () {}),
                const SizedBox(height: 24),
                _buildSectionHeader(colors, 'INVOICES', _invoices.length),
                const SizedBox(height: 12),
                if (_invoices.isEmpty) _buildEmptySection(colors, 'No invoices yet', LucideIcons.fileText)
                else ..._invoices.take(3).map((i) => _buildInvoiceItem(colors, i)),
                if (_invoices.length > 3) _buildSeeAllButton(colors, 'See all ${_invoices.length} invoices', () {}),
                if (_predictions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader(colors, 'MAINTENANCE OPPORTUNITIES', _predictions.length),
                  const SizedBox(height: 12),
                  ..._predictions.map((p) => _buildPredictionItem(colors, p)),
                ],
                const SizedBox(height: 24),
                _buildNewJobButton(colors),
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
      leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
      actions: [
        IconButton(icon: Icon(LucideIcons.pencil, color: colors.textSecondary), onPressed: _editCustomer),
        IconButton(icon: Icon(LucideIcons.moreVertical, color: colors.textSecondary), onPressed: () => _showOptions(colors)),
      ],
    );
  }

  Widget _buildHeader(ZaftoColors colors) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colors.accentPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              _customer!.name.isNotEmpty ? _customer!.name[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: colors.accentPrimary),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_customer!.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              if (_customer!.companyName != null) Text(_customer!.companyName!, style: TextStyle(fontSize: 15, color: colors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(ZaftoColors colors) {
    final hasContact = _customer!.phone != null || _customer!.email != null || _customer!.address != null;
    if (!hasContact) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        children: [
          if (_customer!.phone != null) _buildContactRow(colors, LucideIcons.phone, _customer!.phone!, () => HapticFeedback.lightImpact()),
          if (_customer!.email != null) ...[
            if (_customer!.phone != null) Divider(height: 20, color: colors.borderSubtle),
            _buildContactRow(colors, LucideIcons.mail, _customer!.email!, () => HapticFeedback.lightImpact()),
          ],
          if (_customer!.address != null) ...[
            if (_customer!.phone != null || _customer!.email != null) Divider(height: 20, color: colors.borderSubtle),
            _buildContactRow(colors, LucideIcons.mapPin, _customer!.address!, () => HapticFeedback.lightImpact()),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(ZaftoColors colors, IconData icon, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textTertiary),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: TextStyle(fontSize: 14, color: colors.textPrimary))),
          Icon(LucideIcons.externalLink, size: 16, color: colors.textQuaternary),
        ],
      ),
    );
  }

  Widget _buildStatsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.borderSubtle)),
      child: Row(
        children: [
          Expanded(child: _buildStatItem(colors, '\$${_formatAmount(_totalRevenue)}', 'Total Revenue', colors.accentSuccess)),
          Container(width: 1, height: 40, color: colors.borderSubtle),
          Expanded(child: _buildStatItem(colors, '\$${_formatAmount(_outstanding)}', 'Outstanding', _outstanding > 0 ? Colors.orange : colors.textTertiary)),
          Container(width: 1, height: 40, color: colors.borderSubtle),
          Expanded(child: _buildStatItem(colors, '${_jobs.length}', 'Jobs', colors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildStatItem(ZaftoColors colors, String value, String label, Color valueColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: valueColor)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: colors.textTertiary)),
      ],
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title, int count) {
    return Row(
      children: [
        Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textTertiary, letterSpacing: 0.5)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: colors.fillDefault, borderRadius: BorderRadius.circular(4)),
          child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textTertiary)),
        ),
      ],
    );
  }

  Widget _buildEmptySection(ZaftoColors colors, String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: colors.textQuaternary),
          const SizedBox(width: 8),
          Text(message, style: TextStyle(fontSize: 14, color: colors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildJobItem(ZaftoColors colors, Job job) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.borderSubtle)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.displayTitle, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary)),
                  Text(job.statusLabel, style: TextStyle(fontSize: 12, color: colors.textTertiary)),
                ],
              ),
            ),
            Text('\$${job.estimatedAmount.toStringAsFixed(0)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight, size: 16, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceItem(ZaftoColors colors, Invoice invoice) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.borderSubtle)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(invoice.invoiceNumber, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textPrimary)),
                  Text(invoice.statusLabel, style: TextStyle(fontSize: 12, color: invoice.isPaid ? colors.accentSuccess : (invoice.isOverdue ? Colors.red : colors.textTertiary))),
                ],
              ),
            ),
            Text('\$${invoice.total.toStringAsFixed(0)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight, size: 16, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }

  Widget _buildSeeAllButton(ZaftoColors colors, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.accentInfo)),
      ),
    );
  }

  Widget _buildNewJobButton(ZaftoColors colors) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobCreateScreen())),
        icon: Icon(LucideIcons.plus, size: 18, color: colors.accentPrimary),
        label: Text('Create New Job', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.accentPrimary)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.accentPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showOptions(ZaftoColors colors) {
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
              ListTile(leading: Icon(LucideIcons.phone, color: colors.textSecondary), title: Text('Call Customer', style: TextStyle(color: colors.textPrimary)), onTap: () => Navigator.pop(context)),
              ListTile(leading: Icon(LucideIcons.mail, color: colors.textSecondary), title: Text('Send Email', style: TextStyle(color: colors.textPrimary)), onTap: () => Navigator.pop(context)),
              ListTile(leading: const Icon(LucideIcons.trash2, color: Colors.red), title: const Text('Delete Customer', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(context); _deleteCustomer(); }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editCustomer() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(builder: (context) => CustomerCreateScreen(editCustomer: _customer)),
    );
    if (result != null) {
      setState(() => _customer = result);
    }
  }

  Future<void> _deleteCustomer() async {
    await ref.read(customersProvider.notifier).deleteCustomer(widget.customerId);
    if (mounted) Navigator.pop(context);
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}k';
    return amount.toStringAsFixed(0);
  }

  Widget _buildPredictionItem(ZaftoColors colors, Map<String, dynamic> prediction) {
    final type = prediction['prediction_type'] as String? ?? 'maintenance_due';
    final action = prediction['recommended_action'] as String? ?? '';
    final dateStr = prediction['predicted_date'] as String?;
    final equipment = prediction['home_equipment'] as Map<String, dynamic>?;
    final eqName = equipment?['name'] as String? ?? 'Equipment';
    final confidence = (prediction['confidence_score'] as num?)?.toDouble() ?? 0.5;

    final daysUntil = dateStr != null
        ? DateTime.parse(dateStr).difference(DateTime.now()).inDays
        : 0;

    final icon = switch (type) {
      'end_of_life' => LucideIcons.alertTriangle,
      'seasonal_check' => LucideIcons.thermometer,
      'filter_replacement' => LucideIcons.shield,
      'inspection_recommended' => LucideIcons.checkCircle,
      _ => LucideIcons.wrench,
    };

    final urgencyColor = daysUntil < 0
        ? Colors.red
        : daysUntil <= 14
            ? Colors.amber
            : colors.textTertiary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.accentPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(action,
                      style: TextStyle(fontSize: 13, color: colors.textPrimary, fontWeight: FontWeight.w500),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('$eqName  •  ${(confidence * 100).round()}% confidence',
                      style: TextStyle(fontSize: 11, color: colors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              daysUntil < 0 ? '${daysUntil.abs()}d ago' : daysUntil == 0 ? 'Today' : '${daysUntil}d',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: urgencyColor),
            ),
          ],
        ),
      ),
    );
  }
}
