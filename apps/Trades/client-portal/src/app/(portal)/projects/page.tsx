'use client';
import { useState } from 'react';
import Link from 'next/link';
import { Hammer, Clock, CheckCircle2, AlertCircle, ChevronRight, Calendar } from 'lucide-react';

type ProjectStatus = 'active' | 'scheduled' | 'completed' | 'on_hold';
interface Project {
  id: string; name: string; contractor: string; status: ProjectStatus;
  progress: number; lastUpdate: string; totalCost: string; startDate: string;
  trade: string;
}

const statusConfig: Record<ProjectStatus, { label: string; color: string; bg: string; icon: typeof Clock }> = {
  active: { label: 'In Progress', color: 'text-blue-700', bg: 'bg-blue-50', icon: Hammer },
  scheduled: { label: 'Scheduled', color: 'text-purple-700', bg: 'bg-purple-50', icon: Calendar },
  completed: { label: 'Completed', color: 'text-green-700', bg: 'bg-green-50', icon: CheckCircle2 },
  on_hold: { label: 'On Hold', color: 'text-amber-700', bg: 'bg-amber-50', icon: AlertCircle },
};

const mockProjects: Project[] = [
  { id: 'proj-1', name: '200A Panel Upgrade', contractor: "Mike's Electric", status: 'active', progress: 65, lastUpdate: '2 hours ago', totalCost: '$4,800', startDate: 'Jan 15, 2026', trade: 'Electrical' },
  { id: 'proj-2', name: 'HVAC System Replacement', contractor: 'ComfortAir HVAC', status: 'scheduled', progress: 0, lastUpdate: '1 day ago', totalCost: '$12,400', startDate: 'Feb 20, 2026', trade: 'HVAC' },
  { id: 'proj-3', name: 'Bathroom Remodel', contractor: 'Hartford Remodeling', status: 'active', progress: 88, lastUpdate: '5 hours ago', totalCost: '$18,600', startDate: 'Dec 1, 2025', trade: 'Remodeling' },
  { id: 'proj-4', name: 'Water Heater Install', contractor: "Pete's Plumbing", status: 'completed', progress: 100, lastUpdate: '2 weeks ago', totalCost: '$2,100', startDate: 'Jan 5, 2026', trade: 'Plumbing' },
  { id: 'proj-5', name: 'Roof Repair — Storm Damage', contractor: 'TopShield Roofing', status: 'completed', progress: 100, lastUpdate: '1 month ago', totalCost: '$6,200', startDate: 'Nov 10, 2025', trade: 'Roofing' },
];

export default function ProjectsPage() {
  const [filter, setFilter] = useState<'all' | ProjectStatus>('all');
  const filters: { key: 'all' | ProjectStatus; label: string }[] = [
    { key: 'all', label: 'All' }, { key: 'active', label: 'Active' },
    { key: 'scheduled', label: 'Scheduled' }, { key: 'completed', label: 'Completed' },
  ];
  const filtered = filter === 'all' ? mockProjects : mockProjects.filter(p => p.status === filter);

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Projects</h1>
        <p className="text-gray-500 text-sm mt-0.5">{mockProjects.length} total projects</p>
      </div>

      {/* Filters */}
      <div className="flex gap-2 overflow-x-auto pb-1">
        {filters.map(f => (
          <button key={f.key} onClick={() => setFilter(f.key)}
            className={`px-4 py-2 rounded-full text-xs font-medium whitespace-nowrap transition-all ${filter === f.key ? 'bg-orange-500 text-white' : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'}`}>
            {f.label}
          </button>
        ))}
      </div>

      {/* Project Cards */}
      <div className="space-y-3">
        {filtered.map(project => {
          const config = statusConfig[project.status];
          const StatusIcon = config.icon;
          return (
            <Link key={project.id} href={`/projects/${project.id}`}
              className="block bg-white rounded-xl border border-gray-100 shadow-sm hover:shadow-md transition-all p-4">
              <div className="flex items-start justify-between mb-3">
                <div>
                  <h3 className="font-semibold text-gray-900 text-sm">{project.name}</h3>
                  <p className="text-xs text-gray-500 mt-0.5">{project.contractor} · {project.trade}</p>
                </div>
                <span className={`flex items-center gap-1 text-xs font-medium px-2.5 py-1 rounded-full ${config.bg} ${config.color}`}>
                  <StatusIcon size={12} /> {config.label}
                </span>
              </div>
              {project.status !== 'completed' && project.progress > 0 && (
                <div className="mb-3">
                  <div className="flex justify-between text-xs mb-1">
                    <span className="text-gray-500">Progress</span>
                    <span className="font-medium text-gray-700">{project.progress}%</span>
                  </div>
                  <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                    <div className="h-full bg-orange-500 rounded-full transition-all" style={{ width: `${project.progress}%` }} />
                  </div>
                </div>
              )}
              <div className="flex items-center justify-between text-xs">
                <span className="text-gray-400">Updated {project.lastUpdate}</span>
                <div className="flex items-center gap-2">
                  <span className="font-bold text-gray-900">{project.totalCost}</span>
                  <ChevronRight size={14} className="text-gray-300" />
                </div>
              </div>
            </Link>
          );
        })}
      </div>
    </div>
  );
}
