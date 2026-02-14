'use client';

import { useState } from 'react';
import {
  Shield,
  ShieldAlert,
  ShieldCheck,
  Clock,
  AlertTriangle,
  CheckCircle,
  XCircle,
  DollarSign,
  Send,
  ChevronRight,
  Search,
  Filter,
  BarChart3,
  Wrench,
  Bell,
  FileText,
  ExternalLink,
  Loader2,
  RefreshCw,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import {
  useWarrantyIntelligence,
  type EquipmentWarranty,
  type WarrantyClaim,
  type OutreachLog,
  type ProductRecall,
  type ClaimStatus,
} from '@/lib/hooks/use-warranty-intelligence';

type ViewTab = 'dashboard' | 'equipment' | 'claims' | 'outreach' | 'recalls';

export default function WarrantyIntelligencePage() {
  const {
    equipment,
    claims,
    outreach,
    recalls,
    loading,
    error,
    stats,
    expiringEquipment,
    recalledEquipment,
    createClaim,
    updateClaimStatus,
    refresh,
  } = useWarrantyIntelligence();

  const [activeTab, setActiveTab] = useState<ViewTab>('dashboard');
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedEquipment, setSelectedEquipment] = useState<EquipmentWarranty | null>(null);
  const [showClaimModal, setShowClaimModal] = useState(false);

  // Filter equipment
  const filteredEquipment = equipment.filter(e => {
    const matchesSearch = !searchQuery ||
      e.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (e.manufacturer?.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (e.customerName?.toLowerCase().includes(searchQuery.toLowerCase()));
    const matchesStatus = statusFilter === 'all' || e.warrantyStatus === statusFilter;
    return matchesSearch && matchesStatus;
  });

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <Loader2 className="w-8 h-8 animate-spin text-zinc-400" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-96 gap-4">
        <AlertTriangle className="w-12 h-12 text-red-400" />
        <p className="text-zinc-400">{error}</p>
        <Button onClick={refresh} variant="outline" size="sm">
          <RefreshCw className="w-4 h-4 mr-2" /> Retry
        </Button>
      </div>
    );
  }

  return (
    <>
      <CommandPalette />
      <div className="space-y-6 p-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-zinc-100">Warranty Intelligence</h1>
            <p className="text-sm text-zinc-400 mt-1">
              Track equipment warranties, claims, recalls, and outreach
            </p>
          </div>
          <Button onClick={refresh} variant="outline" size="sm">
            <RefreshCw className="w-4 h-4 mr-2" /> Refresh
          </Button>
        </div>

        {/* Tab Bar */}
        <div className="flex gap-1 border-b border-zinc-800 pb-px">
          {([
            { key: 'dashboard', label: 'Dashboard', icon: BarChart3 },
            { key: 'equipment', label: 'Equipment', icon: Shield },
            { key: 'claims', label: 'Claims', icon: FileText },
            { key: 'outreach', label: 'Outreach', icon: Send },
            { key: 'recalls', label: 'Recalls', icon: AlertTriangle },
          ] as const).map(tab => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={cn(
                'flex items-center gap-2 px-4 py-2.5 text-sm font-medium rounded-t-lg transition-colors',
                activeTab === tab.key
                  ? 'bg-zinc-800 text-zinc-100 border-b-2 border-blue-500'
                  : 'text-zinc-400 hover:text-zinc-200 hover:bg-zinc-800/50'
              )}
            >
              <tab.icon className="w-4 h-4" />
              {tab.label}
              {tab.key === 'claims' && stats.openClaims > 0 && (
                <span className="ml-1 px-1.5 py-0.5 text-xs bg-yellow-500/20 text-yellow-400 rounded-full">
                  {stats.openClaims}
                </span>
              )}
              {tab.key === 'recalls' && stats.activeRecalls > 0 && (
                <span className="ml-1 px-1.5 py-0.5 text-xs bg-red-500/20 text-red-400 rounded-full">
                  {stats.activeRecalls}
                </span>
              )}
            </button>
          ))}
        </div>

        {/* Dashboard Tab */}
        {activeTab === 'dashboard' && (
          <DashboardView
            stats={stats}
            expiringEquipment={expiringEquipment}
            recalledEquipment={recalledEquipment}
            recentClaims={claims.slice(0, 5)}
            recentOutreach={outreach.slice(0, 5)}
            onViewEquipment={(eq) => { setSelectedEquipment(eq); setActiveTab('equipment'); }}
          />
        )}

        {/* Equipment Tab */}
        {activeTab === 'equipment' && (
          <EquipmentView
            equipment={filteredEquipment}
            searchQuery={searchQuery}
            onSearchChange={setSearchQuery}
            statusFilter={statusFilter}
            onStatusChange={setStatusFilter}
            selectedEquipment={selectedEquipment}
            onSelectEquipment={setSelectedEquipment}
            onFileClaim={(eq) => { setSelectedEquipment(eq); setShowClaimModal(true); }}
          />
        )}

        {/* Claims Tab */}
        {activeTab === 'claims' && (
          <ClaimsView
            claims={claims}
            onUpdateStatus={updateClaimStatus}
          />
        )}

        {/* Outreach Tab */}
        {activeTab === 'outreach' && (
          <OutreachView outreach={outreach} />
        )}

        {/* Recalls Tab */}
        {activeTab === 'recalls' && (
          <RecallsView
            recalls={recalls}
            affectedCount={stats.activeRecalls}
          />
        )}
      </div>

      {/* Claim Modal */}
      {showClaimModal && selectedEquipment && (
        <ClaimModal
          equipment={selectedEquipment}
          onClose={() => setShowClaimModal(false)}
          onSubmit={async (reason, amount) => {
            await createClaim({
              equipmentId: selectedEquipment.id,
              claimReason: reason,
              amountClaimed: amount,
            });
            setShowClaimModal(false);
          }}
        />
      )}
    </>
  );
}

