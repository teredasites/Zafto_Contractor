'use client';

import { useState, useMemo } from 'react';
import {
  Plus,
  Briefcase,
  Users,
  UserCheck,
  Calendar,
  Award,
  ChevronDown,
  ChevronUp,
  Play,
  Pause,
  XCircle,
  Eye,
  FileText,
  Star,
  Clock,
  MapPin,
  DollarSign,
  Loader2,
  Check,
  X,
  Video,
  Phone,
  Building2,
  UserPlus,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { Avatar } from '@/components/ui/avatar';
import { CommandPalette } from '@/components/command-palette';
import { formatDate, formatDateTime, cn } from '@/lib/utils';
import {
  useHiring,
  type JobPosting,
  type Applicant,
  type InterviewSchedule,
  type PostingStatus,
  type EmploymentType,
  type ApplicantStage,
  type ApplicantSource,
  type InterviewStatus,
  type PayType,
} from '@/lib/hooks/use-hiring';
import { useTranslation } from '@/lib/translations';
import { formatCurrency, formatDateLocale, formatNumber, formatPercent, formatDateTimeLocale, formatRelativeTimeLocale } from '@/lib/format-locale';

// ==================== STATUS CONFIGS ====================

const postingStatusConfig: Record<PostingStatus, { label: string; variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple' }> = {
  draft: { label: 'Draft', variant: 'default' },
  active: { label: 'Active', variant: 'success' },
  paused: { label: 'Paused', variant: 'warning' },
  filled: { label: 'Filled', variant: 'purple' },
  closed: { label: 'Closed', variant: 'secondary' },
  expired: { label: 'Expired', variant: 'error' },
};

const employmentTypeLabels: Record<EmploymentType, string> = {
  full_time: 'Full-Time',
  part_time: 'Part-Time',
  contract: 'Contract',
  seasonal: 'Seasonal',
  intern: 'Intern',
  apprentice: 'Apprentice',
};

const payTypeLabels: Record<PayType, string> = {
  hourly: '/hr',
  salary: '/yr',
  commission: ' commission',
  per_job: '/job',
};

const stageConfig: Record<ApplicantStage, { label: string; variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple' }> = {
  applied: { label: 'Applied', variant: 'info' },
  screening: { label: 'Screening', variant: 'default' },
  phone_screen: { label: 'Phone Screen', variant: 'purple' },
  interview: { label: 'Interview', variant: 'purple' },
  skills_test: { label: 'Skills Test', variant: 'warning' },
  reference_check: { label: 'Ref. Check', variant: 'warning' },
  background_check: { label: 'BG Check', variant: 'warning' },
  offer: { label: 'Offer', variant: 'success' },
  hired: { label: 'Hired', variant: 'success' },
  rejected: { label: 'Rejected', variant: 'error' },
  withdrawn: { label: 'Withdrawn', variant: 'secondary' },
};

const sourceLabels: Record<ApplicantSource, string> = {
  direct: 'Direct',
  indeed: 'Indeed',
  linkedin: 'LinkedIn',
  ziprecruiter: 'ZipRecruiter',
  referral: 'Referral',
  website: 'Website',
  walk_in: 'Walk-In',
  other: 'Other',
};

const interviewStatusConfig: Record<InterviewStatus, { label: string; variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple' }> = {
  scheduled: { label: 'Scheduled', variant: 'info' },
  confirmed: { label: 'Confirmed', variant: 'success' },
  in_progress: { label: 'In Progress', variant: 'purple' },
  completed: { label: 'Completed', variant: 'success' },
  cancelled: { label: 'Cancelled', variant: 'error' },
  no_show: { label: 'No Show', variant: 'warning' },
  rescheduled: { label: 'Rescheduled', variant: 'default' },
};

const interviewTypeLabels: Record<string, string> = {
  in_person: 'In Person',
  phone: 'Phone',
  video: 'Video',
  working_interview: 'Working Interview',
  group: 'Group',
};

const interviewTypeIcons: Record<string, typeof Phone> = {
  in_person: Building2,
  phone: Phone,
  video: Video,
  working_interview: Briefcase,
  group: Users,
};

// Pipeline stages (visible columns)
const pipelineStages: ApplicantStage[] = ['applied', 'screening', 'interview', 'offer', 'hired'];

type TabId = 'postings' | 'pipeline' | 'interviews';

// ==================== MAIN COMPONENT ====================

export default function HiringPage() {
  const { t } = useTranslation();
  const {
    postings,
    applicants,
    interviews,
    loading,
    error,
    createPosting,
    publishPosting,
    updatePosting,
    addApplicant,
    updateApplicantStage,
    updateInterview,
    activePostings,
    totalApplicants,
    inPipeline,
    interviewsThisWeek,
    hiredCount,
    createUserFromApplicant,
  } = useHiring();

  const [activeTab, setActiveTab] = useState<TabId>('postings');
  const [search, setSearch] = useState('');
  const [showNewPostingModal, setShowNewPostingModal] = useState(false);
  const [showNewApplicantModal, setShowNewApplicantModal] = useState(false);

  const tabs: { id: TabId; label: string; count?: number }[] = [
    { id: 'postings', label: 'Job Postings', count: postings.length },
    { id: 'pipeline', label: 'Applicant Pipeline', count: inPipeline },
    { id: 'interviews', label: 'Interviews', count: interviewsThisWeek },
  ];

  if (loading && postings.length === 0) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="h-8 w-8 animate-spin text-muted" />
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3 text-sm text-red-700 dark:text-red-300">
          {error}
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('hiring.title')}</h1>
          <p className="text-muted mt-1">{t('hiring.managePostingsApplicants')}</p>
        </div>
        <div className="flex items-center gap-3">
          {activeTab === 'postings' && (
            <Button onClick={() => setShowNewPostingModal(true)}>
              <Plus size={16} />
              Create Posting
            </Button>
          )}
          {activeTab === 'pipeline' && (
            <Button onClick={() => setShowNewApplicantModal(true)}>
              <Plus size={16} />
              Add Applicant
            </Button>
          )}
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Briefcase size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{activePostings.length}</p>
                <p className="text-sm text-muted">{t('common.activePostings')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <Users size={20} className="text-purple-600 dark:text-purple-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{totalApplicants}</p>
                <p className="text-sm text-muted">{t('hiring.totalApplicants')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <FileText size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{inPipeline}</p>
                <p className="text-sm text-muted">{t('common.inPipeline')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-cyan-100 dark:bg-cyan-900/30 rounded-lg">
                <Calendar size={20} className="text-cyan-600 dark:text-cyan-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{interviewsThisWeek}</p>
                <p className="text-sm text-muted">{t('hiring.interviewsThisWeek')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <Award size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{hiredCount}</p>
                <p className="text-sm text-muted">Hired (YTD)</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tab Bar */}
      <div className="flex items-center gap-1 p-1 bg-secondary rounded-lg w-fit">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => {
              setActiveTab(tab.id);
              setSearch('');
            }}
            className={cn(
              'px-4 py-2 rounded-md text-sm font-medium transition-colors flex items-center gap-2',
              activeTab === tab.id ? 'bg-surface shadow-sm text-main' : 'text-muted hover:text-main'
            )}
          >
            {tab.label}
            {tab.count !== undefined && (
              <span className={cn(
                'text-xs px-1.5 py-0.5 rounded-full',
                activeTab === tab.id ? 'bg-accent/10 text-accent' : 'bg-surface text-muted'
              )}>
                {tab.count}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      {activeTab === 'postings' && (
        <PostingsTab
          postings={postings}
          search={search}
          setSearch={setSearch}
          onPublish={publishPosting}
          onUpdatePosting={updatePosting}
        />
      )}
      {activeTab === 'pipeline' && (
        <PipelineTab
          applicants={applicants}
          postings={postings}
          search={search}
          setSearch={setSearch}
          onUpdateStage={updateApplicantStage}
          onCreateUser={createUserFromApplicant}
        />
      )}
      {activeTab === 'interviews' && (
        <InterviewsTab
          interviews={interviews}
          search={search}
          setSearch={setSearch}
          onUpdateInterview={updateInterview}
        />
      )}

      {/* Modals */}
      {showNewPostingModal && (
        <NewPostingModal
          onClose={() => setShowNewPostingModal(false)}
          onCreate={createPosting}
        />
      )}
      {showNewApplicantModal && (
        <NewApplicantModal
          postings={postings.filter((p) => p.status === 'active')}
          onClose={() => setShowNewApplicantModal(false)}
          onCreate={addApplicant}
        />
      )}
    </div>
  );
}

// ==================== POSTINGS TAB ====================

function PostingsTab({
  postings,
  search,
  setSearch,
  onPublish,
  onUpdatePosting,
}: {
  postings: JobPosting[];
  search: string;
  setSearch: (v: string) => void;
  onPublish: (id: string) => Promise<void>;
  onUpdatePosting: (id: string, data: Partial<JobPosting>) => Promise<void>;
}) {
  const { t } = useTranslation();
  const [statusFilter, setStatusFilter] = useState('all');
  const [expandedId, setExpandedId] = useState<string | null>(null);

  const filtered = useMemo(() => {
    return postings.filter((p) => {
      const matchesSearch =
        p.title.toLowerCase().includes(search.toLowerCase()) ||
        p.department.toLowerCase().includes(search.toLowerCase()) ||
        p.location.toLowerCase().includes(search.toLowerCase());
      const matchesStatus = statusFilter === 'all' || p.status === statusFilter;
      return matchesSearch && matchesStatus;
    });
  }, [postings, search, statusFilter]);

  const statusOptions = [
    { value: 'all', label: 'All Statuses' },
    { value: 'draft', label: 'Draft' },
    { value: 'active', label: 'Active' },
    { value: 'paused', label: 'Paused' },
    { value: 'filled', label: 'Filled' },
    { value: 'closed', label: 'Closed' },
  ];

  const formatPayRange = (posting: JobPosting) => {
    if (!posting.payRangeMin && !posting.payRangeMax) return 'TBD';
    const suffix = payTypeLabels[posting.payType] || '';
    if (posting.payRangeMin && posting.payRangeMax) {
      return `${formatCurrency(posting.payRangeMin)} - ${formatCurrency(posting.payRangeMax)}${suffix}`;
    }
    if (posting.payRangeMin) return `From ${formatCurrency(posting.payRangeMin)}${suffix}`;
    return `Up to ${formatCurrency(posting.payRangeMax)}${suffix}`;
  };

  const handleAction = async (id: string, action: 'publish' | 'pause' | 'close') => {
    try {
      if (action === 'publish') {
        await onPublish(id);
      } else if (action === 'pause') {
        await onUpdatePosting(id, { status: 'paused' });
      } else if (action === 'close') {
        await onUpdatePosting(id, { status: 'closed' });
      }
    } catch {
      // Real-time will refetch
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder="Search postings..."
          className="sm:w-80"
        />
        <Select
          options={statusOptions}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      <div className="space-y-3">
        {filtered.map((posting) => {
          const isExpanded = expandedId === posting.id;
          const config = postingStatusConfig[posting.status];

          return (
            <Card key={posting.id}>
              <CardContent className="p-0">
                <div
                  className="px-6 py-4 cursor-pointer hover:bg-surface-hover transition-colors"
                  onClick={() => setExpandedId(isExpanded ? null : posting.id)}
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-3 mb-1">
                        <h3 className="text-[15px] font-semibold text-main truncate">{posting.title}</h3>
                        <Badge variant={config.variant} dot>{config.label}</Badge>
                      </div>
                      <div className="flex items-center gap-4 text-sm text-muted flex-wrap">
                        {posting.department && (
                          <span className="flex items-center gap-1">
                            <Building2 size={14} />
                            {posting.department}
                          </span>
                        )}
                        <span>{employmentTypeLabels[posting.employmentType]}</span>
                        <span className="flex items-center gap-1">
                          <DollarSign size={14} />
                          {formatPayRange(posting)}
                        </span>
                        {posting.location && (
                          <span className="flex items-center gap-1">
                            <MapPin size={14} />
                            {posting.location}
                          </span>
                        )}
                      </div>
                    </div>
                    <div className="flex items-center gap-4 ml-4 shrink-0">
                      <div className="text-right">
                        <div className="flex items-center gap-1 text-sm text-muted">
                          <Eye size={14} />
                          <span>{posting.totalViews}</span>
                        </div>
                        <div className="flex items-center gap-1 text-sm text-muted">
                          <Users size={14} />
                          <span>{posting.totalApplications}</span>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        {posting.status === 'draft' && (
                          <Button
                            variant="primary"
                            size="sm"
                            onClick={(e) => { e.stopPropagation(); handleAction(posting.id, 'publish'); }}
                          >
                            <Play size={14} />
                            Publish
                          </Button>
                        )}
                        {posting.status === 'active' && (
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={(e) => { e.stopPropagation(); handleAction(posting.id, 'pause'); }}
                          >
                            <Pause size={14} />
                            Pause
                          </Button>
                        )}
                        {posting.status === 'paused' && (
                          <Button
                            variant="primary"
                            size="sm"
                            onClick={(e) => { e.stopPropagation(); handleAction(posting.id, 'publish'); }}
                          >
                            <Play size={14} />
                            Resume
                          </Button>
                        )}
                        {['active', 'paused'].includes(posting.status) && (
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={(e) => { e.stopPropagation(); handleAction(posting.id, 'close'); }}
                          >
                            <XCircle size={14} />
                          </Button>
                        )}
                        {isExpanded ? <ChevronUp size={16} className="text-muted" /> : <ChevronDown size={16} className="text-muted" />}
                      </div>
                    </div>
                  </div>
                </div>

                {isExpanded && (
                  <div className="px-6 pb-4 border-t border-main pt-4 space-y-3">
                    {posting.description && (
                      <div>
                        <h4 className="text-sm font-medium text-main mb-1">{t('common.description')}</h4>
                        <p className="text-sm text-muted whitespace-pre-wrap">{posting.description}</p>
                      </div>
                    )}
                    <div className="grid grid-cols-2 gap-4 text-sm">
                      <div>
                        <span className="text-muted">Positions:</span>{' '}
                        <span className="text-main">{posting.positionsFilled} / {posting.positionsAvailable} filled</span>
                      </div>
                      {posting.publishedAt && (
                        <div>
                          <span className="text-muted">Published:</span>{' '}
                          <span className="text-main">{formatDate(posting.publishedAt)}</span>
                        </div>
                      )}
                      {posting.expiresAt && (
                        <div>
                          <span className="text-muted">Expires:</span>{' '}
                          <span className="text-main">{formatDate(posting.expiresAt)}</span>
                        </div>
                      )}
                      <div>
                        <span className="text-muted">Posted to:</span>{' '}
                        <span className="text-main">
                          {[
                            posting.postToWebsite && 'Website',
                            posting.postToIndeed && 'Indeed',
                            posting.postToLinkedin && 'LinkedIn',
                            posting.postToZiprecruiter && 'ZipRecruiter',
                          ].filter(Boolean).join(', ') || 'None'}
                        </span>
                      </div>
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          );
        })}

        {filtered.length === 0 && (
          <div className="text-center py-12 text-muted">
            <Briefcase size={40} className="mx-auto mb-3 opacity-30" />
            <p className="text-sm">{t('common.noJobPostingsFound')}</p>
          </div>
        )}
      </div>
    </div>
  );
}

// ==================== PIPELINE TAB ====================

function PipelineTab({
  applicants,
  postings,
  search,
  setSearch,
  onUpdateStage,
  onCreateUser,
}: {
  applicants: Applicant[];
  postings: JobPosting[];
  search: string;
  setSearch: (v: string) => void;
  onUpdateStage: (id: string, stage: ApplicantStage) => Promise<void>;
  onCreateUser?: (applicantId: string, role?: string) => Promise<void>;
}) {
  const { t } = useTranslation();
  const [stageFilter, setStageFilter] = useState('all');
  const [postingFilter, setPostingFilter] = useState('all');

  const stageOptions = [
    { value: 'all', label: 'All Stages' },
    ...pipelineStages.map((s) => ({ value: s, label: stageConfig[s].label })),
    { value: 'rejected', label: 'Rejected' },
    { value: 'withdrawn', label: 'Withdrawn' },
  ];

  const postingOptions = [
    { value: 'all', label: 'All Positions' },
    ...postings.map((p) => ({ value: p.id, label: p.title })),
  ];

  const moveOptions: { value: string; label: string }[] = [
    { value: '', label: 'Move to...' },
    { value: 'screening', label: 'Screening' },
    { value: 'phone_screen', label: 'Phone Screen' },
    { value: 'interview', label: 'Interview' },
    { value: 'skills_test', label: 'Skills Test' },
    { value: 'reference_check', label: 'Reference Check' },
    { value: 'background_check', label: 'Background Check' },
    { value: 'offer', label: 'Offer' },
    { value: 'hired', label: 'Hired' },
    { value: 'rejected', label: 'Rejected' },
  ];

  const filtered = useMemo(() => {
    return applicants.filter((a) => {
      const matchesSearch =
        `${a.firstName} ${a.lastName}`.toLowerCase().includes(search.toLowerCase()) ||
        a.email.toLowerCase().includes(search.toLowerCase()) ||
        (a.jobTitle || '').toLowerCase().includes(search.toLowerCase());
      const matchesStage = stageFilter === 'all' || a.stage === stageFilter;
      const matchesPosting = postingFilter === 'all' || a.jobPostingId === postingFilter;
      return matchesSearch && matchesStage && matchesPosting;
    });
  }, [applicants, search, stageFilter, postingFilter]);

  const getDaysInStage = (applicant: Applicant) => {
    const ref = applicant.stageChangedAt || applicant.createdAt;
    const diff = Date.now() - new Date(ref).getTime();
    return Math.floor(diff / (1000 * 60 * 60 * 24));
  };

  const handleStageChange = async (applicantId: string, newStage: string) => {
    if (!newStage) return;
    try {
      await onUpdateStage(applicantId, newStage as ApplicantStage);
    } catch {
      // Real-time will refetch
    }
  };

  // Group by pipeline stage for pipeline view
  const groupedByStage = useMemo(() => {
    const groups: Record<string, Applicant[]> = {};
    for (const stage of pipelineStages) {
      if (stage === 'screening') {
        // Group screening, phone_screen into one column
        groups[stage] = filtered.filter((a) => ['screening', 'phone_screen'].includes(a.stage));
      } else if (stage === 'interview') {
        // Group interview, skills_test, reference_check, background_check into one column
        groups[stage] = filtered.filter((a) => ['interview', 'skills_test', 'reference_check', 'background_check'].includes(a.stage));
      } else {
        groups[stage] = filtered.filter((a) => a.stage === stage);
      }
    }
    return groups;
  }, [filtered]);

  const pipelineColumnLabels: Record<string, string> = {
    applied: 'Applied',
    screening: 'Screening',
    interview: 'Interview',
    offer: 'Offer',
    hired: 'Hired',
  };

  return (
    <div className="space-y-4">
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder="Search applicants..."
          className="sm:w-80"
        />
        <Select
          options={stageOptions}
          value={stageFilter}
          onChange={(e) => setStageFilter(e.target.value)}
          className="sm:w-48"
        />
        <Select
          options={postingOptions}
          value={postingFilter}
          onChange={(e) => setPostingFilter(e.target.value)}
          className="sm:w-56"
        />
      </div>

      {stageFilter === 'all' ? (
        /* Pipeline View - columns */
        <div className="flex gap-4 overflow-x-auto pb-4">
          {pipelineStages.map((stage) => {
            const stageApplicants = groupedByStage[stage] || [];
            return (
              <div key={stage} className="flex-shrink-0 w-72">
                <div className="bg-secondary rounded-t-xl px-4 py-3 border border-main border-b-0">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Badge variant={stageConfig[stage].variant} dot>
                        {pipelineColumnLabels[stage]}
                      </Badge>
                      <span className="text-sm text-muted">{stageApplicants.length}</span>
                    </div>
                  </div>
                </div>
                <div className="bg-secondary/50 rounded-b-xl border border-main border-t-0 p-2 min-h-[400px] space-y-2">
                  {stageApplicants.map((applicant) => (
                    <ApplicantCard
                      key={applicant.id}
                      applicant={applicant}
                      daysInStage={getDaysInStage(applicant)}
                      moveOptions={moveOptions}
                      onStageChange={handleStageChange}
                      onCreateUser={onCreateUser}
                    />
                  ))}
                  {stageApplicants.length === 0 && (
                    <div className="text-center py-8 text-muted text-sm">
                      No applicants
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        /* Filtered List View */
        <div className="space-y-2">
          {filtered.map((applicant) => (
            <ApplicantCard
              key={applicant.id}
              applicant={applicant}
              daysInStage={getDaysInStage(applicant)}
              moveOptions={moveOptions}
              onStageChange={handleStageChange}
              onCreateUser={onCreateUser}
              listMode
            />
          ))}
          {filtered.length === 0 && (
            <div className="text-center py-12 text-muted">
              <Users size={40} className="mx-auto mb-3 opacity-30" />
              <p className="text-sm">{t('common.noApplicantsFound')}</p>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function ApplicantCard({
  applicant,
  daysInStage,
  moveOptions,
  onStageChange,
  onCreateUser,
  listMode = false,
}: {
  applicant: Applicant;
  daysInStage: number;
  moveOptions: { value: string; label: string }[];
  onStageChange: (id: string, stage: string) => void;
  onCreateUser?: (applicantId: string, role?: string) => Promise<void>;
  listMode?: boolean;
}) {
  const [creatingUser, setCreatingUser] = useState(false);
  const fullName = `${applicant.firstName} ${applicant.lastName}`.trim();
  const config = stageConfig[applicant.stage];
  const srcConfig = sourceLabels[applicant.source] || applicant.source;

  const handleCreateUser = async () => {
    if (!onCreateUser || creatingUser) return;
    setCreatingUser(true);
    try {
      await onCreateUser(applicant.id);
    } catch {
      // Error handled by hook
    } finally {
      setCreatingUser(false);
    }
  };

  return (
    <Card className={cn(listMode && 'mb-0')}>
      <CardContent className="p-3">
        <div className="flex items-start justify-between mb-2">
          <div className="flex items-center gap-2 min-w-0">
            <Avatar name={fullName} size="sm" />
            <div className="min-w-0">
              <p className="font-medium text-main text-sm truncate">{fullName}</p>
              {applicant.jobTitle && (
                <p className="text-xs text-muted truncate">{applicant.jobTitle}</p>
              )}
            </div>
          </div>
          {listMode && <Badge variant={config.variant} dot>{config.label}</Badge>}
        </div>

        <div className="flex items-center gap-2 mb-2 flex-wrap">
          <Badge variant="secondary">{srcConfig}</Badge>
          {applicant.rating > 0 && (
            <span className="flex items-center gap-0.5 text-xs text-amber-500">
              {Array.from({ length: 5 }).map((_, i) => (
                <Star
                  key={i}
                  size={12}
                  className={i < applicant.rating ? 'fill-amber-500' : 'fill-none text-zinc-600'}
                />
              ))}
            </span>
          )}
        </div>

        {/* Create User Account button for hired applicants */}
        {applicant.stage === 'hired' && onCreateUser && (
          <button
            onClick={handleCreateUser}
            disabled={creatingUser}
            className="w-full mb-2 py-1.5 px-3 text-xs font-medium rounded-lg bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 hover:bg-emerald-500/20 disabled:opacity-50 transition-colors flex items-center justify-center gap-1.5"
          >
            <UserPlus size={12} />
            {creatingUser ? 'Creating Account...' : 'Create User Account'}
          </button>
        )}

        <div className="flex items-center justify-between">
          <span className="text-xs text-muted flex items-center gap-1">
            <Clock size={12} />
            {daysInStage}d in stage
          </span>
          <select
            className="text-xs bg-secondary border border-main rounded px-2 py-1 text-main"
            value=""
            onChange={(e) => onStageChange(applicant.id, e.target.value)}
            onClick={(e) => e.stopPropagation()}
          >
            {moveOptions.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        </div>
      </CardContent>
    </Card>
  );
}

// ==================== INTERVIEWS TAB ====================

function InterviewsTab({
  interviews,
  search,
  setSearch,
  onUpdateInterview,
}: {
  interviews: InterviewSchedule[];
  search: string;
  setSearch: (v: string) => void;
  onUpdateInterview: (id: string, data: Partial<InterviewSchedule>) => Promise<void>;
}) {
  const { t } = useTranslation();
  const [statusFilter, setStatusFilter] = useState('all');

  const statusOptions = [
    { value: 'all', label: 'All Statuses' },
    { value: 'scheduled', label: 'Scheduled' },
    { value: 'confirmed', label: 'Confirmed' },
    { value: 'completed', label: 'Completed' },
    { value: 'cancelled', label: 'Cancelled' },
    { value: 'no_show', label: 'No Show' },
  ];

  const filtered = useMemo(() => {
    return interviews.filter((i) => {
      const matchesSearch =
        (i.applicantName || '').toLowerCase().includes(search.toLowerCase()) ||
        (i.applicantJobTitle || '').toLowerCase().includes(search.toLowerCase());
      const matchesStatus = statusFilter === 'all' || i.status === statusFilter;
      return matchesSearch && matchesStatus;
    });
  }, [interviews, search, statusFilter]);

  const handleAction = async (id: string, action: 'complete' | 'cancel' | 'reschedule') => {
    try {
      if (action === 'complete') {
        await onUpdateInterview(id, { status: 'completed' });
      } else if (action === 'cancel') {
        await onUpdateInterview(id, { status: 'cancelled' });
      } else if (action === 'reschedule') {
        await onUpdateInterview(id, { status: 'rescheduled' });
      }
    } catch {
      // Real-time will refetch
    }
  };

  const now = new Date();
  const upcoming = filtered.filter((i) => new Date(i.scheduledAt) >= now && !['completed', 'cancelled'].includes(i.status));
  const past = filtered.filter((i) => new Date(i.scheduledAt) < now || ['completed', 'cancelled'].includes(i.status));

  return (
    <div className="space-y-4">
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder="Search interviews..."
          className="sm:w-80"
        />
        <Select
          options={statusOptions}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      {/* Upcoming Interviews */}
      {upcoming.length > 0 && (
        <div>
          <h3 className="text-sm font-medium text-muted mb-3 uppercase tracking-wider">{t('common.upcoming')}</h3>
          <Card>
            <CardContent className="p-0">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-main">
                    <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.candidate')}</th>
                    <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.position')}</th>
                    <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.type')}</th>
                    <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.dateTime')}</th>
                    <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.status')}</th>
                    <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.actions')}</th>
                  </tr>
                </thead>
                <tbody>
                  {upcoming.map((interview) => {
                    const statusConf = interviewStatusConfig[interview.status];
                    const TypeIcon = interviewTypeIcons[interview.interviewType] || Building2;
                    return (
                      <tr key={interview.id} className="border-b border-main/50 hover:bg-surface-hover">
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-2">
                            <Avatar name={interview.applicantName || 'Unknown'} size="sm" />
                            <span className="text-sm font-medium text-main">{interview.applicantName || 'Unknown'}</span>
                          </div>
                        </td>
                        <td className="px-6 py-4 text-sm text-muted">{interview.applicantJobTitle || '-'}</td>
                        <td className="px-6 py-4">
                          <span className="flex items-center gap-1.5 text-sm text-muted">
                            <TypeIcon size={14} />
                            {interviewTypeLabels[interview.interviewType] || interview.interviewType}
                          </span>
                        </td>
                        <td className="px-6 py-4 text-sm text-main">{formatDateTime(interview.scheduledAt)}</td>
                        <td className="px-6 py-4">
                          <Badge variant={statusConf.variant} dot>{statusConf.label}</Badge>
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-1">
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleAction(interview.id, 'complete')}
                              title={t('jobs.statusComplete')}
                            >
                              <Check size={14} />
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleAction(interview.id, 'reschedule')}
                              title={t('common.reschedule')}
                            >
                              <Clock size={14} />
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleAction(interview.id, 'cancel')}
                              title={t('common.cancel')}
                            >
                              <X size={14} />
                            </Button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Past / Completed Interviews */}
      {past.length > 0 && (
        <div>
          <h3 className="text-sm font-medium text-muted mb-3 uppercase tracking-wider">{t('hiring.pastCompleted')}</h3>
          <Card>
            <CardContent className="p-0">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-main">
                    <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.candidate')}</th>
                    <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.position')}</th>
                    <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.type')}</th>
                    <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.dateTime')}</th>
                    <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.status')}</th>
                    <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.recommendation')}</th>
                  </tr>
                </thead>
                <tbody>
                  {past.map((interview) => {
                    const statusConf = interviewStatusConfig[interview.status];
                    const TypeIcon = interviewTypeIcons[interview.interviewType] || Building2;
                    return (
                      <tr key={interview.id} className="border-b border-main/50 hover:bg-surface-hover">
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-2">
                            <Avatar name={interview.applicantName || 'Unknown'} size="sm" />
                            <span className="text-sm font-medium text-main">{interview.applicantName || 'Unknown'}</span>
                          </div>
                        </td>
                        <td className="px-6 py-4 text-sm text-muted">{interview.applicantJobTitle || '-'}</td>
                        <td className="px-6 py-4">
                          <span className="flex items-center gap-1.5 text-sm text-muted">
                            <TypeIcon size={14} />
                            {interviewTypeLabels[interview.interviewType] || interview.interviewType}
                          </span>
                        </td>
                        <td className="px-6 py-4 text-sm text-main">{formatDateTime(interview.scheduledAt)}</td>
                        <td className="px-6 py-4">
                          <Badge variant={statusConf.variant} dot>{statusConf.label}</Badge>
                        </td>
                        <td className="px-6 py-4 text-sm text-muted">
                          {interview.overallRecommendation || '-'}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </CardContent>
          </Card>
        </div>
      )}

      {filtered.length === 0 && (
        <div className="text-center py-12 text-muted">
          <Calendar size={40} className="mx-auto mb-3 opacity-30" />
          <p className="text-sm">{t('hiring.noInterviewsFound')}</p>
        </div>
      )}
    </div>
  );
}

// ==================== MODALS ====================

function NewPostingModal({
  onClose,
  onCreate,
}: {
  onClose: () => void;
  onCreate: (input: {
    title: string;
    department?: string;
    employmentType?: EmploymentType;
    description?: string;
    payType?: PayType;
    payRangeMin?: number;
    payRangeMax?: number;
    location?: string;
    positionsAvailable?: number;
  }) => Promise<string>;
}) {
  const { t } = useTranslation();
  const [title, setTitle] = useState('');
  const [department, setDepartment] = useState('');
  const [employmentType, setEmploymentType] = useState<EmploymentType>('full_time');
  const [description, setDescription] = useState('');
  const [payType, setPayType] = useState<PayType>('hourly');
  const [payMin, setPayMin] = useState('');
  const [payMax, setPayMax] = useState('');
  const [location, setLocation] = useState('');
  const [positions, setPositions] = useState('1');
  const [saving, setSaving] = useState(false);

  const employmentOptions = Object.entries(employmentTypeLabels).map(([value, label]) => ({ value, label }));
  const payTypeOptions: { value: string; label: string }[] = [
    { value: 'hourly', label: 'Hourly' },
    { value: 'salary', label: 'Salary' },
    { value: 'commission', label: 'Commission' },
    { value: 'per_job', label: 'Per Job' },
  ];

  const handleSubmit = async () => {
    if (!title.trim()) return;
    setSaving(true);
    try {
      await onCreate({
        title: title.trim(),
        department: department.trim() || undefined,
        employmentType,
        description: description.trim() || undefined,
        payType,
        payRangeMin: payMin ? parseFloat(payMin) : undefined,
        payRangeMax: payMax ? parseFloat(payMax) : undefined,
        location: location.trim() || undefined,
        positionsAvailable: positions ? parseInt(positions) : 1,
      });
      onClose();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to create posting');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <CardTitle>{t('common.createJobPosting')}</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Job Title *</label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g. Journeyman Electrician"
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{t('hiring.department')}</label>
              <input
                type="text"
                value={department}
                onChange={(e) => setDepartment(e.target.value)}
                placeholder="e.g. Electrical"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]"
              />
            </div>
            <Select
              label="Employment Type"
              options={employmentOptions}
              value={employmentType}
              onChange={(e) => setEmploymentType(e.target.value as EmploymentType)}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('common.description')}</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Job description..."
              rows={4}
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] resize-none"
            />
          </div>
          <div className="grid grid-cols-3 gap-4">
            <Select
              label="Pay Type"
              options={payTypeOptions}
              value={payType}
              onChange={(e) => setPayType(e.target.value as PayType)}
            />
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Pay Min ($)</label>
              <input
                type="number"
                value={payMin}
                onChange={(e) => setPayMin(e.target.value)}
                placeholder="25"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Pay Max ($)</label>
              <input
                type="number"
                value={payMax}
                onChange={(e) => setPayMax(e.target.value)}
                placeholder="45"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]"
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{t('common.location')}</label>
              <input
                type="text"
                value={location}
                onChange={(e) => setLocation(e.target.value)}
                placeholder="e.g. Phoenix, AZ"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{t('common.positionsAvailable')}</label>
              <input
                type="number"
                value={positions}
                onChange={(e) => setPositions(e.target.value)}
                min="1"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]"
              />
            </div>
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose} disabled={saving}>
              Cancel
            </Button>
            <Button className="flex-1" onClick={handleSubmit} disabled={saving || !title.trim()}>
              {saving ? <Loader2 size={16} className="animate-spin" /> : <Plus size={16} />}
              {saving ? 'Creating...' : 'Create Posting'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function NewApplicantModal({
  postings,
  onClose,
  onCreate,
}: {
  postings: JobPosting[];
  onClose: () => void;
  onCreate: (input: {
    jobPostingId: string;
    firstName: string;
    lastName: string;
    email?: string;
    phone?: string;
    source?: ApplicantSource;
    yearsExperience?: number;
    tradeSpecialties?: string[];
    certifications?: string[];
    licenses?: string[];
  }) => Promise<string>;
}) {
  const { t: tr } = useTranslation();
  const [jobPostingId, setJobPostingId] = useState(postings[0]?.id || '');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [source, setSource] = useState<ApplicantSource>('direct');
  const [experience, setExperience] = useState('');
  const [portfolioUrl, setPortfolioUrl] = useState('');
  const [saving, setSaving] = useState(false);

  const TRADE_OPTIONS = ['electrical', 'plumbing', 'hvac', 'roofing', 'painting', 'carpentry', 'flooring', 'landscaping', 'general', 'solar', 'restoration', 'drywall', 'concrete', 'excavation', 'welding', 'fire_protection', 'insulation', 'glass_glazing'] as const;
  const [selectedTrades, setSelectedTrades] = useState<string[]>([]);
  const [certInput, setCertInput] = useState('');
  const [certs, setCerts] = useState<string[]>([]);

  const toggleTrade = (t: string) => {
    setSelectedTrades((prev) => prev.includes(t) ? prev.filter((x) => x !== t) : [...prev, t]);
  };

  const addCert = () => {
    const val = certInput.trim();
    if (val && !certs.includes(val)) {
      setCerts((prev) => [...prev, val]);
      setCertInput('');
    }
  };

  const postingOptions = postings.map((p) => ({ value: p.id, label: p.title }));
  const sourceOptions: { value: string; label: string }[] = Object.entries(sourceLabels).map(([value, label]) => ({ value, label }));

  const inputCls = "w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]";

  const handleSubmit = async () => {
    if (!firstName.trim() || !jobPostingId) return;
    setSaving(true);
    try {
      await onCreate({
        jobPostingId,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim() || undefined,
        phone: phone.trim() || undefined,
        source,
        yearsExperience: experience ? parseInt(experience) : undefined,
        tradeSpecialties: selectedTrades.length > 0 ? selectedTrades : undefined,
        certifications: certs.length > 0 ? certs : undefined,
      });
      onClose();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to add applicant');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <CardTitle>{tr('common.addApplicant')}</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {postingOptions.length > 0 ? (
            <Select
              label="Position *"
              options={postingOptions}
              value={jobPostingId}
              onChange={(e) => setJobPostingId(e.target.value)}
            />
          ) : (
            <p className="text-sm text-muted">{tr('hiring.noActivePostings')}</p>
          )}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">First Name *</label>
              <input type="text" value={firstName} onChange={(e) => setFirstName(e.target.value)} placeholder="John" className={inputCls} />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{tr('common.lastName')}</label>
              <input type="text" value={lastName} onChange={(e) => setLastName(e.target.value)} placeholder="Smith" className={inputCls} />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{tr('common.email')}</label>
              <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="john@email.com" className={inputCls} />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{tr('common.phone')}</label>
              <input
                type="tel"
                value={phone}
                onChange={(e) => {
                  const digits = e.target.value.replace(/\D/g, '').slice(0, 10);
                  const formatted = digits.length > 6 ? `(${digits.slice(0,3)}) ${digits.slice(3,6)}-${digits.slice(6)}` : digits.length > 3 ? `(${digits.slice(0,3)}) ${digits.slice(3)}` : digits;
                  setPhone(formatted);
                }}
                placeholder="(555) 123-4567"
                className={inputCls}
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Select label={tr('leads.source')} options={sourceOptions} value={source} onChange={(e) => setSource(e.target.value as ApplicantSource)} />
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{tr('common.yearsExperience')}</label>
              <input type="number" value={experience} onChange={(e) => setExperience(e.target.value)} placeholder="5" min="0" className={inputCls} />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{tr('hiring.portfolioWebsite')}</label>
            <input type="url" value={portfolioUrl} onChange={(e) => setPortfolioUrl(e.target.value)} placeholder="https://portfolio.example.com" className={inputCls} />
          </div>

          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{tr('common.tradeSpecialties')}</label>
            <div className="flex flex-wrap gap-1.5">
              {TRADE_OPTIONS.map((t) => (
                <button
                  key={t}
                  type="button"
                  onClick={() => toggleTrade(t)}
                  className={`px-2.5 py-1 text-xs rounded-full border transition-colors ${selectedTrades.includes(t) ? 'bg-accent/20 border-accent text-accent' : 'bg-main border-main text-muted hover:border-accent/50'}`}
                >
                  {t.replace(/_/g, ' ')}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{tr('marketplace.certifications')}</label>
            <div className="flex gap-2">
              <input
                type="text"
                value={certInput}
                onChange={(e) => setCertInput(e.target.value)}
                onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); addCert(); } }}
                placeholder="e.g. EPA 608, OSHA 30"
                className={`flex-1 ${inputCls}`}
              />
              <Button variant="secondary" onClick={addCert} disabled={!certInput.trim()}>{tr('common.add')}</Button>
            </div>
            {certs.length > 0 && (
              <div className="flex flex-wrap gap-1.5 mt-2">
                {certs.map((c) => (
                  <span key={c} className="px-2.5 py-1 text-xs rounded-full bg-accent/20 border border-accent text-accent flex items-center gap-1">
                    {c}
                    <button type="button" onClick={() => setCerts((prev) => prev.filter((x) => x !== c))} className="hover:text-red-400">&times;</button>
                  </span>
                ))}
              </div>
            )}
          </div>

          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose} disabled={saving}>
              Cancel
            </Button>
            <Button className="flex-1" onClick={handleSubmit} disabled={saving || !firstName.trim() || !jobPostingId}>
              {saving ? <Loader2 size={16} className="animate-spin" /> : <UserCheck size={16} />}
              {saving ? 'Adding...' : 'Add Applicant'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
