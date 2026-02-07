'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Bank Reconciliation hook
// Manages reconciliation workflow: start → match transactions → complete
// ============================================================

export interface ReconciliationData {
  id: string;
  bankAccountId: string;
  statementDate: string;
  statementBalance: number;
  calculatedBalance: number | null;
  difference: number | null;
  status: 'in_progress' | 'completed' | 'voided';
  completedAt: string | null;
  completedByUserId: string | null;
  notes: string | null;
  createdAt: string;
}

export interface ReconciliationTransaction {
  id: string;
  transactionDate: string;
  description: string;
  amount: number;
  isIncome: boolean;
  isReconciled: boolean;
  reconciliationId: string | null;
}

function mapReconciliationFromDb(row: Record<string, unknown>): ReconciliationData {
  return {
    id: row.id as string,
    bankAccountId: row.bank_account_id as string,
    statementDate: row.statement_date as string,
    statementBalance: Number(row.statement_balance) || 0,
    calculatedBalance: row.calculated_balance != null ? Number(row.calculated_balance) : null,
    difference: row.difference != null ? Number(row.difference) : null,
    status: row.status as 'in_progress' | 'completed' | 'voided',
    completedAt: row.completed_at as string | null,
    completedByUserId: row.completed_by_user_id as string | null,
    notes: row.notes as string | null,
    createdAt: row.created_at as string,
  };
}

function mapTransactionFromDb(row: Record<string, unknown>): ReconciliationTransaction {
  return {
    id: row.id as string,
    transactionDate: row.transaction_date as string,
    description: row.description as string,
    amount: Number(row.amount) || 0,
    isIncome: row.is_income as boolean,
    isReconciled: row.is_reconciled as boolean,
    reconciliationId: row.reconciliation_id as string | null,
  };
}

