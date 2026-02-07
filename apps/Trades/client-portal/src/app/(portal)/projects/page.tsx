'use client';
import { useState } from 'react';
import Link from 'next/link';
import { Hammer, Clock, CheckCircle2, AlertCircle, ChevronRight, Calendar } from 'lucide-react';
import { useProjects } from '@/lib/hooks/use-projects';
import { formatCurrency } from '@/lib/hooks/mappers';

type ProjectStatus = 'active' | 'scheduled' | 'completed' | 'on_hold';

const statusConfig: Record<ProjectStatus, { label: string; color: string; bg: string; icon: typeof Clock }> = {
  active: { label: 'In Progress', color: 'text-blue-700', bg: 'bg-blue-50', icon: Hammer },
  scheduled: { label: 'Scheduled', color: 'text-purple-700', bg: 'bg-purple-50', icon: Calendar },
  completed: { label: 'Completed', color: 'text-green-700', bg: 'bg-green-50', icon: CheckCircle2 },
  on_hold: { label: 'On Hold', color: 'text-amber-700', bg: 'bg-amber-50', icon: AlertCircle },
};

function ProjectCardSkeleton() {
  return (
    <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-4 animate-pulse">
      <div className="flex items-start justify-between mb-3">
        <div>
          <div className="h-4 w-40 bg-gray-200 rounded" />
          <div className="h-3 w-28 bg-gray-100 rounded mt-2" />
        </div>
        <div className="h-6 w-20 bg-gray-100 rounded-full" />
      </div>
      <div className="mb-3">
        <div className="h-2 bg-gray-100 rounded-full" />
      </div>
      <div className="flex items-center justify-between">
        <div className="h-3 w-24 bg-gray-100 rounded" />
        <div className="h-4 w-16 bg-gray-200 rounded" />
      </div>
    </div>
  );
}

export default function ProjectsPage() {
  const { projects, loading } = useProjects();
  const [filter, setFilter] = useState<'all' | ProjectStatus>('all');
  const filters: { key: 'all' | ProjectStatus; label: string }[] = [
    { key: 'all', label: 'All' }, { key: 'active', label: 'Active' },
    { key: 'scheduled', label: 'Scheduled' }, { key: 'completed', label: 'Completed' },
  ];
  const filtered = filter === 'all' ? projects : projects.filter(p => p.status === filter);

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Projects</h1>
        <p className="text-gray-500 text-sm mt-0.5">{projects.length} total project{projects.length !== 1 ? 's' : ''}</p>
      </div>

      {/* Filters */}
      <div className="flex gap-2 overflow-x-auto pb-1">
        {filters.map(f => (
          <button key={f.key} onClick={() => setFilter(f.key)}
            className={`px-4 py-2 rounded-full text-xs font-medium whitespace-nowrap transition-all ${filter === f.key ? 'text-white' : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'}`}
            style={filter === f.key ? { backgroundColor: 'var(--accent)' } : undefined}>
            {f.label}
          </button>
        ))}
      </div>

      {/* Loading Skeleton */}
      {loading && (
        <div className="space-y-3">
          <ProjectCardSkeleton />
          <ProjectCardSkeleton />
          <ProjectCardSkeleton />
        </div>
      )}

      {/* Empty State */}
      {!loading && projects.length === 0 && (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
          <Hammer size={32} className="mx-auto text-gray-300 mb-3" />
          <h3 className="font-semibold text-gray-900 text-sm">No projects yet</h3>
          <p className="text-xs text-gray-500 mt-1">Your projects will appear here once your contractor creates them.</p>
        </div>
      )}

      {/* No results for filter */}
      {!loading && projects.length > 0 && filtered.length === 0 && (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-6 text-center">
          <p className="text-sm text-gray-500">No {filter.replace('_', ' ')} projects</p>
        </div>
      )}

      {/* Project Cards */}
      {!loading && filtered.length > 0 && (
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
                    <p className="text-xs text-gray-500 mt-0.5">{project.contractor}{project.trade ? ` · ${project.trade}` : ''}</p>
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
                      <div className="h-full rounded-full transition-all" style={{ width: `${project.progress}%`, backgroundColor: 'var(--accent)' }} />
                    </div>
                  </div>
                )}
                <div className="flex items-center justify-between text-xs">
                  <span className="text-gray-400">Updated {project.lastUpdate}</span>
                  <div className="flex items-center gap-2">
                    <span className="font-bold text-gray-900">{formatCurrency(project.totalCost)}</span>
                    <ChevronRight size={14} className="text-gray-300" />
                  </div>
                </div>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
