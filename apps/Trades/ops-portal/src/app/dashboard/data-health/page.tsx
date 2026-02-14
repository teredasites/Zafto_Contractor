'use client';

import { useState, useEffect } from 'react';
import {
  AlertTriangle,
  CheckCircle2,
  Database,
  RefreshCw,
  Building2,
  Users,
  Briefcase,
  FileText,
  Camera,
  Clock,
  Receipt,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { getSupabase } from '@/lib/supabase';

interface IntegrityCheck {
  check_name: string;
  entity_table: string;
  orphan_count: number;
  details: string;
}

const CHECK_ICONS: Record<string, React.ReactNode> = {
  photos_no_job: <Camera className="h-4 w-4" />,
  time_entries_no_job: <Clock className="h-4 w-4" />,
  expenses_no_job: <Receipt className="h-4 w-4" />,
  invoices_no_customer: <FileText className="h-4 w-4" />,
  jobs_no_customer: <Briefcase className="h-4 w-4" />,
  bids_no_customer: <FileText className="h-4 w-4" />,
  users_no_company: <Users className="h-4 w-4" />,
  companies_no_owner: <Building2 className="h-4 w-4" />,
};

export default function DataHealthPage() {
  const [checks, setChecks] = useState<IntegrityCheck[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastRun, setLastRun] = useState<string | null>(null);

  const runChecks = async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase.rpc('check_data_integrity');
      if (err) throw err;
      setChecks((data || []) as IntegrityCheck[]);
      setLastRun(new Date().toISOString());
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to run integrity checks');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    runChecks();
  }, []);

  const totalIssues = checks.reduce((sum, c) => sum + c.orphan_count, 0);
  const issueChecks = checks.filter((c) => c.orphan_count > 0);
  const cleanChecks = checks.filter((c) => c.orphan_count === 0);

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">Data Health</h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">
            Monitor data integrity across all companies
          </p>
        </div>
        <Button onClick={runChecks} loading={loading}>
          <RefreshCw className="h-4 w-4 mr-1.5" />
          Run Checks
        </Button>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card>
          <div className="flex items-center gap-3">
            <div className={`p-2 rounded-lg ${totalIssues > 0 ? 'bg-amber-500/10 text-amber-500' : 'bg-emerald-500/10 text-emerald-500'}`}>
              <Database className="h-5 w-5" />
            </div>
            <div>
              <p className="text-xs text-[var(--text-secondary)]">Total Issues</p>
              <p className="text-xl font-bold text-[var(--text-primary)]">{totalIssues}</p>
            </div>
          </div>
        </Card>
        <Card>
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-emerald-500/10 text-emerald-500">
              <CheckCircle2 className="h-5 w-5" />
            </div>
            <div>
              <p className="text-xs text-[var(--text-secondary)]">Checks Passed</p>
              <p className="text-xl font-bold text-[var(--text-primary)]">{cleanChecks.length}</p>
            </div>
          </div>
        </Card>
        <Card>
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-amber-500/10 text-amber-500">
              <AlertTriangle className="h-5 w-5" />
            </div>
            <div>
              <p className="text-xs text-[var(--text-secondary)]">Checks Failed</p>
              <p className="text-xl font-bold text-[var(--text-primary)]">{issueChecks.length}</p>
            </div>
          </div>
        </Card>
      </div>

      {error && (
        <div className="p-4 rounded-lg bg-red-500/10 text-red-500 text-sm">{error}</div>
      )}

      {/* Issues */}
      {issueChecks.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-amber-500 flex items-center gap-2">
              <AlertTriangle className="h-5 w-5" />
              Issues Found ({issueChecks.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {issueChecks.map((check) => (
              <div key={check.check_name} className="flex items-center justify-between p-3 rounded-lg bg-amber-500/5 border border-amber-500/20">
                <div className="flex items-center gap-3">
                  <div className="text-amber-500">
                    {CHECK_ICONS[check.check_name] || <AlertTriangle className="h-4 w-4" />}
                  </div>
                  <div>
                    <p className="text-sm font-medium text-[var(--text-primary)]">{check.details}</p>
                    <p className="text-xs text-[var(--text-secondary)]">{check.entity_table}</p>
                  </div>
                </div>
                <span className="text-lg font-bold text-amber-500">{check.orphan_count}</span>
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      {/* Clean Checks */}
      <Card>
        <CardHeader>
          <CardTitle className="text-emerald-500 flex items-center gap-2">
            <CheckCircle2 className="h-5 w-5" />
            Passing Checks ({cleanChecks.length})
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          {cleanChecks.map((check) => (
            <div key={check.check_name} className="flex items-center gap-3 p-2 rounded-lg">
              <div className="text-emerald-500">
                {CHECK_ICONS[check.check_name] || <CheckCircle2 className="h-4 w-4" />}
              </div>
              <p className="text-sm text-[var(--text-secondary)]">{check.details}</p>
            </div>
          ))}
          {cleanChecks.length === 0 && !loading && (
            <p className="text-sm text-[var(--text-secondary)]">Run checks to see results.</p>
          )}
        </CardContent>
      </Card>

      {lastRun && (
        <p className="text-xs text-[var(--text-secondary)] text-center">
          Last run: {new Date(lastRun).toLocaleString()}
        </p>
      )}
    </div>
  );
}
