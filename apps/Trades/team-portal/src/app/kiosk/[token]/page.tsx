'use client';

import { useParams } from 'next/navigation';
import { useState, useEffect, useCallback } from 'react';
import { useKiosk, type KioskEmployee } from '@/lib/hooks/use-kiosk';
import {
  Clock, LogIn, LogOut, Coffee, CoffeeIcon, AlertCircle,
  CheckCircle, ArrowLeft, Delete, Loader2, User, ChevronRight,
} from 'lucide-react';

// ── Clock Display ──

function LiveClock() {
  const [time, setTime] = useState(new Date());
  useEffect(() => {
    const id = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(id);
  }, []);

  return (
    <div className="text-center">
      <div className="text-7xl font-light tracking-tight tabular-nums">
        {time.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })}
      </div>
      <div className="text-lg text-white/50 mt-1">
        {time.toLocaleDateString([], { weekday: 'long', month: 'long', day: 'numeric' })}
      </div>
    </div>
  );
}

// ── PIN Keypad ──

function PinKeypad({
  onSubmit,
  onCancel,
  loading,
  error,
}: {
  onSubmit: (pin: string) => void;
  onCancel: () => void;
  loading: boolean;
  error: string | null;
}) {
  const [pin, setPin] = useState('');
  const [shake, setShake] = useState(false);

  const handleDigit = (d: string) => {
    if (pin.length < 8) setPin(prev => prev + d);
  };

  const handleDelete = () => {
    setPin(prev => prev.slice(0, -1));
  };

  const handleSubmit = () => {
    if (pin.length >= 4) onSubmit(pin);
  };

  useEffect(() => {
    if (error) {
      setShake(true);
      setPin('');
      const t = setTimeout(() => setShake(false), 600);
      return () => clearTimeout(t);
    }
  }, [error]);

  return (
    <div className="flex flex-col items-center gap-6">
      {/* PIN display */}
      <div className={`flex gap-3 ${shake ? 'animate-shake' : ''}`}>
        {Array.from({ length: 8 }).map((_, i) => (
          <div
            key={i}
            className={`w-4 h-4 rounded-full transition-all ${
              i < pin.length ? 'bg-emerald-400 scale-110' : 'bg-white/20'
            }`}
          />
        ))}
      </div>

      {error && (
        <p className="text-red-400 text-sm">{error}</p>
      )}

      {/* Keypad grid */}
      <div className="grid grid-cols-3 gap-3">
        {['1', '2', '3', '4', '5', '6', '7', '8', '9'].map(d => (
          <button
            key={d}
            onClick={() => handleDigit(d)}
            className="w-20 h-20 rounded-2xl bg-white/10 hover:bg-white/20 active:bg-white/30 text-3xl font-medium transition-all"
          >
            {d}
          </button>
        ))}
        <button
          onClick={onCancel}
          className="w-20 h-20 rounded-2xl bg-white/5 hover:bg-white/10 active:bg-white/20 text-sm text-white/60 transition-all flex items-center justify-center"
        >
          <ArrowLeft size={24} />
        </button>
        <button
          onClick={() => handleDigit('0')}
          className="w-20 h-20 rounded-2xl bg-white/10 hover:bg-white/20 active:bg-white/30 text-3xl font-medium transition-all"
        >
          0
        </button>
        <button
          onClick={handleDelete}
          className="w-20 h-20 rounded-2xl bg-white/5 hover:bg-white/10 active:bg-white/20 transition-all flex items-center justify-center"
        >
          <Delete size={24} className="text-white/60" />
        </button>
      </div>

      {/* Submit */}
      <button
        onClick={handleSubmit}
        disabled={pin.length < 4 || loading}
        className="w-full max-w-[270px] h-14 rounded-2xl bg-emerald-500 hover:bg-emerald-400 disabled:bg-white/10 disabled:text-white/30 text-lg font-semibold transition-all flex items-center justify-center gap-2"
      >
        {loading ? <Loader2 size={20} className="animate-spin" /> : 'Enter'}
      </button>
    </div>
  );
}

