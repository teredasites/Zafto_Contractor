'use client';

import { useState, useMemo } from 'react';
import { Calendar, Clock, ChevronLeft, ChevronRight, Check, ArrowLeft, Loader2, Video, AlertCircle } from 'lucide-react';
import Link from 'next/link';
import { useBookingTypes, useAvailability, useBookMeeting, type BookingTypeData, type TimeSlot } from '@/lib/hooks/use-meetings';

// ==================== HELPERS ====================

const MEETING_TYPE_LABELS: Record<string, string> = {
  site_walk: 'Site Walk',
  virtual_estimate: 'Virtual Estimate',
  document_review: 'Document Review',
  team_huddle: 'Team Huddle',
  insurance_conference: 'Insurance Conference',
  subcontractor_consult: 'Subcontractor Consult',
  expert_consult: 'Expert Consult',
};

const MEETING_TYPE_DESCRIPTIONS: Record<string, string> = {
  site_walk: 'Walk through your property with your contractor on video',
  virtual_estimate: 'Get a remote estimate via video call',
  document_review: 'Review contracts, plans, or documents together',
  team_huddle: 'Quick sync with the project team',
  insurance_conference: 'Discuss insurance claim details',
  subcontractor_consult: 'Consultation with a specialist',
  expert_consult: 'Expert consultation session',
};

function formatDuration(minutes: number): string {
  if (minutes < 60) return `${minutes} min`;
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return m > 0 ? `${h}h ${m}m` : `${h}h`;
}

function getWeekDays(startOfWeek: Date): Date[] {
  const days: Date[] = [];
  for (let i = 0; i < 7; i++) {
    const d = new Date(startOfWeek);
    d.setDate(d.getDate() + i);
    days.push(d);
  }
  return days;
}

function getStartOfWeek(date: Date): Date {
  const d = new Date(date);
  const day = d.getDay();
  d.setDate(d.getDate() - day);
  d.setHours(0, 0, 0, 0);
  return d;
}

function formatDateISO(date: Date): string {
  return date.toISOString().split('T')[0];
}

function formatSlotTime(dateStr: string): string {
  return new Date(dateStr).toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
}

function isSameDay(d1: Date, d2: Date): boolean {
  return d1.getFullYear() === d2.getFullYear()
    && d1.getMonth() === d2.getMonth()
    && d1.getDate() === d2.getDate();
}

function isToday(date: Date): boolean {
  return isSameDay(date, new Date());
}

function isPast(date: Date): boolean {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const check = new Date(date);
  check.setHours(0, 0, 0, 0);
  return check < today;
}

// ==================== STEP 1: SELECT BOOKING TYPE ====================

function BookingTypeSelector({ types, loading, error, onSelect }: {
  types: BookingTypeData[];
  loading: boolean;
  error: string | null;
  onSelect: (type: BookingTypeData) => void;
}) {
  if (loading) {
    return (
      <div className="space-y-3 animate-pulse">
        {[1, 2, 3].map(i => (
          <div key={i} className="rounded-xl border p-5" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
            <div className="h-5 rounded w-40 mb-2" style={{ backgroundColor: 'var(--bg-secondary)' }} />
            <div className="h-3 rounded w-64" style={{ backgroundColor: 'var(--border-light)' }} />
          </div>
        ))}
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-xl border p-6 text-center" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
        <AlertCircle size={28} className="mx-auto mb-2" style={{ color: 'var(--error)' }} />
        <p className="text-sm" style={{ color: 'var(--error)' }}>{error}</p>
      </div>
    );
  }

  if (types.length === 0) {
    return (
      <div className="rounded-xl border p-8 text-center" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
        <Calendar size={32} className="mx-auto mb-3" style={{ color: 'var(--text-muted)' }} />
        <h3 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>No booking types available</h3>
        <p className="text-xs mt-1" style={{ color: 'var(--text-muted)' }}>
          Your contractor has not set up any booking types yet.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-2">
      {types.map(type => (
        <button
          key={type.id}
          onClick={() => onSelect(type)}
          className="w-full text-left rounded-xl border p-5 transition-all hover:shadow-sm group"
          style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}
          onMouseEnter={e => { (e.currentTarget as HTMLElement).style.borderColor = 'var(--accent)'; }}
          onMouseLeave={e => { (e.currentTarget as HTMLElement).style.borderColor = 'var(--border-light)'; }}
        >
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <h3 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>{type.name}</h3>
              <p className="text-xs mt-1" style={{ color: 'var(--text-muted)' }}>
                {type.description || MEETING_TYPE_DESCRIPTIONS[type.meetingType] || MEETING_TYPE_LABELS[type.meetingType] || type.meetingType}
              </p>
              <div className="flex items-center gap-3 mt-2">
                <span className="flex items-center gap-1 text-xs" style={{ color: 'var(--text-muted)' }}>
                  <Clock size={11} />
                  {formatDuration(type.durationMinutes)}
                </span>
                <span className="flex items-center gap-1 text-xs" style={{ color: 'var(--text-muted)' }}>
                  <Video size={11} />
                  Video Call
                </span>
              </div>
            </div>
            <ChevronRight size={16} className="mt-1 flex-shrink-0" style={{ color: 'var(--text-muted)' }} />
          </div>
        </button>
      ))}
    </div>
  );
}

