'use client';

// L7: Lien Protection Dashboard — at-risk jobs, approaching deadlines, total protected $

import { useState, useMemo } from 'react';
import {
  Shield,
  AlertTriangle,
  Clock,
  DollarSign,
  FileText,
  ChevronRight,
  MapPin,
  Calendar,
  CheckCircle,
  XCircle,
} from 'lucide-react';
import Link from 'next/link';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput } from '@/components/ui/input';
import { useLienProtection, type LienRecord } from '@/lib/hooks/use-lien-protection';

function statusVariant(status: string): 'success' | 'error' | 'warning' | 'info' | 'secondary' {
  switch (status) {
    case 'notice_due': case 'enforcement': return 'error';
    case 'lien_eligible': case 'lien_filed': return 'warning';
    case 'notice_sent': return 'info';
    case 'payment_received': case 'lien_released': case 'resolved': return 'success';
    default: return 'secondary';
  }
}

function StatCard({ label, value, icon: Icon, variant }: {
  label: string; value: string | number;
  icon: React.ComponentType<{ className?: string }>;
  variant?: 'success' | 'warning' | 'error' | 'default';
}) {
  const colors = {
    success: { text: 'text-emerald-400', bg: 'bg-emerald-500/10' },
    warning: { text: 'text-amber-400', bg: 'bg-amber-500/10' },
    error: { text: 'text-red-400', bg: 'bg-red-500/10' },
    default: { text: 'text-zinc-400', bg: 'bg-zinc-800' },
  }[variant || 'default'];

  return (
    <Card>
      <CardContent className="p-4">
        <div className="flex items-center gap-3">
          <div className={`p-2 rounded-lg ${colors.bg}`}>
            <Icon className={`h-4 w-4 ${colors.text}`} />
          </div>
          <div>
            <p className={`text-2xl font-bold ${colors.text}`}>{value}</p>
            <p className="text-xs text-zinc-500">{label}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

export default function LienProtectionPage() {
  const { activeLiens, summary, loading, error, rules, getRuleForState } = useLienProtection();
  const [searchQuery, setSearchQuery] = useState('');

  const filtered = useMemo(() => {
    if (!searchQuery) return activeLiens;
    const q = searchQuery.toLowerCase();
    return activeLiens.filter(l =>
      l.property_address.toLowerCase().includes(q) ||
      l.state_code.toLowerCase().includes(q) ||
      l.status.toLowerCase().includes(q)
    );
  }, [activeLiens, searchQuery]);

  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6">
        <Card><CardContent className="p-8 text-center">
          <p className="text-red-400">{error}</p>
        </CardContent></Card>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Lien Protection</h1>
          <p className="text-sm text-zinc-400 mt-1">Monitor deadlines, protect your right to payment</p>
        </div>
        <Link href="/dashboard/lien-protection/rules">
          <Button variant="ghost" className="gap-2">
            <FileText className="h-4 w-4" />
            Browse State Rules
          </Button>
        </Link>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
        <StatCard label="Active Liens" value={summary.totalActive} icon={Shield} />
        <StatCard label="At Risk" value={summary.totalAtRisk} icon={AlertTriangle} variant="warning" />
        <StatCard label="Amount Owed" value={`$${summary.totalAmountOwed.toLocaleString()}`} icon={DollarSign} variant="error" />
        <StatCard label="Urgent" value={summary.urgentCount} icon={Clock} variant="error" />
        <StatCard label="Liens Filed" value={summary.liensFiled} icon={FileText} />
      </div>

      {/* Search */}
      <SearchInput
        placeholder="Search liens by address or state..."
        value={searchQuery}
        onChange={setSearchQuery}
      />

      {/* List */}
      {filtered.length === 0 ? (
        <Card>
          <CardContent className="p-8 text-center">
            <Shield className="h-12 w-12 text-zinc-600 mx-auto mb-3" />
            <p className="text-zinc-400">No active lien records</p>
            <p className="text-sm text-zinc-500 mt-1">Lien tracking starts when jobs have outstanding payments</p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-3">
          {filtered.map((lien: LienRecord) => {
            const rule = getRuleForState(lien.state_code);
            let daysToDeadline: number | null = null;
            if (rule && lien.last_work_date) {
              const deadline = new Date(lien.last_work_date);
              deadline.setDate(deadline.getDate() + rule.lien_filing_deadline_days);
              daysToDeadline = Math.ceil((deadline.getTime() - Date.now()) / 86400000);
            }

            return (
              <Link key={lien.id} href={`/dashboard/lien-protection/${lien.job_id}`}>
                <Card className="hover:border-zinc-600 transition-colors cursor-pointer">
                  <CardContent className="p-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <div className="p-2 rounded-lg bg-zinc-800">
                          <Shield className="h-4 w-4 text-zinc-400" />
                        </div>
                        <div>
                          <div className="flex items-center gap-2">
                            <h3 className="text-sm font-semibold text-white">{lien.property_address}</h3>
                            <Badge variant={statusVariant(lien.status)} size="sm">
                              {lien.status.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}
                            </Badge>
                          </div>
                          <div className="flex items-center gap-3 mt-1 text-xs text-zinc-500">
                            <span className="flex items-center gap-1"><MapPin className="h-3 w-3" />{lien.state_code}</span>
                            {lien.amount_owed != null && lien.amount_owed > 0 && (
                              <span className="text-amber-400 font-medium">${lien.amount_owed.toLocaleString()} owed</span>
                            )}
                            {lien.last_work_date && (
                              <span className="flex items-center gap-1">
                                <Calendar className="h-3 w-3" />
                                Last: {new Date(lien.last_work_date).toLocaleDateString()}
                              </span>
                            )}
                          </div>
                        </div>
                      </div>
                      <div className="flex items-center gap-3">
                        {daysToDeadline !== null && daysToDeadline > 0 && !lien.lien_filed && (
                          <div className={`text-xs font-medium ${daysToDeadline <= 7 ? 'text-red-400' : daysToDeadline <= 30 ? 'text-amber-400' : 'text-zinc-400'}`}>
                            {daysToDeadline}d to file
                          </div>
                        )}
                        <ChevronRight className="h-4 w-4 text-zinc-600" />
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
