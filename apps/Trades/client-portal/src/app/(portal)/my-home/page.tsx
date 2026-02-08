'use client';
import Link from 'next/link';
import { Zap, Thermometer, Droplets, CheckCircle2, AlertTriangle, Wrench, ChevronRight, Calendar, Shield, Home, Plus, Loader2, FileText } from 'lucide-react';
import { useHome } from '@/lib/hooks/use-home';

const categoryIcons: Record<string, { icon: typeof Zap; color: string; bg: string }> = {
  hvac: { icon: Thermometer, color: 'text-amber-600', bg: 'bg-amber-50' },
  plumbing: { icon: Droplets, color: 'text-cyan-600', bg: 'bg-cyan-50' },
  electrical: { icon: Zap, color: 'text-blue-600', bg: 'bg-blue-50' },
  appliance: { icon: Wrench, color: 'text-gray-600', bg: 'bg-gray-50' },
  roofing: { icon: Home, color: 'text-red-600', bg: 'bg-red-50' },
  water_heater: { icon: Droplets, color: 'text-teal-600', bg: 'bg-teal-50' },
  fire_protection: { icon: Shield, color: 'text-red-600', bg: 'bg-red-50' },
  solar: { icon: Zap, color: 'text-yellow-600', bg: 'bg-yellow-50' },
};

function getCategoryConfig(cat: string) {
  return categoryIcons[cat] || { icon: Wrench, color: 'text-gray-600', bg: 'bg-gray-50' };
}

function formatPropertyType(t: string) {
  return t.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
}