// ── Dashboard View ──────────────────────────────────────

function DashboardView({
  stats,
  expiringEquipment,
  recalledEquipment,
  recentClaims,
  recentOutreach,
  onViewEquipment,
}: {
  stats: ReturnType<typeof useWarrantyIntelligence>['stats'];
  expiringEquipment: EquipmentWarranty[];
  recalledEquipment: EquipmentWarranty[];
  recentClaims: WarrantyClaim[];
  recentOutreach: OutreachLog[];
  onViewEquipment: (eq: EquipmentWarranty) => void;
}) {
  return (
    <div className="space-y-6">
      {/* Stat Cards */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
        <StatCard icon={Shield} label="Total Equipment" value={stats.totalEquipment} color="blue" />
        <StatCard icon={ShieldCheck} label="Active Warranties" value={stats.activeWarranties} color="green" />
        <StatCard icon={Clock} label="Expiring Soon" value={stats.expiringSoon} color="yellow" />
        <StatCard icon={FileText} label="Open Claims" value={stats.openClaims} color="orange" />
        <StatCard icon={DollarSign} label="Claims Approved" value={formatCurrency(stats.approvedClaimValue)} color="green" />
      </div>

      {/* Alerts Row */}
      {(recalledEquipment.length > 0 || stats.expiringSoon > 0) && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {recalledEquipment.length > 0 && (
            <Card className="border-red-500/30 bg-red-500/5">
              <CardHeader className="pb-3">
                <CardTitle className="text-sm font-medium text-red-400 flex items-center gap-2">
                  <AlertTriangle className="w-4 h-4" /> Active Recalls ({recalledEquipment.length})
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                {recalledEquipment.slice(0, 3).map(eq => (
                  <button
                    key={eq.id}
                    onClick={() => onViewEquipment(eq)}
                    className="flex items-center justify-between w-full p-2 rounded-lg hover:bg-red-500/10 transition-colors text-left"
                  >
                    <div>
                      <p className="text-sm font-medium text-zinc-200">{eq.name}</p>
                      <p className="text-xs text-zinc-400">{eq.manufacturer} — {eq.customerName}</p>
                    </div>
                    <ChevronRight className="w-4 h-4 text-zinc-500" />
                  </button>
                ))}
              </CardContent>
            </Card>
          )}

          {stats.expiringSoon > 0 && (
            <Card className="border-yellow-500/30 bg-yellow-500/5">
              <CardHeader className="pb-3">
                <CardTitle className="text-sm font-medium text-yellow-400 flex items-center gap-2">
                  <Clock className="w-4 h-4" /> Expiring Soon ({stats.expiringSoon})
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                {expiringEquipment.slice(0, 3).map(eq => (
                  <button
                    key={eq.id}
                    onClick={() => onViewEquipment(eq)}
                    className="flex items-center justify-between w-full p-2 rounded-lg hover:bg-yellow-500/10 transition-colors text-left"
                  >
                    <div>
                      <p className="text-sm font-medium text-zinc-200">{eq.name}</p>
                      <p className="text-xs text-zinc-400">
                        {eq.daysRemaining} days — {eq.customerName}
                      </p>
                    </div>
                    <ChevronRight className="w-4 h-4 text-zinc-500" />
                  </button>
                ))}
              </CardContent>
            </Card>
          )}
        </div>
      )}

      {/* Recent Activity */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Recent Claims */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-sm font-medium text-zinc-300">Recent Claims</CardTitle>
          </CardHeader>
          <CardContent>
            {recentClaims.length === 0 ? (
              <p className="text-sm text-zinc-500 text-center py-4">No claims filed</p>
            ) : (
              <div className="space-y-2">
                {recentClaims.map(claim => (
                  <div key={claim.id} className="flex items-center justify-between p-2 rounded-lg bg-zinc-800/50">
                    <div>
                      <p className="text-sm text-zinc-200">{claim.claimReason}</p>
                      <p className="text-xs text-zinc-400">{claim.equipmentName} — {formatDate(claim.claimDate)}</p>
                    </div>
                    <ClaimStatusBadge status={claim.claimStatus} />
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Recent Outreach */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-sm font-medium text-zinc-300">Recent Outreach</CardTitle>
          </CardHeader>
          <CardContent>
            {recentOutreach.length === 0 ? (
              <p className="text-sm text-zinc-500 text-center py-4">No outreach sent</p>
            ) : (
              <div className="space-y-2">
                {recentOutreach.map(log => (
                  <div key={log.id} className="flex items-center justify-between p-2 rounded-lg bg-zinc-800/50">
                    <div>
                      <p className="text-sm text-zinc-200">{outreachTypeLabel(log.outreachType)}</p>
                      <p className="text-xs text-zinc-400">{log.customerName} — {log.sentAt ? formatDate(log.sentAt) : 'Pending'}</p>
                    </div>
                    {log.responseStatus && <ResponseBadge status={log.responseStatus} />}
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Outreach Pipeline Stats */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-sm font-medium text-zinc-300">Outreach Pipeline</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-3 gap-4">
            <div className="text-center p-4 rounded-lg bg-zinc-800/50">
              <p className="text-2xl font-bold text-blue-400">{stats.outreachPendingCount}</p>
              <p className="text-xs text-zinc-400 mt-1">Pending</p>
            </div>
            <div className="text-center p-4 rounded-lg bg-zinc-800/50">
              <p className="text-2xl font-bold text-green-400">{stats.outreachBookedCount}</p>
              <p className="text-xs text-zinc-400 mt-1">Booked</p>
            </div>
            <div className="text-center p-4 rounded-lg bg-zinc-800/50">
              <p className="text-2xl font-bold text-emerald-400">
                {formatCurrency(stats.outreachBookedCount * 350)}
              </p>
              <p className="text-xs text-zinc-400 mt-1">Est. Revenue</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ── Equipment View ──────────────────────────────────────

function EquipmentView({
  equipment,
  searchQuery,
  onSearchChange,
  statusFilter,
  onStatusChange,
  selectedEquipment,
  onSelectEquipment,
  onFileClaim,
}: {
  equipment: EquipmentWarranty[];
  searchQuery: string;
  onSearchChange: (q: string) => void;
  statusFilter: string;
  onStatusChange: (s: string) => void;
  selectedEquipment: EquipmentWarranty | null;
  onSelectEquipment: (eq: EquipmentWarranty | null) => void;
  onFileClaim: (eq: EquipmentWarranty) => void;
}) {
  return (
    <div className="space-y-4">
      {/* Filters */}
      <div className="flex gap-3">
        <SearchInput
          placeholder="Search equipment, manufacturer, customer..."
          value={searchQuery}
          onChange={onSearchChange}
          className="flex-1"
        />
        <Select
          value={statusFilter}
          onChange={(e) => onStatusChange(e.target.value)}
          className="w-48"
          options={[
            { value: 'all', label: 'All Status' },
            { value: 'active', label: 'Active' },
            { value: 'expiring_soon', label: 'Expiring Soon' },
            { value: 'expired', label: 'Expired' },
            { value: 'no_warranty', label: 'No Warranty' },
          ]}
        />
      </div>

      {/* Equipment Table */}
      {equipment.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16">
          <Shield className="w-12 h-12 text-zinc-600 mb-3" />
          <p className="text-zinc-400">No equipment found</p>
        </div>
      ) : (
        <div className="border border-zinc-800 rounded-lg overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-zinc-800/50">
              <tr>
                <th className="text-left px-4 py-3 text-zinc-400 font-medium">Equipment</th>
                <th className="text-left px-4 py-3 text-zinc-400 font-medium">Customer</th>
                <th className="text-left px-4 py-3 text-zinc-400 font-medium">Warranty</th>
                <th className="text-left px-4 py-3 text-zinc-400 font-medium">Status</th>
                <th className="text-right px-4 py-3 text-zinc-400 font-medium">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-800">
              {equipment.map(eq => (
                <tr key={eq.id} className="hover:bg-zinc-800/30 transition-colors">
                  <td className="px-4 py-3">
                    <div>
                      <p className="text-zinc-200 font-medium">{eq.name}</p>
                      <p className="text-xs text-zinc-500">
                        {[eq.manufacturer, eq.modelNumber].filter(Boolean).join(' — ')}
                      </p>
                      {eq.serialNumber && (
                        <p className="text-xs text-zinc-600">SN: {eq.serialNumber}</p>
                      )}
                    </div>
                  </td>
                  <td className="px-4 py-3 text-zinc-400">{eq.customerName || '—'}</td>
                  <td className="px-4 py-3">
                    <div>
                      <p className="text-zinc-300 text-xs">
                        {eq.warrantyType ? warrantyTypeLabel(eq.warrantyType) : '—'}
                      </p>
                      {eq.warrantyEndDate && (
                        <p className="text-xs text-zinc-500">Expires {formatDate(eq.warrantyEndDate)}</p>
                      )}
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <WarrantyStatusBadge status={eq.warrantyStatus} daysRemaining={eq.daysRemaining} />
                    {eq.recallStatus === 'active' && (
                      <Badge className="ml-1 bg-red-500/20 text-red-400 text-[10px]">RECALL</Badge>
                    )}
                  </td>
                  <td className="px-4 py-3 text-right">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => onFileClaim(eq)}
                      className="text-xs"
                    >
                      File Claim
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

// ── Claims View ─────────────────────────────────────────

function ClaimsView({
  claims,
  onUpdateStatus,
}: {
  claims: WarrantyClaim[];
  onUpdateStatus: (id: string, status: ClaimStatus, opts?: { resolutionNotes?: string; amountApproved?: number }) => Promise<void>;
}) {
  const [filter, setFilter] = useState<string>('all');

  const filtered = claims.filter(c => filter === 'all' || c.claimStatus === filter);

  return (
    <div className="space-y-4">
      <div className="flex gap-2">
        {['all', 'submitted', 'under_review', 'approved', 'denied', 'resolved', 'closed'].map(s => (
          <button
            key={s}
            onClick={() => setFilter(s)}
            className={cn(
              'px-3 py-1.5 text-xs rounded-full transition-colors',
              filter === s
                ? 'bg-blue-500/20 text-blue-400'
                : 'bg-zinc-800 text-zinc-400 hover:text-zinc-200'
            )}
          >
            {s === 'all' ? 'All' : s.replace('_', ' ').replace(/\b\w/g, c => c.toUpperCase())}
          </button>
        ))}
      </div>

      {filtered.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16">
          <FileText className="w-12 h-12 text-zinc-600 mb-3" />
          <p className="text-zinc-400">No claims found</p>
        </div>
      ) : (
        <div className="space-y-3">
          {filtered.map(claim => (
            <Card key={claim.id}>
              <CardContent className="p-4">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <p className="text-sm font-medium text-zinc-200">{claim.claimReason}</p>
                      <ClaimStatusBadge status={claim.claimStatus} />
                    </div>
                    <p className="text-xs text-zinc-400">
                      {claim.equipmentName} — Filed {formatDate(claim.claimDate)}
                      {claim.manufacturerClaimNumber && ` — Claim #${claim.manufacturerClaimNumber}`}
                    </p>
                    <div className="flex gap-4 mt-2 text-xs text-zinc-500">
                      {claim.amountClaimed != null && (
                        <span>Claimed: {formatCurrency(claim.amountClaimed)}</span>
                      )}
                      {claim.amountApproved != null && (
                        <span className="text-green-400">Approved: {formatCurrency(claim.amountApproved)}</span>
                      )}
                    </div>
                    {claim.resolutionNotes && (
                      <p className="text-xs text-zinc-400 mt-2 italic">{claim.resolutionNotes}</p>
                    )}
                  </div>
                  {(claim.claimStatus === 'submitted' || claim.claimStatus === 'under_review') && (
                    <div className="flex gap-1 ml-4">
                      {claim.claimStatus === 'submitted' && (
                        <Button
                          variant="outline"
                          size="sm"
                          className="text-xs"
                          onClick={() => onUpdateStatus(claim.id, 'under_review')}
                        >
                          Review
                        </Button>
                      )}
                      <Button
                        variant="outline"
                        size="sm"
                        className="text-xs text-green-400"
                        onClick={() => onUpdateStatus(claim.id, 'approved')}
                      >
                        Approve
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        className="text-xs text-red-400"
                        onClick={() => onUpdateStatus(claim.id, 'denied')}
                      >
                        Deny
                      </Button>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}

// ── Outreach View ───────────────────────────────────────

function OutreachView({ outreach }: { outreach: OutreachLog[] }) {
  return (
    <div className="space-y-4">
      {outreach.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16">
          <Send className="w-12 h-12 text-zinc-600 mb-3" />
          <p className="text-zinc-400">No outreach history</p>
          <p className="text-xs text-zinc-500 mt-1">Automated outreach will appear here when the scheduler runs</p>
        </div>
      ) : (
        <div className="border border-zinc-800 rounded-lg overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-zinc-800/50">
              <tr>
                <th className="text-left px-4 py-3 text-zinc-400 font-medium">Type</th>
                <th className="text-left px-4 py-3 text-zinc-400 font-medium">Customer</th>
                <th className="text-left px-4 py-3 text-zinc-400 font-medium">Equipment</th>
                <th className="text-left px-4 py-3 text-zinc-400 font-medium">Sent</th>
                <th className="text-left px-4 py-3 text-zinc-400 font-medium">Response</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-800">
              {outreach.map(log => (
                <tr key={log.id} className="hover:bg-zinc-800/30 transition-colors">
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <OutreachTypeIcon type={log.outreachType} />
                      <span className="text-zinc-200">{outreachTypeLabel(log.outreachType)}</span>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-zinc-400">{log.customerName || '—'}</td>
                  <td className="px-4 py-3 text-zinc-400">{log.equipmentName || '—'}</td>
                  <td className="px-4 py-3 text-zinc-400 text-xs">
                    {log.sentAt ? formatDate(log.sentAt) : 'Pending'}
                  </td>
                  <td className="px-4 py-3">
                    {log.responseStatus ? <ResponseBadge status={log.responseStatus} /> : <span className="text-zinc-600">—</span>}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

// ── Recalls View ────────────────────────────────────────

function RecallsView({ recalls, affectedCount }: { recalls: ProductRecall[]; affectedCount: number }) {
  return (
    <div className="space-y-4">
      {affectedCount > 0 && (
        <div className="flex items-center gap-2 p-3 rounded-lg bg-red-500/10 border border-red-500/20">
          <AlertTriangle className="w-5 h-5 text-red-400" />
          <p className="text-sm text-red-300">
            <strong>{affectedCount}</strong> of your installed equipment {affectedCount === 1 ? 'is' : 'are'} affected by active recalls
          </p>
        </div>
      )}

      {recalls.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16">
          <ShieldCheck className="w-12 h-12 text-zinc-600 mb-3" />
          <p className="text-zinc-400">No active recalls</p>
        </div>
      ) : (
        <div className="space-y-3">
          {recalls.map(recall => (
            <Card key={recall.id} className={cn(
              recall.severity === 'critical' && 'border-red-500/30',
              recall.severity === 'high' && 'border-orange-500/30',
            )}>
              <CardContent className="p-4">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <p className="text-sm font-medium text-zinc-200">{recall.recallTitle}</p>
                      <SeverityBadge severity={recall.severity} />
                    </div>
                    <p className="text-xs text-zinc-400">
                      {recall.manufacturer}
                      {recall.modelPattern && ` — Model: ${recall.modelPattern}`}
                      {' — '}Issued {formatDate(recall.recallDate)}
                    </p>
                    {recall.recallDescription && (
                      <p className="text-xs text-zinc-500 mt-2">{recall.recallDescription}</p>
                    )}
                    {recall.affectedSerialRange && (
                      <p className="text-xs text-zinc-500 mt-1">Serial range: {recall.affectedSerialRange}</p>
                    )}
                  </div>
                  {recall.sourceUrl && (
                    <a
                      href={recall.sourceUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-blue-400 hover:text-blue-300 ml-4"
                    >
                      <ExternalLink className="w-4 h-4" />
                    </a>
                  )}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}

// ── Claim Modal ─────────────────────────────────────────

function ClaimModal({
  equipment,
  onClose,
  onSubmit,
}: {
  equipment: EquipmentWarranty;
  onClose: () => void;
  onSubmit: (reason: string, amount?: number) => Promise<void>;
}) {
  const [reason, setReason] = useState('');
  const [amount, setAmount] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async () => {
    if (!reason.trim()) return;
    setSubmitting(true);
    try {
      await onSubmit(reason.trim(), amount ? parseFloat(amount) : undefined);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60" onClick={onClose}>
      <div className="bg-zinc-900 border border-zinc-700 rounded-xl p-6 w-full max-w-md" onClick={e => e.stopPropagation()}>
        <h2 className="text-lg font-semibold text-zinc-100 mb-1">File Warranty Claim</h2>
        <p className="text-sm text-zinc-400 mb-4">{equipment.name} — {equipment.manufacturer}</p>

        <div className="space-y-3">
          <div>
            <label className="block text-xs text-zinc-400 mb-1">Claim Reason *</label>
            <textarea
              value={reason}
              onChange={e => setReason(e.target.value)}
              placeholder="Describe the issue..."
              rows={3}
              className="w-full px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-sm text-zinc-200 placeholder:text-zinc-500 focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>
          <div>
            <label className="block text-xs text-zinc-400 mb-1">Amount Claimed ($)</label>
            <input
              type="number"
              value={amount}
              onChange={e => setAmount(e.target.value)}
              placeholder="0.00"
              step="0.01"
              min="0"
              className="w-full px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-sm text-zinc-200 placeholder:text-zinc-500 focus:ring-1 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>
        </div>

        <div className="flex justify-end gap-2 mt-5">
          <Button variant="outline" size="sm" onClick={onClose}>Cancel</Button>
          <Button
            size="sm"
            onClick={handleSubmit}
            disabled={!reason.trim() || submitting}
          >
            {submitting ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : null}
            Submit Claim
          </Button>
        </div>
      </div>
    </div>
  );
}

// ── Helper Components ───────────────────────────────────

function StatCard({ icon: Icon, label, value, color }: { icon: React.ComponentType<{ className?: string }>; label: string; value: string | number; color: string }) {
  const iconColors: Record<string, string> = {
    blue: 'text-blue-400', green: 'text-green-400', yellow: 'text-yellow-400',
    orange: 'text-orange-400', red: 'text-red-400',
  };
  const bgColors: Record<string, string> = {
    blue: 'bg-blue-500/10', green: 'bg-green-500/10', yellow: 'bg-yellow-500/10',
    orange: 'bg-orange-500/10', red: 'bg-red-500/10',
  };
  return (
    <Card>
      <CardContent className="p-4">
        <div className="flex items-center gap-3">
          <div className={cn('p-2 rounded-lg', bgColors[color] || bgColors.blue)}>
            <Icon className={cn('w-5 h-5', iconColors[color] || iconColors.blue)} />
          </div>
          <div>
            <p className="text-xl font-bold text-zinc-100">{value}</p>
            <p className="text-xs text-zinc-400">{label}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function WarrantyStatusBadge({ status, daysRemaining }: { status: string; daysRemaining: number | null }) {
  const config: Record<string, { bg: string; text: string; label: string }> = {
    active: { bg: 'bg-green-500/20', text: 'text-green-400', label: daysRemaining ? `${Math.round(daysRemaining / 30)}mo left` : 'Active' },
    expiring_soon: { bg: 'bg-yellow-500/20', text: 'text-yellow-400', label: daysRemaining != null ? `${daysRemaining}d left` : 'Expiring' },
    expired: { bg: 'bg-zinc-700/50', text: 'text-zinc-400', label: 'Expired' },
    no_warranty: { bg: 'bg-zinc-800', text: 'text-zinc-500', label: 'None' },
  };
  const c = config[status] || config.no_warranty;
  return <Badge className={cn(c.bg, c.text, 'text-[10px]')}>{c.label}</Badge>;
}

function ClaimStatusBadge({ status }: { status: ClaimStatus }) {
  const config: Record<ClaimStatus, { bg: string; text: string; label: string }> = {
    submitted: { bg: 'bg-blue-500/20', text: 'text-blue-400', label: 'Submitted' },
    under_review: { bg: 'bg-yellow-500/20', text: 'text-yellow-400', label: 'Under Review' },
    approved: { bg: 'bg-green-500/20', text: 'text-green-400', label: 'Approved' },
    denied: { bg: 'bg-red-500/20', text: 'text-red-400', label: 'Denied' },
    resolved: { bg: 'bg-emerald-500/20', text: 'text-emerald-400', label: 'Resolved' },
    closed: { bg: 'bg-zinc-700/50', text: 'text-zinc-400', label: 'Closed' },
  };
  const c = config[status] || config.submitted;
  return <Badge className={cn(c.bg, c.text, 'text-[10px]')}>{c.label}</Badge>;
}

function ResponseBadge({ status }: { status: string }) {
  const config: Record<string, { bg: string; text: string }> = {
    pending: { bg: 'bg-yellow-500/20', text: 'text-yellow-400' },
    opened: { bg: 'bg-blue-500/20', text: 'text-blue-400' },
    clicked: { bg: 'bg-blue-500/20', text: 'text-blue-400' },
    booked: { bg: 'bg-green-500/20', text: 'text-green-400' },
    declined: { bg: 'bg-red-500/20', text: 'text-red-400' },
    no_response: { bg: 'bg-zinc-700/50', text: 'text-zinc-400' },
  };
  const c = config[status] || config.pending;
  return (
    <Badge className={cn(c.bg, c.text, 'text-[10px]')}>
      {status.replace('_', ' ')}
    </Badge>
  );
}

function SeverityBadge({ severity }: { severity: string }) {
  const config: Record<string, { bg: string; text: string }> = {
    low: { bg: 'bg-zinc-700/50', text: 'text-zinc-400' },
    medium: { bg: 'bg-yellow-500/20', text: 'text-yellow-400' },
    high: { bg: 'bg-orange-500/20', text: 'text-orange-400' },
    critical: { bg: 'bg-red-500/20', text: 'text-red-400' },
  };
  const c = config[severity] || config.medium;
  return <Badge className={cn(c.bg, c.text, 'text-[10px]')}>{severity}</Badge>;
}

function OutreachTypeIcon({ type }: { type: string }) {
  switch (type) {
    case 'warranty_expiring': return <Clock className="w-4 h-4 text-yellow-400" />;
    case 'maintenance_reminder': return <Wrench className="w-4 h-4 text-blue-400" />;
    case 'recall_notice': return <AlertTriangle className="w-4 h-4 text-red-400" />;
    case 'upsell_extended': return <ShieldCheck className="w-4 h-4 text-green-400" />;
    case 'seasonal_check': return <Bell className="w-4 h-4 text-orange-400" />;
    default: return <Send className="w-4 h-4 text-zinc-400" />;
  }
}

function outreachTypeLabel(type: string): string {
  const labels: Record<string, string> = {
    warranty_expiring: 'Warranty Expiring',
    maintenance_reminder: 'Maintenance Reminder',
    recall_notice: 'Recall Notice',
    upsell_extended: 'Extended Warranty Upsell',
    seasonal_check: 'Seasonal Check',
  };
  return labels[type] || type;
}

function warrantyTypeLabel(type: string): string {
  const labels: Record<string, string> = {
    manufacturer: 'Manufacturer',
    extended: 'Extended',
    labor: 'Labor Only',
    parts_labor: 'Parts & Labor',
    home_warranty: 'Home Warranty',
  };
  return labels[type] || type;
}
