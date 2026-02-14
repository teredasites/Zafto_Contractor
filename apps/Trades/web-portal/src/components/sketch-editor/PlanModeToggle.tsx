'use client';

// ZAFTO Plan Mode Toggle (SK12)
// Switches between interior floor plan and exterior site plan drawing modes.

import React from 'react';
import { Home, Map } from 'lucide-react';

export type PlanMode = 'floor' | 'site';

interface PlanModeToggleProps {
  mode: PlanMode;
  onModeChange: (mode: PlanMode) => void;
}

export default function PlanModeToggle({ mode, onModeChange }: PlanModeToggleProps) {
  return (
    <div className="flex items-center bg-gray-100 rounded-lg p-0.5 border border-gray-200">
      <button
        onClick={() => onModeChange('floor')}
        className={`flex items-center gap-1 px-2.5 py-1 rounded-md text-xs font-medium transition-all ${
          mode === 'floor'
            ? 'bg-white text-gray-900 shadow-sm'
            : 'text-gray-500 hover:text-gray-700'
        }`}
      >
        <Home size={12} />
        Floor Plan
      </button>
      <button
        onClick={() => onModeChange('site')}
        className={`flex items-center gap-1 px-2.5 py-1 rounded-md text-xs font-medium transition-all ${
          mode === 'site'
            ? 'bg-white text-gray-900 shadow-sm'
            : 'text-gray-500 hover:text-gray-700'
        }`}
      >
        <Map size={12} />
        Site Plan
      </button>
    </div>
  );
}
