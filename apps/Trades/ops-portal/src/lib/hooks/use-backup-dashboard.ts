'use client';

// DEPTH41 — Backup Fortress: Ops Dashboard Hook
// Shows backup status, verification results, storage metrics, alerts.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ── Types ──

export interface BackupJob {
  id: string;
  backupType: string;
  schedule: string;
  status: string;
  startedAt: string | null;
  completedAt: string | null;
  failedAt: string | null;
  errorMessage: string | null;
  storageProvider: string;
  storageBucket: string | null;
  storageKey: string | null;
  fileSizeBytes: number | null;
  compressedSizeBytes: number | null;
  encryptionAlgorithm: string | null;
  checksumSha256: string | null;
  immutableUntil: string | null;
  retentionDays: number;
  isImmutable: boolean;
  tableCount: number | null;
  rowCountSnapshot: Record<string, number> | null;
  databaseSizeBytes: number | null;
  createdAt: string;
}

export interface BackupVerification {
  id: string;
  backupJobId: string;
  status: string;
  startedAt: string | null;
  completedAt: string | null;
  tableCountsMatch: boolean | null;
  tableCountExpected: number | null;
  tableCountActual: number | null;
  rowCountMismatches: Array<{ table: string; expected: number; actual: number }>;
  dataIntegrityCheck: boolean | null;
  restoreTimeSeconds: number | null;
  errorDetails: string | null;
  overallHealth: string;
  notes: string | null;
  createdAt: string;
}

export interface BackupStorageMetric {
  id: string;
  metricDate: string;
  storageProvider: string;
  totalSizeBytes: number;
  backupCount: number;
  oldestBackupAt: string | null;
  newestBackupAt: string | null;
  estimatedCostCents: number;
}

export interface BackupAlert {
  id: string;
  alertType: string;
  severity: string;
  backupJobId: string | null;
  message: string;
  details: Record<string, unknown>;
  acknowledgedAt: string | null;
  acknowledgedBy: string | null;
  resolvedAt: string | null;
  resolutionNotes: string | null;
  createdAt: string;
}

export interface DisasterRecoveryRunbook {
  id: string;
  scenario: string;
  severity: string;
  title: string;
  description: string | null;
  steps: Array<{
    order: number;
    title: string;
    instructions: string;
    estimated_minutes: number;
    requires_admin: boolean;
  }>;
  estimatedRecoveryTimeMinutes: number | null;
  maxDataLossMinutes: number | null;
  lastTestedAt: string | null;
  lastTestResult: string | null;
}

// ── Hook: useBackupDashboard ──

