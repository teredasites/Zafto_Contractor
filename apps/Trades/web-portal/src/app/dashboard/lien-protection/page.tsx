'use client';

// 9A: Mechanic's Lien Engine — 50-state rules, auto-deadline tracking, preliminary notice
// generation, lien waiver management, deadline alerts, lien filing preparation.

import { useState, useMemo } from 'react';
import {
  Shield,
  AlertTriangle,
  Clock,
  DollarSign,
  FileText,
  ChevronRight,
  ChevronDown,
  MapPin,
  Calendar,
  CheckCircle,
  XCircle,
  Bell,
  Scale,
  Gavel,
  BookOpen,
  Send,
  Download,
  Eye,
  Timer,
  Landmark,
  CircleDot,
  Info,
  Plus,
  ClipboardCheck,
  FilePlus,
  CalendarClock,
  Stamp,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput } from '@/components/ui/input';
import { useLienProtection, type LienRecord, type LienRule } from '@/lib/hooks/use-lien-protection';
import { useTranslation } from '@/lib/translations';
import { formatCurrency } from '@/lib/format-locale';
import { CommandPalette } from '@/components/command-palette';
import {
  STATE_LIEN_WAIVER_CONFIGS,
} from '@/lib/official-lien-waivers';

// ── Tab type ──────────────────────────────────────────────
type Tab = 'dashboard' | 'rules' | 'waivers' | 'deadlines' | 'notices';

const TABS: { id: Tab; label: string; icon: React.ComponentType<{ className?: string }> }[] = [
  { id: 'dashboard', label: 'Dashboard', icon: Shield },
  { id: 'rules', label: 'State Rules', icon: BookOpen },
  { id: 'waivers', label: 'Waivers', icon: ClipboardCheck },
  { id: 'deadlines', label: 'Deadlines', icon: CalendarClock },
  { id: 'notices', label: 'Notices', icon: Send },
];

// ── Status helpers ────────────────────────────────────────
function statusVariant(status: string): 'success' | 'error' | 'warning' | 'info' | 'secondary' {
  switch (status) {
    case 'notice_due': case 'enforcement': return 'error';
    case 'lien_eligible': case 'lien_filed': return 'warning';
    case 'notice_sent': return 'info';
    case 'payment_received': case 'lien_released': case 'resolved': return 'success';
    default: return 'secondary';
  }
}

function urgencyVariant(days: number): 'error' | 'warning' | 'info' | 'secondary' {
  if (days <= 3) return 'error';
  if (days <= 7) return 'error';
  if (days <= 14) return 'warning';
  if (days <= 30) return 'info';
  return 'secondary';
}

function urgencyColor(days: number): string {
  if (days <= 3) return 'text-red-400';
  if (days <= 7) return 'text-red-400';
  if (days <= 14) return 'text-amber-400';
  if (days <= 30) return 'text-blue-400';
  return 'text-muted';
}

function formatStatusLabel(status: string): string {
  return status.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
}

// ── Helpers for extracting display data from LienRule.special_rules JSONB ──
function extractSpecialRuleField(rule: LienRule, field: string): string[] {
  if (!rule.special_rules || !Array.isArray(rule.special_rules)) return [];
  const entry = rule.special_rules.find(r => field in (r as Record<string, unknown>));
  if (!entry) return [];
  const val = (entry as Record<string, unknown>)[field];
  return Array.isArray(val) ? val.map(String) : typeof val === 'string' ? [val] : [];
}

function getRequiredForms(rule: LienRule): string[] {
  return extractSpecialRuleField(rule, 'required_forms');
}

function getRecordingOffice(rule: LienRule): string | null {
  const vals = extractSpecialRuleField(rule, 'recording_office');
  return vals.length > 0 ? vals[0] : null;
}

function getSpecialRequirements(rule: LienRule): string[] {
  return extractSpecialRuleField(rule, 'special_requirements');
}

// (Waiver types reserved for future dedicated waiver tracking table)

// ── Deadline interface (derived from real liens + rules) ──
interface LienDeadline {
  id: string;
  jobName: string;
  propertyAddress: string;
  stateCode: string;
  deadlineType: 'preliminary_notice' | 'lien_filing' | 'lien_enforcement' | 'notice_of_intent';
  deadlineDate: string;
  daysRemaining: number;
  status: 'upcoming' | 'urgent' | 'critical' | 'overdue' | 'completed';
  amountAtRisk: number;
}

function computeDeadlineStatus(daysRemaining: number, isCompleted: boolean): LienDeadline['status'] {
  if (isCompleted) return 'completed';
  if (daysRemaining <= 0) return 'overdue';
  if (daysRemaining <= 7) return 'critical';
  if (daysRemaining <= 14) return 'urgent';
  return 'upcoming';
}

// ── Notice interface (derived from real liens + rules) ──
interface PrelimNotice {
  id: string;
  propertyAddress: string;
  stateCode: string;
  amountDue: number;
  firstFurnishingDate: string | null;
  noticeSentDate: string | null;
  noticeDeadline: string | null;
  status: 'draft' | 'generated' | 'sent' | 'confirmed' | 'expired';
}