// ── Employee Grid (Name-Tap) ──

function EmployeeGrid({
  employees,
  onSelect,
}: {
  employees: KioskEmployee[];
  onSelect: (e: KioskEmployee) => void;
}) {
  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-3 max-h-[60vh] overflow-y-auto p-1">
      {employees.map(emp => (
        <button
          key={emp.id}
          onClick={() => onSelect(emp)}
          className="group flex flex-col items-center gap-2 p-4 rounded-2xl bg-white/5 hover:bg-white/10 active:bg-white/15 transition-all border border-white/5 hover:border-white/20"
        >
          {/* Avatar */}
          <div className="relative">
            <div className="w-16 h-16 rounded-full bg-white/10 flex items-center justify-center overflow-hidden">
              {emp.avatar ? (
                <img src={emp.avatar} alt="" className="w-full h-full object-cover" />
              ) : (
                <User size={28} className="text-white/40" />
              )}
            </div>
            {/* Active indicator */}
            {emp.activeEntry && (
              <div className="absolute -bottom-0.5 -right-0.5 w-5 h-5 rounded-full bg-emerald-500 border-2 border-[#0a0a0a] flex items-center justify-center">
                <Clock size={10} />
              </div>
            )}
          </div>

          {/* Name */}
          <span className="text-sm font-medium text-center leading-tight">
            {emp.name || 'Unknown'}
          </span>

          {/* Status */}
          {emp.activeEntry ? (
            <span className="text-xs text-emerald-400">Clocked In</span>
          ) : (
            <span className="text-xs text-white/30">Not clocked in</span>
          )}
        </button>
      ))}
    </div>
  );
}

// ── Confirm Screen ──

function ConfirmScreen({
  employee,
  onClockIn,
  onClockOut,
  onStartBreak,
  onEndBreak,
  onCancel,
  loading,
  allowBreakToggle,
}: {
  employee: KioskEmployee;
  onClockIn: () => void;
  onClockOut: () => void;
  onStartBreak: () => void;
  onEndBreak: () => void;
  onCancel: () => void;
  loading: boolean;
  allowBreakToggle: boolean;
}) {
  const isClockedIn = !!employee.activeEntry;

  // Determine if on break (check location_pings — we approximate by checking if break_start was last action)
  // For now, just show break toggle when clocked in

  return (
    <div className="flex flex-col items-center gap-8 max-w-md mx-auto">
      {/* Employee info */}
      <div className="flex flex-col items-center gap-3">
        <div className="w-24 h-24 rounded-full bg-white/10 flex items-center justify-center overflow-hidden">
          {employee.avatar ? (
            <img src={employee.avatar} alt="" className="w-full h-full object-cover" />
          ) : (
            <User size={40} className="text-white/40" />
          )}
        </div>
        <h2 className="text-3xl font-semibold">{employee.name || 'Employee'}</h2>
        {employee.role && (
          <span className="text-white/40 text-sm capitalize">{employee.role.replace(/_/g, ' ')}</span>
        )}
      </div>

      {/* Status */}
      {isClockedIn && employee.activeEntry && (
        <div className="text-center">
          <p className="text-emerald-400 text-sm">Clocked in since</p>
          <p className="text-xl font-medium">
            {new Date(employee.activeEntry.clockIn).toLocaleTimeString([], {
              hour: 'numeric',
              minute: '2-digit',
            })}
          </p>
          {employee.activeEntry.breakMinutes > 0 && (
            <p className="text-white/40 text-xs mt-1">
              {employee.activeEntry.breakMinutes} min break
            </p>
          )}
        </div>
      )}

      {/* Actions */}
      <div className="flex flex-col gap-3 w-full">
        {!isClockedIn ? (
          <button
            onClick={onClockIn}
            disabled={loading}
            className="w-full h-16 rounded-2xl bg-emerald-500 hover:bg-emerald-400 active:bg-emerald-600 text-xl font-semibold transition-all flex items-center justify-center gap-3 disabled:opacity-50"
          >
            {loading ? <Loader2 size={24} className="animate-spin" /> : (
              <>
                <LogIn size={24} />
                Clock In
              </>
            )}
          </button>
        ) : (
          <>
            <button
              onClick={onClockOut}
              disabled={loading}
              className="w-full h-16 rounded-2xl bg-red-500 hover:bg-red-400 active:bg-red-600 text-xl font-semibold transition-all flex items-center justify-center gap-3 disabled:opacity-50"
            >
              {loading ? <Loader2 size={24} className="animate-spin" /> : (
                <>
                  <LogOut size={24} />
                  Clock Out
                </>
              )}
            </button>

            {allowBreakToggle && (
              <div className="flex gap-3">
                <button
                  onClick={onStartBreak}
                  disabled={loading}
                  className="flex-1 h-14 rounded-2xl bg-amber-500/20 hover:bg-amber-500/30 active:bg-amber-500/40 text-amber-400 font-semibold transition-all flex items-center justify-center gap-2 disabled:opacity-50"
                >
                  <Coffee size={20} />
                  Start Break
                </button>
                <button
                  onClick={onEndBreak}
                  disabled={loading}
                  className="flex-1 h-14 rounded-2xl bg-blue-500/20 hover:bg-blue-500/30 active:bg-blue-500/40 text-blue-400 font-semibold transition-all flex items-center justify-center gap-2 disabled:opacity-50"
                >
                  <CoffeeIcon size={20} />
                  End Break
                </button>
              </div>
            )}
          </>
        )}

        <button
          onClick={onCancel}
          className="w-full h-12 rounded-2xl bg-white/5 hover:bg-white/10 text-white/60 font-medium transition-all"
        >
          Back
        </button>
      </div>
    </div>
  );
}