export function useReconciliation() {
  const [reconciliations, setReconciliations] = useState<ReconciliationData[]>([]);
  const [loading, setLoading] = useState(true);

  const supabase = getSupabase();

  const fetchReconciliations = useCallback(async (bankAccountId?: string) => {
    let query = supabase
      .from('bank_reconciliations')
      .select('*')
      .order('statement_date', { ascending: false })
      .limit(50);

    if (bankAccountId) {
      query = query.eq('bank_account_id', bankAccountId);
    }

    const { data, error } = await query;
    if (!error && data) {
      setReconciliations(data.map((row: Record<string, unknown>) => mapReconciliationFromDb(row)));
    }
    setLoading(false);
  }, [supabase]);

  useEffect(() => {
    fetchReconciliations();
  }, [fetchReconciliations]);

  // Start a new reconciliation
  const startReconciliation = useCallback(async (
    bankAccountId: string,
    statementDate: string,
    statementBalance: number,
  ): Promise<ReconciliationData | null> => {
    const { data, error } = await supabase
      .from('bank_reconciliations')
      .insert({
        bank_account_id: bankAccountId,
        statement_date: statementDate,
        statement_balance: statementBalance,
        status: 'in_progress',
      })
      .select('*')
      .single();

    if (error || !data) {
      console.error('Failed to start reconciliation:', error);
      return null;
    }

    const mapped = mapReconciliationFromDb(data as Record<string, unknown>);
    setReconciliations(prev => [mapped, ...prev]);
    return mapped;
  }, [supabase]);

  // Fetch unreconciled transactions for a bank account
  const fetchUnreconciledTransactions = useCallback(async (
    bankAccountId: string,
  ): Promise<ReconciliationTransaction[]> => {
    const { data, error } = await supabase
      .from('bank_transactions')
      .select('id, transaction_date, description, amount, is_income, is_reconciled, reconciliation_id')
      .eq('bank_account_id', bankAccountId)
      .eq('is_reconciled', false)
      .order('transaction_date', { ascending: true });

    if (error || !data) return [];
    return data.map((row: Record<string, unknown>) => mapTransactionFromDb(row));
  }, [supabase]);

  // Fetch transactions already matched to a reconciliation (for resume)
  const fetchMatchedTransactions = useCallback(async (
    reconciliationId: string,
  ): Promise<ReconciliationTransaction[]> => {
    const { data, error } = await supabase
      .from('bank_transactions')
      .select('id, transaction_date, description, amount, is_income, is_reconciled, reconciliation_id')
      .eq('reconciliation_id', reconciliationId)
      .order('transaction_date', { ascending: true });

    if (error || !data) return [];
    return data.map((row: Record<string, unknown>) => mapTransactionFromDb(row));
  }, [supabase]);

  // Complete a reconciliation (difference must be 0)
  const completeReconciliation = useCallback(async (
    reconciliationId: string,
    checkedTransactionIds: string[],
    calculatedBalance: number,
    statementBalance: number,
  ): Promise<boolean> => {
    const difference = Math.round((statementBalance - calculatedBalance) * 100) / 100;
    if (Math.abs(difference) > 0.005) {
      console.error('Cannot complete: difference is not zero:', difference);
      return false;
    }

    const { data: { user } } = await supabase.auth.getUser();

    // Mark transactions as reconciled
    const { error: txnErr } = await supabase
      .from('bank_transactions')
      .update({
        is_reconciled: true,
        reconciliation_id: reconciliationId,
      })
      .in('id', checkedTransactionIds);

    if (txnErr) {
      console.error('Failed to mark transactions reconciled:', txnErr);
      return false;
    }

    // Complete the reconciliation record
    const { error: recErr } = await supabase
      .from('bank_reconciliations')
      .update({
        calculated_balance: calculatedBalance,
        difference: 0,
        status: 'completed',
        completed_at: new Date().toISOString(),
        completed_by_user_id: user?.id || null,
      })
      .eq('id', reconciliationId);

    if (recErr) {
      console.error('Failed to complete reconciliation:', recErr);
      return false;
    }

    await fetchReconciliations();
    return true;
  }, [supabase, fetchReconciliations]);

  // Save progress (finish later)
  const saveProgress = useCallback(async (
    reconciliationId: string,
    checkedTransactionIds: string[],
    calculatedBalance: number,
    statementBalance: number,
    notes?: string,
  ): Promise<boolean> => {
    const difference = Math.round((statementBalance - calculatedBalance) * 100) / 100;

    // Tag checked transactions with this reconciliation ID (but don't mark reconciled)
    const { error: txnErr } = await supabase
      .from('bank_transactions')
      .update({ reconciliation_id: reconciliationId })
      .in('id', checkedTransactionIds);

    if (txnErr) {
      console.error('Failed to tag transactions:', txnErr);
      return false;
    }

    // Update reconciliation
    const { error: recErr } = await supabase
      .from('bank_reconciliations')
      .update({
        calculated_balance: calculatedBalance,
        difference,
        notes: notes || null,
      })
      .eq('id', reconciliationId);

    if (recErr) {
      console.error('Failed to save progress:', recErr);
      return false;
    }

    await fetchReconciliations();
    return true;
  }, [supabase, fetchReconciliations]);

  // Void a completed reconciliation
  const voidReconciliation = useCallback(async (
    reconciliationId: string,
  ): Promise<boolean> => {
    // Un-reconcile all transactions linked to this reconciliation
    const { error: txnErr } = await supabase
      .from('bank_transactions')
      .update({
        is_reconciled: false,
        reconciliation_id: null,
      })
      .eq('reconciliation_id', reconciliationId);

    if (txnErr) {
      console.error('Failed to un-reconcile transactions:', txnErr);
      return false;
    }

    // Void the reconciliation
    const { error: recErr } = await supabase
      .from('bank_reconciliations')
      .update({ status: 'voided' })
      .eq('id', reconciliationId);

    if (recErr) {
      console.error('Failed to void reconciliation:', recErr);
      return false;
    }

    await fetchReconciliations();
    return true;
  }, [supabase, fetchReconciliations]);

  return {
    reconciliations,
    loading,
    startReconciliation,
    fetchUnreconciledTransactions,
    fetchMatchedTransactions,
    completeReconciliation,
    saveProgress,
    voidReconciliation,
    fetchReconciliations,
  };
}
