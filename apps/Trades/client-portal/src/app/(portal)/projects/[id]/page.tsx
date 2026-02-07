'use client';
import { useState } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import { ArrowLeft, Hammer, Clock, CheckCircle2, Calendar, FileText, Users, MessageSquare, MapPin, AlertCircle, Inbox } from 'lucide-react';
import { useProject } from '@/lib/hooks/use-projects';
import { useChangeOrders } from '@/lib/hooks/use-change-orders';
import { useInvoices } from '@/lib/hooks/use-invoices';
import { formatCurrency, formatDate } from '@/lib/hooks/mappers';

type ProjectStatus = 'active' | 'scheduled' | 'completed' | 'on_hold';

const statusConfig: Record<ProjectStatus, { label: string; color: string; bg: string; icon: typeof Clock }> = {
  active: { label: 'In Progress', color: 'text-blue-700', bg: 'bg-blue-50', icon: Hammer },
  scheduled: { label: 'Scheduled', color: 'text-purple-700', bg: 'bg-purple-50', icon: Calendar },
  completed: { label: 'Completed', color: 'text-green-700', bg: 'bg-green-50', icon: CheckCircle2 },
  on_hold: { label: 'On Hold', color: 'text-amber-700', bg: 'bg-amber-50', icon: AlertCircle },
};

function DetailSkeleton() {
  return (
    <div className="space-y-5 animate-pulse">
      <div>
        <div className="h-4 w-28 bg-gray-200 rounded mb-3" />
        <div className="flex items-start justify-between">
          <div>
            <div className="h-6 w-48 bg-gray-200 rounded" />
            <div className="h-4 w-32 bg-gray-100 rounded mt-2" />
          </div>
          <div className="h-6 w-20 bg-gray-100 rounded-full" />
        </div>
      </div>
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-4">
        <div className="h-3 bg-gray-100 rounded-full mb-2" />
        <div className="h-3 bg-gray-100 rounded-full w-2/3" />
      </div>
      <div className="grid grid-cols-3 gap-2">
        <div className="bg-white rounded-xl border border-gray-100 p-3 h-16" />
        <div className="bg-white rounded-xl border border-gray-100 p-3 h-16" />
        <div className="bg-white rounded-xl border border-gray-100 p-3 h-16" />
      </div>
      <div className="bg-white rounded-xl border border-gray-100 p-4 h-32" />
    </div>
  );
}

