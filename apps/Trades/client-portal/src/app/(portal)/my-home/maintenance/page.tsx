'use client';
import { useState } from 'react';
import Link from 'next/link';
import { ArrowLeft, Calendar, CheckCircle2, Clock, Pause, Loader2, Bell, AlertTriangle } from 'lucide-react';
import { useHome, type MaintenanceSchedule } from '@/lib/hooks/use-home';

const frequencyLabels: Record<string, string> = {
  monthly: 'Monthly',
  quarterly: 'Every 3 Months',
  semi_annual: 'Every 6 Months',
  annual: 'Yearly',
  biennial: 'Every 2 Years',
  custom: 'Custom',
};

const priorityColors: Record<string, { bg: string; text: string }> = {
  critical: { bg: 'bg-red-50', text: 'text-red-700' },
  high: { bg: 'bg-amber-50', text: 'text-amber-700' },
  medium: { bg: 'bg-blue-50', text: 'text-blue-700' },
  low: { bg: 'bg-gray-50', text: 'text-gray-600' },
};

function isOverdue(schedule: MaintenanceSchedule): boolean {
  return new Date(schedule.nextDueDate) < new Date();
}

function isDueSoon(schedule: MaintenanceSchedule): boolean {
  const due = new Date(schedule.nextDueDate);
  const thirtyDays = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
  return due <= thirtyDays && !isOverdue(schedule);
}

export default function MaintenancePage() {
  const { maintenanceSchedules, loading, completeMaintenanceTask } = useHome();
  const [completing, setCompleting] = useState<string | null>(null);

  const overdue = maintenanceSchedules.filter(isOverdue);
  const dueSoon = maintenanceSchedules.filter(isDueSoon);
  const upcoming = maintenanceSchedules.filter(m => !isOverdue(m) && !isDueSoon(m));

  const handleComplete = async (id: string) => {
    setCompleting(id);
    try {
      await completeMaintenanceTask(id);
    } catch {
      // silent
    } finally {
      setCompleting(null);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 size={24} className="animate-spin text-orange-500" />
      </div>
    );
  }

  const renderScheduleCard = (m: MaintenanceSchedule) => {
    const overdueBool = isOverdue(m);
    const pc = m.aiPriority ? priorityColors[m.aiPriority] || priorityColors.low : null;

    return (
      <div key={m.id} className={`bg-white rounded-xl border shadow-sm p-4 ${overdueBool ? 'border-red-200' : 'border-gray-100'}`}>
        <div className="flex items-start justify-between mb-2">
          <div className="flex-1">
            <h3 className="font-semibold text-sm text-gray-900">{m.title}</h3>
            <p className="text-xs text-gray-500 mt-0.5 capitalize">{m.category.replace(/_/g, ' ')} · {frequencyLabels[m.frequency] || m.frequency}</p>
          </div>
          {overdueBool ? (
            <span className="px-2 py-0.5 rounded-full text-[10px] font-medium bg-red-50 text-red-700">Overdue</span>
          ) : pc && m.aiPriority ? (
            <span className={`px-2 py-0.5 rounded-full text-[10px] font-medium ${pc.bg} ${pc.text}`}>{m.aiPriority}</span>
          ) : null}
        </div>

        {m.description && <p className="text-xs text-gray-600 mb-2">{m.description}</p>}

        <div className="flex items-center justify-between">
          <div className="flex items-center gap-1 text-xs text-gray-500">
            <Calendar size={12} />
            <span>Due: {new Date(m.nextDueDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}</span>
          </div>
          <div className="flex items-center gap-2">
            <Link href="/request" className="text-[10px] text-orange-500 font-medium hover:text-orange-600">Schedule</Link>
            <button
              onClick={() => handleComplete(m.id)}
              disabled={completing === m.id}
              className="text-[10px] text-green-600 font-medium hover:text-green-700 disabled:opacity-50"
            >
              {completing === m.id ? 'Saving...' : 'Done'}
            </button>
          </div>
        </div>

        {m.aiRecommended && m.aiReason && (
          <div className="mt-2 p-2 bg-purple-50 rounded-lg flex items-start gap-2">
            <Bell size={12} className="text-purple-500 mt-0.5 flex-shrink-0" />
            <p className="text-[10px] text-purple-700">{m.aiReason}</p>
          </div>
        )}
      </div>
    );
  };

  return (
    <div className="space-y-5">
      <div>
        <Link href="/my-home" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-3"><ArrowLeft size={16} /> Back to My Home</Link>
        <h1 className="text-xl font-bold text-gray-900">Maintenance Schedule</h1>
        <p className="text-sm text-gray-500 mt-0.5">{maintenanceSchedules.length} active reminders</p>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-3 gap-3">
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-3 text-center">
          <AlertTriangle size={16} className="mx-auto text-red-500 mb-1" />
          <p className="text-lg font-bold text-gray-900">{overdue.length}</p>
          <p className="text-[10px] text-gray-500">Overdue</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-3 text-center">
          <Clock size={16} className="mx-auto text-amber-500 mb-1" />
          <p className="text-lg font-bold text-gray-900">{dueSoon.length}</p>
          <p className="text-[10px] text-gray-500">Due Soon</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-3 text-center">
          <CheckCircle2 size={16} className="mx-auto text-green-500 mb-1" />
          <p className="text-lg font-bold text-gray-900">{upcoming.length}</p>
          <p className="text-[10px] text-gray-500">Upcoming</p>
        </div>
      </div>

      {maintenanceSchedules.length === 0 ? (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
          <Calendar size={32} className="mx-auto text-gray-300 mb-2" />
          <p className="text-sm text-gray-500">No maintenance reminders set</p>
          <p className="text-xs text-gray-400 mt-1">AI-recommended maintenance will appear as equipment is added</p>
        </div>
      ) : (
        <>
          {overdue.length > 0 && (
            <div>
              <h3 className="font-bold text-sm text-red-700 mb-2 flex items-center gap-1"><AlertTriangle size={14} /> Overdue</h3>
              <div className="space-y-2">{overdue.map(renderScheduleCard)}</div>
            </div>
          )}
          {dueSoon.length > 0 && (
            <div>
              <h3 className="font-bold text-sm text-amber-700 mb-2 flex items-center gap-1"><Clock size={14} /> Due Soon</h3>
              <div className="space-y-2">{dueSoon.map(renderScheduleCard)}</div>
            </div>
          )}
          {upcoming.length > 0 && (
            <div>
              <h3 className="font-bold text-sm text-gray-700 mb-2">Upcoming</h3>
              <div className="space-y-2">{upcoming.map(renderScheduleCard)}</div>
            </div>
          )}
        </>
      )}
    </div>
  );
}
