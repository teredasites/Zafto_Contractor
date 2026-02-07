'use client';
import { useState } from 'react';
import Link from 'next/link';
import {
  Wrench, ChevronRight, AlertTriangle, CheckCircle2, Clock,
  Droplets, Zap, Thermometer, Refrigerator, Building2, Bug,
  KeyRound, Trees, Sofa, MoreHorizontal, Sun, Sunset, Moon,
} from 'lucide-react';
import { useMaintenanceRequests } from '@/lib/hooks/use-maintenance';
import { formatDate } from '@/lib/hooks/mappers';
import {
  urgencyLabel, categoryLabel, maintenanceStatusLabel,
  type MaintenanceUrgency, type MaintenanceCategory,
} from '@/lib/hooks/tenant-mappers';

// ==================== CATEGORY CONFIG ====================

const categories: { key: MaintenanceCategory; label: string; icon: typeof Zap }[] = [
  { key: 'plumbing', label: 'Plumbing', icon: Droplets },
  { key: 'electrical', label: 'Electrical', icon: Zap },
  { key: 'hvac', label: 'HVAC', icon: Thermometer },
  { key: 'appliance', label: 'Appliance', icon: Refrigerator },
  { key: 'structural', label: 'Structural', icon: Building2 },
  { key: 'pest', label: 'Pest Control', icon: Bug },
  { key: 'lock_key', label: 'Lock & Key', icon: KeyRound },
  { key: 'exterior', label: 'Exterior', icon: Trees },
  { key: 'interior', label: 'Interior', icon: Sofa },
  { key: 'other', label: 'Other', icon: MoreHorizontal },
];

const urgencyOptions: { key: MaintenanceUrgency; label: string }[] = [
  { key: 'routine', label: 'Routine' },
  { key: 'urgent', label: 'Urgent' },
  { key: 'emergency', label: 'Emergency' },
];

const timeSlots = [
  { key: 'morning', label: 'Morning', sub: '8am - 12pm', icon: Sun },
  { key: 'afternoon', label: 'Afternoon', sub: '12pm - 5pm', icon: Sunset },
  { key: 'evening', label: 'Evening', sub: '5pm - 8pm', icon: Moon },
];

type MaintenanceStatusKey = 'submitted' | 'reviewed' | 'approved' | 'scheduled' | 'in_progress' | 'completed' | 'cancelled';

const statusStyles: Record<MaintenanceStatusKey, { color: string; bg: string }> = {
  submitted: { color: 'var(--accent)', bg: 'var(--accent-light)' },
  reviewed: { color: 'var(--warning)', bg: 'color-mix(in srgb, var(--warning) 15%, transparent)' },
  approved: { color: '#3b82f6', bg: '#eff6ff' },
  scheduled: { color: '#3b82f6', bg: '#eff6ff' },
  in_progress: { color: 'var(--accent)', bg: 'var(--accent-light)' },
  completed: { color: 'var(--success)', bg: 'color-mix(in srgb, var(--success) 15%, transparent)' },
  cancelled: { color: 'var(--text-muted)', bg: 'var(--bg-secondary)' },
};

const urgencyStyles: Record<MaintenanceUrgency, { color: string; bg: string }> = {
  routine: { color: 'var(--text-muted)', bg: 'var(--bg-secondary)' },
  urgent: { color: 'var(--warning)', bg: 'color-mix(in srgb, var(--warning) 15%, transparent)' },
  emergency: { color: 'var(--danger)', bg: 'color-mix(in srgb, var(--danger) 15%, transparent)' },
};

// ==================== LOADING SKELETON ====================

function ListSkeleton() {
  return (
    <div className="space-y-2 animate-pulse">
      {[1, 2, 3].map(i => (
        <div key={i} className="flex items-center gap-3 rounded-xl border p-4" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
          <div className="w-10 h-10 rounded-xl" style={{ backgroundColor: 'var(--bg-secondary)' }} />
          <div className="flex-1 space-y-2">
            <div className="h-4 rounded w-32" style={{ backgroundColor: 'var(--bg-secondary)' }} />
            <div className="h-3 rounded w-48" style={{ backgroundColor: 'var(--border-light)' }} />
          </div>
          <div className="h-4 rounded w-20" style={{ backgroundColor: 'var(--bg-secondary)' }} />
        </div>
      ))}
    </div>
  );
}

// ==================== PAGE ====================

