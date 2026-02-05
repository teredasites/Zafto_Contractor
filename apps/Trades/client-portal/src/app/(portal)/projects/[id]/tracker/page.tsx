'use client';
import Link from 'next/link';
import { ArrowLeft, MapPin, Phone, MessageSquare, Clock, CheckCircle2, Truck, Wrench, ClipboardCheck, User } from 'lucide-react';

const tracker = {
  crewMember: 'Mike Torres', role: 'Lead Electrician', phone: '(860) 555-0142', photo: null,
  eta: '12 min', distance: '3.2 miles', jobName: '200A Panel Upgrade',
  currentStep: 2,
  steps: [
    { label: 'Dispatched', icon: ClipboardCheck, time: '8:15 AM' },
    { label: 'En Route', icon: Truck, time: '8:22 AM' },
    { label: 'On Site', icon: MapPin, time: null },
    { label: 'In Progress', icon: Wrench, time: null },
    { label: 'Complete', icon: CheckCircle2, time: null },
  ],
  todayCrew: [
    { name: 'Mike Torres', role: 'Lead Electrician', arriving: true },
    { name: 'James Park', role: 'Apprentice', arriving: true },
  ],
};

export default function LiveTrackerPage() {
  return (
    <div className="space-y-5">
      <Link href="/projects/proj-1" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700">
        <ArrowLeft size={16} /> Back to Project
      </Link>

      {/* Live ETA Card */}
      <div className="bg-gradient-to-br from-blue-600 to-blue-700 rounded-2xl p-6 text-white">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-14 h-14 bg-white/20 rounded-full flex items-center justify-center">
            <User size={24} />
          </div>
          <div>
            <h2 className="font-bold text-lg">{tracker.crewMember}</h2>
            <p className="text-blue-200 text-sm">{tracker.role}</p>
          </div>
        </div>
        <div className="bg-white/10 rounded-xl p-4 mb-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-blue-200 text-xs">Estimated Arrival</p>
              <p className="text-3xl font-black mt-0.5">{tracker.eta}</p>
            </div>
            <div className="text-right">
              <p className="text-blue-200 text-xs">Distance</p>
              <p className="text-lg font-bold mt-0.5">{tracker.distance}</p>
            </div>
          </div>
          <div className="mt-3 h-2 bg-white/20 rounded-full overflow-hidden">
            <div className="h-full bg-white rounded-full animate-pulse" style={{ width: '65%' }} />
          </div>
        </div>
        <div className="flex gap-3">
          <button className="flex-1 py-2.5 bg-white/20 hover:bg-white/30 rounded-xl text-sm font-medium flex items-center justify-center gap-2 transition-all">
            <Phone size={16} /> Call
          </button>
          <Link href="/messages" className="flex-1 py-2.5 bg-white/20 hover:bg-white/30 rounded-xl text-sm font-medium flex items-center justify-center gap-2 transition-all">
            <MessageSquare size={16} /> Message
          </Link>
        </div>
      </div>

      {/* Status Steps */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
        <h3 className="font-bold text-sm text-gray-900 mb-4">Job Status</h3>
        <div className="space-y-0">
          {tracker.steps.map((step, i) => {
            const Icon = step.icon;
            const isComplete = i < tracker.currentStep;
            const isCurrent = i === tracker.currentStep;
            return (
              <div key={step.label} className="flex gap-3">
                <div className="flex flex-col items-center">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center ${isComplete ? 'bg-green-100' : isCurrent ? 'bg-blue-100 animate-pulse' : 'bg-gray-100'}`}>
                    <Icon size={14} className={isComplete ? 'text-green-600' : isCurrent ? 'text-blue-600' : 'text-gray-400'} />
                  </div>
                  {i < tracker.steps.length - 1 && <div className={`w-0.5 h-6 ${isComplete ? 'bg-green-200' : 'bg-gray-200'}`} />}
                </div>
                <div className="pb-6 last:pb-0">
                  <p className={`text-sm font-medium ${isComplete ? 'text-green-700' : isCurrent ? 'text-blue-700' : 'text-gray-400'}`}>{step.label}</p>
                  {step.time && <p className="text-xs text-gray-400">{step.time}</p>}
                  {isCurrent && <p className="text-xs text-blue-500 font-medium">Currently here</p>}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Today's Crew */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
        <h3 className="font-bold text-sm text-gray-900 mb-3">Today&apos;s Crew</h3>
        {tracker.todayCrew.map(member => (
          <div key={member.name} className="flex items-center gap-3 py-2.5">
            <div className="w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center">
              <User size={16} className="text-gray-500" />
            </div>
            <div className="flex-1">
              <p className="text-sm font-medium text-gray-900">{member.name}</p>
              <p className="text-xs text-gray-500">{member.role}</p>
            </div>
            {member.arriving && (
              <span className="text-xs px-2 py-0.5 bg-blue-50 text-blue-600 rounded-full font-medium flex items-center gap-1">
                <MapPin size={10} /> En Route
              </span>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
