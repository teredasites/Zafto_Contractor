'use client';

import { useParams } from 'next/navigation';
import Link from 'next/link';
import { useState, useEffect } from 'react';
import { ArrowLeft, MapPin, Phone, MessageSquare, Clock, CheckCircle2, Truck, Wrench, ClipboardCheck, User, AlertCircle } from 'lucide-react';
import { useProject } from '@/lib/hooks/use-projects';
import { getSupabase } from '@/lib/supabase';

interface TeamMember {
  id: string;
  name: string;
  role: string;
}

const STATUS_STEPS = [
  { key: 'draft', label: 'Scheduled', icon: ClipboardCheck },
  { key: 'dispatched', label: 'Dispatched', icon: ClipboardCheck },
  { key: 'en_route', label: 'En Route', icon: Truck },
  { key: 'in_progress', label: 'On Site', icon: Wrench },
  { key: 'completed', label: 'Complete', icon: CheckCircle2 },
];

function getStepIndex(rawStatus: string): number {
  const statusMap: Record<string, number> = {
    draft: 0, scheduled: 0, lead: 0,
    dispatched: 1,
    en_route: 2,
    in_progress: 3, on_hold: 3,
    completed: 4, invoiced: 4, paid: 4,
  };
  return statusMap[rawStatus] ?? 0;
}

export default function LiveTrackerPage() {
  const params = useParams();
  const projectId = params.id as string;
  const { project, loading, error } = useProject(projectId);
  const [teamMembers, setTeamMembers] = useState<TeamMember[]>([]);

  // Fetch assigned team members
  useEffect(() => {
    if (!project || project.assignedUserIds.length === 0) return;
    const fetchTeam = async () => {
      const supabase = getSupabase();
      const { data } = await supabase
        .from('users')
        .select('id, name, role')
        .in('id', project.assignedUserIds);
      if (data) {
        setTeamMembers(data.map((u: Record<string, unknown>) => ({
          id: u.id as string,
          name: (u.name as string) || 'Team Member',
          role: (u.role as string) || 'technician',
        })));
      }
    };
    fetchTeam();
  }, [project]);

  if (loading) {
    return (
      <div className="space-y-5 animate-pulse">
        <div className="h-6 w-32 bg-gray-200 rounded" />
        <div className="h-64 bg-gray-200 rounded-2xl" />
        <div className="h-48 bg-gray-200 rounded-xl" />
      </div>
    );
  }

  if (error || !project) {
    return (
      <div className="space-y-5">
        <Link href={`/projects/${projectId}`} className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700">
          <ArrowLeft size={16} /> Back to Project
        </Link>
        <div className="bg-white rounded-xl border border-gray-100 p-8 text-center">
          <AlertCircle size={32} className="mx-auto text-gray-400 mb-3" />
          <p className="text-gray-600">Unable to load job tracker</p>
          <p className="text-sm text-gray-400 mt-1">{error || 'Project not found'}</p>
        </div>
      </div>
    );
  }

  const currentStep = getStepIndex(project.rawStatus);
  const leadMember = teamMembers[0];
  const scheduledTime = project.scheduledStart
    ? new Date(project.scheduledStart).toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })
    : null;

  const formatRole = (role: string) =>
    role.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());

  return (
    <div className="space-y-5">
      <Link href={`/projects/${projectId}`} className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700">
        <ArrowLeft size={16} /> Back to Project
      </Link>

      {/* Live Status Card */}
      <div className="bg-gradient-to-br from-blue-600 to-blue-700 rounded-2xl p-6 text-white">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-14 h-14 bg-white/20 rounded-full flex items-center justify-center">
            <User size={24} />
          </div>
          <div>
            <h2 className="font-bold text-lg">{leadMember?.name || 'Crew Pending'}</h2>
            <p className="text-blue-200 text-sm">{leadMember ? formatRole(leadMember.role) : 'Not yet assigned'}</p>
          </div>
        </div>
        <div className="bg-white/10 rounded-xl p-4 mb-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-blue-200 text-xs">Job Status</p>
              <p className="text-2xl font-black mt-0.5 capitalize">{project.rawStatus.replace(/_/g, ' ')}</p>
            </div>
            <div className="text-right">
              <p className="text-blue-200 text-xs">Scheduled</p>
              <p className="text-lg font-bold mt-0.5">{scheduledTime || 'TBD'}</p>
            </div>
          </div>
          <div className="mt-3 h-2 bg-white/20 rounded-full overflow-hidden">
            <div
              className="h-full bg-white rounded-full transition-all duration-500"
              style={{ width: `${Math.max(10, (currentStep / (STATUS_STEPS.length - 1)) * 100)}%` }}
            />
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
        <h3 className="font-bold text-sm text-gray-900 mb-4">Job Progress</h3>
        <div className="space-y-0">
          {STATUS_STEPS.map((step, i) => {
            const Icon = step.icon;
            const isComplete = i < currentStep;
            const isCurrent = i === currentStep;
            return (
              <div key={step.key} className="flex gap-3">
                <div className="flex flex-col items-center">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center ${isComplete ? 'bg-green-100' : isCurrent ? 'bg-blue-100 animate-pulse' : 'bg-gray-100'}`}>
                    <Icon size={14} className={isComplete ? 'text-green-600' : isCurrent ? 'text-blue-600' : 'text-gray-400'} />
                  </div>
                  {i < STATUS_STEPS.length - 1 && <div className={`w-0.5 h-6 ${isComplete ? 'bg-green-200' : 'bg-gray-200'}`} />}
                </div>
                <div className="pb-6 last:pb-0">
                  <p className={`text-sm font-medium ${isComplete ? 'text-green-700' : isCurrent ? 'text-blue-700' : 'text-gray-400'}`}>{step.label}</p>
                  {isCurrent && <p className="text-xs text-blue-500 font-medium">Current status</p>}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Today's Crew */}
      <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
        <h3 className="font-bold text-sm text-gray-900 mb-3">Assigned Crew</h3>
        {teamMembers.length === 0 ? (
          <p className="text-sm text-gray-500 py-2">Crew not yet assigned</p>
        ) : (
          teamMembers.map(member => (
            <div key={member.id} className="flex items-center gap-3 py-2.5">
              <div className="w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center">
                <User size={16} className="text-gray-500" />
              </div>
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900">{member.name}</p>
                <p className="text-xs text-gray-500">{formatRole(member.role)}</p>
              </div>
              {currentStep >= 2 && currentStep < 4 && (
                <span className="text-xs px-2 py-0.5 bg-green-50 text-green-600 rounded-full font-medium flex items-center gap-1">
                  <MapPin size={10} /> On Site
                </span>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
}