export default function PropertyProfilePage() {
  const {
    primaryProperty, equipment, serviceHistory, maintenanceSchedules,
    maintenanceDue, alertCount, healthScore, loading, equipmentByProperty,
    serviceForProperty,
  } = useHome();

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 size={24} className="animate-spin text-orange-500" />
      </div>
    );
  }

  const prop = primaryProperty;
  const propEquipment = prop ? equipmentByProperty(prop.id) : [];
  const propServices = prop ? serviceForProperty(prop.id) : [];

  // Group equipment by category for systems overview
  const categories = [...new Set(propEquipment.map(e => e.category))];
  const systemsSummary = categories.map(cat => {
    const items = propEquipment.filter(e => e.category === cat);
    const worstCondition = items.some(e => e.condition === 'critical' || e.condition === 'poor')
      ? 'attention'
      : items.some(e => e.condition === 'fair') ? 'fair' : 'good';
    const detail = items.length === 1
      ? `${items[0].manufacturer || ''} ${items[0].name}`.trim()
      : `${items.length} pieces tracked`;
    return { category: cat, status: worstCondition, detail, count: items.length };
  });

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">My Home</h1>
        <p className="text-gray-500 text-sm mt-0.5">Your property&apos;s digital profile</p>
      </div>

      {!prop ? (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
          <Home size={40} className="mx-auto text-gray-300 mb-3" />
          <h2 className="font-bold text-gray-900 mb-1">No Property Added</h2>
          <p className="text-sm text-gray-500 mb-4">Add your home to start tracking equipment, service history, and maintenance.</p>
          <button className="px-4 py-2 bg-orange-500 text-white rounded-lg text-sm font-medium hover:bg-orange-600 transition-colors inline-flex items-center gap-2">
            <Plus size={16} /> Add Property
          </button>
        </div>
      ) : (
        <>
          {/* Property Card */}
          <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-14 h-14 bg-gray-100 rounded-xl flex items-center justify-center">
                <Home size={24} className="text-gray-500" />
              </div>
              <div>
                <h2 className="font-bold text-gray-900">{prop.address}</h2>
                <p className="text-xs text-gray-500">{prop.city}, {prop.state} {prop.zipCode}</p>
              </div>
            </div>
            <div className="grid grid-cols-3 gap-3 text-center">
              <div className="bg-gray-50 rounded-lg p-2.5">
                <p className="text-sm font-bold text-gray-900">{formatPropertyType(prop.propertyType)}</p>
                <p className="text-[10px] text-gray-400">Type</p>
              </div>
              <div className="bg-gray-50 rounded-lg p-2.5">
                <p className="text-sm font-bold text-gray-900">{prop.squareFootage ? `${prop.squareFootage.toLocaleString()} ft²` : '—'}</p>
                <p className="text-[10px] text-gray-400">Size</p>
              </div>
              <div className="bg-gray-50 rounded-lg p-2.5">
                <p className="text-sm font-bold text-gray-900">{prop.yearBuilt || '—'}</p>
                <p className="text-[10px] text-gray-400">Built</p>
              </div>
            </div>
          </div>

          {/* Health Score */}
          {healthScore !== null && (
            <div className={`bg-gradient-to-r ${healthScore >= 70 ? 'from-green-500 to-emerald-600' : healthScore >= 40 ? 'from-amber-500 to-orange-600' : 'from-red-500 to-rose-600'} rounded-xl p-5 text-white`}>
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-white/70 text-xs">Property Health Score</p>
                  <p className="text-4xl font-black mt-1">{healthScore}%</p>
                  <p className="text-white/70 text-xs mt-1">Based on equipment age, maintenance & service history</p>
                </div>
                <div className="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center">
                  <Shield size={28} />
                </div>
              </div>
            </div>
          )}

          {/* Systems Overview */}
          {systemsSummary.length > 0 && (
            <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
              <h3 className="font-bold text-sm text-gray-900 mb-3">Systems Overview</h3>
              <div className="space-y-2.5">
                {systemsSummary.map(sys => {
                  const config = getCategoryConfig(sys.category);
                  const Icon = config.icon;
                  return (
                    <div key={sys.category} className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                      <div className={`p-2 rounded-lg ${config.bg}`}><Icon size={16} className={config.color} /></div>
                      <div className="flex-1">
                        <p className="text-sm font-medium text-gray-900 capitalize">{sys.category.replace(/_/g, ' ')}</p>
                        <p className="text-xs text-gray-500">{sys.detail}</p>
                      </div>
                      {sys.status === 'good' ? <CheckCircle2 size={16} className="text-green-500" /> : <AlertTriangle size={16} className="text-amber-500" />}
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Equipment Link */}
          <Link href="/my-home/equipment" className="flex items-center gap-3 bg-white rounded-xl border border-gray-100 shadow-sm p-4 hover:shadow-md transition-all">
            <div className="p-2.5 bg-orange-50 rounded-xl"><Wrench size={18} className="text-orange-600" /></div>
            <div className="flex-1">
              <h3 className="font-semibold text-sm text-gray-900">Equipment Passport</h3>
              <p className="text-xs text-gray-500">{propEquipment.length} pieces tracked{alertCount > 0 ? ` · ${alertCount} alerts` : ''}</p>
            </div>
            <ChevronRight size={16} className="text-gray-300" />
          </Link>

          {/* Documents Link */}
          <Link href="/my-home/documents" className="flex items-center gap-3 bg-white rounded-xl border border-gray-100 shadow-sm p-4 hover:shadow-md transition-all">
            <div className="p-2.5 bg-purple-50 rounded-xl"><FileText size={18} className="text-purple-600" /></div>
            <div className="flex-1">
              <h3 className="font-semibold text-sm text-gray-900">Home Documents</h3>
              <p className="text-xs text-gray-500">Warranties, manuals, permits & receipts</p>
            </div>
            <ChevronRight size={16} className="text-gray-300" />
          </Link>

          {/* Upcoming Maintenance */}
          <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
            <h3 className="font-bold text-sm text-gray-900 mb-3">Upcoming Maintenance</h3>
            {maintenanceDue.length === 0 ? (
              <p className="text-sm text-gray-400">No maintenance due in the next 30 days</p>
            ) : (
              <div className="space-y-2.5">
                {maintenanceDue.slice(0, 5).map(m => (
                  <div key={m.id} className="flex items-center gap-3">
                    <Calendar size={14} className={m.aiPriority === 'high' || m.aiPriority === 'critical' ? 'text-amber-500' : 'text-gray-400'} />
                    <div className="flex-1">
                      <p className="text-sm text-gray-900">{m.title}</p>
                      <p className="text-xs text-gray-400">{new Date(m.nextDueDate).toLocaleDateString()}</p>
                    </div>
                    <Link href="/request" className="text-[10px] text-orange-500 font-medium hover:text-orange-600">Schedule</Link>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Service History */}
          <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
            <h3 className="font-bold text-sm text-gray-900 mb-3">Service History</h3>
            {propServices.length === 0 ? (
              <p className="text-sm text-gray-400">No service history yet</p>
            ) : (
              <div className="space-y-3">
                {propServices.slice(0, 6).map((w, i) => (
                  <div key={w.id} className="flex items-start gap-3">
                    <div className="flex flex-col items-center">
                      <div className="w-2 h-2 bg-orange-400 rounded-full mt-1.5" />
                      {i < propServices.length - 1 && i < 5 && <div className="w-0.5 h-6 bg-gray-200 mt-1" />}
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-900">{w.title}</p>
                      <p className="text-xs text-gray-500">
                        {w.contractorName || 'Unknown'} · {new Date(w.serviceDate).toLocaleDateString('en-US', { month: 'short', year: 'numeric' })}
                        {w.totalCost ? ` · $${w.totalCost.toLocaleString()}` : ''}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </>
      )}
    </div>
  );
}