export default function ProjectDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { project, loading: projectLoading } = useProject(id);
  const { orders, loading: ordersLoading } = useChangeOrders();
  const { invoices, loading: invoicesLoading } = useInvoices();

  const [tab, setTab] = useState<'timeline' | 'details' | 'documents'>('timeline');
  const tabs = [
    { key: 'timeline' as const, label: 'Timeline' },
    { key: 'details' as const, label: 'Details' },
    { key: 'documents' as const, label: 'Documents' },
  ];

  const loading = projectLoading || ordersLoading || invoicesLoading;

  if (loading) {
    return (
      <div className="space-y-5">
        <Link href="/projects" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-3">
          <ArrowLeft size={16} /> Back to Projects
        </Link>
        <DetailSkeleton />
      </div>
    );
  }

  if (!project) {
    return (
      <div className="space-y-5">
        <Link href="/projects" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-3">
          <ArrowLeft size={16} /> Back to Projects
        </Link>
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
          <AlertCircle size={32} className="mx-auto text-gray-300 mb-3" />
          <h3 className="font-semibold text-gray-900 text-sm">Project not found</h3>
          <p className="text-xs text-gray-500 mt-1">This project may have been removed or you don't have access.</p>
        </div>
      </div>
    );
  }

  const config = statusConfig[project.status];
  const StatusIcon = config.icon;

  // Filter change orders for this project
  const projectChangeOrders = orders.filter(co => co.jobTitle === project.name);

  // Filter invoices for this project and compute cost summary
  const projectInvoices = invoices.filter(i => i.projectId === id);
  const totalPaid = projectInvoices
    .filter(i => i.status === 'paid')
    .reduce((sum, i) => sum + i.amount, 0);
  const totalInvoiced = projectInvoices.reduce((sum, i) => sum + i.amount, 0);
  const remaining = project.totalCost - totalPaid;

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
            <p className="text-sm text-gray-500 mt-0.5">{project.contractor}{project.trade ? ` · ${project.trade}` : ''}</p>
          </div>
          <span className={`flex items-center gap-1 text-xs font-medium px-2.5 py-1 rounded-full ${config.bg} ${config.color}`}>
            <StatusIcon size={12} /> {config.label}
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
          <div className="h-full rounded-full" style={{ width: `${project.progress}%`, backgroundColor: 'var(--accent)' }} />
        </div>
        <div className="flex justify-between mt-2 text-xs text-gray-400">
          <span>{project.startDate ? `Started ${formatDate(project.startDate)}` : 'Not started'}</span>
          <span>{project.endDate ? `Est. ${formatDate(project.endDate)}` : ''}</span>
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
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-6 text-center">
          <Clock size={28} className="mx-auto text-gray-300 mb-3" />
          <h3 className="font-semibold text-gray-900 text-sm">Timeline</h3>
          <p className="text-xs text-gray-500 mt-1">Timeline events will appear as your project progresses.</p>
        </div>
      )}

      {/* Details Tab */}
      {tab === 'details' && (
        <div className="space-y-4">
          {/* Scope of Work */}
          <div className="bg-white rounded-xl border border-gray-100 p-4">
            <h3 className="font-semibold text-sm text-gray-900 mb-2">Scope of Work</h3>
            {project.description ? (
              <p className="text-sm text-gray-600">{project.description}</p>
            ) : (
              <p className="text-sm text-gray-400 italic">No description provided.</p>
            )}
          </div>

          {/* Cost Summary */}
          <div className="bg-white rounded-xl border border-gray-100 p-4">
            <h3 className="font-semibold text-sm text-gray-900 mb-3">Cost Summary</h3>
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-gray-500">Estimate Total</span>
                <span className="font-medium">{formatCurrency(project.totalCost)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-500">Paid</span>
                <span className="text-green-600 font-medium">{formatCurrency(totalPaid)}</span>
              </div>
              {totalInvoiced > totalPaid && (
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Invoiced (unpaid)</span>
                  <span className="text-amber-600 font-medium">{formatCurrency(totalInvoiced - totalPaid)}</span>
                </div>
              )}
              <div className="flex justify-between text-sm border-t border-gray-100 pt-2">
                <span className="font-medium text-gray-700">Remaining</span>
                <span className="font-bold text-gray-900">{formatCurrency(remaining > 0 ? remaining : 0)}</span>
              </div>
            </div>
          </div>

          {/* Crew */}
          <div className="bg-white rounded-xl border border-gray-100 p-4">
            <h3 className="font-semibold text-sm text-gray-900 mb-3">Crew</h3>
            <div className="flex items-center gap-3 py-2">
              <div className="w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center">
                <Users size={14} className="text-gray-400" />
              </div>
              <p className="text-sm text-gray-500">Crew information will appear here.</p>
            </div>
          </div>

          {/* Change Orders */}
          {projectChangeOrders.length > 0 && (
            <div className="bg-white rounded-xl border border-gray-100 p-4">
              <h3 className="font-semibold text-sm text-gray-900 mb-3">Change Orders</h3>
              {projectChangeOrders.map(co => (
                <div key={co.id} className="flex items-center justify-between py-2">
                  <div>
                    <p className="text-sm font-medium text-gray-900">{co.title}</p>
                    <p className="text-xs text-gray-500">{co.orderNumber} · {co.status}</p>
                  </div>
                  <span className="text-sm font-bold" style={{ color: 'var(--accent)' }}>
                    {co.amount >= 0 ? '+' : ''}{formatCurrency(co.amount)}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Documents Tab */}
      {tab === 'documents' && (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-6 text-center">
          <Inbox size={28} className="mx-auto text-gray-300 mb-3" />
          <h3 className="font-semibold text-gray-900 text-sm">Documents</h3>
          <p className="text-xs text-gray-500 mt-1">Documents will appear here when your contractor uploads them.</p>
        </div>
      )}
    </div>
  );
}
