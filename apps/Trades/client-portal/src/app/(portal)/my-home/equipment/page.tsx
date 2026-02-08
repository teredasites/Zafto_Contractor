'use client';
import { useState } from 'react';
import Link from 'next/link';
import { ArrowLeft, CheckCircle2, AlertTriangle, AlertOctagon, Clock, ChevronRight, Search, Loader2, Wrench } from 'lucide-react';
import { useHome, type HomeEquipment } from '@/lib/hooks/use-home';

type ConditionStatus = 'excellent' | 'good' | 'fair' | 'poor' | 'critical' | 'unknown';

const conditionConfig: Record<ConditionStatus, { label: string; color: string; bg: string; icon: typeof CheckCircle2 }> = {
  excellent: { label: 'Excellent', color: 'text-green-700', bg: 'bg-green-50', icon: CheckCircle2 },
  good: { label: 'Good', color: 'text-green-700', bg: 'bg-green-50', icon: CheckCircle2 },
  fair: { label: 'Fair', color: 'text-amber-700', bg: 'bg-amber-50', icon: Clock },
  poor: { label: 'Needs Attention', color: 'text-red-700', bg: 'bg-red-50', icon: AlertTriangle },
  critical: { label: 'Critical', color: 'text-red-700', bg: 'bg-red-50', icon: AlertOctagon },
  unknown: { label: 'Unknown', color: 'text-gray-700', bg: 'bg-gray-100', icon: Wrench },
};

function getConditionConfig(condition: string) {
  return conditionConfig[condition as ConditionStatus] || conditionConfig.unknown;
}

function getEquipmentAge(installDate: string | null): string {
  if (!installDate) return 'Unknown age';
  const installed = new Date(installDate);
  const now = new Date();
  const years = Math.floor((now.getTime() - installed.getTime()) / (365.25 * 24 * 60 * 60 * 1000));
  const months = Math.floor(((now.getTime() - installed.getTime()) % (365.25 * 24 * 60 * 60 * 1000)) / (30.44 * 24 * 60 * 60 * 1000));
  if (years === 0) return months <= 1 ? '1 month' : `${months} months`;
  return years === 1 ? '1 year' : `${years} years`;
}

function getAlert(eq: HomeEquipment): string | null {
  if (eq.condition === 'critical') return 'Critical condition — replacement recommended';
  if (eq.condition === 'poor') return 'Needs attention — schedule service';
  if (eq.warrantyExpiry) {
    const expiry = new Date(eq.warrantyExpiry);
    const sixMonths = new Date(Date.now() + 180 * 24 * 60 * 60 * 1000);
    if (expiry <= sixMonths) return `Warranty expires ${expiry.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })}`;
  }
  if (eq.nextServiceDue) {
    const due = new Date(eq.nextServiceDue);
    if (due <= new Date()) return 'Service overdue';
    const thirtyDays = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    if (due <= thirtyDays) return `Service due ${due.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}`;
  }
  if (eq.estimatedLifespanYears && eq.installDate) {
    const installed = new Date(eq.installDate);
    const ageYears = (Date.now() - installed.getTime()) / (365.25 * 24 * 60 * 60 * 1000);
    if (ageYears >= eq.estimatedLifespanYears) return 'Past average lifespan — replacement recommended';
  }
  return null;
}

export default function EquipmentListPage() {
  const { equipment, loading, primaryProperty } = useHome();
  const [search, setSearch] = useState('');
  const [filterCondition, setFilterCondition] = useState<'all' | ConditionStatus>('all');

  const propEquipment = primaryProperty
    ? equipment.filter(e => e.propertyId === primaryProperty.id)
    : equipment;

  const filtered = propEquipment.filter(e => {
    if (filterCondition !== 'all' && e.condition !== filterCondition) return false;
    if (search && !`${e.name} ${e.manufacturer || ''} ${e.modelNumber || ''}`.toLowerCase().includes(search.toLowerCase())) return false;
    return true;
  });

  const alertCount = propEquipment.filter(e => e.condition === 'poor' || e.condition === 'critical' || getAlert(e) !== null).length;

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 size={24} className="animate-spin text-orange-500" />
      </div>
    );
  }

  return (
    <div className="space-y-5">
      <div>
        <Link href="/my-home" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-3"><ArrowLeft size={16} /> Back to My Home</Link>
        <h1 className="text-xl font-bold text-gray-900">Equipment Passport</h1>
        <p className="text-sm text-gray-500 mt-0.5">{propEquipment.length} pieces tracked{alertCount > 0 ? ` · ${alertCount} alerts` : ''}</p>
      </div>

      <div className="relative">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
        <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search equipment..." className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-gray-200 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 outline-none text-sm" />
      </div>

      <div className="flex gap-2 overflow-x-auto pb-1">
        {(['all', 'critical', 'poor', 'fair', 'good', 'excellent'] as const).map(f => (
          <button key={f} onClick={() => setFilterCondition(f)} className={`px-3 py-1.5 rounded-full text-xs font-medium whitespace-nowrap transition-all ${filterCondition === f ? 'bg-orange-500 text-white' : 'bg-white text-gray-600 border border-gray-200'}`}>
            {f === 'all' ? 'All' : conditionConfig[f].label}
          </button>
        ))}
      </div>

      {filtered.length === 0 ? (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
          <Wrench size={32} className="mx-auto text-gray-300 mb-2" />
          <p className="text-sm text-gray-500">{propEquipment.length === 0 ? 'No equipment tracked yet' : 'No equipment matches your filters'}</p>
        </div>
      ) : (
        <div className="space-y-2">
          {filtered.map(eq => {
            const config = getConditionConfig(eq.condition);
            const StatusIcon = config.icon;
            const alert = getAlert(eq);
            return (
              <Link key={eq.id} href={`/my-home/equipment/${eq.id}`} className="flex items-center gap-3 bg-white rounded-xl border border-gray-100 shadow-sm p-4 hover:shadow-md transition-all">
                <div className={`p-2.5 rounded-xl ${config.bg}`}><StatusIcon size={18} className={config.color} /></div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-sm text-gray-900">{eq.name}</h3>
                  <p className="text-xs text-gray-500">
                    {eq.manufacturer ? `${eq.manufacturer} ` : ''}{eq.modelNumber || ''} · {getEquipmentAge(eq.installDate)}
                  </p>
                  {alert && <p className={`text-xs mt-1 font-medium ${config.color}`}>{alert}</p>}
                </div>
                <ChevronRight size={14} className="text-gray-300" />
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
