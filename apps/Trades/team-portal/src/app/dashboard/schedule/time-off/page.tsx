'use client';

import { useState } from 'react';
import Link from 'next/link';
import {
  ArrowLeft, Calendar, Clock, CheckCircle2, XCircle, AlertCircle, Plus,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';
import { useTimeOff, type TimeOffRequest } from '@/lib/hooks/use-time-off';

const REQUEST_TYPES = [
  { value: 'vacation', label: 'Vacation' },
  { value: 'sick', label: 'Sick Day' },
  { value: 'personal', label: 'Personal' },
  { value: 'bereavement', label: 'Bereavement' },
  { value: 'jury_duty', label: 'Jury Duty' },
  { value: 'other', label: 'Other' },
];

const STATUS_CONFIG: Record<string, { color: string; icon: typeof CheckCircle2; label: string }> = {
  pending: { color: 'text-amber-500', icon: Clock, label: 'Pending' },
  approved: { color: 'text-green-500', icon: CheckCircle2, label: 'Approved' },
  denied: { color: 'text-red-500', icon: XCircle, label: 'Denied' },
  cancelled: { color: 'text-gray-400', icon: XCircle, label: 'Cancelled' },
};

function formatDateRange(start: string, end: string) {
  const s = new Date(start + 'T00:00:00');
  const e = new Date(end + 'T00:00:00');
  const opts: Intl.DateTimeFormatOptions = { month: 'short', day: 'numeric' };
  if (start === end) return s.toLocaleDateString('en-US', opts);
  return `${s.toLocaleDateString('en-US', opts)} - ${e.toLocaleDateString('en-US', opts)}`;
}

function dayCount(start: string, end: string) {
  const s = new Date(start + 'T00:00:00');
  const e = new Date(end + 'T00:00:00');
  return Math.max(1, Math.round((e.getTime() - s.getTime()) / 86400000) + 1);
}

export default function TimeOffPage() {
  const { requests, loading, error, submitRequest, cancelRequest } = useTimeOff();
  const [showForm, setShowForm] = useState(false);
  const [saving, setSaving] = useState(false);
  const [formData, setFormData] = useState({
    requestType: 'vacation',
    startDate: '',
    endDate: '',
    notes: '',
  });
  const [formError, setFormError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.startDate || !formData.endDate) {
      setFormError('Start and end dates are required');
      return;
    }
    if (formData.endDate < formData.startDate) {
      setFormError('End date must be after start date');
      return;
    }
    setFormError('');
    setSaving(true);
    try {
      await submitRequest(formData);
      setShowForm(false);
      setFormData({ requestType: 'vacation', startDate: '', endDate: '', notes: '' });
    } catch {
      setFormError('Failed to submit request');
    } finally {
      setSaving(false);
    }
  };

  const pendingCount = requests.filter((r) => r.status === 'pending').length;
  const approvedCount = requests.filter((r) => r.status === 'approved').length;

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link href="/dashboard/schedule" className="p-2 hover:bg-surface-hover rounded-lg transition-colors">
            <ArrowLeft size={18} className="text-muted" />
          </Link>
          <div>
            <h1 className="text-xl font-semibold text-main">Time Off Requests</h1>
            <p className="text-sm text-muted mt-0.5">Request and manage time off</p>
          </div>
        </div>
        <Button onClick={() => setShowForm(!showForm)} size="sm">
          <Plus size={14} />
          New Request
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 gap-3">
        <Card>
          <CardContent className="py-4 text-center">
            <p className="text-2xl font-bold text-amber-500">{pendingCount}</p>
            <p className="text-xs text-muted">Pending</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-4 text-center">
            <p className="text-2xl font-bold text-green-500">{approvedCount}</p>
            <p className="text-xs text-muted">Approved</p>
          </CardContent>
        </Card>
      </div>

      {/* New Request Form */}
      {showForm && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">New Time Off Request</CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              {formError && (
                <div className="px-3 py-2 rounded-lg text-sm bg-red-500/10 text-red-500 flex items-center gap-2">
                  <AlertCircle size={14} />
                  {formError}
                </div>
              )}
              <div>
                <label className="block text-xs font-medium text-muted mb-1.5">Type</label>
                <select
                  value={formData.requestType}
                  onChange={(e) => setFormData({ ...formData, requestType: e.target.value })}
                  className="w-full px-3 py-2.5 bg-secondary border border-main rounded-lg text-main text-sm focus:outline-none focus:ring-2 focus:ring-accent/50"
                >
                  {REQUEST_TYPES.map((t) => (
                    <option key={t.value} value={t.value}>{t.label}</option>
                  ))}
                </select>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-muted mb-1.5">Start Date</label>
                  <input
                    type="date"
                    value={formData.startDate}
                    onChange={(e) => setFormData({ ...formData, startDate: e.target.value, endDate: formData.endDate || e.target.value })}
                    className="w-full px-3 py-2.5 bg-secondary border border-main rounded-lg text-main text-sm focus:outline-none focus:ring-2 focus:ring-accent/50"
                    required
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-muted mb-1.5">End Date</label>
                  <input
                    type="date"
                    value={formData.endDate}
                    min={formData.startDate}
                    onChange={(e) => setFormData({ ...formData, endDate: e.target.value })}
                    className="w-full px-3 py-2.5 bg-secondary border border-main rounded-lg text-main text-sm focus:outline-none focus:ring-2 focus:ring-accent/50"
                    required
                  />
                </div>
              </div>
              <div>
                <label className="block text-xs font-medium text-muted mb-1.5">Notes (optional)</label>
                <textarea
                  value={formData.notes}
                  onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                  placeholder="Reason or additional details..."
                  className="w-full px-3 py-2.5 bg-secondary border border-main rounded-lg text-main text-sm placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/50 resize-none"
                  rows={3}
                />
              </div>
              <div className="flex gap-2">
                <Button type="submit" size="sm" className="flex-1" disabled={saving}>
                  {saving ? 'Submitting...' : 'Submit Request'}
                </Button>
                <Button type="button" variant="secondary" size="sm" onClick={() => setShowForm(false)}>
                  Cancel
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      )}

      {/* Requests List */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Calendar size={16} className="text-muted" />
            Your Requests
          </CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-3">
              {[1, 2, 3].map((i) => (
                <div key={i} className="skeleton h-16 rounded-lg" />
              ))}
            </div>
          ) : requests.length === 0 ? (
            <div className="text-center py-8">
              <Calendar size={32} className="mx-auto text-muted mb-3" />
              <p className="text-sm text-muted">No time off requests yet</p>
            </div>
          ) : (
            <div className="space-y-3">
              {requests.map((req) => {
                const config = STATUS_CONFIG[req.status] || STATUS_CONFIG.pending;
                const Icon = config.icon;
                return (
                  <div key={req.id} className="flex items-center gap-3 p-3 bg-secondary rounded-lg">
                    <div className={cn('w-9 h-9 rounded-full flex items-center justify-center bg-surface', config.color)}>
                      <Icon size={16} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <p className="text-sm font-medium text-main capitalize">
                          {req.requestType.replace(/_/g, ' ')}
                        </p>
                        <Badge variant={req.status === 'approved' ? 'success' : req.status === 'denied' ? 'error' : 'warning'}>
                          {config.label}
                        </Badge>
                      </div>
                      <p className="text-xs text-muted">
                        {formatDateRange(req.startDate, req.endDate)}
                        {' '}({dayCount(req.startDate, req.endDate)} day{dayCount(req.startDate, req.endDate) > 1 ? 's' : ''})
                      </p>
                      {req.notes && <p className="text-xs text-muted truncate mt-0.5">{req.notes}</p>}
                      {req.reviewNotes && (
                        <p className="text-xs text-amber-500 mt-0.5">Manager: {req.reviewNotes}</p>
                      )}
                    </div>
                    {req.status === 'pending' && (
                      <button
                        onClick={() => cancelRequest(req.id)}
                        className="text-xs text-muted hover:text-red-500 transition-colors px-2 py-1"
                      >
                        Cancel
                      </button>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
