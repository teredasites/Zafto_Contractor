'use client';
import { useState } from 'react';
import Link from 'next/link';
import { ArrowLeft, CheckCircle2, AlertTriangle, AlertOctagon, Clock, ChevronRight, Search } from 'lucide-react';

type EquipStatus = 'healthy' | 'maintenance_due' | 'recall' | 'warranty_expiring' | 'end_of_life';
interface Equipment { id: string; name: string; make: string; model: string; category: string; installDate: string; age: string; status: EquipStatus; alert?: string; }

const statusConfig: Record<EquipStatus, { label: string; color: string; bg: string; icon: typeof CheckCircle2 }> = {
  healthy: { label: 'Healthy', color: 'text-green-700', bg: 'bg-green-50', icon: CheckCircle2 },
  maintenance_due: { label: 'Maintenance Due', color: 'text-amber-700', bg: 'bg-amber-50', icon: Clock },
  recall: { label: 'Recall Active', color: 'text-red-700', bg: 'bg-red-50', icon: AlertOctagon },
  warranty_expiring: { label: 'Warranty Expiring', color: 'text-purple-700', bg: 'bg-purple-50', icon: AlertTriangle },
  end_of_life: { label: 'End of Life', color: 'text-gray-700', bg: 'bg-gray-100', icon: AlertTriangle },
};

const mockEquipment: Equipment[] = [
  { id: 'eq-1', name: 'Central Air Conditioner', make: 'Carrier', model: '24ACC636A003', category: 'HVAC', installDate: 'Jun 2014', age: '11 years', status: 'recall', alert: 'Compressor recall — contact manufacturer' },
  { id: 'eq-2', name: 'Water Heater', make: 'Rheem', model: 'PROG50-38N', category: 'Plumbing', installDate: 'Jan 2018', age: '8 years', status: 'maintenance_due', alert: 'Annual flush recommended' },
  { id: 'eq-3', name: 'Main Breaker Panel', make: 'Eaton', model: 'BR2040B200V', category: 'Electrical', installDate: 'Jan 2026', age: '1 month', status: 'healthy' },
  { id: 'eq-4', name: 'Heat Pump', make: 'Trane', model: 'XR15-060', category: 'HVAC', installDate: 'Mar 2022', age: '4 years', status: 'warranty_expiring', alert: 'Warranty expires May 2027' },
  { id: 'eq-5', name: 'Gas Furnace', make: 'Carrier', model: '59TP6B080V17-14', category: 'HVAC', installDate: 'Jun 2014', age: '11 years', status: 'end_of_life', alert: 'Past average lifespan — replacement recommended' },
  { id: 'eq-6', name: 'Tankless Water Heater', make: 'Rinnai', model: 'RU199iN', category: 'Plumbing', installDate: 'Jan 2026', age: '1 month', status: 'healthy' },
];

export default function EquipmentListPage() {
  const [search, setSearch] = useState('');
  const [filterStatus, setFilterStatus] = useState<'all' | EquipStatus>('all');
  const filtered = mockEquipment.filter(e => {
    if (filterStatus !== 'all' && e.status !== filterStatus) return false;
    if (search && !`${e.name} ${e.make} ${e.model}`.toLowerCase().includes(search.toLowerCase())) return false;
    return true;
  });
  const alertCount = mockEquipment.filter(e => e.status !== 'healthy').length;

  return (
    <div className="space-y-5">
      <div>
        <Link href="/my-home" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-3"><ArrowLeft size={16} /> Back to My Home</Link>
        <h1 className="text-xl font-bold text-gray-900">Equipment Passport</h1>
        <p className="text-sm text-gray-500 mt-0.5">{mockEquipment.length} pieces tracked · {alertCount} alerts</p>
      </div>
      <div className="relative">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
        <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search equipment..." className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-gray-200 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 outline-none text-sm" />
      </div>
      <div className="flex gap-2 overflow-x-auto pb-1">
        {(['all', 'recall', 'maintenance_due', 'warranty_expiring', 'healthy'] as const).map(f => (
          <button key={f} onClick={() => setFilterStatus(f)} className={`px-3 py-1.5 rounded-full text-xs font-medium whitespace-nowrap transition-all ${filterStatus === f ? 'bg-orange-500 text-white' : 'bg-white text-gray-600 border border-gray-200'}`}>
            {f === 'all' ? 'All' : statusConfig[f].label}
          </button>
        ))}
      </div>
      <div className="space-y-2">
        {filtered.map(eq => {
          const config = statusConfig[eq.status];
          const StatusIcon = config.icon;
          return (
            <Link key={eq.id} href={`/my-home/equipment/${eq.id}`} className="flex items-center gap-3 bg-white rounded-xl border border-gray-100 shadow-sm p-4 hover:shadow-md transition-all">
              <div className={`p-2.5 rounded-xl ${config.bg}`}><StatusIcon size={18} className={config.color} /></div>
              <div className="flex-1 min-w-0">
                <h3 className="font-semibold text-sm text-gray-900">{eq.name}</h3>
                <p className="text-xs text-gray-500">{eq.make} {eq.model} · {eq.age}</p>
                {eq.alert && <p className={`text-xs mt-1 font-medium ${config.color}`}>{eq.alert}</p>}
              </div>
              <ChevronRight size={14} className="text-gray-300" />
            </Link>
          );
        })}
      </div>
    </div>
  );
}