// ── Main Kiosk Page ──

export default function KioskPage() {
  const params = useParams();
  const token = params.token as string;

  const {
    screen,
    config,
    company,
    employees,
    selectedEmployee,
    error,
    successMessage,
    actionLoading,
    goToIdle,
    goToIdentify,
    selectEmployee,
    verifyPin,
    clockIn,
    clockOut,
    startBreak,
    endBreak,
  } = useKiosk(token);

  const [pinError, setPinError] = useState<string | null>(null);

  const handlePinSubmit = useCallback(async (pin: string) => {
    setPinError(null);
    const ok = await verifyPin(pin);
    if (!ok) setPinError('Invalid PIN — try again');
  }, [verifyPin]);

  // Primary color from branding
  const accentColor = config?.branding.primary_color || '#10b981';

  // ── LOADING SCREEN ──
  if (screen === 'loading') {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center gap-4">
        <Loader2 size={48} className="animate-spin text-white/40" />
        <p className="text-white/40">Loading kiosk...</p>
      </div>
    );
  }

  // ── ERROR SCREEN ──
  if (screen === 'error') {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center gap-4 px-8">
        <AlertCircle size={64} className="text-red-400" />
        <h1 className="text-2xl font-semibold">Kiosk Error</h1>
        <p className="text-white/60 text-center max-w-md">{error}</p>
        <button
          onClick={goToIdle}
          className="mt-4 px-6 h-12 rounded-2xl bg-white/10 hover:bg-white/20 font-medium transition-all"
        >
          Retry
        </button>
      </div>
    );
  }

  // ── IDLE SCREEN ──
  if (screen === 'idle') {
    return (
      <div
        className="min-h-screen flex flex-col items-center justify-center cursor-pointer"
        onClick={goToIdentify}
        style={config?.branding.background_url ? {
          backgroundImage: `url(${config.branding.background_url})`,
          backgroundSize: 'cover',
          backgroundPosition: 'center',
        } : undefined}
      >
        <div className="flex flex-col items-center gap-8 p-8">
          {/* Company logo */}
          {config?.settings.show_company_logo && company?.logo_url ? (
            <img
              src={company.logo_url}
              alt={company.name}
              className="h-16 object-contain"
            />
          ) : company?.name ? (
            <h1 className="text-2xl font-bold tracking-tight">{company.name}</h1>
          ) : null}

          {/* Live clock */}
          <LiveClock />

          {/* Greeting */}
          <p className="text-xl text-white/50 mt-4">
            {config?.settings.greeting_message || 'Tap anywhere to clock in'}
          </p>

          {/* Kiosk name */}
          <p className="text-sm text-white/20 absolute bottom-4">
            {config?.name}
          </p>
        </div>
      </div>
    );
  }

  // ── IDENTIFY SCREEN ──
  if (screen === 'identify') {
    return (
      <div className="min-h-screen flex flex-col p-6">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <button
            onClick={goToIdle}
            className="flex items-center gap-2 text-white/40 hover:text-white/60 transition-colors"
          >
            <ArrowLeft size={20} />
            <span className="text-sm">Back</span>
          </button>
          <LiveClock />
          <div className="w-16" /> {/* Spacer for centering */}
        </div>

        <h2 className="text-2xl font-semibold text-center mb-6">Who are you?</h2>

        {/* Employee grid */}
        <EmployeeGrid employees={employees} onSelect={selectEmployee} />

        {/* Active count */}
        <div className="mt-4 text-center text-white/30 text-sm">
          {employees.filter(e => e.activeEntry).length} of {employees.length} clocked in
        </div>
      </div>
    );
  }

  // ── PIN ENTRY SCREEN ──
  if (screen === 'pin_entry' && selectedEmployee) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center p-6">
        {/* Employee info */}
        <div className="flex flex-col items-center gap-2 mb-8">
          <div className="w-16 h-16 rounded-full bg-white/10 flex items-center justify-center overflow-hidden">
            {selectedEmployee.avatar ? (
              <img src={selectedEmployee.avatar} alt="" className="w-full h-full object-cover" />
            ) : (
              <User size={28} className="text-white/40" />
            )}
          </div>
          <h2 className="text-xl font-semibold">{selectedEmployee.name}</h2>
          <p className="text-white/40 text-sm">Enter your PIN</p>
        </div>

        <PinKeypad
          onSubmit={handlePinSubmit}
          onCancel={goToIdentify}
          loading={actionLoading}
          error={pinError}
        />
      </div>
    );
  }

  // ── CONFIRM SCREEN ──
  if (screen === 'confirm' && selectedEmployee) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center p-6">
        <ConfirmScreen
          employee={selectedEmployee}
          onClockIn={() => clockIn()}
          onClockOut={clockOut}
          onStartBreak={startBreak}
          onEndBreak={endBreak}
          onCancel={goToIdentify}
          loading={actionLoading}
          allowBreakToggle={config?.settings.allow_break_toggle ?? true}
        />

        {error && (
          <div className="mt-4 flex items-center gap-2 text-red-400 text-sm">
            <AlertCircle size={16} />
            {error}
          </div>
        )}
      </div>
    );
  }

  // ── SUCCESS SCREEN ──
  if (screen === 'success') {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center gap-6 p-6">
        <div
          className="w-24 h-24 rounded-full flex items-center justify-center"
          style={{ backgroundColor: `${accentColor}20` }}
        >
          <CheckCircle size={48} style={{ color: accentColor }} />
        </div>

        <h2 className="text-3xl font-semibold">{selectedEmployee?.name || 'Success'}</h2>
        <p className="text-xl text-white/60">{successMessage}</p>

        <div className="mt-8 flex items-center gap-2 text-white/20 text-sm">
          <span>Returning to home screen...</span>
        </div>

        <button
          onClick={goToIdle}
          className="mt-4 px-8 h-12 rounded-2xl bg-white/10 hover:bg-white/20 text-white/60 font-medium transition-all"
        >
          Done
        </button>
      </div>
    );
  }

  // Fallback
  return (
    <div className="min-h-screen flex items-center justify-center">
      <Loader2 size={32} className="animate-spin text-white/40" />
    </div>
  );
}