// ==================== STEP 2: SELECT DATE + TIME ====================

function DateTimePicker({ bookingType, onBack, onBook }: {
  bookingType: BookingTypeData;
  onBack: () => void;
  onBook: (startTime: string) => void;
}) {
  const [weekOffset, setWeekOffset] = useState(0);
  const [selectedDate, setSelectedDate] = useState<Date | null>(null);
  const [selectedSlot, setSelectedSlot] = useState<string | null>(null);

  const baseWeekStart = useMemo(() => getStartOfWeek(new Date()), []);
  const currentWeekStart = useMemo(() => {
    const d = new Date(baseWeekStart);
    d.setDate(d.getDate() + weekOffset * 7);
    return d;
  }, [baseWeekStart, weekOffset]);

  const weekDays = useMemo(() => getWeekDays(currentWeekStart), [currentWeekStart]);

  const endOfWeek = useMemo(() => {
    const d = new Date(currentWeekStart);
    d.setDate(d.getDate() + 6);
    return d;
  }, [currentWeekStart]);

  const { slots, loading: slotsLoading, error: slotsError } = useAvailability(
    bookingType.slug,
    formatDateISO(currentWeekStart),
    formatDateISO(endOfWeek),
  );

  // Filter slots for selected date
  const dailySlots = useMemo(() => {
    if (!selectedDate) return [];
    return slots.filter(slot => {
      const slotDate = new Date(slot.start);
      return isSameDay(slotDate, selectedDate);
    });
  }, [slots, selectedDate]);

  // Count slots per day for indicators
  const slotCountByDay = useMemo(() => {
    const counts: Record<string, number> = {};
    slots.forEach(slot => {
      const key = new Date(slot.start).toDateString();
      counts[key] = (counts[key] || 0) + 1;
    });
    return counts;
  }, [slots]);

  const handleDateSelect = (date: Date) => {
    if (isPast(date)) return;
    setSelectedDate(date);
    setSelectedSlot(null);
  };

  const handleConfirm = () => {
    if (selectedSlot) onBook(selectedSlot);
  };

  const weekLabel = currentWeekStart.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });

  return (
    <div className="space-y-5">
      {/* Back + Type Info */}
      <div className="flex items-center gap-3">
        <button
          onClick={onBack}
          className="p-2 rounded-lg transition-colors"
          style={{ color: 'var(--text-muted)' }}
        >
          <ArrowLeft size={18} />
        </button>
        <div>
          <h2 className="font-semibold text-sm" style={{ color: 'var(--text)' }}>{bookingType.name}</h2>
          <p className="text-xs" style={{ color: 'var(--text-muted)' }}>{formatDuration(bookingType.durationMinutes)} video call</p>
        </div>
      </div>

      {/* Week Navigator */}
      <div className="rounded-xl border p-4" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
        <div className="flex items-center justify-between mb-4">
          <button
            onClick={() => { setWeekOffset(w => Math.max(0, w - 1)); setSelectedDate(null); setSelectedSlot(null); }}
            disabled={weekOffset === 0}
            className="p-1.5 rounded-lg transition-colors disabled:opacity-30"
            style={{ color: 'var(--text-muted)' }}
          >
            <ChevronLeft size={16} />
          </button>
          <span className="text-sm font-semibold" style={{ color: 'var(--text)' }}>{weekLabel}</span>
          <button
            onClick={() => { setWeekOffset(w => w + 1); setSelectedDate(null); setSelectedSlot(null); }}
            disabled={weekOffset >= 4}
            className="p-1.5 rounded-lg transition-colors disabled:opacity-30"
            style={{ color: 'var(--text-muted)' }}
          >
            <ChevronRight size={16} />
          </button>
        </div>

        {/* Day Cells */}
        <div className="grid grid-cols-7 gap-1">
          {weekDays.map(day => {
            const dayLabel = day.toLocaleDateString('en-US', { weekday: 'short' });
            const dateNum = day.getDate();
            const past = isPast(day);
            const today = isToday(day);
            const selected = selectedDate && isSameDay(day, selectedDate);
            const hasSlots = (slotCountByDay[day.toDateString()] || 0) > 0;

            return (
              <button
                key={day.toISOString()}
                onClick={() => handleDateSelect(day)}
                disabled={past}
                className="flex flex-col items-center py-2 rounded-lg transition-colors"
                style={{
                  backgroundColor: selected ? 'var(--accent)' : 'transparent',
                  color: selected ? 'white' : past ? 'var(--border)' : 'var(--text)',
                  opacity: past ? 0.4 : 1,
                  cursor: past ? 'not-allowed' : 'pointer',
                }}
              >
                <span className="text-[10px] font-medium" style={{ color: selected ? 'rgba(255,255,255,0.7)' : 'var(--text-muted)' }}>
                  {dayLabel}
                </span>
                <span className={`text-sm font-bold mt-0.5 ${today && !selected ? 'underline' : ''}`}>
                  {dateNum}
                </span>
                {hasSlots && !past && (
                  <div className="w-1 h-1 rounded-full mt-0.5" style={{ backgroundColor: selected ? 'rgba(255,255,255,0.7)' : 'var(--accent)' }} />
                )}
              </button>
            );
          })}
        </div>
      </div>

      {/* Time Slots */}
      {selectedDate && (
        <div className="rounded-xl border p-4" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
          <h3 className="text-xs font-semibold uppercase tracking-wider mb-3" style={{ color: 'var(--text-muted)' }}>
            Available Times -- {selectedDate.toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' })}
          </h3>

          {slotsLoading && (
            <div className="flex items-center justify-center py-8">
              <Loader2 size={20} className="animate-spin" style={{ color: 'var(--accent)' }} />
            </div>
          )}

          {slotsError && (
            <p className="text-xs text-center py-4" style={{ color: 'var(--error)' }}>{slotsError}</p>
          )}

          {!slotsLoading && !slotsError && dailySlots.length === 0 && (
            <p className="text-xs text-center py-6" style={{ color: 'var(--text-muted)' }}>
              No available times on this date. Try another day.
            </p>
          )}

          {!slotsLoading && dailySlots.length > 0 && (
            <div className="grid grid-cols-3 sm:grid-cols-4 gap-2">
              {dailySlots.map(slot => {
                const isSelected = selectedSlot === slot.start;
                return (
                  <button
                    key={slot.start}
                    onClick={() => setSelectedSlot(slot.start)}
                    className="py-2.5 rounded-lg text-sm font-medium transition-all border"
                    style={{
                      backgroundColor: isSelected ? 'var(--accent)' : 'transparent',
                      borderColor: isSelected ? 'var(--accent)' : 'var(--border-light)',
                      color: isSelected ? 'white' : 'var(--text)',
                    }}
                  >
                    {formatSlotTime(slot.start)}
                  </button>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* Confirm Button */}
      {selectedSlot && (
        <button
          onClick={handleConfirm}
          className="w-full flex items-center justify-center gap-2 py-3 rounded-xl text-sm font-semibold text-white transition-colors"
          style={{ backgroundColor: 'var(--accent)' }}
        >
          <Check size={16} />
          Confirm Booking
        </button>
      )}
    </div>
  );
}

// ==================== STEP 3: CONFIRMATION ====================

function BookingConfirmation({ bookingType, startTime, onReset }: {
  bookingType: BookingTypeData;
  startTime: string;
  onReset: () => void;
}) {
  const d = new Date(startTime);
  return (
    <div className="rounded-xl border p-8 text-center" style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--border-light)' }}>
      <div className="w-14 h-14 rounded-full mx-auto mb-4 flex items-center justify-center" style={{ backgroundColor: 'color-mix(in srgb, var(--success) 15%, transparent)' }}>
        <Check size={28} style={{ color: 'var(--success)' }} />
      </div>
      <h2 className="text-lg font-bold mb-1" style={{ color: 'var(--text)' }}>Meeting Booked</h2>
      <p className="text-sm mb-4" style={{ color: 'var(--text-muted)' }}>
        Your meeting has been scheduled. You will receive a confirmation.
      </p>

      <div className="rounded-xl p-4 mb-5 text-left" style={{ backgroundColor: 'var(--bg-secondary)' }}>
        <div className="space-y-2">
          <div className="flex justify-between text-sm">
            <span style={{ color: 'var(--text-muted)' }}>Type</span>
            <span className="font-medium" style={{ color: 'var(--text)' }}>{bookingType.name}</span>
          </div>
          <div className="flex justify-between text-sm">
            <span style={{ color: 'var(--text-muted)' }}>Date</span>
            <span className="font-medium" style={{ color: 'var(--text)' }}>
              {d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })}
            </span>
          </div>
          <div className="flex justify-between text-sm">
            <span style={{ color: 'var(--text-muted)' }}>Time</span>
            <span className="font-medium" style={{ color: 'var(--text)' }}>
              {d.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })}
            </span>
          </div>
          <div className="flex justify-between text-sm">
            <span style={{ color: 'var(--text-muted)' }}>Duration</span>
            <span className="font-medium" style={{ color: 'var(--text)' }}>{formatDuration(bookingType.durationMinutes)}</span>
          </div>
        </div>
      </div>

      <div className="flex gap-2">
        <Link
          href="/meetings"
          className="flex-1 py-2.5 rounded-xl text-sm font-semibold text-white text-center transition-colors"
          style={{ backgroundColor: 'var(--accent)' }}
        >
          View Meetings
        </Link>
        <button
          onClick={onReset}
          className="flex-1 py-2.5 rounded-xl text-sm font-semibold border transition-colors"
          style={{ borderColor: 'var(--border-light)', color: 'var(--text)' }}
        >
          Book Another
        </button>
      </div>
    </div>
  );
}

// ==================== PAGE ====================

export default function BookPage() {
  const { bookingTypes, loading, error } = useBookingTypes();
  const { bookMeeting, booking, error: bookError, success, reset } = useBookMeeting();

  const [selectedType, setSelectedType] = useState<BookingTypeData | null>(null);
  const [bookedTime, setBookedTime] = useState<string | null>(null);

  const handleSelectType = (type: BookingTypeData) => {
    setSelectedType(type);
  };

  const handleBack = () => {
    setSelectedType(null);
  };

  const handleBook = async (startTime: string) => {
    if (!selectedType) return;
    const result = await bookMeeting(selectedType.slug, startTime);
    if (result) {
      setBookedTime(startTime);
    }
  };

  const handleReset = () => {
    reset();
    setSelectedType(null);
    setBookedTime(null);
  };

  // Step 3: Confirmed
  if (success && selectedType && bookedTime) {
    return (
      <div className="space-y-5">
        <div>
          <h1 className="text-xl font-bold" style={{ color: 'var(--text)' }}>Book a Meeting</h1>
        </div>
        <BookingConfirmation bookingType={selectedType} startTime={bookedTime} onReset={handleReset} />
      </div>
    );
  }

  // Step 2: Select date/time
  if (selectedType) {
    return (
      <div className="space-y-5">
        <div>
          <h1 className="text-xl font-bold" style={{ color: 'var(--text)' }}>Book a Meeting</h1>
          <p className="text-sm mt-0.5" style={{ color: 'var(--text-muted)' }}>
            Pick a date and time that works for you
          </p>
        </div>

        {bookError && (
          <div className="rounded-xl px-4 py-3 text-sm flex items-center gap-2" style={{ backgroundColor: 'var(--error-light)', color: 'var(--error)' }}>
            <AlertCircle size={14} />
            {bookError}
          </div>
        )}

        {booking && (
          <div className="flex items-center justify-center py-8">
            <Loader2 size={24} className="animate-spin" style={{ color: 'var(--accent)' }} />
            <span className="ml-2 text-sm" style={{ color: 'var(--text-muted)' }}>Booking your meeting...</span>
          </div>
        )}

        {!booking && (
          <DateTimePicker bookingType={selectedType} onBack={handleBack} onBook={handleBook} />
        )}
      </div>
    );
  }

  // Step 1: Select type
  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-xl font-bold" style={{ color: 'var(--text)' }}>Book a Meeting</h1>
        <p className="text-sm mt-0.5" style={{ color: 'var(--text-muted)' }}>
          Choose the type of meeting you would like to schedule
        </p>
      </div>

      <BookingTypeSelector types={bookingTypes} loading={loading} error={error} onSelect={handleSelectType} />
    </div>
  );
}
