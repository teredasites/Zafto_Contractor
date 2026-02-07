import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

// Read-only Chart of Accounts viewer for mobile.
// Admin CRUD happens in Web CRM only.

class _Account {
  final String id;
  final String accountNumber;
  final String accountName;
  final String accountType;
  final String normalBalance;
  final String? parentAccountId;
  final bool isActive;
  final bool isSystem;

  const _Account({
    required this.id,
    required this.accountNumber,
    required this.accountName,
    required this.accountType,
    required this.normalBalance,
    this.parentAccountId,
    required this.isActive,
    required this.isSystem,
  });

  factory _Account.fromJson(Map<String, dynamic> json) {
    return _Account(
      id: json['id'] as String,
      accountNumber: json['account_number'] as String,
      accountName: json['account_name'] as String,
      accountType: json['account_type'] as String,
      normalBalance: json['normal_balance'] as String,
      parentAccountId: json['parent_account_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isSystem: json['is_system'] as bool? ?? false,
    );
  }
}

// Riverpod provider for COA list
final _coaProvider = FutureProvider.autoDispose<List<_Account>>((ref) async {
  final data = await Supabase.instance.client
      .from('chart_of_accounts')
      .select('id, account_number, account_name, account_type, normal_balance, parent_account_id, is_active, is_system')
      .eq('is_active', true)
      .order('sort_order');

  return (data as List)
      .map((row) => _Account.fromJson(row as Map<String, dynamic>))
      .toList();
});

// Riverpod provider for account balances from GL
final _accountBalancesProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final data = await Supabase.instance.client
      .from('journal_entry_lines')
      .select(
          'account_id, debit_amount, credit_amount, chart_of_accounts!inner(normal_balance)');

  final balances = <String, double>{};
  for (final row in (data as List)) {
    final accountId = row['account_id'] as String;
    final debit = (row['debit_amount'] as num?)?.toDouble() ?? 0;
    final credit = (row['credit_amount'] as num?)?.toDouble() ?? 0;
    final acct = row['chart_of_accounts'] as Map<String, dynamic>?;
    final normalBal = acct?['normal_balance'] as String? ?? 'debit';

    final net = normalBal == 'debit' ? debit - credit : credit - debit;
    balances[accountId] = (balances[accountId] ?? 0) + net;
  }
  return balances;
});

class ChartOfAccountsScreen extends ConsumerStatefulWidget {
  const ChartOfAccountsScreen({super.key});

  @override
  ConsumerState<ChartOfAccountsScreen> createState() =>
      _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState
    extends ConsumerState<ChartOfAccountsScreen> {
  String _filterType = 'all';
  String _search = '';

  static const _typeOrder = [
    'asset',
    'liability',
    'equity',
    'revenue',
    'cogs',
    'expense',
  ];

  static const _typeLabels = {
    'asset': 'Assets',
    'liability': 'Liabilities',
    'equity': 'Equity',
    'revenue': 'Revenue',
    'cogs': 'Cost of Goods Sold',
    'expense': 'Expenses',
  };

  Color _typeColor(String type) {
    switch (type) {
      case 'asset':
        return Colors.blue;
      case 'liability':
        return Colors.orange;
      case 'equity':
        return Colors.purple;
      case 'revenue':
        return Colors.green;
      case 'cogs':
        return Colors.amber.shade700;
      case 'expense':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final coaAsync = ref.watch(_coaProvider);
    final balAsync = ref.watch(_accountBalancesProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Chart of Accounts',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: coaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertCircle, size: 40, color: colors.accentError),
              const SizedBox(height: 12),
              Text('Failed to load accounts',
                  style: TextStyle(color: colors.textSecondary)),
            ],
          ),
        ),
        data: (accounts) {
          final balances = balAsync.valueOrNull ?? {};

          // Filter
          final filtered = accounts.where((a) {
            if (_filterType != 'all' && a.accountType != _filterType) {
              return false;
            }
            if (_search.isNotEmpty) {
              final q = _search.toLowerCase();
              return a.accountNumber.toLowerCase().contains(q) ||
                  a.accountName.toLowerCase().contains(q);
            }
            return true;
          }).toList();

          // Group by type
          final grouped = <String, List<_Account>>{};
          for (final type in _typeOrder) {
            final list = filtered.where((a) => a.accountType == type).toList();
            if (list.isNotEmpty) {
              grouped[type] = list;
            }
          }

          return Column(
            children: [
              // Search bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search accounts...',
                    hintStyle: TextStyle(color: colors.textTertiary),
                    prefixIcon: Icon(LucideIcons.search,
                        size: 18, color: colors.textTertiary),
                    filled: true,
                    fillColor: colors.bgInset,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),

              // Type filter chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filterType == 'all',
                      onTap: () => setState(() => _filterType = 'all'),
                      colors: colors,
                    ),
                    ..._typeOrder.map((type) => _FilterChip(
                          label: _typeLabels[type] ?? type,
                          selected: _filterType == type,
                          onTap: () => setState(() => _filterType = type),
                          colors: colors,
                          color: _typeColor(type),
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Account list
              Expanded(
                child: grouped.isEmpty
                    ? Center(
                        child: Text(
                          'No accounts found',
                          style: TextStyle(color: colors.textTertiary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: grouped.length,
                        itemBuilder: (context, index) {
                          final type = grouped.keys.elementAt(index);
                          final typeAccounts = grouped[type]!;
                          final typeTotal = typeAccounts.fold<double>(
                            0,
                            (sum, a) => sum + (balances[a.id] ?? 0),
                          );

                          return _AccountTypeGroup(
                            type: type,
                            label: _typeLabels[type] ?? type,
                            color: _typeColor(type),
                            accounts: typeAccounts,
                            balances: balances,
                            total: typeTotal,
                            colors: colors,
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ZaftoColors colors;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? (color ?? colors.accentPrimary)
                : colors.bgInset,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountTypeGroup extends StatefulWidget {
  final String type;
  final String label;
  final Color color;
  final List<_Account> accounts;
  final Map<String, double> balances;
  final double total;
  final ZaftoColors colors;

  const _AccountTypeGroup({
    required this.type,
    required this.label,
    required this.color,
    required this.accounts,
    required this.balances,
    required this.total,
    required this.colors,
  });

  @override
  State<_AccountTypeGroup> createState() => _AccountTypeGroupState();
}

class _AccountTypeGroupState extends State<_AccountTypeGroup> {
  bool _expanded = true;

  String _formatCurrency(double amount) {
    final abs = amount.abs();
    final prefix = amount < 0 ? '-' : '';
    return '$prefix\$${abs.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: colors.isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  _expanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                  size: 16,
                  color: widget.color,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: widget.color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${widget.accounts.length})',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textTertiary,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatCurrency(widget.total),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...widget.accounts.map((account) {
            final balance = widget.balances[account.id] ?? 0;
            final isChild = account.parentAccountId != null;

            return Container(
              padding: EdgeInsets.only(
                left: isChild ? 32 : 16,
                right: 16,
                top: 10,
                bottom: 10,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colors.borderSubtle,
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      account.accountNumber,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace',
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            account.accountName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (account.isSystem) ...[
                          const SizedBox(width: 6),
                          Icon(LucideIcons.lock, size: 12,
                              color: colors.textQuaternary),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    _formatCurrency(balance),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: balance >= 0
                          ? colors.textPrimary
                          : colors.accentError,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 12),
      ],
    );
  }
}
