'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Plus,
  Search,
  Users,
  Mail,
  Phone,
  MapPin,
  MoreHorizontal,
  Shield,
  Clock,
  CheckCircle,
  XCircle,
  UserPlus,
  Map,
  LayoutGrid,
  Radio,
  Calendar,
  Briefcase,
  Navigation,
  ChevronRight,
  GripVertical,
  AlertCircle,
  MessageSquare,
  Send,
  X,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge, StatusBadge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { Avatar } from '@/components/ui/avatar';
import { TeamMap } from '@/components/ui/team-map';
import { CommandPalette } from '@/components/command-palette';
import { formatRelativeTime, formatCurrency, formatDate, formatTime, cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';
import { useJobs, useTeam } from '@/lib/hooks/use-jobs';
import { getSupabase } from '@/lib/supabase';
import type { TeamMember, UserRole, Job } from '@/types';

const roleColors: Record<UserRole, { bg: string; text: string }> = {
  owner: { bg: 'bg-amber-100 dark:bg-amber-900/30', text: 'text-amber-700 dark:text-amber-300' },
  admin: { bg: 'bg-purple-100 dark:bg-purple-900/30', text: 'text-purple-700 dark:text-purple-300' },
  office: { bg: 'bg-blue-100 dark:bg-blue-900/30', text: 'text-blue-700 dark:text-blue-300' },
  field_tech: { bg: 'bg-emerald-100 dark:bg-emerald-900/30', text: 'text-emerald-700 dark:text-emerald-300' },
  subcontractor: { bg: 'bg-slate-100 dark:bg-slate-800', text: 'text-slate-700 dark:text-slate-300' },
};

const roleLabels: Record<UserRole, string> = {
  owner: 'Owner',
  admin: 'Admin',
  office: 'Office',
  field_tech: 'Field Tech',
  subcontractor: 'Subcontractor',
};

type ViewMode = 'team' | 'dispatch';

export default function TeamPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const { team } = useTeam();
  const { jobs } = useJobs();
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('all');
  const [showInviteModal, setShowInviteModal] = useState(false);
  const [viewMode, setViewMode] = useState<ViewMode>('dispatch');
  const [selectedJob, setSelectedJob] = useState<Job | null>(null);
  const [showMessageModal, setShowMessageModal] = useState(false);
  const [selectedMemberForMessage, setSelectedMemberForMessage] = useState<TeamMember | null>(null);

  const filteredMembers = team.filter((member) => {
    const matchesSearch =
      member.name.toLowerCase().includes(search.toLowerCase()) ||
      member.email.toLowerCase().includes(search.toLowerCase());

    const matchesRole = roleFilter === 'all' || member.role === roleFilter;

    return matchesSearch && matchesRole;
  });

  const roleOptions = [
    { value: 'all', label: 'All Roles' },
    { value: 'admin', label: 'Admin' },
    { value: 'office', label: 'Office' },
    { value: 'field_tech', label: 'Field Tech' },
    { value: 'subcontractor', label: 'Subcontractor' },
  ];

  const activeCount = team.filter((m) => m.isActive).length;
  const fieldCount = team.filter((m) => m.role === 'field_tech').length;
  const onlineCount = team.filter(
    (m) => m.lastActive && new Date().getTime() - new Date(m.lastActive).getTime() < 30 * 60 * 1000
  ).length;

  // Get today's scheduled jobs
  const todayJobs = jobs.filter((job) => {
    if (!job.scheduledStart) return false;
    const today = new Date();
    const jobDate = new Date(job.scheduledStart);
    return jobDate.toDateString() === today.toDateString();
  });

  const unassignedJobs = jobs.filter(
    (job) => (job.status === 'scheduled' || job.status === 'lead') && job.assignedTo.length === 0
  );

  const handleJobClick = (job: Job) => {
    setSelectedJob(selectedJob?.id === job.id ? null : job);
  };

  const handleMemberClick = (member: TeamMember) => {
    setSelectedMemberForMessage(member);
    setShowMessageModal(true);
  };

  const handleSendMessage = (member: TeamMember) => {
    setSelectedMemberForMessage(member);
    setShowMessageModal(true);
  };

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('team.title')}</h1>
          <p className="text-muted mt-1">
            {viewMode === 'dispatch' ? 'Live dispatch board and team locations' : 'Manage your team members and permissions'}
          </p>
        </div>
        <div className="flex items-center gap-3">
          {/* View Toggle */}
          <div className="flex items-center p-1 bg-secondary rounded-lg">
            <button
              onClick={() => setViewMode('dispatch')}
              className={cn(
                'flex items-center gap-2 px-3 py-1.5 rounded-md text-sm font-medium transition-colors',
                viewMode === 'dispatch' ? 'bg-surface shadow-sm text-main' : 'text-muted hover:text-main'
              )}
            >
              <Map size={16} />
              Dispatch
            </button>
            <button
              onClick={() => setViewMode('team')}
              className={cn(
                'flex items-center gap-2 px-3 py-1.5 rounded-md text-sm font-medium transition-colors',
                viewMode === 'team' ? 'bg-surface shadow-sm text-main' : 'text-muted hover:text-main'
              )}
            >
              <LayoutGrid size={16} />
              Team
            </button>
          </div>
          <Button onClick={() => setShowInviteModal(true)}>
            <UserPlus size={16} />
            Invite Member
          </Button>
        </div>
      </div>

      {viewMode === 'dispatch' ? (
        // ==================== DISPATCH BOARD VIEW ====================
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
          {/* Left Panel - Jobs Queue */}
          <div className="lg:col-span-1 space-y-4">
            {/* Stats */}
            <div className="grid grid-cols-2 gap-3">
              <Card>
                <CardContent className="p-3">
                  <div className="flex items-center gap-2">
                    <div className="p-1.5 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                      <Radio size={14} className="text-emerald-600 dark:text-emerald-400" />
                    </div>
                    <div>
                      <p className="text-lg font-semibold text-main">{onlineCount}</p>
                      <p className="text-xs text-muted">Online</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
              <Card>
                <CardContent className="p-3">
                  <div className="flex items-center gap-2">
                    <div className="p-1.5 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                      <Briefcase size={14} className="text-blue-600 dark:text-blue-400" />
                    </div>
                    <div>
                      <p className="text-lg font-semibold text-main">{todayJobs.length}</p>
                      <p className="text-xs text-muted">{t('common.today')}</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>

            {/* Today's Jobs */}
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm">Today's Schedule</CardTitle>
              </CardHeader>
              <CardContent className="p-0">
                <div className="divide-y divide-main max-h-[300px] overflow-y-auto">
                  {todayJobs.length === 0 ? (
                    <div className="px-4 py-6 text-center text-muted text-sm">
                      No jobs scheduled for today
                    </div>
                  ) : (
                    todayJobs.map((job) => (
                      <button
                        key={job.id}
                        className={cn(
                          'w-full px-4 py-3 text-left hover:bg-surface-hover transition-colors',
                          selectedJob?.id === job.id && 'bg-accent-light'
                        )}
                        onClick={() => handleJobClick(job)}
                      >
                        <div className="flex items-start gap-2">
                          <div
                            className={cn(
                              'w-1 h-full min-h-[40px] rounded-full flex-shrink-0',
                              job.priority === 'urgent' ? 'bg-red-500' : job.priority === 'high' ? 'bg-amber-500' : 'bg-blue-500'
                            )}
                          />
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2">
                              <p className="text-sm font-medium text-main truncate">{job.title}</p>
                              {job.priority === 'urgent' && (
                                <AlertCircle size={12} className="text-red-500 flex-shrink-0" />
                              )}
                            </div>
                            <p className="text-xs text-muted truncate">
                              {job.customer?.firstName} {job.customer?.lastName}
                            </p>
                            <div className="flex items-center gap-2 mt-1">
                              {job.scheduledStart && (
                                <span className="text-xs text-muted">
                                  {formatTime(job.scheduledStart)}
                                </span>
                              )}
                              <StatusBadge status={job.status} size="sm" />
                            </div>
                          </div>
                        </div>
                      </button>
                    ))
                  )}
                </div>
              </CardContent>
            </Card>

            {/* Unassigned Jobs */}
            {unassignedJobs.length > 0 && (
              <Card className="border-amber-200 dark:border-amber-900/50">
                <CardHeader className="pb-2">
                  <CardTitle className="text-sm flex items-center gap-2">
                    <AlertCircle size={14} className="text-amber-500" />
                    Unassigned ({unassignedJobs.length})
                  </CardTitle>
                </CardHeader>
                <CardContent className="p-0">
                  <div className="divide-y divide-main max-h-[200px] overflow-y-auto">
                    {unassignedJobs.map((job) => (
                      <div
                        key={job.id}
                        className="px-4 py-3 hover:bg-surface-hover cursor-grab transition-colors"
                        draggable
                      >
                        <div className="flex items-center gap-2">
                          <GripVertical size={14} className="text-muted flex-shrink-0" />
                          <div className="flex-1 min-w-0">
                            <p className="text-sm font-medium text-main truncate">{job.title}</p>
                            <p className="text-xs text-muted">
                              {job.scheduledStart ? formatDate(job.scheduledStart) : 'No date set'}
                            </p>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            )}

            {/* Field Techs List */}
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-sm">{t('common.fieldTechs')}</CardTitle>
              </CardHeader>
              <CardContent className="p-0">
                <div className="divide-y divide-main">
                  {team
                    .filter((m) => m.role === 'field_tech')
                    .map((member) => {
                      const isOnline =
                        member.lastActive &&
                        new Date().getTime() - new Date(member.lastActive).getTime() < 30 * 60 * 1000;
                      const assignedJobs = jobs.filter(
                        (j) => j.assignedTo.includes(member.id) && (j.status === 'scheduled' || j.status === 'in_progress')
                      );

                      return (
                        <div
                          key={member.id}
                          className="px-4 py-3 hover:bg-surface-hover transition-colors"
                        >
                          <div className="flex items-center gap-3">
                            <Avatar name={member.name} size="sm" showStatus isOnline={isOnline} />
                            <div className="flex-1 min-w-0">
                              <p className="text-sm font-medium text-main truncate">{member.name}</p>
                              <p className="text-xs text-muted">
                                {assignedJobs.length > 0
                                  ? `${assignedJobs.length} job${assignedJobs.length > 1 ? 's' : ''} assigned`
                                  : 'Available'}
                              </p>
                            </div>
                            <div className="flex items-center gap-2">
                              {isOnline && (
                                <span className="text-xs text-emerald-600 dark:text-emerald-400 font-medium">
                                  Live
                                </span>
                              )}
                              <button
                                onClick={() => handleSendMessage(member)}
                                className="p-1.5 hover:bg-surface rounded-lg transition-colors text-muted hover:text-accent"
                                title="Send message"
                              >
                                <MessageSquare size={16} />
                              </button>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Right Panel - Map */}
          <div className="lg:col-span-3">
            <Card className="h-[calc(100vh-14rem)]">
              <CardHeader className="pb-2">
                <div className="flex items-center justify-between">
                  <CardTitle className="flex items-center gap-2">
                    <Radio size={16} className="text-emerald-500" />
                    Live Dispatch Board
                  </CardTitle>
                  <div className="flex items-center gap-2 text-xs text-muted">
                    <span className="w-2 h-2 bg-emerald-500 rounded-full animate-pulse" />
                    Live updates every 60s
                  </div>
                </div>
              </CardHeader>
              <CardContent className="p-4 h-[calc(100%-4rem)]">
                <TeamMap
                  members={team}
                  jobs={jobs}
                  variant="full"
                  onMemberClick={handleMemberClick}
                  onJobClick={handleJobClick}
                  className="h-full"
                />
              </CardContent>
            </Card>
          </div>
        </div>
      ) : (
        // ==================== TEAM MEMBERS VIEW ====================
        <>
          {/* Stats */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <Card>
              <CardContent className="p-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                    <Users size={20} className="text-blue-600 dark:text-blue-400" />
                  </div>
                  <div>
                    <p className="text-2xl font-semibold text-main">{team.length}</p>
                    <p className="text-sm text-muted">Total Members</p>
                  </div>
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                    <CheckCircle size={20} className="text-emerald-600 dark:text-emerald-400" />
                  </div>
                  <div>
                    <p className="text-2xl font-semibold text-main">{onlineCount}</p>
                    <p className="text-sm text-muted">Online Now</p>
                  </div>
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                    <MapPin size={20} className="text-purple-600 dark:text-purple-400" />
                  </div>
                  <div>
                    <p className="text-2xl font-semibold text-main">{fieldCount}</p>
                    <p className="text-sm text-muted">{t('common.fieldTechs')}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                    <Shield size={20} className="text-amber-600 dark:text-amber-400" />
                  </div>
                  <div>
                    <p className="text-2xl font-semibold text-main">{activeCount}</p>
                    <p className="text-sm text-muted">{t('common.active')}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Filters */}
          <div className="flex flex-col sm:flex-row gap-4">
            <SearchInput
              value={search}
              onChange={setSearch}
              placeholder="Search team members..."
              className="sm:w-80"
            />
            <Select
              options={roleOptions}
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value)}
              className="sm:w-48"
            />
          </div>

          {/* Team Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredMembers.map((member) => (
              <TeamMemberCard key={member.id} member={member} />
            ))}
          </div>
        </>
      )}

      {/* Invite Modal */}
      {showInviteModal && (
        <InviteModal onClose={() => setShowInviteModal(false)} />
      )}

      {/* Message Modal */}
      {showMessageModal && selectedMemberForMessage && (
        <MessageModal
          member={selectedMemberForMessage}
          onClose={() => {
            setShowMessageModal(false);
            setSelectedMemberForMessage(null);
          }}
        />
      )}
    </div>
  );
}

function TeamMemberCard({ member }: { member: TeamMember }) {
  const isOnline =
    member.lastActive &&
    new Date().getTime() - new Date(member.lastActive).getTime() < 30 * 60 * 1000;

  const roleStyle = roleColors[member.role];

  return (
    <Card className="p-6">
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-4">
          <Avatar
            name={member.name}
            size="lg"
            showStatus
            isOnline={isOnline}
          />
          <div>
            <h4 className="font-medium text-main">{member.name}</h4>
            <span
              className={cn(
                'inline-block px-2 py-0.5 text-xs font-medium rounded-full mt-1',
                roleStyle.bg,
                roleStyle.text
              )}
            >
              {roleLabels[member.role]}
            </span>
          </div>
        </div>
        <button className="p-1.5 hover:bg-surface-hover rounded-lg transition-colors">
          <MoreHorizontal size={18} className="text-muted" />
        </button>
      </div>

      <div className="mt-4 space-y-2">
        <div className="flex items-center gap-2 text-sm text-muted">
          <Mail size={14} />
          <span className="truncate">{member.email}</span>
        </div>
        {member.phone && (
          <div className="flex items-center gap-2 text-sm text-muted">
            <Phone size={14} />
            <span>{member.phone}</span>
          </div>
        )}
        {member.location && isOnline && (
          <div className="flex items-center gap-2 text-sm text-muted">
            <MapPin size={14} />
            <span>On location</span>
          </div>
        )}
      </div>

      <div className="mt-4 pt-4 border-t border-main">
        <div className="flex items-center justify-between text-sm">
          <span className="text-muted">Last Active</span>
          <span className={cn('font-medium', isOnline ? 'text-emerald-600' : 'text-muted')}>
            {isOnline ? 'Online' : member.lastActive ? formatRelativeTime(member.lastActive) : 'Never'}
          </span>
        </div>
      </div>
    </Card>
  );
}

function InviteModal({ onClose }: { onClose: () => void }) {
  const { t } = useTranslation();
  const [email, setEmail] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [phone, setPhone] = useState('');
  const [role, setRole] = useState('field_tech');
  const [trade, setTrade] = useState('');
  const [sending, setSending] = useState(false);
  const [error, setError] = useState('');

  const handleInvite = async () => {
    if (!email.trim()) { setError('Email is required'); return; }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) { setError('Invalid email address'); return; }
    if (!firstName.trim()) { setError('First name is required'); return; }
    setError('');
    setSending(true);
    try {
      const { getSupabase } = await import('@/lib/supabase');
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');
      const companyId = user.app_metadata?.company_id;

      // Create invite record
      await supabase.from('team_invites').insert({
        company_id: companyId,
        email: email.trim().toLowerCase(),
        first_name: firstName.trim(),
        last_name: lastName.trim(),
        phone: phone.trim() || null,
        role,
        trade: trade || null,
        invited_by: user.id,
        status: 'pending',
      });
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to send invite');
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>Invite Team Member</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {error && (
            <div className="px-3 py-2.5 rounded-lg text-sm bg-red-500/10 text-red-500">{error}</div>
          )}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">First Name</label>
              <input
                type="text"
                value={firstName}
                onChange={(e) => setFirstName(e.target.value)}
                placeholder="John"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Last Name</label>
              <input
                type="text"
                value={lastName}
                onChange={(e) => setLastName(e.target.value)}
                placeholder="Smith"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
              />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Email Address</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="team@company.com"
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('common.phone')}</label>
            <input
              type="tel"
              value={phone}
              onChange={(e) => {
                const digits = e.target.value.replace(/\D/g, '').slice(0, 10);
                const formatted = digits.length > 6 ? `(${digits.slice(0,3)}) ${digits.slice(3,6)}-${digits.slice(6)}` : digits.length > 3 ? `(${digits.slice(0,3)}) ${digits.slice(3)}` : digits;
                setPhone(formatted);
              }}
              placeholder="(860) 555-0123"
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
            />
          </div>
          <Select
            label="Role"
            options={[
              { value: 'admin', label: 'Admin - Full access except billing' },
              { value: 'office_manager', label: 'Office Manager - Customers, bids, jobs, invoices' },
              { value: 'field_tech', label: 'Field Tech - Assigned jobs + field tools' },
              { value: 'apprentice', label: 'Apprentice - Limited field access' },
              { value: 'subcontractor', label: 'Subcontractor - Their assigned work only' },
            ]}
            value={role}
            onChange={(e) => setRole(e.target.value)}
          />
          <Select
            label="Trade Specialty"
            options={[
              { value: '', label: 'Select trade...' },
              { value: 'electrical', label: 'Electrical' },
              { value: 'plumbing', label: 'Plumbing' },
              { value: 'hvac', label: 'HVAC' },
              { value: 'roofing', label: 'Roofing' },
              { value: 'solar', label: 'Solar' },
              { value: 'gc', label: 'General Contractor' },
              { value: 'remodeler', label: 'Remodeler' },
              { value: 'landscaping', label: 'Landscaping' },
              { value: 'painting', label: 'Painting' },
              { value: 'other', label: 'Other' },
            ]}
            value={trade}
            onChange={(e) => setTrade(e.target.value)}
          />
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>
              Cancel
            </Button>
            <Button className="flex-1" onClick={handleInvite} disabled={sending}>
              <Mail size={16} />
              {sending ? 'Sending...' : 'Send Invite'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function MessageModal({ member, onClose }: { member: TeamMember; onClose: () => void }) {
  const [message, setMessage] = useState('');
  const [messageType, setMessageType] = useState<'sms' | 'push'>('push');
  const [sending, setSending] = useState(false);

  const handleSend = async () => {
    if (!message.trim()) return;
    setSending(true);
    try {
      if (messageType === 'sms' && member.phone) {
        const supabase = getSupabase();
        await supabase.functions.invoke('signalwire-sms', {
          body: { action: 'send', to: member.phone, message: message.trim() },
        });
      }
      // Push notifications deferred to mobile app integration
      onClose();
    } catch {
      alert('Failed to send message. Please try again.');
    } finally {
      setSending(false);
    }
  };

  const quickMessages = [
    'Head to the next job when ready',
    'Customer is waiting - please call them',
    'Take photos before you leave the site',
    'Check in when you arrive',
    'Need an update on current job',
  ];

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Avatar name={member.name} size="sm" />
              <div>
                <CardTitle className="text-base">Message {member.name}</CardTitle>
                <p className="text-xs text-muted">{member.phone || member.email}</p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="p-1.5 hover:bg-surface-hover rounded-lg transition-colors"
            >
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Message Type Toggle */}
          <div className="flex items-center p-1 bg-secondary rounded-lg">
            <button
              onClick={() => setMessageType('push')}
              className={cn(
                'flex-1 px-3 py-1.5 rounded-md text-sm font-medium transition-colors',
                messageType === 'push' ? 'bg-surface shadow-sm text-main' : 'text-muted hover:text-main'
              )}
            >
              Push Notification
            </button>
            <button
              onClick={() => setMessageType('sms')}
              className={cn(
                'flex-1 px-3 py-1.5 rounded-md text-sm font-medium transition-colors',
                messageType === 'sms' ? 'bg-surface shadow-sm text-main' : 'text-muted hover:text-main'
              )}
            >
              SMS
            </button>
          </div>

          {/* Quick Messages */}
          <div>
            <label className="block text-sm font-medium text-main mb-2">Quick Messages</label>
            <div className="flex flex-wrap gap-2">
              {quickMessages.map((qm, idx) => (
                <button
                  key={idx}
                  onClick={() => setMessage(qm)}
                  className="px-2 py-1 text-xs bg-secondary hover:bg-surface-hover rounded-md transition-colors text-muted hover:text-main"
                >
                  {qm}
                </button>
              ))}
            </div>
          </div>

          {/* Message Input */}
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">
              Message
            </label>
            <textarea
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Type your message..."
              rows={3}
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent resize-none"
            />
          </div>

          <div className="flex items-center gap-3 pt-2">
            <Button variant="secondary" className="flex-1" onClick={onClose}>
              Cancel
            </Button>
            <Button
              className="flex-1"
              onClick={handleSend}
              disabled={!message.trim() || sending}
            >
              <Send size={16} />
              {sending ? 'Sending...' : 'Send'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
