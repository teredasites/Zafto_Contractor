'use client';
import Link from 'next/link';
import { ArrowLeft, Star, Wrench, Loader2, Calendar, DollarSign } from 'lucide-react';
import { useHome } from '@/lib/hooks/use-home';

const serviceTypeLabels: Record<string, string> = {
  repair: 'Repair',
  replacement: 'Replacement',
  installation: 'Installation',
  inspection: 'Inspection',
  maintenance: 'Maintenance',
  emergency: 'Emergency',
  other: 'Other',
};

const serviceTypeColors: Record<string, string> = {
  repair: 'bg-amber-50 text-amber-700',
  replacement: 'bg-red-50 text-red-700',
  installation: 'bg-blue-50 text-blue-700',
  inspection: 'bg-purple-50 text-purple-700',
  maintenance: 'bg-green-50 text-green-700',
  emergency: 'bg-red-50 text-red-800',
  other: 'bg-gray-50 text-gray-700',
};

export default function ServiceHistoryPage() {
  const { serviceHistory, loading, primaryProperty } = useHome();

  const propServices = primaryProperty
    ? serviceHistory.filter(s => s.propertyId === primaryProperty.id)
    : serviceHistory;

  const totalSpent = propServices.reduce((sum, s) => sum + (s.totalCost || 0), 0);

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
        <h1 className="text-xl font-bold text-gray-900">Service History</h1>
        <p className="text-sm text-gray-500 mt-0.5">{propServices.length} services recorded</p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 gap-3">
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-4">
          <div className="flex items-center gap-2 mb-1">
            <Wrench size={14} className="text-gray-400" />
            <p className="text-xs text-gray-500">Total Services</p>
          </div>
          <p className="text-2xl font-bold text-gray-900">{propServices.length}</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-4">
          <div className="flex items-center gap-2 mb-1">
            <DollarSign size={14} className="text-gray-400" />
            <p className="text-xs text-gray-500">Total Spent</p>
          </div>
          <p className="text-2xl font-bold text-gray-900">${totalSpent.toLocaleString()}</p>
        </div>
      </div>

      {/* Service Timeline */}
      {propServices.length === 0 ? (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
          <Calendar size={32} className="mx-auto text-gray-300 mb-2" />
          <p className="text-sm text-gray-500">No service history yet</p>
          <p className="text-xs text-gray-400 mt-1">Service records will appear here as work is completed</p>
        </div>
      ) : (
        <div className="space-y-3">
          {propServices.map((svc) => (
            <div key={svc.id} className="bg-white rounded-xl border border-gray-100 shadow-sm p-4">
              <div className="flex items-start justify-between mb-2">
                <div className="flex-1">
                  <h3 className="font-semibold text-sm text-gray-900">{svc.title}</h3>
                  <p className="text-xs text-gray-500 mt-0.5">
                    {svc.contractorName || 'Unknown Contractor'} · {new Date(svc.serviceDate).toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}
                  </p>
                </div>
                <span className={`px-2 py-0.5 rounded-full text-[10px] font-medium ${serviceTypeColors[svc.serviceType] || serviceTypeColors.other}`}>
                  {serviceTypeLabels[svc.serviceType] || svc.serviceType}
                </span>
              </div>
              {svc.description && (
                <p className="text-xs text-gray-600 mb-2">{svc.description}</p>
              )}
              <div className="flex items-center gap-4 text-xs text-gray-500">
                <span className="capitalize">{svc.tradeCategory.replace(/_/g, ' ')}</span>
                {svc.totalCost && <span>${svc.totalCost.toLocaleString()}</span>}
                {svc.rating && (
                  <span className="flex items-center gap-0.5">
                    <Star size={10} className="text-amber-400 fill-amber-400" />
                    {svc.rating}/5
                  </span>
                )}
                {svc.warrantyUntil && (
                  <span>Warranty until {new Date(svc.warrantyUntil).toLocaleDateString('en-US', { month: 'short', year: 'numeric' })}</span>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