export default function MaintenancePage() {
  const { requests, activeCount, loading, submitting, submitRequest, refresh } = useMaintenanceRequests();

  // Form state
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [urgency, setUrgency] = useState<MaintenanceUrgency>('routine');
  const [category, setCategory] = useState<MaintenanceCategory | null>(null);
  const [preferredTimes, setPreferredTimes] = useState<string[]>([]);
  const [successBanner, setSuccessBanner] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isEmergency = urgency === 'emergency';

  function toggleTime(key: string) {
    setPreferredTimes(prev =>
      prev.includes(key) ? prev.filter(t => t !== key) : [...prev, key]
    );
  }

  async function handleSubmit() {
    if (!title.trim() || !description.trim()) return;
    setError(null);
    try {
      await submitRequest({
        title: title.trim(),
        description: description.trim(),
        urgency,
        category,
        preferredTimes: preferredTimes.length > 0 ? preferredTimes : null,
      });
      // Clear form
      setTitle('');
      setDescription('');
      setUrgency('routine');
      setCategory(null);
      setPreferredTimes([]);
      setSuccessBanner(true);
      setTimeout(() => setSuccessBanner(false), 4000);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to submit request');
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold" style={{ color: 'var(--text)' }}>Maintenance</h1>
        <p className="text-sm mt-0.5" style={{ color: 'var(--text-muted)' }}>Submit and track maintenance requests</p>
      </div>

      {/* ==================== SUCCESS BANNER ==================== */}
      {successBanner && (
        <div className="flex items-center gap-3 rounded-xl p-4" style={{ backgroundColor: 'color-mix(in srgb, var(--success) 12%, transparent)', border: '1px solid color-mix(in srgb, var(--success) 30%, transparent)' }}>
          <CheckCircle2 size={18} style={{ color: 'var(--success)' }} />
          <div>
            <p className="text-sm font-semibold" style={{ color: 'var(--success)' }}>Request submitted successfully</p>
            <p className="text-xs mt-0.5" style={{ color: 'var(--text-muted)' }}>Your property manager will review it shortly.</p>
          </div>
        </div>
      )}

      {/* ==================== SUBMIT REQUEST FORM ==================== */}
      <div className="rounded-xl border p-5 space-y-5" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
        <h2 className="font-bold text-sm" style={{ color: 'var(--text)' }}>Submit a Request</h2>

        {/* Emergency Warning */}
        {isEmergency && (
          <div className="flex items-center gap-2 rounded-xl p-3" style={{ backgroundColor: 'color-mix(in srgb, var(--danger) 10%, transparent)', border: '1px solid color-mix(in srgb, var(--danger) 30%, transparent)' }}>
            <AlertTriangle size={16} style={{ color: 'var(--danger)' }} />
            <p className="text-xs" style={{ color: 'var(--danger)' }}>Emergency requests are dispatched immediately. Your property manager will be notified with priority.</p>
          </div>
        )}

        {/* Title */}
        <div>
          <label className="block text-xs font-medium mb-1.5" style={{ color: 'var(--text-muted)' }}>Title</label>
          <input
            value={title}
            onChange={e => setTitle(e.target.value)}
            placeholder="e.g. Kitchen faucet leaking"
            className="w-full px-4 py-2.5 rounded-xl border outline-none text-sm transition-colors"
            style={{ borderColor: 'var(--border-light)', color: 'var(--text)', backgroundColor: 'var(--surface)' }}
          />
        </div>

        {/* Description */}
        <div>
          <label className="block text-xs font-medium mb-1.5" style={{ color: 'var(--text-muted)' }}>Description</label>
          <textarea
            value={description}
            onChange={e => setDescription(e.target.value)}
            placeholder="Describe the issue in detail..."
            rows={4}
            className="w-full px-4 py-3 rounded-xl border outline-none text-sm resize-none transition-colors"
            style={{ borderColor: 'var(--border-light)', color: 'var(--text)', backgroundColor: 'var(--surface)' }}
          />
        </div>

        {/* Urgency */}
        <div>
          <label className="block text-xs font-medium mb-2" style={{ color: 'var(--text-muted)' }}>Urgency</label>
          <div className="flex gap-2">
            {urgencyOptions.map(opt => {
              const selected = urgency === opt.key;
              const isEm = opt.key === 'emergency';
              return (
                <button
                  key={opt.key}
                  onClick={() => setUrgency(opt.key)}
                  className="flex-1 py-2.5 rounded-xl text-xs font-medium border-2 transition-all"
                  style={{
                    borderColor: selected
                      ? (isEm ? 'var(--danger)' : 'var(--accent)')
                      : 'var(--border-light)',
                    backgroundColor: selected
                      ? (isEm ? 'color-mix(in srgb, var(--danger) 10%, transparent)' : 'var(--accent-light)')
                      : 'transparent',
                    color: selected
                      ? (isEm ? 'var(--danger)' : 'var(--accent)')
                      : 'var(--text-muted)',
                  }}
                >
                  {opt.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* Category */}
        <div>
          <label className="block text-xs font-medium mb-2" style={{ color: 'var(--text-muted)' }}>Category</label>
          <div className="grid grid-cols-5 gap-2">
            {categories.map(cat => {
              const Icon = cat.icon;
              const selected = category === cat.key;
              return (
                <button
                  key={cat.key}
                  onClick={() => setCategory(cat.key)}
                  className="p-2.5 rounded-xl border-2 text-center transition-all"
                  style={{
                    borderColor: selected ? 'var(--accent)' : 'var(--border-light)',
                    backgroundColor: selected ? 'var(--accent-light)' : 'transparent',
                  }}
                >
                  <Icon
                    size={18}
                    className="mx-auto mb-1"
                    style={{ color: selected ? 'var(--accent)' : 'var(--text-muted)' }}
                  />
                  <p className="text-[10px] font-medium" style={{ color: 'var(--text)' }}>{cat.label}</p>
                </button>
              );
            })}
          </div>
        </div>

        {/* Preferred Times */}
        <div>
          <label className="block text-xs font-medium mb-2" style={{ color: 'var(--text-muted)' }}>Preferred Times</label>
          <div className="flex gap-2">
            {timeSlots.map(slot => {
              const Icon = slot.icon;
              const checked = preferredTimes.includes(slot.key);
              return (
                <button
                  key={slot.key}
                  onClick={() => toggleTime(slot.key)}
                  className="flex-1 flex items-center gap-2 p-3 rounded-xl border-2 transition-all"
                  style={{
                    borderColor: checked ? 'var(--accent)' : 'var(--border-light)',
                    backgroundColor: checked ? 'var(--accent-light)' : 'transparent',
                  }}
                >
                  <Icon size={14} style={{ color: checked ? 'var(--accent)' : 'var(--text-muted)' }} />
                  <div className="text-left">
                    <p className="text-xs font-medium" style={{ color: 'var(--text)' }}>{slot.label}</p>
                    <p className="text-[10px]" style={{ color: 'var(--text-muted)' }}>{slot.sub}</p>
                  </div>
                </button>
              );
            })}
          </div>
        </div>

        {/* Error */}
        {error && (
          <div className="flex items-center gap-2 rounded-xl p-3" style={{ backgroundColor: 'color-mix(in srgb, var(--danger) 10%, transparent)', border: '1px solid color-mix(in srgb, var(--danger) 30%, transparent)' }}>
            <AlertTriangle size={14} style={{ color: 'var(--danger)' }} />
            <p className="text-xs" style={{ color: 'var(--danger)' }}>{error}</p>
          </div>
        )}

        {/* Submit */}
        <button
          onClick={handleSubmit}
          disabled={!title.trim() || !description.trim() || submitting}
          className="w-full py-3.5 font-bold rounded-xl text-sm text-white transition-all disabled:opacity-40 disabled:cursor-not-allowed"
          style={{ backgroundColor: isEmergency ? 'var(--danger)' : 'var(--accent)' }}
        >
          {submitting ? 'Submitting...' : isEmergency ? 'Submit Emergency Request' : 'Submit Request'}
        </button>
      </div>

      {/* ==================== MY REQUESTS ==================== */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="font-bold text-sm" style={{ color: 'var(--text)' }}>
            My Requests
            {activeCount > 0 && (
              <span
                className="ml-2 text-[10px] font-medium px-2 py-0.5 rounded-full"
                style={{ backgroundColor: 'var(--accent-light)', color: 'var(--accent)' }}
              >
                {activeCount} active
              </span>
            )}
          </h2>
        </div>

        {loading && <ListSkeleton />}

        {!loading && requests.length === 0 && (
          <div className="rounded-xl border p-8 text-center" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
            <Wrench size={32} className="mx-auto mb-3" style={{ color: 'var(--text-muted)' }} />
            <h3 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>No maintenance requests</h3>
            <p className="text-xs mt-1" style={{ color: 'var(--text-muted)' }}>Submit your first request using the form above.</p>
          </div>
        )}

        {!loading && requests.length > 0 && (
          <div className="space-y-2">
            {requests.map(req => {
              const sStyle = statusStyles[req.status as MaintenanceStatusKey] || statusStyles.submitted;
              const uStyle = urgencyStyles[req.urgency] || urgencyStyles.routine;
              return (
                <Link
                  key={req.id}
                  href={`/maintenance/${req.id}`}
                  className="flex items-center gap-3 rounded-xl border p-4 transition-all hover:shadow-sm"
                  style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}
                >
                  <div className="p-2.5 rounded-xl" style={{ backgroundColor: sStyle.bg }}>
                    <Wrench size={18} style={{ color: sStyle.color }} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <h3 className="font-semibold text-sm truncate" style={{ color: 'var(--text)' }}>{req.title}</h3>
                      <span
                        className="text-[10px] font-medium px-2 py-0.5 rounded-full"
                        style={{ backgroundColor: uStyle.bg, color: uStyle.color }}
                      >
                        {urgencyLabel(req.urgency)}
                      </span>
                    </div>
                    <p className="text-xs mt-0.5" style={{ color: 'var(--text-muted)' }}>
                      {categoryLabel(req.category)} &middot; {formatDate(req.createdAt)}
                    </p>
                  </div>
                  <div className="flex items-center gap-2 flex-shrink-0">
                    <span
                      className="text-[10px] font-medium px-2 py-0.5 rounded-full"
                      style={{ backgroundColor: sStyle.bg, color: sStyle.color }}
                    >
                      {maintenanceStatusLabel(req.status)}
                    </span>
                    <ChevronRight size={14} style={{ color: 'var(--text-muted)' }} />
                  </div>
                </Link>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
