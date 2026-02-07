import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/theme_provider.dart';
import '../../services/zbooks_service.dart';
import 'expense_entry_screen.dart';
import 'expense_list_screen.dart';
import 'chart_of_accounts_screen.dart';
import '../field_tools/receipt_scanner_screen.dart';

// ZBooks Hub — main entry point to ZBooks from the mobile app.
// Shows financial summary, quick actions, and recent expenses.

const _categoryIcons = {
  'materials': LucideIcons.package2,
  'tools': LucideIcons.wrench,
  'fuel': LucideIcons.fuel,
  'equipment': LucideIcons.hardHat,
  'vehicle': LucideIcons.truck,
  'office': LucideIcons.building,
  'permits': LucideIcons.fileCheck,
  'subcontractor': LucideIcons.users,
  'uncategorized': LucideIcons.moreHorizontal,
};

final recentExpensesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('expense_records')
      .select('id, expense_date, description, total, category, status')
      .isFilter('deleted_at', null)
      .order('expense_date', ascending: false)
      .limit(10);
  return List<Map<String, dynamic>>.from(data);
});

class ZBooksHubScreen extends ConsumerStatefulWidget {
  const ZBooksHubScreen({super.key});

  @override
  ConsumerState<ZBooksHubScreen> createState() => _ZBooksHubScreenState();
}

class _ZBooksHubScreenState extends ConsumerState<ZBooksHubScreen> {
  String _formatCurrency(double amount) {
    final prefix = amount < 0 ? '-' : '';
    final abs = amount.abs();
    return '$prefix\$${abs.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'approved':
        return Colors.amber;
      case 'posted':
        return Colors.green;
      case 'voided':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final summaryAsync = ref.watch(financialSummaryProvider);
    final expensesAsync = ref.watch(recentExpensesProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('ZBooks',
            style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Failed to load financial summary',
              style: TextStyle(color: colors.textSecondary)),
        ),
        data: (summary) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Financial Summary Card ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.bgElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Financial Summary',
                          style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryTile(
                              icon: LucideIcons.banknote,
                              label: 'Cash Position',
                              value: _formatCurrency(summary.cashPosition),
                              colors: colors,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryTile(
                              icon: LucideIcons.arrowUpRight,
                              label: 'Accounts Receivable',
                              value: _formatCurrency(summary.accountsReceivable),
                              colors: colors,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryTile(
                              icon: LucideIcons.arrowDownRight,
                              label: 'Accounts Payable',
                              value: _formatCurrency(summary.accountsPayable),
                              colors: colors,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryTile(
                              icon: LucideIcons.trendingUp,
                              label: 'Net Income MTD',
                              value: _formatCurrency(summary.netIncome),
                              colors: colors,
                              valueColor: summary.netIncome >= 0
                                  ? colors.accentSuccess
                                  : colors.accentError,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- Quick Actions ---
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final result = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                                builder: (_) => const ExpenseEntryScreen()),
                          );
                          if (result == true) {
                            ref.invalidate(recentExpensesProvider);
                            ref.invalidate(financialSummaryProvider);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            color: colors.accentPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    colors.accentPrimary.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              Icon(LucideIcons.plusCircle,
                                  size: 24, color: colors.accentPrimary),
                              const SizedBox(height: 8),
                              Text('Record Expense',
                                  style: TextStyle(
                                      color: colors.accentPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const ReceiptScannerScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            color:
                                colors.accentSuccess.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: colors.accentSuccess
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              Icon(LucideIcons.camera,
                                  size: 24, color: colors.accentSuccess),
                              const SizedBox(height: 8),
                              Text('Capture Receipt',
                                  style: TextStyle(
                                      color: colors.accentSuccess,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // --- Recent Expenses ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Expenses',
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ExpenseListScreen()),
                        );
                      },
                      child: Text('See All',
                          style: TextStyle(
                              color: colors.accentPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                expensesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('Failed to load expenses',
                          style: TextStyle(color: colors.textSecondary)),
                    ),
                  ),
                  data: (expenses) {
                    if (expenses.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        width: double.infinity,
                        child: Column(
                          children: [
                            Icon(LucideIcons.receipt,
                                size: 40, color: colors.textTertiary),
                            const SizedBox(height: 12),
                            Text('No expenses yet',
                                style: TextStyle(
                                    color: colors.textTertiary,
                                    fontSize: 14)),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: expenses.map((expense) {
                        final category =
                            (expense['category'] as String?) ?? 'uncategorized';
                        final icon = _categoryIcons[category] ??
                            LucideIcons.dollarSign;
                        final description =
                            (expense['description'] as String?) ?? '';
                        final expenseDate =
                            (expense['expense_date'] as String?) ?? '';
                        final total =
                            (expense['total'] as num?)?.toDouble() ?? 0;
                        final status =
                            (expense['status'] as String?) ?? 'draft';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.bgElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colors.bgInset,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(icon,
                                    size: 18, color: colors.textSecondary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(description,
                                        style: TextStyle(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text(expenseDate,
                                            style: TextStyle(
                                                color: colors.textTertiary,
                                                fontSize: 12)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _statusColor(status)
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(status.toUpperCase(),
                                              style: TextStyle(
                                                  color: _statusColor(status),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatCurrency(total),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // --- Bottom Links ---
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ChartOfAccountsScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: colors.bgElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.bookOpen,
                            size: 18, color: colors.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Chart of Accounts',
                              style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14)),
                        ),
                        Icon(LucideIcons.chevronRight,
                            size: 18, color: colors.textTertiary),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- Summary Tile Widget ---

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final dynamic colors;
  final Color? valueColor;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: colors.textTertiary),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
