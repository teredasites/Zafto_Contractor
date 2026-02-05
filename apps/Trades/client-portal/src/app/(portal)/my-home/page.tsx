'use client';
import Link from 'next/link';
import { House, Zap, Thermometer, Droplets, CheckCircle2, AlertTriangle, Wrench, ChevronRight, Calendar, Shield } from 'lucide-react';

const property = {
  address: '142 Maple Drive', city: 'Hartford, CT 06010', type: 'Single Family', sqft: '2,400', yearBuilt: '1998', healthScore: 92,
  systems: [
    { name: 'Electrical', icon: Zap, status: 'good' as const, detail: '200A panel (2026)', color: 'text-blue-600', bg: 'bg-blue-50' },
    { name: 'HVAC', icon: Thermometer, status: 'attention' as const, detail: 'System is 12 years old', color: 'text-amber-600', bg: 'bg-amber-50' },
    { name: 'Plumbing', icon: Droplets, status: 'good' as const, detail: 'New water heater (2026)', color: 'text-cyan-600', bg: 'bg-cyan-50' },
  ],
  recentWork: [
    { date: 'Jan 2026', title: '200A Panel Upgrade', contractor: "Mike's Electric", trade: 'Electrical' },
    { date: 'Jan 2026', title: 'Water Heater Install', contractor: "Pete's Plumbing", trade: 'Plumbing' },
    { date: 'Nov 2025', title: 'Roof Repair — Storm', contractor: 'TopShield Roofing', trade: 'Roofing' },
    { date: 'Oct 2025', title: 'HVAC Tune-Up', contractor: 'ComfortAir HVAC', trade: 'HVAC' },
  ],
  upcomingMaintenance: [
    { item: 'HVAC Filter Change', due: 'Feb 15, 2026', urgency: 'low' },
    { item: 'Water Heater Flush', due: 'Jul 2026', urgency: 'low' },
    { item: 'HVAC System Replacement', due: 'Recommended within 2 years', urgency: 'medium' },
  ],
};

export default function PropertyProfilePage() {
  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">My Home</h1>
        <p className="text-gray-500 text-sm mt-0.5">Your property&apos;s digital profile</p>
      </div>

      {/* Property Card */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-14 h-14 bg-gray-100 rounded-xl flex items-center justify-center text-2xl">🏠</div>
          <div>
            <h2 className="font-bold text-gray-900">{property.address}</h2>
            <p className="text-xs text-gray-500">{property.city}</p>
          </div>
        </div>
        <div className="grid grid-cols-3 gap-3 text-center">
          <div className="bg-gray-50 rounded-lg p-2.5"><p className="text-sm font-bold text-gray-900">{property.type}</p><p className="text-[10px] text-gray-400">Type</p></div>
          <div className="bg-gray-50 rounded-lg p-2.5"><p className="text-sm font-bold text-gray-900">{property.sqft} ft²</p><p className="text-[10px] text-gray-400">Size</p></div>
          <div className="bg-gray-50 rounded-lg p-2.5"><p className="text-sm font-bold text-gray-900">{property.yearBuilt}</p><p className="text-[10px] text-gray-400">Built</p></div>
        </div>
      </div>

      {/* Health Score */}
      <div className="bg-gradient-to-r from-green-500 to-emerald-600 rounded-xl p-5 text-white">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-green-200 text-xs">Property Health Score</p>
            <p className="text-4xl font-black mt-1">{property.healthScore}%</p>
            <p className="text-green-200 text-xs mt-1">Based on equipment age, maintenance & service history</p>
          </div>
          <div className="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center">
            <Shield size={28} />
          </div>
        </div>
      </div>

      {/* Systems Overview */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
        <h3 className="font-bold text-sm text-gray-900 mb-3">Systems Overview</h3>
        <div className="space-y-2.5">
          {property.systems.map(sys => {
            const Icon = sys.icon;
            return (
              <div key={sys.name} className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                <div className={`p-2 rounded-lg ${sys.bg}`}><Icon size={16} className={sys.color} /></div>
                <div className="flex-1">
                  <p className="text-sm font-medium text-gray-900">{sys.name}</p>
                  <p className="text-xs text-gray-500">{sys.detail}</p>
                </div>
                {sys.status === 'good' ? <CheckCircle2 size={16} className="text-green-500" /> : <AlertTriangle size={16} className="text-amber-500" />}
              </div>
            );
          })}
        </div>
      </div>

      {/* Equipment Link */}
      <Link href="/my-home/equipment" className="flex items-center gap-3 bg-white rounded-xl border border-gray-100 shadow-sm p-4 hover:shadow-md transition-all">
        <div className="p-2.5 bg-orange-50 rounded-xl"><Wrench size={18} className="text-orange-600" /></div>
        <div className="flex-1"><h3 className="font-semibold text-sm text-gray-900">Equipment Passport</h3><p className="text-xs text-gray-500">6 pieces tracked · 1 alert</p></div>
        <ChevronRight size={16} className="text-gray-300" />
      </Link>

      {/* Upcoming Maintenance */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
        <h3 className="font-bold text-sm text-gray-900 mb-3">Upcoming Maintenance</h3>
        <div className="space-y-2.5">
          {property.upcomingMaintenance.map(m => (
            <div key={m.item} className="flex items-center gap-3">
              <Calendar size={14} className={m.urgency === 'medium' ? 'text-amber-500' : 'text-gray-400'} />
              <div className="flex-1"><p className="text-sm text-gray-900">{m.item}</p><p className="text-xs text-gray-400">{m.due}</p></div>
              <Link href="/request" className="text-[10px] text-orange-500 font-medium hover:text-orange-600">Schedule</Link>
            </div>
          ))}
        </div>
      </div>

      {/* Service History */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
        <h3 className="font-bold text-sm text-gray-900 mb-3">Service History</h3>
        <div className="space-y-3">
          {property.recentWork.map((w, i) => (
            <div key={i} className="flex items-start gap-3">
              <div className="flex flex-col items-center"><div className="w-2 h-2 bg-orange-400 rounded-full mt-1.5" />{i < property.recentWork.length - 1 && <div className="w-0.5 h-6 bg-gray-200 mt-1" />}</div>
              <div><p className="text-sm font-medium text-gray-900">{w.title}</p><p className="text-xs text-gray-500">{w.contractor} · {w.date}</p></div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
