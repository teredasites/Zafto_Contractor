'use client';
import Link from 'next/link';
import { ArrowLeft, AlertOctagon, Calendar, Wrench, Shield, Clock, FileText, ChevronRight, ExternalLink } from 'lucide-react';

const equipment = {
  id: 'eq-1', name: 'Central Air Conditioner', make: 'Carrier', model: '24ACC636A003', serial: 'CAR-2014-0892461',
  category: 'HVAC', installDate: 'June 15, 2014', installedBy: 'ComfortAir HVAC', age: 11, avgLifespan: 15,
  warranty: { type: 'Manufacturer Limited', expires: 'June 15, 2024', status: 'Expired' },
  recall: { active: true, severity: 'High', title: 'Compressor Bearing Failure Risk', description: 'Carrier has issued a voluntary recall for 24ACC6 series units manufactured between 2013-2015 due to potential compressor bearing failure. Contact your HVAC contractor or Carrier directly.', recallNumber: 'CR-2025-8821', issueDate: 'Dec 1, 2025' },
  maintenanceHistory: [
    { date: 'Oct 5, 2025', service: 'Annual Tune-Up', contractor: 'ComfortAir HVAC', notes: 'Refrigerant levels normal, coils cleaned' },
    { date: 'Apr 12, 2025', service: 'Filter Replacement', contractor: 'Homeowner', notes: 'Replaced 20x25x1 filter' },
    { date: 'Sep 20, 2024', service: 'Annual Tune-Up', contractor: 'ComfortAir HVAC', notes: 'Capacitor showing wear, recommended monitoring' },
    { date: 'Mar 8, 2024', service: 'Emergency Repair', contractor: 'ComfortAir HVAC', notes: 'Replaced contactor, system restored' },
  ],
};

export default function EquipmentDetailPage() {
  const lifespanPercent = Math.min(100, (equipment.age / equipment.avgLifespan) * 100);
  return (
    <div className="space-y-5">
      <div>
        <Link href="/my-home/equipment" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-3"><ArrowLeft size={16} /> Back to Equipment</Link>
        <h1 className="text-xl font-bold text-gray-900">{equipment.name}</h1>
        <p className="text-sm text-gray-500 mt-0.5">{equipment.make} · {equipment.model}</p>
      </div>

      {/* Recall Alert */}
      {equipment.recall.active && (
        <div className="bg-red-50 border border-red-200 rounded-xl p-4">
          <div className="flex items-start gap-3">
            <AlertOctagon size={20} className="text-red-600 mt-0.5" />
            <div>
              <h3 className="font-bold text-sm text-red-800">{equipment.recall.title}</h3>
              <p className="text-xs text-red-600 mt-1">{equipment.recall.description}</p>
              <div className="flex items-center gap-3 mt-2">
                <span className="text-[10px] text-red-500">Recall #{equipment.recall.recallNumber} · {equipment.recall.issueDate}</span>
                <Link href="/request" className="text-xs text-red-700 font-bold hover:text-red-800 flex items-center gap-1">Schedule Service <ChevronRight size={12} /></Link>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Equipment Info */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5 space-y-3">
        <h3 className="font-bold text-sm text-gray-900">Equipment Details</h3>
        {[
          ['Make', equipment.make], ['Model', equipment.model], ['Serial', equipment.serial],
          ['Installed', equipment.installDate], ['Installed By', equipment.installedBy], ['Category', equipment.category],
        ].map(([label, val]) => (
          <div key={label} className="flex justify-between text-sm"><span className="text-gray-500">{label}</span><span className="font-medium text-gray-900">{val}</span></div>
        ))}
      </div>

      {/* Lifespan Bar */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
        <h3 className="font-bold text-sm text-gray-900 mb-3">Lifespan Position</h3>
        <div className="flex justify-between text-xs mb-1.5">
          <span className="text-gray-500">Age: {equipment.age} years</span>
          <span className="text-gray-500">Avg lifespan: {equipment.avgLifespan} years</span>
        </div>
        <div className="h-4 bg-gray-100 rounded-full overflow-hidden relative">
          <div className={`h-full rounded-full ${lifespanPercent > 80 ? 'bg-red-500' : lifespanPercent > 60 ? 'bg-amber-500' : 'bg-green-500'}`} style={{ width: `${lifespanPercent}%` }} />
        </div>
        <p className="text-xs text-gray-400 mt-2">{lifespanPercent > 80 ? 'Approaching end of expected lifespan — consider replacement planning' : lifespanPercent > 60 ? 'Past midpoint — regular maintenance is critical' : 'Early in lifespan — maintain regular service schedule'}</p>
      </div>

      {/* Warranty */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
        <h3 className="font-bold text-sm text-gray-900 mb-2 flex items-center gap-2"><Shield size={14} className="text-gray-400" /> Warranty</h3>
        <div className="space-y-2">
          <div className="flex justify-between text-sm"><span className="text-gray-500">Type</span><span className="font-medium">{equipment.warranty.type}</span></div>
          <div className="flex justify-between text-sm"><span className="text-gray-500">Expires</span><span className="font-medium">{equipment.warranty.expires}</span></div>
          <div className="flex justify-between text-sm"><span className="text-gray-500">Status</span><span className="font-medium text-red-600">{equipment.warranty.status}</span></div>
        </div>
      </div>

      {/* Maintenance History */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
        <h3 className="font-bold text-sm text-gray-900 mb-3 flex items-center gap-2"><Wrench size={14} className="text-gray-400" /> Service History</h3>
        <div className="space-y-4">
          {equipment.maintenanceHistory.map((m, i) => (
            <div key={i} className="flex gap-3">
              <div className="flex flex-col items-center"><div className="w-2 h-2 bg-orange-400 rounded-full mt-2" />{i < equipment.maintenanceHistory.length - 1 && <div className="w-0.5 flex-1 bg-gray-200 mt-1" />}</div>
              <div><p className="text-sm font-medium text-gray-900">{m.service}</p><p className="text-xs text-gray-500">{m.contractor} · {m.date}</p><p className="text-xs text-gray-400 mt-0.5">{m.notes}</p></div>
            </div>
          ))}
        </div>
      </div>

      <Link href="/request" className="block w-full py-3 bg-orange-500 hover:bg-orange-600 text-white font-bold rounded-xl text-sm text-center transition-all">
        Schedule Service for This Equipment
      </Link>
    </div>
  );
}
