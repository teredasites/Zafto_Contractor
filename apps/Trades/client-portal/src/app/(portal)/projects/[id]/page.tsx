'use client';
import { useState } from 'react';
import Link from 'next/link';
import { ArrowLeft, Hammer, Clock, CheckCircle2, Camera, FileText, PenLine, Users, MessageSquare, MapPin, ChevronRight } from 'lucide-react';

interface TimelineEvent { id: string; date: string; title: string; description: string; type: 'completed' | 'current' | 'upcoming'; hasPhotos?: boolean; }

const project = {
  id: 'proj-1', name: '200A Panel Upgrade', contractor: "Mike's Electric", contractorPhone: '(860) 555-0142',
  status: 'active' as const, progress: 65, trade: 'Electrical',
  scope: 'Upgrade existing 100A panel to 200A service. Includes new meter base, main breaker panel, and 20 new circuits.',
  startDate: 'Jan 15, 2026', estCompletion: 'Feb 14, 2026',
  estimateTotal: '$4,800', paid: '$2,400', remaining: '$2,400',
  crew: [{ name: 'Mike Torres', role: 'Lead Electrician' }, { name: 'James Park', role: 'Apprentice' }],
  changeOrders: [{ id: 'co-1', title: 'Add EV charger circuit', amount: '+$450', status: 'approved' }],
};

const timeline: TimelineEvent[] = [
  { id: 't1', date: 'Jan 15', title: 'Project Started', description: 'Permit pulled, materials ordered', type: 'completed' },
  { id: 't2', date: 'Jan 18', title: 'Meter Base Installed', description: 'New 200A meter base mounted and inspected', type: 'completed', hasPhotos: true },
  { id: 't3', date: 'Jan 22', title: 'Panel Mounted', description: 'New Eaton 200A panel installed, circuits being wired', type: 'completed', hasPhotos: true },
  { id: 't4', date: 'Feb 1', title: 'Circuit Wiring', description: '14 of 20 circuits completed', type: 'current' },
  { id: 't5', date: 'Feb 8', title: 'Final Connections', description: 'Complete remaining circuits, connect to utility', type: 'upcoming' },
  { id: 't6', date: 'Feb 12', title: 'Inspection', description: 'City electrical inspection scheduled', type: 'upcoming' },
  { id: 't7', date: 'Feb 14', title: 'Project Complete', description: 'Final walkthrough and cleanup', type: 'upcoming' },
];

