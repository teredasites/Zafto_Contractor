'use client';

import { useState } from 'react';
import { Phone, X, Delete } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { getSupabase } from '@/lib/supabase';
import { cn } from '@/lib/utils';

interface PhoneDialerProps {
  prefillNumber?: string;
  customerId?: string;
  jobId?: string;
  onClose?: () => void;
  compact?: boolean;
}

const DIAL_PAD = [
  ['1', '2', '3'],
  ['4', '5', '6'],
  ['7', '8', '9'],
  ['*', '0', '#'],
];

export function PhoneDialer({ prefillNumber, customerId, jobId, onClose, compact }: PhoneDialerProps) {
  const [number, setNumber] = useState(prefillNumber || '');
  const [calling, setCalling] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleDial = (digit: string) => {
    setNumber(prev => prev + digit);
  };

  const handleBackspace = () => {
    setNumber(prev => prev.slice(0, -1));
  };

  const handleCall = async () => {
    if (!number.trim() || calling) return;

    try {
      setCalling(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase.functions.invoke('signalwire-voice', {
        body: { action: 'call', toNumber: number.trim(), customerId, jobId },
      });

      if (err) throw new Error(err.message);
      if (data?.error) throw new Error(data.error);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to initiate call');
    } finally {
      setCalling(false);
    }
  };

  return (
    <div className={cn(
      'bg-surface border border-main rounded-xl shadow-xl',
      compact ? 'p-3 w-64' : 'p-6 w-80'
    )}>
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-sm font-medium text-muted">Dial</h3>
        {onClose && (
          <Button variant="ghost" size="sm" className="h-6 w-6 p-0" onClick={onClose}>
            <X className="h-3.5 w-3.5" />
          </Button>
        )}
      </div>

      {/* Number display */}
      <div className="flex items-center justify-between mb-4 bg-secondary rounded-lg px-4 py-3">
        <input
          type="tel"
          value={number}
          onChange={(e) => setNumber(e.target.value)}
          placeholder="Enter number"
          className="bg-transparent text-xl font-mono text-main focus:outline-none w-full"
        />
        {number && (
          <Button variant="ghost" size="sm" className="h-7 w-7 p-0 flex-shrink-0" onClick={handleBackspace}>
            <Delete className="h-4 w-4" />
          </Button>
        )}
      </div>

      {/* Dial pad */}
      {!compact && (
        <div className="grid grid-cols-3 gap-2 mb-4">
          {DIAL_PAD.flat().map(digit => (
            <button
              key={digit}
              onClick={() => handleDial(digit)}
              className="h-12 rounded-lg bg-secondary hover:bg-surface-hover text-lg font-medium text-main transition-colors"
            >
              {digit}
            </button>
          ))}
        </div>
      )}

      {/* Error */}
      {error && <p className="text-xs text-red-400 mb-2">{error}</p>}

      {/* Call button */}
      <Button
        onClick={handleCall}
        disabled={!number.trim() || calling}
        className="w-full bg-emerald-600 hover:bg-emerald-700 gap-2"
      >
        <Phone className="h-4 w-4" />
        {calling ? 'Calling...' : 'Call'}
      </Button>
    </div>
  );
}

// Click-to-call button for embedding in customer/job pages
export function ClickToCall({ phoneNumber, customerId, jobId }: {
  phoneNumber: string;
  customerId?: string;
  jobId?: string;
}) {
  const [showDialer, setShowDialer] = useState(false);

  return (
    <div className="relative inline-block">
      <Button
        variant="ghost"
        size="sm"
        className="h-7 gap-1.5 text-emerald-400 hover:text-emerald-300"
        onClick={() => setShowDialer(!showDialer)}
      >
        <Phone className="h-3.5 w-3.5" />
        {phoneNumber}
      </Button>
      {showDialer && (
        <div className="absolute top-full right-0 mt-2 z-50">
          <PhoneDialer
            prefillNumber={phoneNumber}
            customerId={customerId}
            jobId={jobId}
            onClose={() => setShowDialer(false)}
            compact
          />
        </div>
      )}
    </div>
  );
}
