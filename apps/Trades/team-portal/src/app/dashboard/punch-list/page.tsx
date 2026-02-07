'use client';

import { useState } from 'react';
import { CheckSquare, Plus, X, Square, Check, Calendar } from 'lucide-react';
import { useMyJobs } from '@/lib/hooks/use-jobs';
import { usePunchList } from '@/lib/hooks/use-punch-list';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { cn, formatDate } from '@/lib/utils';

type FilterChip = 'all' | 'open' | 'completed';

const PRIORITY_VARIANT: Record<string, 'default' | 'success' | 'warning' | 'error' | 'info'> = {
  low: 'default',
  normal: 'info',
  high: 'warning',
  urgent: 'error',
};

export default function PunchListPage() {
  const { jobs, loading: jobsLoading } = useMyJobs();
  const [filterJobId, setFilterJobId] = useState<string | undefined>(undefined);
  const { items, loading: itemsLoading, addItem, toggleComplete, openCount, completedCount } = usePunchList(filterJobId);

  const [filterChip, setFilterChip] = useState<FilterChip>('all');
  const [showForm, setShowForm] = useState(false);
  const [formJobId, setFormJobId] = useState('');
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [priority, setPriority] = useState('normal');
  const [category, setCategory] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const filteredItems = items.filter((item) => {
    if (filterChip === 'open') return item.status !== 'completed' && item.status !== 'skipped';
    if (filterChip === 'completed') return item.status === 'completed' || item.status === 'skipped';
    return true;
  });

  const total = items.length;
  const progressPercent = total > 0 ? Math.round((completedCount / total) * 100) : 0;

  const resetForm = () => {
    setFormJobId('');
    setTitle('');
    setDescription('');
    setPriority('normal');
    setCategory('');
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formJobId || !title) return;
    setSubmitting(true);
    await addItem({
      jobId: formJobId,
      title,
      description,
      priority,
      category,
    });
    resetForm();
    setShowForm(false);
    setSubmitting(false);
  };

  const loading = jobsLoading || itemsLoading;

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div className="skeleton h-7 w-32 rounded-lg" />
        <div className="skeleton h-12 w-full rounded-lg" />
        <div className="skeleton h-6 w-full rounded-full" />
        <div className="skeleton h-48 w-full rounded-xl" />
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-start justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold text-main">Punch List</h1>
          <p className="text-sm text-muted mt-1">
            Track items that need to be addressed before job completion
          </p>
        </div>
        <Button
          size="sm"
          onClick={() => setShowForm(!showForm)}
          className="flex-shrink-0"
        >
          {showForm ? <X size={16} /> : <Plus size={16} />}
          {showForm ? 'Cancel' : 'Add Item'}
        </Button>
      </div>

      {/* Job Filter */}
      <div className="space-y-1.5">
        <label className="text-sm font-medium text-main">Filter by Job</label>
        <select
          value={filterJobId || ''}
          onChange={(e) => setFilterJobId(e.target.value || undefined)}
          className={cn(
            'w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main',
            'focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
            'text-[15px]'
          )}
        >
          <option value="">All Jobs</option>
          {jobs.map((job) => (
            <option key={job.id} value={job.id}>
              {job.title} - {job.customerName}
            </option>
          ))}
        </select>
      </div>

      {/* Progress Bar */}
      {total > 0 && (
        <div className="space-y-2">
          <div className="flex items-center justify-between text-sm">
            <span className="text-muted">Progress</span>
            <span className="font-medium text-main">{completedCount} / {total} ({progressPercent}%)</span>
          </div>
          <div className="w-full h-2.5 bg-secondary rounded-full overflow-hidden">
            <div
              className="h-full bg-accent rounded-full transition-all duration-300"
              style={{ width: `${progressPercent}%` }}
            />
          </div>
        </div>
      )}

      {/* Filter Chips */}
      <div className="flex gap-2 overflow-x-auto pb-1 -mx-1 px-1">
        {(['all', 'open', 'completed'] as FilterChip[]).map((chip) => {
          const chipCount = chip === 'all' ? total : chip === 'open' ? openCount : completedCount;
          return (
            <button
              key={chip}
              onClick={() => setFilterChip(chip)}
              className={cn(
                'flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium whitespace-nowrap transition-colors min-h-[40px]',
                filterChip === chip
                  ? 'bg-accent text-white'
                  : 'bg-secondary text-muted hover:text-main hover:bg-surface-hover border border-main'
              )}
            >
              {chip.charAt(0).toUpperCase() + chip.slice(1)}
              <span className={cn(
                'text-xs px-1.5 py-0.5 rounded-full',
                filterChip === chip
                  ? 'bg-white/20 text-white'
                  : 'bg-surface text-muted'
              )}>
                {chipCount}
              </span>
            </button>
          );
        })}
      </div>

      {/* Add Item Form */}
      {showForm && (
        <Card>
          <CardHeader>
            <CardTitle>Add Punch List Item</CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-sm font-medium text-main">Job</label>
                <select
                  value={formJobId}
                  onChange={(e) => setFormJobId(e.target.value)}
                  required
                  className={cn(
                    'w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main',
                    'focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
                    'text-[15px]'
                  )}
                >
                  <option value="">Select a job...</option>
                  {jobs.map((job) => (
                    <option key={job.id} value={job.id}>
                      {job.title} - {job.customerName}
                    </option>
                  ))}
                </select>
              </div>

              <Input
                label="Title"
                placeholder="Missing outlet cover, touch-up paint..."
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                required
              />

              <div className="space-y-1.5">
                <label className="text-sm font-medium text-main">Description</label>
                <textarea
                  rows={2}
                  placeholder="Additional details..."
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  className={cn(
                    'w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main',
                    'placeholder:text-muted focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
                    'text-[15px] resize-none'
                  )}
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-main">Priority</label>
                  <select
                    value={priority}
                    onChange={(e) => setPriority(e.target.value)}
                    className={cn(
                      'w-full px-3.5 py-2.5 bg-secondary border border-main rounded-lg text-main',
                      'focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent',
                      'text-[15px]'
                    )}
                  >
                    <option value="low">Low</option>
                    <option value="normal">Normal</option>
                    <option value="high">High</option>
                    <option value="urgent">Urgent</option>
                  </select>
                </div>
                <Input
                  label="Category"
                  placeholder="Electrical, Plumbing..."
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                />
              </div>

              <Button
                type="submit"
                loading={submitting}
                disabled={!formJobId || !title}
                className="w-full sm:w-auto min-h-[44px]"
              >
                <Plus size={16} />
                Add Item
              </Button>
            </form>
          </CardContent>
        </Card>
      )}

      {/* Items List */}
      {filteredItems.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <CheckSquare size={40} className="text-muted mx-auto mb-3" />
            <p className="text-sm font-medium text-main">
              {filterChip !== 'all' ? `No ${filterChip} items` : 'No punch list items'}
            </p>
            <p className="text-sm text-muted mt-1">
              {filterChip !== 'all'
                ? 'Try a different filter'
                : 'Add items that need to be resolved before job completion.'}
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-2">
          {filteredItems.map((item) => {
            const isCompleted = item.status === 'completed' || item.status === 'skipped';
            return (
              <Card key={item.id}>
                <CardContent className="py-3.5">
                  <div className="flex items-start gap-3">
                    <button
                      onClick={() => toggleComplete(item.id, item.status)}
                      className="flex-shrink-0 mt-0.5"
                    >
                      {isCompleted ? (
                        <div className="w-5 h-5 rounded bg-accent flex items-center justify-center">
                          <Check size={14} className="text-white" />
                        </div>
                      ) : (
                        <Square size={20} className="text-muted hover:text-accent transition-colors" />
                      )}
                    </button>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2 flex-wrap">
                        <p className={cn(
                          'text-sm font-medium',
                          isCompleted ? 'text-muted line-through' : 'text-main'
                        )}>
                          {item.title}
                        </p>
                        <Badge variant={PRIORITY_VARIANT[item.priority] || 'default'}>
                          {item.priority}
                        </Badge>
                        {item.category && (
                          <Badge variant="default">{item.category}</Badge>
                        )}
                      </div>
                      {item.description && (
                        <p className="text-xs text-muted mt-0.5 line-clamp-1">{item.description}</p>
                      )}
                      {item.dueDate && (
                        <span className="text-xs text-muted flex items-center gap-1 mt-1">
                          <Calendar size={12} />
                          Due {formatDate(item.dueDate)}
                        </span>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}
