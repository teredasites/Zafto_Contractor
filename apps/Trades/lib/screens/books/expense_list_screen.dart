import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/theme_provider.dart';
import 'expense_entry_screen.dart';

// Expense list screen for mobile.
// Techs see own expenses; owner/admin see all.

class _Expense {
  final String id;
  final String expenseDate;
  final String description;
  final double total;
  final String category;
  final String paymentMethod;
  final String status;
  final String? vendorName;
  final String? receiptUrl;

  const _Expense({
    required this.id,
    required this.expenseDate,
    required this.description,
    required this.total,
    required this.category,
    required this.paymentMethod,
    required this.status,
    this.vendorName,
    this.receiptUrl,
  });
}

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

final _expensesProvider =
    FutureProvider.autoDispose<List<_Expense>>((ref) async {
  final data = await Supabase.instance.client
      .from('expense_records')
      .select('id, expense_date, description, total, category, payment_method, status, receipt_url, vendors(vendor_name)')
      .isFilter('deleted_at', null)
      .order('expense_date', ascending: false)
      .limit(100);

  return (data as List).map((row) {
    final vendor = row['vendors'] as Map<String, dynamic>?;
    return _Expense(
      id: row['id'] as String,
      expenseDate: row['expense_date'] as String,
      description: row['description'] as String,
      total: (row['total'] as num).toDouble(),
      category: row['category'] as String,
      paymentMethod: row['payment_method'] as String,
      status: row['status'] as String,
      vendorName: vendor?['vendor_name'] as String?,
      receiptUrl: row['receipt_url'] as String?,
    );
  }).toList();
});

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  String _filter = 'all';

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

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final expensesAsync = ref.watch(_expensesProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Expenses',
            style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.accentPrimary,
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ExpenseEntryScreen()),
          );
          if (result == true) {
            ref.invalidate(_expensesProvider);
          }
        },
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Failed to load expenses',
              style: TextStyle(color: colors.textSecondary)),
        ),
        data: (expenses) {
          // Filter
          final filtered = _filter == 'all'
              ? expenses
              : expenses.where((e) => e.status == _filter).toList();

          // Summary
          final totalAmount = expenses
              .where((e) => e.status != 'voided')
              .fold<double>(0, (s, e) => s + e.total);

          return Column(
            children: [
              // Summary card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Expenses',
                            style: TextStyle(
                                color: colors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(_formatCurrency(totalAmount),
                            style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Text('${expenses.length} records',
                        style: TextStyle(
                            color: colors.textTertiary, fontSize: 13)),
                  ],
                ),
              ),

              // Status filter
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final f in [
                      ('all', 'All'),
                      ('draft', 'Draft'),
                      ('approved', 'Approved'),
                      ('posted', 'Posted'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _filter = f.$1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _filter == f.$1
                                  ? colors.accentPrimary
                                  : colors.bgInset,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(f.$2,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _filter == f.$1
                                        ? Colors.white
                                        : colors.textSecondary)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Expense list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text('No expenses',
                            style: TextStyle(color: colors.textTertiary)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final expense = filtered[index];
                          final icon = _categoryIcons[expense.category] ??
                              LucideIcons.dollarSign;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colors.bgElevated,
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: colors.borderSubtle),
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
                                      size: 18,
                                      color: colors.textSecondary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(expense.description,
                                          style: TextStyle(
                                              color: colors.textPrimary,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Text(expense.expenseDate,
                                              style: TextStyle(
                                                  color:
                                                      colors.textTertiary,
                                                  fontSize: 12)),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _statusColor(
                                                      expense.status)
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                                expense.status
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                    color: _statusColor(
                                                        expense.status),
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                          ),
                                          if (expense.receiptUrl !=
                                              null) ...[
                                            const SizedBox(width: 6),
                                            Icon(LucideIcons.receipt,
                                                size: 12,
                                                color:
                                                    colors.textTertiary),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatCurrency(expense.total),
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
