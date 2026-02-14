'use client';

// L9: Employee Compliance Status — CE hours, license renewals, compliance gaps

import { useState } from 'react';
import {
  GraduationCap,
  CheckCircle,
  Clock,
  AlertTriangle,
  Award,
  FileText,
  Plus,
  ChevronDown,
  ChevronUp,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { useMyComplianceStatus, type CECredit, type LicenseRenewal, type ComplianceGap } from '@/lib/hooks/use-compliance-status';

function StatCard({ label, value, icon: Icon, accent }: {
  label: string; value: string | number;
  icon: React.ComponentType<{ className?: string }>;
  accent?: string;
}) {
  return (
    <Card>
      <CardContent className="p-4">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-lg bg-surface-hover">
            <Icon className={`h-4 w-4 ${accent || 'text-muted'}`} />
          </div>
          <div>
            <p className={`text-2xl font-bold ${accent || 'text-main'}`}>{value}</p>
            <p className="text-xs text-muted">{label}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function ProgressBar({ completed, required }: { completed: number; required: number }) {
  const pct = required > 0 ? Math.min((completed / required) * 100, 100) : 0;
  const color = pct >= 100 ? 'bg-emerald-500' : pct >= 50 ? 'bg-blue-500' : 'bg-amber-500';

  return (
    <div className="w-full">
      <div className="flex items-center justify-between text-xs mb-1">
        <span className="text-muted">{completed} / {required} credits</span>
        <span className="text-muted">{Math.round(pct)}%</span>
      </div>
      <div className="h-2 bg-surface rounded-full overflow-hidden">
        <div className={`h-full ${color} rounded-full transition-all`} style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}

function RenewalStatusBadge({ status }: { status: string }) {
  const variant = status === 'overdue' ? 'error'
    : status === 'completed' ? 'success'
    : status === 'pending_approval' ? 'info'
    : status === 'in_progress' ? 'warning'
    : 'default';
  return (
    <Badge variant={variant} className="text-xs">
      {status.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}
    </Badge>
  );
}

export default function EmployeeCompliancePage() {
  const { ceCredits, renewals, gaps, summary, loading, error } = useMyComplianceStatus();
  const [showAddCE, setShowAddCE] = useState(false);
  const [expandedRenewal, setExpandedRenewal] = useState<string | null>(null);

  if (loading) {
    return (
      <div className="space-y-4 animate-pulse">
        <div className="h-8 bg-surface rounded w-48" />
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[1, 2, 3, 4].map(i => <div key={i} className="h-20 bg-surface rounded-lg" />)}
        </div>
        <div className="h-64 bg-surface rounded-lg" />
      </div>
    );
  }

  if (error) {
    return (
      <Card><CardContent className="p-8 text-center"><p className="text-red-500">{error}</p></CardContent></Card>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-main">My Compliance Status</h1>
        <p className="text-sm text-muted mt-1">CE credits, license renewals, and compliance requirements</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard label="CE Hours Earned" value={summary.totalCEHours} icon={GraduationCap} accent="text-blue-500" />
        <StatCard label="Verified Hours" value={summary.verifiedCEHours} icon={CheckCircle} accent="text-emerald-500" />
        <StatCard label="Active Renewals" value={summary.activeRenewals} icon={Clock} accent="text-amber-500" />
        <StatCard label="Compliance Gaps" value={summary.complianceGaps} icon={AlertTriangle} accent={summary.complianceGaps > 0 ? 'text-red-500' : 'text-emerald-500'} />
      </div>

      {/* Compliance Gaps Alert */}
      {gaps.length > 0 && (
        <Card className="border-red-500/30">
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2 text-red-500">
              <AlertTriangle className="h-4 w-4" />
              Missing Compliance Items
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {gaps.map((gap: ComplianceGap, i: number) => (
              <div key={i} className="flex items-center justify-between p-3 bg-red-500/5 rounded-lg">
                <div>
                  <p className="text-sm font-medium text-main">{gap.requirementName}</p>
                  <p className="text-xs text-muted">{gap.tradeType} — {gap.description}</p>
                </div>
                <Badge variant="error" className="text-xs">{gap.category}</Badge>
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      {/* License Renewals */}
      {renewals.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Award className="h-4 w-4 text-accent" />
              License Renewals
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {renewals.map((renewal: LicenseRenewal) => {
              const isExpanded = expandedRenewal === renewal.id;
              const daysUntil = Math.ceil(
                (new Date(renewal.renewalDueDate).getTime() - Date.now()) / 86400000
              );
              return (
                <div key={renewal.id} className="border border-border rounded-lg">
                  <button
                    onClick={() => setExpandedRenewal(isExpanded ? null : renewal.id)}
                    className="w-full p-3 text-left flex items-center justify-between"
                  >
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="text-sm font-medium text-main">
                          Renewal — Due {new Date(renewal.renewalDueDate).toLocaleDateString()}
                        </span>
                        <RenewalStatusBadge status={renewal.status} />
                      </div>
                      <ProgressBar completed={renewal.ceCreditsCompleted} required={renewal.ceCreditsRequired} />
                    </div>
                    <div className="flex items-center gap-2 ml-3">
                      <span className={`text-xs font-medium ${
                        daysUntil <= 7 ? 'text-red-500' : daysUntil <= 30 ? 'text-amber-500' : 'text-muted'
                      }`}>
                        {daysUntil > 0 ? `${daysUntil}d` : 'Overdue'}
                      </span>
                      {isExpanded ? <ChevronUp className="h-4 w-4 text-muted" /> : <ChevronDown className="h-4 w-4 text-muted" />}
                    </div>
                  </button>
                  {isExpanded && (
                    <div className="px-3 pb-3 border-t border-border pt-2 text-sm space-y-1">
                      <div className="flex justify-between">
                        <span className="text-muted">Credits Remaining</span>
                        <span className="text-main font-medium">{renewal.ceCreditsRemaining}</span>
                      </div>
                      {renewal.renewalFee != null && (
                        <div className="flex justify-between">
                          <span className="text-muted">Renewal Fee</span>
                          <span className={renewal.feePaid ? 'text-emerald-500' : 'text-amber-500'}>
                            ${renewal.renewalFee} {renewal.feePaid ? '(Paid)' : '(Unpaid)'}
                          </span>
                        </div>
                      )}
                      {renewal.notes && (
                        <p className="text-xs text-muted pt-1">{renewal.notes}</p>
                      )}
                    </div>
                  )}
                </div>
              );
            })}
          </CardContent>
        </Card>
      )}

      {/* CE Credit History */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-base flex items-center gap-2">
              <GraduationCap className="h-4 w-4 text-accent" />
              CE Credit History
            </CardTitle>
            <span className="text-xs text-muted">{ceCredits.length} course{ceCredits.length !== 1 ? 's' : ''}</span>
          </div>
        </CardHeader>
        <CardContent>
          {ceCredits.length === 0 ? (
            <div className="text-center py-8">
              <GraduationCap className="h-10 w-10 text-muted mx-auto mb-2 opacity-50" />
              <p className="text-muted text-sm">No CE credits recorded yet</p>
              <p className="text-muted text-xs mt-1">Credits will appear here as you complete courses</p>
            </div>
          ) : (
            <div className="space-y-2">
              {ceCredits.map((credit: CECredit) => (
                <div key={credit.id} className="flex items-center justify-between p-3 bg-surface rounded-lg">
                  <div className="flex items-center gap-3">
                    <div className={`p-1.5 rounded ${credit.verified ? 'bg-emerald-500/10' : 'bg-surface-hover'}`}>
                      {credit.verified
                        ? <CheckCircle className="h-3.5 w-3.5 text-emerald-500" />
                        : <Clock className="h-3.5 w-3.5 text-muted" />}
                    </div>
                    <div>
                      <p className="text-sm font-medium text-main">{credit.courseName}</p>
                      <div className="flex items-center gap-2 text-xs text-muted">
                        {credit.provider && <span>{credit.provider}</span>}
                        <span>{new Date(credit.completionDate).toLocaleDateString()}</span>
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    {credit.ceCategory && (
                      <Badge variant="default" className="text-xs">{credit.ceCategory}</Badge>
                    )}
                    <span className="text-sm font-bold text-main">{credit.creditHours}h</span>
                    {credit.certificateDocumentPath && (
                      <FileText className="h-3.5 w-3.5 text-blue-500" />
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
