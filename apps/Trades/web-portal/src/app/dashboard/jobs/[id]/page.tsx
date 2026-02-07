'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import {
  ArrowLeft,
  Briefcase,
  MapPin,
  Calendar,
  Clock,
  User,
  Phone,
  Mail,
  DollarSign,
  FileText,
  Camera,
  MessageSquare,
  CheckSquare,
  Edit,
  MoreHorizontal,
  Trash2,
  Receipt,
  PlayCircle,
  PauseCircle,
  CheckCircle,
  Plus,
  Package,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { StatusBadge, Badge } from '@/components/ui/badge';
import { Avatar, AvatarGroup } from '@/components/ui/avatar';
import { formatCurrency, formatDate, formatDateTime, cn } from '@/lib/utils';
import { useJob, useTeam } from '@/lib/hooks/use-jobs';
import type { Job, JobNote } from '@/types';

type TabType = 'overview' | 'tasks' | 'materials' | 'photos' | 'time' | 'notes';

export default function JobDetailPage() {
  const router = useRouter();
  const params = useParams();
  const jobId = params.id as string;

  const { job, loading } = useJob(jobId);
  const { team } = useTeam();
  const [activeTab, setActiveTab] = useState<TabType>('overview');
  const [menuOpen, setMenuOpen] = useState(false);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent" />
      </div>
    );
  }

  if (!job) {
    return (
      <div className="text-center py-12">
        <Briefcase size={48} className="mx-auto text-muted mb-4" />
        <h2 className="text-xl font-semibold text-main">Job not found</h2>
        <p className="text-muted mt-2">The job you're looking for doesn't exist.</p>
        <Button variant="secondary" className="mt-4" onClick={() => router.push('/dashboard/jobs')}>
          Back to Jobs
        </Button>
      </div>
    );
  }

  const assignedMembers = job.assignedTo.map((id) => team.find((t) => t.id === id)).filter(Boolean);

  const tabs: { id: TabType; label: string; icon: React.ReactNode }[] = [
    { id: 'overview', label: 'Overview', icon: <Briefcase size={16} /> },
    { id: 'tasks', label: 'Tasks', icon: <CheckSquare size={16} /> },
    { id: 'materials', label: 'Materials', icon: <Package size={16} /> },
    { id: 'photos', label: 'Photos', icon: <Camera size={16} /> },
    { id: 'time', label: 'Time', icon: <Clock size={16} /> },
    { id: 'notes', label: 'Notes', icon: <MessageSquare size={16} /> },
  ];

  return (
    <div className="space-y-6 pb-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.back()}
            className="p-2 hover:bg-surface-hover rounded-lg transition-colors"
          >
            <ArrowLeft size={20} className="text-muted" />
          </button>
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-semibold text-main">{job.title}</h1>
              <StatusBadge status={job.status} />
              {job.priority === 'urgent' && <Badge variant="error">Urgent</Badge>}
              {job.priority === 'high' && <Badge variant="warning">High</Badge>}
            </div>
            <p className="text-muted mt-1">
              {job.customer?.firstName} {job.customer?.lastName}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {job.status === 'scheduled' && (
            <Button>
              <PlayCircle size={16} />
              Start Job
            </Button>
          )}
          {job.status === 'in_progress' && (
            <>
              <Button variant="secondary">
                <PauseCircle size={16} />
                Pause
              </Button>
              <Button>
                <CheckCircle size={16} />
                Complete
              </Button>
            </>
          )}
          {job.status === 'completed' && (
            <Button onClick={() => router.push(`/dashboard/invoices/new?jobId=${job.id}`)}>
              <Receipt size={16} />
              Create Invoice
            </Button>
          )}
          <div className="relative">
            <Button variant="ghost" size="icon" onClick={() => setMenuOpen(!menuOpen)}>
              <MoreHorizontal size={18} />
            </Button>
            {menuOpen && (
              <>
                <div className="fixed inset-0 z-40" onClick={() => setMenuOpen(false)} />
                <div className="absolute right-0 top-full mt-1 w-48 bg-surface border border-main rounded-lg shadow-lg py-1 z-50">
                  <button className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                    <Edit size={16} />
                    Edit Job
                  </button>
                  <button className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                    <FileText size={16} />
                    View Bid
                  </button>
                  <hr className="my-1 border-main" />
                  <button className="w-full px-4 py-2 text-left text-sm hover:bg-red-50 dark:hover:bg-red-900/20 text-red-600 flex items-center gap-2">
                    <Trash2 size={16} />
                    Delete
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 p-1 bg-secondary rounded-lg w-fit">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={cn(
              'flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-md transition-colors',
              activeTab === tab.id
                ? 'bg-surface text-main shadow-sm'
                : 'text-muted hover:text-main'
            )}
          >
            {tab.icon}
            {tab.label}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
          {activeTab === 'overview' && <OverviewTab job={job} />}
          {activeTab === 'tasks' && <TasksTab job={job} />}
          {activeTab === 'materials' && <MaterialsTab job={job} />}
          {activeTab === 'photos' && <PhotosTab job={job} />}
          {activeTab === 'time' && <TimeTab job={job} />}
          {activeTab === 'notes' && <NotesTab job={job} />}
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Job Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <p className="text-sm text-muted mb-1">Value</p>
                <p className="text-2xl font-semibold text-main">{formatCurrency(job.estimatedValue)}</p>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">Status</span>
                <StatusBadge status={job.status} />
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">Priority</span>
                <Badge variant={job.priority === 'urgent' ? 'error' : job.priority === 'high' ? 'warning' : 'default'}>
                  {job.priority.charAt(0).toUpperCase() + job.priority.slice(1)}
                </Badge>
              </div>
              {job.scheduledStart && (
                <div className="flex justify-between text-sm">
                  <span className="text-muted">Scheduled</span>
                  <span className="text-main">{formatDate(job.scheduledStart)}</span>
                </div>
              )}
              <div className="flex justify-between text-sm">
                <span className="text-muted">Created</span>
                <span className="text-main">{formatDate(job.createdAt)}</span>
              </div>
            </CardContent>
          </Card>

          {/* Customer */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <User size={18} className="text-muted" />
                Customer
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="font-medium text-main">
                {job.customer?.firstName} {job.customer?.lastName}
              </div>
              {job.customer?.email && (
                <div className="flex items-center gap-2 text-sm text-muted">
                  <Mail size={14} />
                  <a href={`mailto:${job.customer.email}`} className="hover:text-accent">
                    {job.customer.email}
                  </a>
                </div>
              )}
              {job.customer?.phone && (
                <div className="flex items-center gap-2 text-sm text-muted">
                  <Phone size={14} />
                  <a href={`tel:${job.customer.phone}`} className="hover:text-accent">
                    {job.customer.phone}
                  </a>
                </div>
              )}
              <Button variant="secondary" size="sm" className="w-full" onClick={() => router.push(`/dashboard/customers/${job.customerId}`)}>
                View Customer
              </Button>
            </CardContent>
          </Card>

          {/* Location */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <MapPin size={18} className="text-muted" />
                Location
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-main">
                {job.address.street}<br />
                {job.address.city}, {job.address.state} {job.address.zip}
              </p>
              <Button variant="secondary" size="sm" className="w-full mt-3">
                Get Directions
              </Button>
            </CardContent>
          </Card>

          {/* Team */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <User size={18} className="text-muted" />
                Assigned Team
              </CardTitle>
            </CardHeader>
            <CardContent>
              {assignedMembers.length === 0 ? (
                <p className="text-sm text-muted">No team members assigned</p>
              ) : (
                <div className="space-y-3">
                  {assignedMembers.map((member) => member && (
                    <div key={member.id} className="flex items-center gap-3">
                      <Avatar name={member.name} size="sm" />
                      <div>
                        <p className="text-sm font-medium text-main">{member.name}</p>
                        <p className="text-xs text-muted capitalize">{member.role.replace('_', ' ')}</p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
              <Button variant="secondary" size="sm" className="w-full mt-3">
                <Plus size={14} />
                Assign Member
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}

function OverviewTab({ job }: { job: Job }) {
  return (
    <div className="space-y-6">
      {/* Description */}
      {job.description && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Description</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-main whitespace-pre-wrap">{job.description}</p>
          </CardContent>
        </Card>
      )}

      {/* Timeline */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Timeline</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <TimelineItem
              label="Created"
              date={job.createdAt}
              completed={true}
            />
            <TimelineItem
              label="Scheduled"
              date={job.scheduledStart}
              completed={!!job.scheduledStart}
            />
            <TimelineItem
              label="Started"
              date={job.actualStart}
              completed={!!job.actualStart}
            />
            <TimelineItem
              label="Completed"
              date={job.actualEnd}
              completed={job.status === 'completed' || job.status === 'invoiced' || job.status === 'paid'}
              isLast
            />
          </div>
        </CardContent>
      </Card>

      {/* Tags */}
      {job.tags.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Tags</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex flex-wrap gap-2">
              {job.tags.map((tag) => (
                <Badge key={tag} variant="default">{tag}</Badge>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

function TimelineItem({ label, date, completed, isLast = false }: { label: string; date?: Date; completed: boolean; isLast?: boolean }) {
  return (
    <div className="flex gap-3">
      <div className="flex flex-col items-center">
        <div className={cn(
          'w-3 h-3 rounded-full',
          completed ? 'bg-emerald-500' : 'bg-secondary border-2 border-main'
        )} />
        {!isLast && <div className={cn('w-0.5 h-8 mt-1', completed ? 'bg-emerald-500' : 'bg-main')} />}
      </div>
      <div className="flex-1 pb-4">
        <div className={cn('font-medium text-sm', completed ? 'text-main' : 'text-muted')}>
          {label}
        </div>
        {date && (
          <div className="text-xs text-muted">{formatDateTime(date)}</div>
        )}
      </div>
    </div>
  );
}

function TasksTab({ job }: { job: Job }) {
  const [tasks] = useState([
    { id: '1', title: 'Site walkthrough', completed: true },
    { id: '2', title: 'Turn off power at breaker', completed: true },
    { id: '3', title: 'Remove old fixtures', completed: false },
    { id: '4', title: 'Install new fixtures', completed: false },
    { id: '5', title: 'Test all connections', completed: false },
    { id: '6', title: 'Customer sign-off', completed: false },
  ]);

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="text-base">Task Checklist</CardTitle>
        <Button variant="secondary" size="sm">
          <Plus size={14} />
          Add Task
        </Button>
      </CardHeader>
      <CardContent>
        <div className="space-y-2">
          {tasks.map((task) => (
            <div
              key={task.id}
              className={cn(
                'flex items-center gap-3 p-3 rounded-lg border transition-colors',
                task.completed ? 'border-emerald-200 bg-emerald-50 dark:border-emerald-900 dark:bg-emerald-900/20' : 'border-main'
              )}
            >
              <button className={cn(
                'w-5 h-5 rounded border-2 flex items-center justify-center transition-colors',
                task.completed ? 'bg-emerald-500 border-emerald-500 text-white' : 'border-muted hover:border-accent'
              )}>
                {task.completed && <CheckCircle size={14} />}
              </button>
              <span className={cn('flex-1', task.completed && 'line-through text-muted')}>
                {task.title}
              </span>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}

function MaterialsTab({ job }: { job: Job }) {
  const [materials] = useState([
    { id: '1', name: '2x4 LED Panel', quantity: 48, unitPrice: 85, used: 24 },
    { id: '2', name: 'Wire nuts (100 pack)', quantity: 2, unitPrice: 12, used: 1 },
    { id: '3', name: '12/2 Romex (250ft)', quantity: 1, unitPrice: 145, used: 0 },
  ]);

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="text-base">Materials</CardTitle>
        <Button variant="secondary" size="sm">
          <Plus size={14} />
          Add Material
        </Button>
      </CardHeader>
      <CardContent className="p-0">
        <table className="w-full">
          <thead>
            <tr className="border-b border-main">
              <th className="text-left text-xs font-medium text-muted uppercase px-6 py-3">Item</th>
              <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">Qty</th>
              <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">Used</th>
              <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">Price</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-main">
            {materials.map((item) => (
              <tr key={item.id}>
                <td className="px-6 py-4 font-medium text-main">{item.name}</td>
                <td className="px-6 py-4 text-right text-muted">{item.quantity}</td>
                <td className="px-6 py-4 text-right text-muted">{item.used}</td>
                <td className="px-6 py-4 text-right font-medium text-main">{formatCurrency(item.unitPrice)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </CardContent>
    </Card>
  );
}

function PhotosTab({ job }: { job: Job }) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="text-base">Photos</CardTitle>
        <Button variant="secondary" size="sm">
          <Plus size={14} />
          Upload Photo
        </Button>
      </CardHeader>
      <CardContent>
        {job.photos.length === 0 ? (
          <div className="py-12 text-center">
            <Camera size={48} className="mx-auto text-muted mb-4 opacity-50" />
            <p className="text-muted">No photos uploaded yet</p>
            <Button variant="secondary" size="sm" className="mt-4">
              <Plus size={14} />
              Upload First Photo
            </Button>
          </div>
        ) : (
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            {job.photos.map((photo) => (
              <div key={photo.id} className="aspect-square rounded-lg bg-secondary overflow-hidden">
                <img src={photo.url} alt={photo.caption || 'Job photo'} className="w-full h-full object-cover" />
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function TimeTab({ job }: { job: Job }) {
  const [entries] = useState([
    { id: '1', member: 'Mike Johnson', date: new Date(), start: '8:00 AM', end: '12:30 PM', hours: 4.5 },
    { id: '2', member: 'Carlos Rivera', date: new Date(), start: '8:00 AM', end: '12:30 PM', hours: 4.5 },
  ]);

  const totalHours = entries.reduce((sum, e) => sum + e.hours, 0);

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <div>
          <CardTitle className="text-base">Time Entries</CardTitle>
          <p className="text-sm text-muted mt-1">Total: {totalHours} hours</p>
        </div>
        <Button variant="secondary" size="sm">
          <Plus size={14} />
          Add Entry
        </Button>
      </CardHeader>
      <CardContent className="p-0">
        <div className="divide-y divide-main">
          {entries.map((entry) => (
            <div key={entry.id} className="px-6 py-4 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Avatar name={entry.member} size="sm" />
                <div>
                  <p className="font-medium text-main">{entry.member}</p>
                  <p className="text-sm text-muted">{formatDate(entry.date)}</p>
                </div>
              </div>
              <div className="text-right">
                <p className="font-medium text-main">{entry.hours} hrs</p>
                <p className="text-sm text-muted">{entry.start} - {entry.end}</p>
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}

function NotesTab({ job }: { job: Job }) {
  const [newNote, setNewNote] = useState('');

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Notes</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex gap-3">
          <textarea
            value={newNote}
            onChange={(e) => setNewNote(e.target.value)}
            placeholder="Add a note..."
            className="flex-1 px-4 py-3 bg-secondary border border-main rounded-lg resize-none text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/50"
            rows={3}
          />
        </div>
        <Button disabled={!newNote.trim()}>Add Note</Button>

        <div className="space-y-4 pt-4 border-t border-main">
          {job.notes.length === 0 ? (
            <p className="text-center text-muted py-4">No notes yet</p>
          ) : (
            job.notes.map((note) => (
              <div key={note.id} className="p-4 bg-secondary rounded-lg">
                <div className="flex items-center gap-2 mb-2">
                  <Avatar name={note.authorName} size="sm" />
                  <span className="font-medium text-main text-sm">{note.authorName}</span>
                  <span className="text-xs text-muted">{formatDateTime(note.createdAt)}</span>
                </div>
                <p className="text-main">{note.content}</p>
              </div>
            ))
          )}
        </div>
      </CardContent>
    </Card>
  );
}
