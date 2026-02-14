'use client';

import { Shield, ShieldCheck, Clock, AlertTriangle, Wrench, ChevronRight, Loader2, FileText, CheckCircle2 } from 'lucide-react';
import { useWarrantyPortfolio, type EquipmentWarranty, type WarrantyClaim } from '@/lib/hooks/use-warranty-portfolio';
import { useState } from 'react';

const warrantyTypeLabels: Record<string, string> = {
  manufacturer: 'Manufacturer',
  extended: 'Extended',
  labor: 'Labor Only',
  parts_labor: 'Parts & Labor',
  home_warranty: 'Home Warranty',
};

function formatDate(d: string): string {
  return new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

export default function WarrantiesPage() {
  const { equipment, claims, loading, error, activeCount, expiringCount, recallCount } = useWarrantyPortfolio();
  const [selectedId, setSelectedId] = useState<string | null>(null);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 size={24} className="animate-spin text-orange-500" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-64 gap-3">
        <AlertTriangle size={32} className="text-red-400" />
        <p className="text-gray-500 text-sm">{error}</p>
      </div>
    );
  }

  const selectedEquipment = selectedId ? equipment.find(e => e.id === selectedId) : null;
  const selectedClaims = selectedId ? claims.filter(c => c.equipmentId === selectedId) : [];

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">My Warranties</h1>
        <p className="text-sm text-gray-500 mt-1">Equipment installed in your home and warranty coverage</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-3">
        <div className="bg-white rounded-xl border border-gray-200 p-4 text-center">
          <div className="flex items-center justify-center mb-2">
            <div className="p-2 rounded-lg bg-green-50">
              <ShieldCheck size={20} className="text-green-600" />
            </div>
          </div>
          <p className="text-2xl font-bold text-gray-900">{activeCount}</p>
          <p className="text-xs text-gray-500">Active</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4 text-center">
          <div className="flex items-center justify-center mb-2">
            <div className="p-2 rounded-lg bg-amber-50">
              <Clock size={20} className="text-amber-600" />
            </div>
          </div>
          <p className="text-2xl font-bold text-gray-900">{expiringCount}</p>
          <p className="text-xs text-gray-500">Expiring Soon</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4 text-center">
          <div className="flex items-center justify-center mb-2">
            <div className="p-2 rounded-lg bg-red-50">
              <AlertTriangle size={20} className="text-red-600" />
            </div>
          </div>
          <p className="text-2xl font-bold text-gray-900">{recallCount}</p>
          <p className="text-xs text-gray-500">Recalls</p>
        </div>
      </div>

      {/* Recall Alert */}
      {recallCount > 0 && (
        <div className="flex items-center gap-3 p-3 bg-red-50 border border-red-200 rounded-xl">
          <AlertTriangle size={18} className="text-red-600 shrink-0" />
          <p className="text-sm text-red-700">
            <strong>{recallCount}</strong> {recallCount === 1 ? 'piece' : 'pieces'} of equipment {recallCount === 1 ? 'has' : 'have'} an active recall. Contact your contractor for service.
          </p>
        </div>
      )}

      {/* Equipment not found */}
      {equipment.length === 0 && (
        <div className="flex flex-col items-center justify-center py-16 text-center">
          <Shield size={48} className="text-gray-300 mb-3" />
          <p className="text-gray-600 font-medium">No Equipment Tracked</p>
          <p className="text-sm text-gray-400 mt-1">Equipment installed during service visits will appear here with warranty info.</p>
        </div>
      )}

      {/* Equipment List / Detail */}
      {selectedEquipment ? (
        <EquipmentDetail
          equipment={selectedEquipment}
          claims={selectedClaims}
          onBack={() => setSelectedId(null)}
        />
      ) : (
        <div className="space-y-2">
          {equipment.map(eq => (
            <EquipmentCard key={eq.id} equipment={eq} onClick={() => setSelectedId(eq.id)} />
          ))}
        </div>
      )}
    </div>
  );
}

// ── Equipment Card ──────────────────────────────────────

function EquipmentCard({ equipment, onClick }: { equipment: EquipmentWarranty; onClick: () => void }) {
  const statusConfig: Record<string, { color: string; bg: string; label: string }> = {
    active: { color: 'text-green-700', bg: 'bg-green-50 border-green-200', label: equipment.daysRemaining ? `${Math.round(equipment.daysRemaining / 30)}mo left` : 'Active' },
    expiring_soon: { color: 'text-amber-700', bg: 'bg-amber-50 border-amber-200', label: equipment.daysRemaining != null ? `${equipment.daysRemaining}d left` : 'Expiring' },
    expired: { color: 'text-gray-500', bg: 'bg-gray-50 border-gray-200', label: 'Expired' },
    no_warranty: { color: 'text-gray-400', bg: 'bg-gray-50 border-gray-200', label: 'No Warranty' },
  };
  const s = statusConfig[equipment.status];

  return (
    <button
      onClick={onClick}
      className="w-full bg-white rounded-xl border border-gray-200 p-4 text-left hover:border-orange-300 transition-colors"
    >
      <div className="flex items-center gap-3">
        {/* Status Indicator */}
        <div className={`w-1 h-12 rounded-full ${
          equipment.status === 'active' ? 'bg-green-500' :
          equipment.status === 'expiring_soon' ? 'bg-amber-500' :
          'bg-gray-300'
        }`} />

        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <p className="font-medium text-gray-900 truncate">{equipment.name}</p>
            {equipment.recallStatus === 'active' && (
              <span className="shrink-0 px-1.5 py-0.5 text-[10px] font-bold bg-red-100 text-red-700 rounded">RECALL</span>
            )}
          </div>
          <p className="text-xs text-gray-500 truncate">
            {[equipment.manufacturer, equipment.modelNumber].filter(Boolean).join(' — ')}
          </p>
        </div>

        <span className={`shrink-0 px-2 py-1 text-xs font-medium rounded-lg border ${s.bg} ${s.color}`}>
          {s.label}
        </span>
        <ChevronRight size={16} className="text-gray-400 shrink-0" />
      </div>
    </button>
  );
}

