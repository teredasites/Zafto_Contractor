// ZAFTO ZBooks Service — Read-only GL queries for mobile
// Mobile views journal entries and account balances but does not create entries.
// Auto-posting happens via Web CRM hooks (use-zbooks-engine.ts).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Models ---

class JournalEntryLine {
  final String id;
  final String accountId;
  final String accountNumber;
  final String accountName;
  final double debitAmount;
  final double creditAmount;
  final String? description;
  final String? jobId;

  const JournalEntryLine({
    required this.id,
    required this.accountId,
    required this.accountNumber,
    required this.accountName,
    required this.debitAmount,
    required this.creditAmount,
    this.description,
    this.jobId,
  });

  factory JournalEntryLine.fromJson(Map<String, dynamic> json) {
    final acct = json['chart_of_accounts'] as Map<String, dynamic>?;
    return JournalEntryLine(
      id: json['id'] as String,
      accountId: json['account_id'] as String,
      accountNumber: acct?['account_number'] as String? ?? '',
      accountName: acct?['account_name'] as String? ?? '',
      debitAmount: (json['debit_amount'] as num?)?.toDouble() ?? 0,
      creditAmount: (json['credit_amount'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String?,
      jobId: json['job_id'] as String?,
    );
  }
}

class JournalEntry {
  final String id;
  final String entryNumber;
  final String entryDate;
  final String description;
  final String status;
  final String? sourceType;
  final String? sourceId;
  final String? memo;
  final String createdAt;
  final List<JournalEntryLine> lines;

  const JournalEntry({
    required this.id,
    required this.entryNumber,
    required this.entryDate,
    required this.description,
    required this.status,
    this.sourceType,
    this.sourceId,
    this.memo,
    required this.createdAt,
    required this.lines,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    final rawLines = json['journal_entry_lines'] as List<dynamic>? ?? [];
    return JournalEntry(
      id: json['id'] as String,
      entryNumber: json['entry_number'] as String,
      entryDate: json['entry_date'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      sourceType: json['source_type'] as String?,
      sourceId: json['source_id'] as String?,
      memo: json['memo'] as String?,
      createdAt: json['created_at'] as String,
      lines: rawLines
          .map((l) => JournalEntryLine.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }

  double get totalDebits =>
      lines.fold<double>(0, (sum, l) => sum + l.debitAmount);
  double get totalCredits =>
      lines.fold<double>(0, (sum, l) => sum + l.creditAmount);
}

class AccountBalance {
  final String id;
  final String accountNumber;
  final String accountName;
  final String accountType;
  final String normalBalance;
  final double balance;

  const AccountBalance({
    required this.id,
    required this.accountNumber,
    required this.accountName,
    required this.accountType,
    required this.normalBalance,
    required this.balance,
  });
}

class FinancialSummary {
  final double totalRevenue;
  final double totalExpenses;
  final double netIncome;
  final double cashPosition;
  final double accountsReceivable;
  final double accountsPayable;

  const FinancialSummary({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netIncome,
    required this.cashPosition,
    required this.accountsReceivable,
    required this.accountsPayable,
  });
}

// --- Repository ---

class ZBooksRepository {
  final _supabase = Supabase.instance.client;

  Future<List<JournalEntry>> getRecentEntries({int limit = 50}) async {
    final data = await _supabase
        .from('journal_entries')
        .select(
            '*, journal_entry_lines(*, chart_of_accounts(account_number, account_name))')
        .eq('status', 'posted')
        .order('entry_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((row) => JournalEntry.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<FinancialSummary> getFinancialSummary() async {
    // Fetch all posted journal entry lines with account info
    final data = await _supabase
        .from('journal_entry_lines')
        .select(
            'debit_amount, credit_amount, chart_of_accounts!inner(account_type, account_number)')
        .eq('journal_entries.status', 'posted');

    double totalRevenue = 0;
    double totalCogs = 0;
    double totalExpenses = 0;
    double cashPosition = 0;
    double accountsReceivable = 0;
    double accountsPayable = 0;

    for (final row in (data as List)) {
      final acct = row['chart_of_accounts'] as Map<String, dynamic>?;
      if (acct == null) continue;
      final type = acct['account_type'] as String;
      final debit = (row['debit_amount'] as num?)?.toDouble() ?? 0;
      final credit = (row['credit_amount'] as num?)?.toDouble() ?? 0;
      final number = acct['account_number'] as String? ?? '';

      switch (type) {
        case 'revenue':
          totalRevenue += credit - debit;
          break;
        case 'cogs':
          totalCogs += debit - credit;
          break;
        case 'expense':
          totalExpenses += debit - credit;
          break;
        case 'asset':
          if (number == '1100') {
            accountsReceivable += debit - credit;
          } else if (number.startsWith('10')) {
            cashPosition += debit - credit;
          }
          break;
        case 'liability':
          if (number == '2000') {
            accountsPayable += credit - debit;
          }
          break;
      }
    }

    return FinancialSummary(
      totalRevenue: totalRevenue,
      totalExpenses: totalCogs + totalExpenses,
      netIncome: totalRevenue - totalCogs - totalExpenses,
      cashPosition: cashPosition,
      accountsReceivable: accountsReceivable,
      accountsPayable: accountsPayable,
    );
  }
}

// --- Providers ---

final zbooksRepositoryProvider = Provider<ZBooksRepository>((ref) {
  return ZBooksRepository();
});

// Recent journal entries (read-only)
final recentJournalEntriesProvider =
    FutureProvider.autoDispose<List<JournalEntry>>((ref) async {
  final repo = ref.watch(zbooksRepositoryProvider);
  return repo.getRecentEntries();
});

// Financial summary (read-only)
final financialSummaryProvider =
    FutureProvider.autoDispose<FinancialSummary>((ref) async {
  final repo = ref.watch(zbooksRepositoryProvider);
  return repo.getFinancialSummary();
});