export function useBackupDashboard() {
  const [jobs, setJobs] = useState<BackupJob[]>([]);
  const [verifications, setVerifications] = useState<BackupVerification[]>([]);
  const [metrics, setMetrics] = useState<BackupStorageMetric[]>([]);
  const [alerts, setAlerts] = useState<BackupAlert[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      // Fetch recent backup jobs
      const { data: jobsData, error: jobsErr } = await supabase
        .from('backup_jobs')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(50);
      if (jobsErr) throw jobsErr;

      // Fetch recent verifications
      const { data: verData, error: verErr } = await supabase
        .from('backup_verifications')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(20);
      if (verErr) throw verErr;

      // Fetch last 30 days of metrics
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      const { data: metricData, error: metErr } = await supabase
        .from('backup_storage_metrics')
        .select('*')
        .gte('metric_date', thirtyDaysAgo.toISOString().split('T')[0])
        .order('metric_date', { ascending: false });
      if (metErr) throw metErr;

      // Fetch unresolved alerts
      const { data: alertData, error: alertErr } = await supabase
        .from('backup_alerts')
        .select('*')
        .is('resolved_at', null)
        .order('created_at', { ascending: false })
        .limit(20);
      if (alertErr) throw alertErr;

      setJobs((jobsData || []).map((r: Record<string, unknown>) => ({
        id: r.id as string,
        backupType: r.backup_type as string,
        schedule: r.schedule as string,
        status: r.status as string,
        startedAt: r.started_at as string | null,
        completedAt: r.completed_at as string | null,
        failedAt: r.failed_at as string | null,
        errorMessage: r.error_message as string | null,
        storageProvider: r.storage_provider as string,
        storageBucket: r.storage_bucket as string | null,
        storageKey: r.storage_key as string | null,
        fileSizeBytes: r.file_size_bytes as number | null,
        compressedSizeBytes: r.compressed_size_bytes as number | null,
        encryptionAlgorithm: r.encryption_algorithm as string | null,
        checksumSha256: r.checksum_sha256 as string | null,
        immutableUntil: r.immutable_until as string | null,
        retentionDays: (r.retention_days as number) || 90,
        isImmutable: (r.is_immutable as boolean) || true,
        tableCount: r.table_count as number | null,
        rowCountSnapshot: r.row_count_snapshot as Record<string, number> | null,
        databaseSizeBytes: r.database_size_bytes as number | null,
        createdAt: r.created_at as string,
      })));

      setVerifications((verData || []).map((r: Record<string, unknown>) => ({
        id: r.id as string,
        backupJobId: r.backup_job_id as string,
        status: r.status as string,
        startedAt: r.started_at as string | null,
        completedAt: r.completed_at as string | null,
        tableCountsMatch: r.table_counts_match as boolean | null,
        tableCountExpected: r.table_count_expected as number | null,
        tableCountActual: r.table_count_actual as number | null,
        rowCountMismatches: (r.row_count_mismatches as Array<{ table: string; expected: number; actual: number }>) || [],
        dataIntegrityCheck: r.data_integrity_check as boolean | null,
        restoreTimeSeconds: r.restore_time_seconds as number | null,
        errorDetails: r.error_details as string | null,
        overallHealth: (r.overall_health as string) || 'unknown',
        notes: r.notes as string | null,
        createdAt: r.created_at as string,
      })));

      setMetrics((metricData || []).map((r: Record<string, unknown>) => ({
        id: r.id as string,
        metricDate: r.metric_date as string,
        storageProvider: r.storage_provider as string,
        totalSizeBytes: (r.total_size_bytes as number) || 0,
        backupCount: (r.backup_count as number) || 0,
        oldestBackupAt: r.oldest_backup_at as string | null,
        newestBackupAt: r.newest_backup_at as string | null,
        estimatedCostCents: (r.estimated_cost_cents as number) || 0,
      })));

      setAlerts((alertData || []).map((r: Record<string, unknown>) => ({
        id: r.id as string,
        alertType: r.alert_type as string,
        severity: r.severity as string,
        backupJobId: r.backup_job_id as string | null,
        message: r.message as string,
        details: (r.details as Record<string, unknown>) || {},
        acknowledgedAt: r.acknowledged_at as string | null,
        acknowledgedBy: r.acknowledged_by as string | null,
        resolvedAt: r.resolved_at as string | null,
        resolutionNotes: r.resolution_notes as string | null,
        createdAt: r.created_at as string,
      })));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load backup data');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetch(); }, [fetch]);

  // Mutations
  const acknowledgeAlert = useCallback(async (alertId: string) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    const { error: err } = await supabase
      .from('backup_alerts')
      .update({
        acknowledged_at: new Date().toISOString(),
        acknowledged_by: user?.email || 'unknown',
      })
      .eq('id', alertId);
    if (err) throw err;
    await fetch();
  }, [fetch]);

  const resolveAlert = useCallback(async (alertId: string, notes: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('backup_alerts')
      .update({
        resolved_at: new Date().toISOString(),
        resolution_notes: notes,
      })
      .eq('id', alertId);
    if (err) throw err;
    await fetch();
  }, [fetch]);

  // Computed stats
  const lastBackup = jobs.find(j => j.status === 'completed');
  const lastVerification = verifications.find(v => v.status === 'passed' || v.status === 'failed');
  const failedJobs = jobs.filter(j => j.status === 'failed');
  const unresolvedAlerts = alerts.filter(a => !a.resolvedAt);

  const overallHealth = (() => {
    if (failedJobs.length > 0 && failedJobs[0].createdAt > (lastBackup?.createdAt || '')) return 'red';
    if (unresolvedAlerts.some(a => a.severity === 'critical')) return 'red';
    if (unresolvedAlerts.length > 0) return 'yellow';
    if (!lastBackup) return 'yellow';
    const hoursSinceLastBackup = (Date.now() - new Date(lastBackup.createdAt).getTime()) / (1000 * 60 * 60);
    if (hoursSinceLastBackup > 48) return 'red';
    if (hoursSinceLastBackup > 25) return 'yellow';
    return 'green';
  })();

  const totalStorageCostCents = metrics.reduce((sum, m) => sum + m.estimatedCostCents, 0);

  return {
    jobs,
    verifications,
    metrics,
    alerts: unresolvedAlerts,
    loading,
    error,
    overallHealth,
    lastBackup,
    lastVerification,
    failedJobCount: failedJobs.length,
    unresolvedAlertCount: unresolvedAlerts.length,
    totalStorageCostCents,
    acknowledgeAlert,
    resolveAlert,
    refresh: fetch,
  };
}

// ── Hook: useDisasterRecoveryRunbook ──

export function useDisasterRecoveryRunbook() {
  const [runbooks, setRunbooks] = useState<DisasterRecoveryRunbook[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: err } = await supabase
        .from('disaster_recovery_runbook')
        .select('*')
        .order('severity');

      if (err) throw err;

      setRunbooks((data || []).map((r: Record<string, unknown>) => ({
        id: r.id as string,
        scenario: r.scenario as string,
        severity: r.severity as string,
        title: r.title as string,
        description: r.description as string | null,
        steps: (r.steps as Array<{
          order: number;
          title: string;
          instructions: string;
          estimated_minutes: number;
          requires_admin: boolean;
        }>) || [],
        estimatedRecoveryTimeMinutes: r.estimated_recovery_time_minutes as number | null,
        maxDataLossMinutes: r.max_data_loss_minutes as number | null,
        lastTestedAt: r.last_tested_at as string | null,
        lastTestResult: r.last_test_result as string | null,
      })));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load runbook');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetch(); }, [fetch]);

  return { runbooks, loading, error, refresh: fetch };
}