export default function ProjectDetailPage() {
  const [tab, setTab] = useState<'timeline' | 'details' | 'documents'>('timeline');
  const tabs = [
    { key: 'timeline' as const, label: 'Timeline' },
    { key: 'details' as const, label: 'Details' },
    { key: 'documents' as const, label: 'Documents' },
  ];

  return (
    <div className="space-y-5">
      {/* Back + Header */}
      <div>
        <Link href="/projects" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-3">
          <ArrowLeft size={16} /> Back to Projects
        </Link>
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-xl font-bold text-gray-900">{project.name}</h1>
            <p className="text-sm text-gray-500 mt-0.5">{project.contractor} · {project.trade}</p>
          </div>
          <span className="flex items-center gap-1 text-xs font-medium px-2.5 py-1 rounded-full bg-blue-50 text-blue-700">
            <Hammer size={12} /> In Progress
          </span>
        </div>
      </div>

      {/* Progress Bar */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-4">
        <div className="flex justify-between text-xs mb-2">
          <span className="text-gray-500">Overall Progress</span>
          <span className="font-bold text-gray-900">{project.progress}%</span>
        </div>
        <div className="h-3 bg-gray-100 rounded-full overflow-hidden">
          <div className="h-full bg-orange-500 rounded-full" style={{ width: `${project.progress}%` }} />
        </div>
        <div className="flex justify-between mt-2 text-xs text-gray-400">
          <span>Started {project.startDate}</span>
          <span>Est. {project.estCompletion}</span>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-3 gap-2">
        <Link href={`/projects/${project.id}/tracker`} className="bg-white rounded-xl border border-gray-100 p-3 text-center hover:shadow-sm transition-all">
          <MapPin size={18} className="mx-auto text-blue-500 mb-1" />
          <span className="text-xs font-medium text-gray-700">Track Crew</span>
        </Link>
        <Link href="/messages" className="bg-white rounded-xl border border-gray-100 p-3 text-center hover:shadow-sm transition-all">
          <MessageSquare size={18} className="mx-auto text-green-500 mb-1" />
          <span className="text-xs font-medium text-gray-700">Message</span>
        </Link>
        <Link href={`/projects/${project.id}/estimate`} className="bg-white rounded-xl border border-gray-100 p-3 text-center hover:shadow-sm transition-all">
          <FileText size={18} className="mx-auto text-orange-500 mb-1" />
          <span className="text-xs font-medium text-gray-700">Estimate</span>
        </Link>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 bg-gray-100 rounded-lg p-1">
        {tabs.map(t => (
          <button key={t.key} onClick={() => setTab(t.key)}
            className={`flex-1 py-2 text-xs font-medium rounded-md transition-all ${tab === t.key ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500'}`}>
            {t.label}
          </button>
        ))}
      </div>

      {/* Timeline Tab */}
      {tab === 'timeline' && (
        <div className="relative">
          {timeline.map((event, i) => (
            <div key={event.id} className="flex gap-3 pb-6 last:pb-0">
              <div className="flex flex-col items-center">
                <div className={`w-3 h-3 rounded-full border-2 mt-1 ${event.type === 'completed' ? 'bg-green-500 border-green-500' : event.type === 'current' ? 'bg-orange-500 border-orange-500 animate-pulse' : 'bg-white border-gray-300'}`} />
                {i < timeline.length - 1 && <div className={`w-0.5 flex-1 mt-1 ${event.type === 'completed' ? 'bg-green-200' : 'bg-gray-200'}`} />}
              </div>
              <div className="flex-1 pb-2">
                <div className="flex items-center gap-2">
                  <span className="text-xs text-gray-400 font-medium">{event.date}</span>
                  {event.type === 'current' && <span className="text-[10px] px-1.5 py-0.5 bg-orange-100 text-orange-600 rounded font-medium">CURRENT</span>}
                </div>
                <h4 className={`font-medium text-sm mt-0.5 ${event.type === 'upcoming' ? 'text-gray-400' : 'text-gray-900'}`}>{event.title}</h4>
                <p className={`text-xs mt-0.5 ${event.type === 'upcoming' ? 'text-gray-300' : 'text-gray-500'}`}>{event.description}</p>
                {event.hasPhotos && (
                  <button className="flex items-center gap-1 text-xs text-blue-500 mt-1.5 hover:text-blue-600">
                    <Camera size={12} /> View Photos
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Details Tab */}
      {tab === 'details' && (
        <div className="space-y-4">
          <div className="bg-white rounded-xl border border-gray-100 p-4">
            <h3 className="font-semibold text-sm text-gray-900 mb-2">Scope of Work</h3>
            <p className="text-sm text-gray-600">{project.scope}</p>
          </div>
          <div className="bg-white rounded-xl border border-gray-100 p-4">
            <h3 className="font-semibold text-sm text-gray-900 mb-3">Cost Summary</h3>
            <div className="space-y-2">
              <div className="flex justify-between text-sm"><span className="text-gray-500">Estimate Total</span><span className="font-medium">{project.estimateTotal}</span></div>
              <div className="flex justify-between text-sm"><span className="text-gray-500">Paid</span><span className="text-green-600 font-medium">{project.paid}</span></div>
              <div className="flex justify-between text-sm border-t border-gray-100 pt-2"><span className="font-medium text-gray-700">Remaining</span><span className="font-bold text-gray-900">{project.remaining}</span></div>
            </div>
          </div>
          <div className="bg-white rounded-xl border border-gray-100 p-4">
            <h3 className="font-semibold text-sm text-gray-900 mb-3">Crew</h3>
            {project.crew.map(c => (
              <div key={c.name} className="flex items-center gap-3 py-2">
                <div className="w-8 h-8 bg-gray-200 rounded-full flex items-center justify-center"><Users size={14} className="text-gray-500" /></div>
                <div><p className="text-sm font-medium text-gray-900">{c.name}</p><p className="text-xs text-gray-500">{c.role}</p></div>
              </div>
            ))}
          </div>
          {project.changeOrders.length > 0 && (
            <div className="bg-white rounded-xl border border-gray-100 p-4">
              <h3 className="font-semibold text-sm text-gray-900 mb-3">Change Orders</h3>
              {project.changeOrders.map(co => (
                <div key={co.id} className="flex items-center justify-between py-2">
                  <div><p className="text-sm font-medium text-gray-900">{co.title}</p><p className="text-xs text-gray-500">{co.status}</p></div>
                  <span className="text-sm font-bold text-orange-600">{co.amount}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Documents Tab */}
      {tab === 'documents' && (
        <div className="space-y-2">
          {[
            { name: 'Estimate — 200A Panel Upgrade.pdf', type: 'Estimate', date: 'Jan 10, 2026' },
            { name: 'Service Agreement — Signed.pdf', type: 'Agreement', date: 'Jan 12, 2026' },
            { name: 'Electrical Permit #EP-2026-0142.pdf', type: 'Permit', date: 'Jan 14, 2026' },
            { name: 'Inspection Report — Meter Base.pdf', type: 'Inspection', date: 'Jan 19, 2026' },
          ].map(doc => (
            <div key={doc.name} className="flex items-center gap-3 bg-white rounded-xl border border-gray-100 p-3 hover:shadow-sm transition-all cursor-pointer">
              <div className="p-2 bg-gray-50 rounded-lg"><FileText size={16} className="text-gray-400" /></div>
              <div className="flex-1 min-w-0"><p className="text-sm font-medium text-gray-900 truncate">{doc.name}</p><p className="text-xs text-gray-400">{doc.type} · {doc.date}</p></div>
              <ChevronRight size={14} className="text-gray-300" />
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