// ── Stat Card Component ───────────────────────────────────
function StatCard({ label, value, icon: Icon, variant }: {
  label: string; value: string | number;
  icon: React.ComponentType<{ className?: string }>;
  variant?: 'success' | 'warning' | 'error' | 'default';
}) {
  const colors = {
    success: { text: 'text-emerald-400', bg: 'bg-emerald-500/10' },
    warning: { text: 'text-amber-400', bg: 'bg-amber-500/10' },
    error: { text: 'text-red-400', bg: 'bg-red-500/10' },
    default: { text: 'text-muted', bg: 'bg-secondary' },
  }[variant || 'default'];

  return (
    <Card>
      <CardContent className="p-4">
        <div className="flex items-center gap-3">
          <div className={`p-2.5 rounded-lg ${colors.bg}`}>
            <Icon className={`h-5 w-5 ${colors.text}`} />
          </div>
          <div>
            <p className={`text-2xl font-bold ${colors.text}`}>{value}</p>
            <p className="text-xs text-muted">{label}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

// ── Timeline Indicator ────────────────────────────────────
function DeadlineTimeline({ daysRemaining, label }: { daysRemaining: number; label: string }) {
  const pct = daysRemaining <= 0 ? 100 : Math.min(100, Math.max(0, 100 - (daysRemaining / 120) * 100));
  const barColor = daysRemaining <= 3 ? 'bg-red-500' : daysRemaining <= 14 ? 'bg-amber-500' : daysRemaining <= 30 ? 'bg-blue-500' : 'bg-secondary';

  return (
    <div className="space-y-1">
      <div className="flex items-center justify-between text-xs">
        <span className="text-muted">{label}</span>
        <span className={urgencyColor(daysRemaining)}>
          {daysRemaining <= 0 ? `${Math.abs(daysRemaining)}d overdue` : `${daysRemaining}d remaining`}
        </span>
      </div>
      <div className="h-1.5 bg-secondary rounded-full overflow-hidden">
        <div className={`h-full rounded-full transition-all ${barColor}`} style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}

// ══════════════════════════════════════════════════════════
// ── MAIN PAGE COMPONENT ──────────────────────────────────
// ══════════════════════════════════════════════════════════
export default function LienProtectionPage() {
  const { t } = useTranslation();
  const { activeLiens, summary, loading, error, rules, getRuleForState } = useLienProtection();
  const [activeTab, setActiveTab] = useState<Tab>('dashboard');
  const [searchQuery, setSearchQuery] = useState('');
  const [expandedState, setExpandedState] = useState<string | null>(null);
  const [deadlineFilter, setDeadlineFilter] = useState<'all' | 'critical' | 'urgent' | 'upcoming' | 'overdue'>('all');
  const [noticeFilter, setNoticeFilter] = useState<'all' | 'draft' | 'generated' | 'sent' | 'confirmed' | 'expired'>('all');

  // ── Filtered Liens (dashboard) ──
  const filteredLiens = useMemo(() => {
    if (!searchQuery) return activeLiens;
    const q = searchQuery.toLowerCase();
    return activeLiens.filter(l =>
      l.property_address.toLowerCase().includes(q) ||
      l.state_code.toLowerCase().includes(q) ||
      l.status.toLowerCase().includes(q)
    );
  }, [activeLiens, searchQuery]);

  // ── Filtered State Rules (from DB) ──
  const filteredRules = useMemo(() => {
    if (!searchQuery) return rules;
    const q = searchQuery.toLowerCase();
    return rules.filter(r =>
      r.state_name.toLowerCase().includes(q) ||
      r.state_code.toLowerCase().includes(q) ||
      (r.statutory_reference || '').toLowerCase().includes(q)
    );
  }, [rules, searchQuery]);

  // ── Derived Deadlines from real liens + rules ──
  const derivedDeadlines = useMemo((): LienDeadline[] => {
    const deadlines: LienDeadline[] = [];
    const now = Date.now();

    for (const lien of activeLiens) {
      const rule = rules.find(r => r.state_code === lien.state_code);
      if (!rule) continue;

      // Preliminary notice deadline
      if (rule.preliminary_notice_required && rule.preliminary_notice_deadline_days && lien.first_work_date) {
        const deadline = new Date(lien.first_work_date);
        deadline.setDate(deadline.getDate() + rule.preliminary_notice_deadline_days);
        const daysRemaining = Math.ceil((deadline.getTime() - now) / 86400000);
        deadlines.push({
          id: `${lien.id}-prelim`,
          jobName: lien.property_address,
          propertyAddress: lien.property_address,
          stateCode: lien.state_code,
          deadlineType: 'preliminary_notice',
          deadlineDate: deadline.toISOString().split('T')[0],
          daysRemaining,
          status: computeDeadlineStatus(daysRemaining, lien.preliminary_notice_sent),
          amountAtRisk: lien.amount_owed ?? 0,
        });
      }

      // Lien filing deadline
      const filingRefDate = lien.last_work_date || lien.completion_date;
      if (filingRefDate) {
        const deadline = new Date(filingRefDate);
        deadline.setDate(deadline.getDate() + rule.lien_filing_deadline_days);
        const daysRemaining = Math.ceil((deadline.getTime() - now) / 86400000);
        deadlines.push({
          id: `${lien.id}-filing`,
          jobName: lien.property_address,
          propertyAddress: lien.property_address,
          stateCode: lien.state_code,
          deadlineType: 'lien_filing',
          deadlineDate: deadline.toISOString().split('T')[0],
          daysRemaining,
          status: computeDeadlineStatus(daysRemaining, lien.lien_filed),
          amountAtRisk: lien.amount_owed ?? 0,
        });
      }

      // Lien enforcement deadline
      if (rule.lien_enforcement_deadline_days && lien.lien_filing_date) {
        const deadline = new Date(lien.lien_filing_date);
        deadline.setDate(deadline.getDate() + rule.lien_enforcement_deadline_days);
        const daysRemaining = Math.ceil((deadline.getTime() - now) / 86400000);
        deadlines.push({
          id: `${lien.id}-enforce`,
          jobName: lien.property_address,
          propertyAddress: lien.property_address,
          stateCode: lien.state_code,
          deadlineType: 'lien_enforcement',
          deadlineDate: deadline.toISOString().split('T')[0],
          daysRemaining,
          status: computeDeadlineStatus(daysRemaining, lien.enforcement_filed),
          amountAtRisk: lien.amount_owed ?? 0,
        });
      }

      // Notice of intent deadline
      if (rule.notice_of_intent_required && rule.notice_of_intent_deadline_days && filingRefDate) {
        const deadline = new Date(filingRefDate);
        deadline.setDate(deadline.getDate() + rule.notice_of_intent_deadline_days);
        const daysRemaining = Math.ceil((deadline.getTime() - now) / 86400000);
        deadlines.push({
          id: `${lien.id}-noi`,
          jobName: lien.property_address,
          propertyAddress: lien.property_address,
          stateCode: lien.state_code,
          deadlineType: 'notice_of_intent',
          deadlineDate: deadline.toISOString().split('T')[0],
          daysRemaining,
          status: computeDeadlineStatus(daysRemaining, lien.notice_of_intent_sent),
          amountAtRisk: lien.amount_owed ?? 0,
        });
      }
    }

    // Sort by most urgent first (lowest daysRemaining)
    return deadlines.filter(d => d.status !== 'completed').sort((a, b) => a.daysRemaining - b.daysRemaining);
  }, [activeLiens, rules]);

  // ── Filtered Deadlines ──
  const filteredDeadlines = useMemo(() => {
    let list = derivedDeadlines;
    if (deadlineFilter !== 'all') {
      list = list.filter(d => d.status === deadlineFilter);
    }
    if (!searchQuery) return list;
    const q = searchQuery.toLowerCase();
    return list.filter(d =>
      d.jobName.toLowerCase().includes(q) ||
      d.propertyAddress.toLowerCase().includes(q) ||
      d.stateCode.toLowerCase().includes(q)
    );
  }, [derivedDeadlines, searchQuery, deadlineFilter]);

  // ── Derived Notices from real liens ──
  const derivedNotices = useMemo((): PrelimNotice[] => {
    return activeLiens
      .filter(lien => {
        const rule = rules.find(r => r.state_code === lien.state_code);
        return rule?.preliminary_notice_required;
      })
      .map(lien => {
        const rule = rules.find(r => r.state_code === lien.state_code)!;
        let deadlineDate: string | null = null;
        if (lien.first_work_date && rule.preliminary_notice_deadline_days) {
          const d = new Date(lien.first_work_date);
          d.setDate(d.getDate() + rule.preliminary_notice_deadline_days);
          deadlineDate = d.toISOString().split('T')[0];
        }

        let status: PrelimNotice['status'] = 'draft';
        if (lien.preliminary_notice_sent && lien.preliminary_notice_date) {
          status = 'confirmed';
        } else if (lien.preliminary_notice_sent) {
          status = 'sent';
        } else if (lien.preliminary_notice_document_path) {
          status = 'generated';
        } else if (deadlineDate && new Date(deadlineDate) < new Date()) {
          status = 'expired';
        }

        return {
          id: `notice-${lien.id}`,
          propertyAddress: lien.property_address,
          stateCode: lien.state_code,
          amountDue: lien.amount_owed ?? 0,
          firstFurnishingDate: lien.first_work_date,
          noticeSentDate: lien.preliminary_notice_date,
          noticeDeadline: deadlineDate,
          status,
        };
      });
  }, [activeLiens, rules]);

  // ── Filtered Notices ──
  const filteredNotices = useMemo(() => {
    let list = derivedNotices;
    if (noticeFilter !== 'all') {
      list = list.filter(n => n.status === noticeFilter);
    }
    if (!searchQuery) return list;
    const q = searchQuery.toLowerCase();
    return list.filter(n =>
      n.propertyAddress.toLowerCase().includes(q) ||
      n.stateCode.toLowerCase().includes(q)
    );
  }, [derivedNotices, searchQuery, noticeFilter]);

  // ── Loading State ──
  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500" />
      </div>
    );
  }

  // ── Error State ──
  if (error) {
    return (
      <div className="p-6">
        <Card>
          <CardContent className="p-8 text-center">
            <AlertTriangle className="h-10 w-10 text-red-400 mx-auto mb-3" />
            <p className="text-red-400 font-medium">Failed to load lien data</p>
            <p className="text-sm text-muted mt-1">{error}</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  // ── Aggregate counts for deadline tabs ──
  const criticalCount = derivedDeadlines.filter(d => d.status === 'critical').length;
  const urgentDeadlineCount = derivedDeadlines.filter(d => d.status === 'urgent').length;
  const overdueCount = derivedDeadlines.filter(d => d.status === 'overdue').length;
  const upcomingCount = derivedDeadlines.filter(d => d.status === 'upcoming').length;
  // No waiver tracking in DB yet — always 0
  const flaggedWaiverCount = 0;

  return (
    <div className="p-6 space-y-6">
      <CommandPalette />
      {/* ── Header ── */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-main flex items-center gap-2">
            <Shield className="h-6 w-6 text-blue-400" />
            Lien Protection Engine
          </h1>
          <p className="text-sm text-muted mt-1">
            50-state rules, auto-deadline tracking, preliminary notices, waiver management
          </p>
        </div>
        <div className="flex items-center gap-2">
          {(criticalCount + overdueCount) > 0 && (
            <div className="flex items-center gap-1.5 px-3 py-1.5 bg-red-500/10 border border-red-500/20 rounded-lg">
              <Bell className="h-4 w-4 text-red-400" />
              <span className="text-sm font-medium text-red-400">
                {criticalCount + overdueCount} critical deadline{criticalCount + overdueCount !== 1 ? 's' : ''}
              </span>
            </div>
          )}
          <Button variant="primary" className="gap-2">
            <Plus className="h-4 w-4" />
            New Lien Record
          </Button>
        </div>
      </div>

      {/* ── Tabs ── */}
      <div className="flex items-center gap-1 border-b border-main pb-0">
        {TABS.map(tab => {
          const TabIcon = tab.icon;
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => { setActiveTab(tab.id); setSearchQuery(''); }}
              className={`flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 transition-colors ${
                isActive
                  ? 'border-blue-500 text-blue-400'
                  : 'border-transparent text-muted hover:text-main'
              }`}
            >
              <TabIcon className="h-4 w-4" />
              {tab.label}
              {tab.id === 'deadlines' && (criticalCount + overdueCount) > 0 && (
                <span className="ml-1 text-xs bg-red-500/20 text-red-400 px-1.5 py-0.5 rounded-full font-semibold">
                  {criticalCount + overdueCount}
                </span>
              )}
              {tab.id === 'waivers' && flaggedWaiverCount > 0 && (
                <span className="ml-1 text-xs bg-amber-500/20 text-amber-400 px-1.5 py-0.5 rounded-full font-semibold">
                  {flaggedWaiverCount}
                </span>
              )}
            </button>
          );
        })}
      </div>

      {/* ═══════════════════════════════════════════════════════ */}
      {/* ── TAB: DASHBOARD ──────────────────────────────────── */}
      {/* ═══════════════════════════════════════════════════════ */}
      {activeTab === 'dashboard' && (
        <div className="space-y-6">
          {/* Stats Row */}
          <div className="grid grid-cols-2 lg:grid-cols-6 gap-4">
            <StatCard label="Active Liens" value={summary.totalActive} icon={Shield} />
            <StatCard label="At Risk" value={summary.totalAtRisk} icon={AlertTriangle} variant="warning" />
            <StatCard label="Amount Owed" value={formatCurrency(summary.totalAmountOwed)} icon={DollarSign} variant="error" />
            <StatCard label="Urgent" value={summary.urgentCount} icon={Clock} variant="error" />
            <StatCard label="Liens Filed" value={summary.liensFiled} icon={FileText} />
            <StatCard label="Approaching" value={summary.approachingDeadlines} icon={Timer} variant="warning" />
          </div>

          {/* Search */}
          <SearchInput
            placeholder="Search liens by address, state, or status..."
            value={searchQuery}
            onChange={setSearchQuery}
          />

          {/* Active Liens List */}
          {filteredLiens.length === 0 ? (
            <Card>
              <CardContent className="p-8 text-center">
                <Shield className="h-12 w-12 text-muted opacity-50 mx-auto mb-3" />
                <p className="text-muted font-medium">No active lien records</p>
                <p className="text-sm text-muted mt-1">Lien tracking starts when jobs have outstanding payments</p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-3">
              {filteredLiens.map((lien: LienRecord) => {
                const rule = getRuleForState(lien.state_code);
                let daysToDeadline: number | null = null;
                let deadlineLabel = '';
                if (rule && lien.last_work_date) {
                  const deadline = new Date(lien.last_work_date);
                  deadline.setDate(deadline.getDate() + rule.lien_filing_deadline_days);
                  daysToDeadline = Math.ceil((deadline.getTime() - Date.now()) / 86400000);
                  deadlineLabel = 'Lien Filing';
                }

                return (
                  <Card key={lien.id} className="hover:border-accent/30 transition-colors">
                    <CardContent className="p-4">
                      <div className="flex items-start justify-between">
                        <div className="flex items-start gap-3 flex-1">
                          <div className="p-2 rounded-lg bg-secondary mt-0.5">
                            <Shield className="h-4 w-4 text-muted" />
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2 flex-wrap">
                              <h3 className="text-sm font-semibold text-main">{lien.property_address}</h3>
                              <Badge variant={statusVariant(lien.status)} size="sm">
                                {formatStatusLabel(lien.status)}
                              </Badge>
                              {lien.lien_filed && (
                                <Badge variant="purple" size="sm">Lien Filed</Badge>
                              )}
                            </div>
                            <div className="flex items-center gap-3 mt-1.5 text-xs text-muted flex-wrap">
                              <span className="flex items-center gap-1">
                                <MapPin className="h-3 w-3" />{lien.state_code}
                              </span>
                              {lien.amount_owed != null && lien.amount_owed > 0 && (
                                <span className="text-amber-400 font-medium">
                                  {formatCurrency(lien.amount_owed)} owed
                                </span>
                              )}
                              {lien.contract_amount != null && (
                                <span className="flex items-center gap-1">
                                  <DollarSign className="h-3 w-3" />
                                  Contract: {formatCurrency(lien.contract_amount)}
                                </span>
                              )}
                              {lien.last_work_date && (
                                <span className="flex items-center gap-1">
                                  <Calendar className="h-3 w-3" />
                                  Last work: {lien.last_work_date}
                                </span>
                              )}
                              {lien.preliminary_notice_sent && (
                                <span className="flex items-center gap-1 text-emerald-400">
                                  <CheckCircle className="h-3 w-3" />
                                  Prelim sent
                                </span>
                              )}
                            </div>

                            {/* Deadline Timeline */}
                            {daysToDeadline !== null && !lien.lien_filed && (
                              <div className="mt-3 max-w-md">
                                <DeadlineTimeline daysRemaining={daysToDeadline} label={deadlineLabel} />
                              </div>
                            )}
                          </div>
                        </div>

                        <div className="flex items-center gap-2 ml-4">
                          {daysToDeadline !== null && daysToDeadline > 0 && !lien.lien_filed && (
                            <div className={`text-xs font-semibold px-2 py-1 rounded ${
                              daysToDeadline <= 7 ? 'bg-red-500/10 text-red-400' :
                              daysToDeadline <= 30 ? 'bg-amber-500/10 text-amber-400' :
                              'bg-secondary text-muted'
                            }`}>
                              {daysToDeadline}d to file
                            </div>
                          )}
                          <Button variant="ghost" className="h-8 w-8 p-0">
                            <ChevronRight className="h-4 w-4 text-muted" />
                          </Button>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* ═══════════════════════════════════════════════════════ */}
      {/* ── TAB: STATE RULES ────────────────────────────────── */}
      {/* ═══════════════════════════════════════════════════════ */}
      {activeTab === 'rules' && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-semibold text-main">50-State Lien Rules Database</h2>
              <p className="text-sm text-muted">{rules.length} states with detailed mechanic&apos;s lien requirements</p>
            </div>
          </div>

          <SearchInput
            placeholder="Search by state name, code, or statute..."
            value={searchQuery}
            onChange={setSearchQuery}
          />

          {filteredRules.length === 0 ? (
            <Card>
              <CardContent className="p-8 text-center">
                <BookOpen className="h-12 w-12 text-muted opacity-50 mx-auto mb-3" />
                <p className="text-muted font-medium">
                  {rules.length === 0 ? 'State lien rules have not been loaded yet' : 'No states match your search'}
                </p>
                {rules.length === 0 && (
                  <p className="text-sm text-muted mt-1">Lien rules will appear here once the state rules database is seeded.</p>
                )}
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-2">
              {filteredRules.map(rule => {
                const isExpanded = expandedState === rule.state_code;
                const requiredForms = getRequiredForms(rule);
                const recordingOffice = getRecordingOffice(rule);
                const specialRequirements = getSpecialRequirements(rule);
                return (
                  <Card key={rule.state_code} className="overflow-hidden">
                    <button
                      className="w-full text-left"
                      onClick={() => setExpandedState(isExpanded ? null : rule.state_code)}
                    >
                      <CardContent className="p-4">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-3">
                            <div className="w-10 h-10 rounded-lg bg-blue-500/10 flex items-center justify-center">
                              <span className="text-sm font-bold text-blue-400">{rule.state_code}</span>
                            </div>
                            <div>
                              <h3 className="text-sm font-semibold text-main">{rule.state_name}</h3>
                              <p className="text-xs text-muted">{rule.statutory_reference || ''}</p>
                            </div>
                          </div>
                          <div className="flex items-center gap-3">
                            <div className="hidden sm:flex items-center gap-2">
                              {rule.preliminary_notice_required && (
                                <Badge variant="info" size="sm">Prelim Required</Badge>
                              )}
                              {rule.notarization_required && (
                                <Badge variant="purple" size="sm">Notarization</Badge>
                              )}
                              {rule.residential_different && (
                                <Badge variant="warning" size="sm">Res. Different</Badge>
                              )}
                            </div>
                            <div className="flex items-center gap-4 text-xs text-muted">
                              <span className="hidden md:inline">{rule.lien_filing_deadline_days}d filing</span>
                              <span className="hidden md:inline">{rule.lien_enforcement_deadline_days ?? '—'}d enforcement</span>
                            </div>
                            {isExpanded ? (
                              <ChevronDown className="h-4 w-4 text-muted" />
                            ) : (
                              <ChevronRight className="h-4 w-4 text-muted" />
                            )}
                          </div>
                        </div>
                      </CardContent>
                    </button>

                    {isExpanded && (
                      <div className="border-t border-main bg-surface/50">
                        <CardContent className="p-5 space-y-5">
                          {/* Key Deadlines Grid */}
                          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                            {/* Preliminary Notice */}
                            <div className="p-3 rounded-lg bg-secondary/50 border border-main">
                              <div className="flex items-center gap-2 mb-2">
                                <Send className="h-4 w-4 text-blue-400" />
                                <span className="text-xs font-semibold text-blue-400 uppercase tracking-wider">Preliminary Notice</span>
                              </div>
                              {rule.preliminary_notice_required ? (
                                <>
                                  <p className="text-lg font-bold text-main">{rule.preliminary_notice_deadline_days} days</p>
                                  <p className="text-xs text-muted mt-1">From: {rule.preliminary_notice_from || 'first furnishing'}</p>
                                </>
                              ) : (
                                <p className="text-sm text-muted">Not required in this state</p>
                              )}
                            </div>
                            {/* Lien Filing */}
                            <div className="p-3 rounded-lg bg-secondary/50 border border-main">
                              <div className="flex items-center gap-2 mb-2">
                                <Gavel className="h-4 w-4 text-amber-400" />
                                <span className="text-xs font-semibold text-amber-400 uppercase tracking-wider">Lien Filing</span>
                              </div>
                              <p className="text-lg font-bold text-main">{rule.lien_filing_deadline_days} days</p>
                              <p className="text-xs text-muted mt-1">From: {rule.lien_filing_from}</p>
                            </div>
                            {/* Enforcement */}
                            <div className="p-3 rounded-lg bg-secondary/50 border border-main">
                              <div className="flex items-center gap-2 mb-2">
                                <Scale className="h-4 w-4 text-red-400" />
                                <span className="text-xs font-semibold text-red-400 uppercase tracking-wider">Enforcement</span>
                              </div>
                              <p className="text-lg font-bold text-main">{rule.lien_enforcement_deadline_days ?? '—'} days</p>
                              <p className="text-xs text-muted mt-1">From: {rule.lien_enforcement_from || '—'}</p>
                            </div>
                          </div>

                          {/* Required Forms (from special_rules JSONB) */}
                          {requiredForms.length > 0 && (
                            <div>
                              <h4 className="text-xs font-semibold text-muted uppercase tracking-wider mb-2 flex items-center gap-1.5">
                                <FileText className="h-3.5 w-3.5" /> Required Forms
                              </h4>
                              <div className="flex flex-wrap gap-2">
                                {requiredForms.map((form, i) => (
                                  <span key={i} className="text-xs bg-secondary text-main px-2.5 py-1 rounded-md border border-main">
                                    {form}
                                  </span>
                                ))}
                              </div>
                            </div>
                          )}

                          {/* Recording Office & Details */}
                          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            {recordingOffice && (
                              <div>
                                <h4 className="text-xs font-semibold text-muted uppercase tracking-wider mb-2 flex items-center gap-1.5">
                                  <Landmark className="h-3.5 w-3.5" /> Recording Office
                                </h4>
                                <p className="text-sm text-main">{recordingOffice}</p>
                              </div>
                            )}
                            <div>
                              <h4 className="text-xs font-semibold text-muted uppercase tracking-wider mb-2 flex items-center gap-1.5">
                                <Info className="h-3.5 w-3.5" /> Key Attributes
                              </h4>
                              <div className="flex flex-wrap gap-2 text-xs">
                                <span className={`px-2 py-0.5 rounded ${rule.notarization_required ? 'bg-purple-500/10 text-purple-400' : 'bg-secondary text-muted'}`}>
                                  {rule.notarization_required ? 'Notarization Required' : 'No Notarization'}
                                </span>
                                <span className={`px-2 py-0.5 rounded ${rule.residential_different ? 'bg-amber-500/10 text-amber-400' : 'bg-secondary text-muted'}`}>
                                  {rule.residential_different ? 'Residential Rules Differ' : 'Same for All Projects'}
                                </span>
                              </div>
                            </div>
                          </div>

                          {/* Special Requirements (from special_rules JSONB) */}
                          {specialRequirements.length > 0 && (
                            <div>
                              <h4 className="text-xs font-semibold text-muted uppercase tracking-wider mb-2 flex items-center gap-1.5">
                                <AlertTriangle className="h-3.5 w-3.5" /> Special Requirements
                              </h4>
                              <ul className="space-y-1.5">
                                {specialRequirements.map((req, i) => (
                                  <li key={i} className="flex items-start gap-2 text-sm text-main">
                                    <CircleDot className="h-3 w-3 text-muted opacity-50 mt-1 flex-shrink-0" />
                                    {req}
                                  </li>
                                ))}
                              </ul>
                            </div>
                          )}

                          {/* Notes */}
                          {rule.notes && (
                            <div className="text-xs text-muted bg-secondary/30 p-3 rounded-lg border border-main">
                              <span className="font-semibold">Notes:</span> {rule.notes}
                            </div>
                          )}

                          {/* Official Waiver Form Status */}
                          {STATE_LIEN_WAIVER_CONFIGS[rule.state_code] && (
                            <div className="mt-2 pt-2 border-t border-main">
                              <h4 className="text-xs font-semibold text-muted uppercase tracking-wider mb-2 flex items-center gap-1.5">
                                <Stamp className="h-3.5 w-3.5" /> Lien Waiver Forms
                              </h4>
                              <div className="flex items-center gap-2 flex-wrap">
                                <Badge variant={STATE_LIEN_WAIVER_CONFIGS[rule.state_code].hasStatutoryForm ? 'warning' : 'secondary'} className="text-xs">
                                  {STATE_LIEN_WAIVER_CONFIGS[rule.state_code].hasStatutoryForm ? 'Statutory (Mandatory Form)' : 'Non-Statutory'}
                                </Badge>
                                {STATE_LIEN_WAIVER_CONFIGS[rule.state_code].notarizationRequired && (
                                  <Badge variant="purple" size="sm">Notarization Required for Waivers</Badge>
                                )}
                                <span className="text-xs text-muted">
                                  {STATE_LIEN_WAIVER_CONFIGS[rule.state_code].statuteCitation}
                                </span>
                              </div>
                              {STATE_LIEN_WAIVER_CONFIGS[rule.state_code].forms.length > 0 && (
                                <div className="mt-2 flex flex-wrap gap-1.5">
                                  {STATE_LIEN_WAIVER_CONFIGS[rule.state_code].forms.map((form, i) => (
                                    <span key={i} className="text-xs bg-secondary text-main px-2 py-0.5 rounded border border-main">
                                      {form.title}
                                    </span>
                                  ))}
                                </div>
                              )}
                              {STATE_LIEN_WAIVER_CONFIGS[rule.state_code].specialRequirements.length > 0 && (
                                <ul className="mt-2 space-y-1">
                                  {STATE_LIEN_WAIVER_CONFIGS[rule.state_code].specialRequirements.map((req, i) => (
                                    <li key={i} className="flex items-start gap-2 text-xs text-muted">
                                      <CircleDot className="h-2.5 w-2.5 opacity-50 mt-0.5 flex-shrink-0" />
                                      {req}
                                    </li>
                                  ))}
                                </ul>
                              )}
                            </div>
                          )}
                        </CardContent>
                      </div>
                    )}
                  </Card>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* ═══════════════════════════════════════════════════════ */}
      {/* ── TAB: WAIVERS ────────────────────────────────────── */}
      {/* ═══════════════════════════════════════════════════════ */}
      {activeTab === 'waivers' && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-semibold text-main">Lien Waiver Management</h2>
              <p className="text-sm text-muted">Track conditional and unconditional waivers sent and received</p>
            </div>
            <Button variant="primary" className="gap-2">
              <Plus className="h-4 w-4" />
              Request Waiver
            </Button>
          </div>

          {/* Waiver Stats */}
          <div className="grid grid-cols-2 lg:grid-cols-5 gap-3">
            <Card>
              <CardContent className="p-3 text-center">
                <p className="text-xl font-bold text-main">0</p>
                <p className="text-xs text-muted">Total Waivers</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-3 text-center">
                <p className="text-xl font-bold text-emerald-400">0</p>
                <p className="text-xs text-muted">Received</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-3 text-center">
                <p className="text-xl font-bold text-blue-400">0</p>
                <p className="text-xs text-muted">Sent / Pending</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-3 text-center">
                <p className="text-xl font-bold text-red-400">0</p>
                <p className="text-xs text-muted">Overdue / Missing</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-3 text-center">
                <p className="text-xl font-bold text-amber-400">0</p>
                <p className="text-xs text-muted">Payment w/o Waiver</p>
              </CardContent>
            </Card>
          </div>

          {/* Empty State */}
          <Card>
            <CardContent className="p-12 text-center">
              <ClipboardCheck className="h-14 w-14 text-muted opacity-40 mx-auto mb-4" />
              <p className="text-main font-semibold text-lg">No lien waivers tracked yet</p>
              <p className="text-sm text-muted mt-2 max-w-md mx-auto">
                Waivers will appear here as you manage liens on your jobs. Track conditional and unconditional progress and final waivers for all subcontractors and suppliers.
              </p>
              <div className="mt-6 grid grid-cols-1 md:grid-cols-4 gap-3 max-w-2xl mx-auto">
                {(['Conditional Progress', 'Unconditional Progress', 'Conditional Final', 'Unconditional Final'] as const).map(type => (
                  <div key={type} className="p-3 rounded-lg bg-secondary/50 border border-main text-center">
                    <p className="text-xs font-medium text-main">{type}</p>
                    <p className="text-xs text-muted mt-1">Waiver</p>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* ═══════════════════════════════════════════════════════ */}
      {/* ── TAB: DEADLINES ──────────────────────────────────── */}
      {/* ═══════════════════════════════════════════════════════ */}
      {activeTab === 'deadlines' && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-semibold text-main">Deadline Calendar</h2>
              <p className="text-sm text-muted">Auto-calculated lien deadlines with urgency alerts</p>
            </div>
          </div>

          {/* Urgency Summary Cards */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
            <button onClick={() => setDeadlineFilter('overdue')} className="text-left">
              <Card className={`${deadlineFilter === 'overdue' ? 'border-red-500/50' : ''} hover:border-accent/30 transition-colors`}>
                <CardContent className="p-3">
                  <div className="flex items-center gap-2">
                    <div className="p-1.5 rounded bg-red-500/10">
                      <XCircle className="h-4 w-4 text-red-400" />
                    </div>
                    <div>
                      <p className="text-lg font-bold text-red-400">{overdueCount}</p>
                      <p className="text-xs text-muted">Overdue</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </button>
            <button onClick={() => setDeadlineFilter('critical')} className="text-left">
              <Card className={`${deadlineFilter === 'critical' ? 'border-red-500/50' : ''} hover:border-accent/30 transition-colors`}>
                <CardContent className="p-3">
                  <div className="flex items-center gap-2">
                    <div className="p-1.5 rounded bg-red-500/10">
                      <AlertTriangle className="h-4 w-4 text-red-400" />
                    </div>
                    <div>
                      <p className="text-lg font-bold text-red-400">{criticalCount}</p>
                      <p className="text-xs text-muted">Critical (0-7d)</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </button>
            <button onClick={() => setDeadlineFilter('urgent')} className="text-left">
              <Card className={`${deadlineFilter === 'urgent' ? 'border-amber-500/50' : ''} hover:border-accent/30 transition-colors`}>
                <CardContent className="p-3">
                  <div className="flex items-center gap-2">
                    <div className="p-1.5 rounded bg-amber-500/10">
                      <Clock className="h-4 w-4 text-amber-400" />
                    </div>
                    <div>
                      <p className="text-lg font-bold text-amber-400">{urgentDeadlineCount}</p>
                      <p className="text-xs text-muted">Urgent (8-14d)</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </button>
            <button onClick={() => setDeadlineFilter(deadlineFilter === 'all' ? 'upcoming' : 'all')} className="text-left">
              <Card className={`${deadlineFilter === 'upcoming' || deadlineFilter === 'all' ? 'border-accent/30' : ''} hover:border-accent/30 transition-colors`}>
                <CardContent className="p-3">
                  <div className="flex items-center gap-2">
                    <div className="p-1.5 rounded bg-blue-500/10">
                      <Calendar className="h-4 w-4 text-blue-400" />
                    </div>
                    <div>
                      <p className="text-lg font-bold text-blue-400">{upcomingCount}</p>
                      <p className="text-xs text-muted">Upcoming (15+d)</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </button>
          </div>

          {/* Active Filter Indicator */}
          {deadlineFilter !== 'all' && (
            <div className="flex items-center gap-2">
              <Badge variant="info" size="sm">Filtered: {deadlineFilter}</Badge>
              <button onClick={() => setDeadlineFilter('all')} className="text-xs text-muted hover:text-main">
                Clear filter
              </button>
            </div>
          )}

          <SearchInput
            placeholder="Search deadlines by job, address, or state..."
            value={searchQuery}
            onChange={setSearchQuery}
          />

          {/* Deadline List */}
          {filteredDeadlines.length === 0 ? (
            <Card>
              <CardContent className="p-8 text-center">
                <CalendarClock className="h-12 w-12 text-muted opacity-50 mx-auto mb-3" />
                <p className="text-muted font-medium">
                  {derivedDeadlines.length === 0
                    ? 'No lien deadlines to track'
                    : 'No deadlines match your filters'}
                </p>
                {derivedDeadlines.length === 0 && (
                  <p className="text-sm text-muted mt-1">Deadlines are auto-calculated when liens have work dates and matching state rules.</p>
                )}
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-2">
              {filteredDeadlines
                .sort((a, b) => a.daysRemaining - b.daysRemaining)
                .map(deadline => {
                  const typeLabels: Record<string, string> = {
                    preliminary_notice: 'Preliminary Notice',
                    lien_filing: 'Lien Filing',
                    lien_enforcement: 'Lien Enforcement',
                    notice_of_intent: 'Notice of Intent',
                  };
                  const typeIcons: Record<string, React.ComponentType<{ className?: string }>> = {
                    preliminary_notice: Send,
                    lien_filing: Gavel,
                    lien_enforcement: Scale,
                    notice_of_intent: FileText,
                  };
                  const TypeIcon = typeIcons[deadline.deadlineType] || FileText;

                  return (
                    <Card key={deadline.id} className={`${
                      deadline.status === 'overdue' ? 'border-red-500/30' :
                      deadline.status === 'critical' ? 'border-red-500/20' :
                      ''
                    }`}>
                      <CardContent className="p-4">
                        <div className="flex items-start justify-between gap-4">
                          <div className="flex items-start gap-3 flex-1 min-w-0">
                            <div className={`p-2 rounded-lg mt-0.5 ${
                              deadline.status === 'overdue' ? 'bg-red-500/10' :
                              deadline.status === 'critical' ? 'bg-red-500/10' :
                              deadline.status === 'urgent' ? 'bg-amber-500/10' :
                              'bg-secondary'
                            }`}>
                              <TypeIcon className={`h-4 w-4 ${
                                deadline.status === 'overdue' || deadline.status === 'critical' ? 'text-red-400' :
                                deadline.status === 'urgent' ? 'text-amber-400' :
                                'text-blue-400'
                              }`} />
                            </div>
                            <div className="flex-1 min-w-0">
                              <div className="flex items-center gap-2 flex-wrap">
                                <h3 className="text-sm font-semibold text-main">{deadline.jobName}</h3>
                                <Badge variant={urgencyVariant(deadline.daysRemaining)} size="sm">
                                  {typeLabels[deadline.deadlineType]}
                                </Badge>
                                {deadline.status === 'overdue' && (
                                  <Badge variant="error" size="sm">OVERDUE</Badge>
                                )}
                              </div>
                              <div className="flex items-center gap-3 mt-1 text-xs text-muted">
                                <span className="flex items-center gap-1">
                                  <MapPin className="h-3 w-3" />{deadline.propertyAddress}
                                </span>
                                <span className="flex items-center gap-1">
                                  <Landmark className="h-3 w-3" />{deadline.stateCode}
                                </span>
                              </div>

                              {/* Timeline bar */}
                              <div className="mt-3 max-w-sm">
                                <DeadlineTimeline
                                  daysRemaining={deadline.daysRemaining}
                                  label={`Deadline: ${deadline.deadlineDate}`}
                                />
                              </div>

                              {/* Urgency Alerts */}
                              {deadline.daysRemaining <= 7 && deadline.daysRemaining > 0 && (
                                <div className="flex items-center gap-4 mt-2 text-xs">
                                  {[30, 14, 7, 3, 1].filter(d => d >= deadline.daysRemaining).map(d => (
                                    <span key={d} className={`flex items-center gap-1 ${
                                      d <= 3 ? 'text-red-400' : d <= 7 ? 'text-red-400' : d <= 14 ? 'text-amber-400' : 'text-blue-400'
                                    }`}>
                                      <Bell className="h-3 w-3" />
                                      {d}d alert triggered
                                    </span>
                                  ))}
                                </div>
                              )}
                            </div>
                          </div>
                          <div className="text-right flex-shrink-0">
                            <p className={`text-lg font-bold ${urgencyColor(deadline.daysRemaining)}`}>
                              {deadline.daysRemaining <= 0
                                ? `${Math.abs(deadline.daysRemaining)}d late`
                                : `${deadline.daysRemaining}d`
                              }
                            </p>
                            <p className="text-xs text-muted mt-0.5">
                              {formatCurrency(deadline.amountAtRisk)} at risk
                            </p>
                            <Button variant="ghost" className="mt-2 h-7 text-xs gap-1 px-2">
                              <Eye className="h-3 w-3" />
                              View
                            </Button>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  );
                })}
            </div>
          )}

          {/* Total At Risk Summary */}
          <Card>
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <DollarSign className="h-5 w-5 text-amber-400" />
                  <span className="text-sm font-medium text-main">Total Amount at Risk (Filtered)</span>
                </div>
                <span className="text-xl font-bold text-amber-400">
                  {formatCurrency(filteredDeadlines.reduce((s, d) => s + d.amountAtRisk, 0))}
                </span>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* ═══════════════════════════════════════════════════════ */}
      {/* ── TAB: NOTICES ────────────────────────────────────── */}
      {/* ═══════════════════════════════════════════════════════ */}
      {activeTab === 'notices' && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-semibold text-main">Preliminary Notice Generation</h2>
              <p className="text-sm text-muted">Generate, track, and send preliminary notices pre-filled from job data</p>
            </div>
            <Button variant="primary" className="gap-2">
              <FilePlus className="h-4 w-4" />
              Generate Notice
            </Button>
          </div>

          {/* Notice Stats */}
          <div className="grid grid-cols-2 lg:grid-cols-5 gap-3">
            <Card>
              <CardContent className="p-3 text-center">
                <p className="text-xl font-bold text-main">{derivedNotices.length}</p>
                <p className="text-xs text-muted">Total Notices</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-3 text-center">
                <p className="text-xl font-bold text-muted">{derivedNotices.filter(n => n.status === 'draft').length}</p>
                <p className="text-xs text-muted">Drafts</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-3 text-center">
                <p className="text-xl font-bold text-blue-400">{derivedNotices.filter(n => n.status === 'generated').length}</p>
                <p className="text-xs text-muted">Generated</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-3 text-center">
                <p className="text-xl font-bold text-amber-400">{derivedNotices.filter(n => n.status === 'sent').length}</p>
                <p className="text-xs text-muted">Sent</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-3 text-center">
                <p className="text-xl font-bold text-emerald-400">{derivedNotices.filter(n => n.status === 'confirmed').length}</p>
                <p className="text-xs text-muted">Confirmed</p>
              </CardContent>
            </Card>
          </div>

          {/* Filter Pills */}
          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-xs text-muted mr-1">Filter:</span>
            {([
              { key: 'all', label: 'All' },
              { key: 'draft', label: 'Draft' },
              { key: 'generated', label: 'Generated' },
              { key: 'sent', label: 'Sent' },
              { key: 'confirmed', label: 'Confirmed' },
              { key: 'expired', label: 'Expired' },
            ] as { key: typeof noticeFilter; label: string }[]).map(f => (
              <button
                key={f.key}
                onClick={() => setNoticeFilter(f.key)}
                className={`text-xs px-3 py-1 rounded-full border transition-colors ${
                  noticeFilter === f.key
                    ? 'border-blue-500 bg-blue-500/10 text-blue-400'
                    : 'border-main text-muted hover:border-accent/30'
                }`}
              >
                {f.label}
              </button>
            ))}
          </div>

          <SearchInput
            placeholder="Search by address or state..."
            value={searchQuery}
            onChange={setSearchQuery}
          />

          {/* Notice List */}
          {filteredNotices.length === 0 ? (
            <Card>
              <CardContent className="p-8 text-center">
                <Send className="h-12 w-12 text-muted opacity-50 mx-auto mb-3" />
                <p className="text-muted font-medium">
                  {derivedNotices.length === 0
                    ? 'No preliminary notices required yet'
                    : 'No notices match your filters'}
                </p>
                {derivedNotices.length === 0 && (
                  <p className="text-sm text-muted mt-1">Preliminary notices will appear here for liens in states that require them.</p>
                )}
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-2">
              {filteredNotices.map(notice => {
                const statusConfig: Record<string, { variant: 'success' | 'info' | 'warning' | 'error' | 'secondary' | 'default'; label: string }> = {
                  draft: { variant: 'secondary', label: 'Draft' },
                  generated: { variant: 'info', label: 'Generated' },
                  sent: { variant: 'warning', label: 'Sent' },
                  confirmed: { variant: 'success', label: 'Confirmed' },
                  expired: { variant: 'error', label: 'Expired' },
                };
                const cfg = statusConfig[notice.status] || statusConfig.draft;

                return (
                  <Card key={notice.id}>
                    <CardContent className="p-4">
                      <div className="flex items-start justify-between gap-4">
                        <div className="flex items-start gap-3 flex-1 min-w-0">
                          <div className={`p-2 rounded-lg mt-0.5 ${
                            notice.status === 'confirmed' ? 'bg-emerald-500/10' :
                            notice.status === 'sent' ? 'bg-amber-500/10' :
                            notice.status === 'generated' ? 'bg-blue-500/10' :
                            'bg-secondary'
                          }`}>
                            <Send className={`h-4 w-4 ${
                              notice.status === 'confirmed' ? 'text-emerald-400' :
                              notice.status === 'sent' ? 'text-amber-400' :
                              notice.status === 'generated' ? 'text-blue-400' :
                              'text-muted'
                            }`} />
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2 flex-wrap">
                              <h3 className="text-sm font-semibold text-main">{notice.propertyAddress}</h3>
                              <Badge variant={cfg.variant} size="sm">{cfg.label}</Badge>
                              <Badge variant="secondary" size="sm">{notice.stateCode}</Badge>
                            </div>

                            {/* Property */}
                            <div className="flex items-center gap-3 mt-1.5 text-xs text-muted flex-wrap">
                              <span className="flex items-center gap-1">
                                <MapPin className="h-3 w-3" />{notice.stateCode}
                              </span>
                            </div>

                            {/* Key Dates & Amount */}
                            <div className="flex items-center gap-4 mt-2 text-xs flex-wrap">
                              {notice.firstFurnishingDate && (
                                <span className="text-muted">
                                  First furnishing: <span className="text-main">{notice.firstFurnishingDate}</span>
                                </span>
                              )}
                              {notice.noticeDeadline && (
                                <span className="text-muted">
                                  Deadline: <span className={`font-medium ${
                                    new Date(notice.noticeDeadline) < new Date() ? 'text-red-400' : 'text-main'
                                  }`}>{notice.noticeDeadline}</span>
                                </span>
                              )}
                              {notice.amountDue > 0 && (
                                <span className="text-amber-400 font-medium">
                                  {formatCurrency(notice.amountDue)} due
                                </span>
                              )}
                            </div>
                          </div>
                        </div>

                        <div className="flex flex-col items-end gap-2 flex-shrink-0">
                          {notice.noticeSentDate && (
                            <p className="text-xs text-muted">
                              Sent: <span className="text-main">{notice.noticeSentDate}</span>
                            </p>
                          )}
                          <div className="flex items-center gap-2">
                            {notice.status === 'draft' && (
                              <Button variant="primary" className="h-7 text-xs gap-1 px-2">
                                <FilePlus className="h-3 w-3" />
                                Generate
                              </Button>
                            )}
                            {notice.status === 'generated' && (
                              <Button variant="primary" className="h-7 text-xs gap-1 px-2">
                                <Send className="h-3 w-3" />
                                Send
                              </Button>
                            )}
                            {(notice.status === 'sent' || notice.status === 'confirmed') && (
                              <Button variant="ghost" className="h-7 text-xs gap-1 px-2">
                                <Download className="h-3 w-3" />
                                PDF
                              </Button>
                            )}
                            <Button variant="ghost" className="h-7 text-xs gap-1 px-2">
                              <Eye className="h-3 w-3" />
                              View
                            </Button>
                          </div>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          )}

          {/* Lien Filing Preparation Section */}
          <Card>
            <CardHeader>
              <CardTitle className="text-sm font-semibold text-main flex items-center gap-2">
                <Gavel className="h-4 w-4 text-amber-400" />
                Lien Filing Preparation
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <p className="text-sm text-muted">
                When a payment dispute cannot be resolved and deadlines are approaching, prepare a formal mechanic&apos;s lien filing with all required information from the job record.
              </p>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                <div className="p-3 rounded-lg bg-secondary/50 border border-main">
                  <div className="flex items-center gap-2 mb-2">
                    <FileText className="h-4 w-4 text-blue-400" />
                    <span className="text-xs font-semibold text-blue-400">Step 1</span>
                  </div>
                  <p className="text-sm text-main font-medium">Verify Job Data</p>
                  <p className="text-xs text-muted mt-1">Property address, owner info, work dates, and amounts are pulled from the job record automatically.</p>
                </div>
                <div className="p-3 rounded-lg bg-secondary/50 border border-main">
                  <div className="flex items-center gap-2 mb-2">
                    <Download className="h-4 w-4 text-amber-400" />
                    <span className="text-xs font-semibold text-amber-400">Step 2</span>
                  </div>
                  <p className="text-sm text-main font-medium">Generate Lien Document</p>
                  <p className="text-xs text-muted mt-1">State-specific lien form is generated with all required fields, legal descriptions, and statutory references.</p>
                </div>
                <div className="p-3 rounded-lg bg-secondary/50 border border-main">
                  <div className="flex items-center gap-2 mb-2">
                    <Landmark className="h-4 w-4 text-emerald-400" />
                    <span className="text-xs font-semibold text-emerald-400">Step 3</span>
                  </div>
                  <p className="text-sm text-main font-medium">File with County</p>
                  <p className="text-xs text-muted mt-1">Filing instructions for the specific state recording office, with notarization requirements if applicable.</p>
                </div>
              </div>
              <div className="flex items-center gap-2 pt-2">
                <Button variant="outline" className="gap-2">
                  <Gavel className="h-4 w-4" />
                  Prepare Lien Filing
                </Button>
                <span className="text-xs text-muted">Select a job with outstanding payment to begin</span>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}