// ── Equipment Detail ────────────────────────────────────

function EquipmentDetail({
  equipment,
  claims,
  onBack,
}: {
  equipment: EquipmentWarranty;
  claims: WarrantyClaim[];
  onBack: () => void;
}) {
  return (
    <div className="space-y-4">
      <button onClick={onBack} className="text-sm text-orange-600 hover:text-orange-700 font-medium">
        &larr; Back to list
      </button>

      {/* Equipment Info */}
      <div className="bg-white rounded-xl border border-gray-200 p-5 space-y-3">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-lg bg-blue-50">
            <Wrench size={20} className="text-blue-600" />
          </div>
          <div>
            <h2 className="text-lg font-semibold text-gray-900">{equipment.name}</h2>
            <p className="text-sm text-gray-500">
              {[equipment.manufacturer, equipment.modelNumber].filter(Boolean).join(' — ')}
            </p>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3 pt-2">
          <DetailRow label="Serial Number" value={equipment.serialNumber || '—'} />
          <DetailRow label="Category" value={equipment.category?.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase()) || '—'} />
          <DetailRow label="Warranty Type" value={equipment.warrantyType ? warrantyTypeLabels[equipment.warrantyType] || equipment.warrantyType : '—'} />
          <DetailRow label="Provider" value={equipment.warrantyProvider || '—'} />
          <DetailRow label="Start Date" value={equipment.warrantyStartDate ? formatDate(equipment.warrantyStartDate) : '—'} />
          <DetailRow label="End Date" value={equipment.warrantyEndDate ? formatDate(equipment.warrantyEndDate) : '—'} />
        </div>

        {/* Warranty Status Banner */}
        {equipment.status === 'active' && (
          <div className="flex items-center gap-2 p-3 bg-green-50 border border-green-200 rounded-lg mt-3">
            <CheckCircle2 size={16} className="text-green-600" />
            <p className="text-sm text-green-700">
              Warranty active — {equipment.daysRemaining ? `${Math.round(equipment.daysRemaining / 30)} months remaining` : 'covered'}
            </p>
          </div>
        )}
        {equipment.status === 'expiring_soon' && (
          <div className="flex items-center gap-2 p-3 bg-amber-50 border border-amber-200 rounded-lg mt-3">
            <Clock size={16} className="text-amber-600" />
            <p className="text-sm text-amber-700">
              Warranty expiring in {equipment.daysRemaining} days — contact your contractor about extended coverage
            </p>
          </div>
        )}
        {equipment.status === 'expired' && (
          <div className="flex items-center gap-2 p-3 bg-gray-50 border border-gray-200 rounded-lg mt-3">
            <Shield size={16} className="text-gray-400" />
            <p className="text-sm text-gray-500">Warranty has expired</p>
          </div>
        )}
        {equipment.recallStatus === 'active' && (
          <div className="flex items-center gap-2 p-3 bg-red-50 border border-red-200 rounded-lg mt-3">
            <AlertTriangle size={16} className="text-red-600" />
            <p className="text-sm text-red-700">
              Active recall on this equipment — contact your contractor for service
            </p>
          </div>
        )}
      </div>

      {/* Claims */}
      <div className="bg-white rounded-xl border border-gray-200 p-5">
        <h3 className="text-sm font-semibold text-gray-900 mb-3 flex items-center gap-2">
          <FileText size={16} className="text-gray-400" />
          Warranty Claims
        </h3>
        {claims.length === 0 ? (
          <p className="text-sm text-gray-400 text-center py-6">No claims filed for this equipment</p>
        ) : (
          <div className="space-y-2">
            {claims.map(claim => (
              <div key={claim.id} className="p-3 bg-gray-50 rounded-lg border border-gray-100">
                <div className="flex items-center justify-between mb-1">
                  <p className="text-sm font-medium text-gray-900">{claim.claimReason}</p>
                  <ClaimBadge status={claim.claimStatus} />
                </div>
                <p className="text-xs text-gray-500">Filed {formatDate(claim.claimDate)}</p>
                {claim.amountApproved != null && (
                  <p className="text-xs text-green-600 mt-1">Approved: ${claim.amountApproved.toFixed(2)}</p>
                )}
                {claim.resolutionNotes && (
                  <p className="text-xs text-gray-400 mt-1 italic">{claim.resolutionNotes}</p>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

// ── Helpers ─────────────────────────────────────────────

function DetailRow({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-xs text-gray-400">{label}</p>
      <p className="text-sm text-gray-900">{value}</p>
    </div>
  );
}

function ClaimBadge({ status }: { status: string }) {
  const config: Record<string, { bg: string; text: string; label: string }> = {
    submitted: { bg: 'bg-blue-100', text: 'text-blue-700', label: 'Submitted' },
    under_review: { bg: 'bg-amber-100', text: 'text-amber-700', label: 'Under Review' },
    approved: { bg: 'bg-green-100', text: 'text-green-700', label: 'Approved' },
    denied: { bg: 'bg-red-100', text: 'text-red-700', label: 'Denied' },
    resolved: { bg: 'bg-emerald-100', text: 'text-emerald-700', label: 'Resolved' },
    closed: { bg: 'bg-gray-100', text: 'text-gray-500', label: 'Closed' },
  };
  const c = config[status] || config.submitted;
  return (
    <span className={`px-2 py-0.5 text-[10px] font-medium rounded-full ${c.bg} ${c.text}`}>
      {c.label}
    </span>
  );
}
