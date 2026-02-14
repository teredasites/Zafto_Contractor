'use client';

// ZAFTO 2D/3D View Toggle (SK10)
// Sits in the sketch editor header. Toggles between Konva 2D and Three.js 3D.

import React from 'react';
import { Square, Box } from 'lucide-react';

interface ViewToggleProps {
  is3D: boolean;
  onToggle: () => void;
}

export default function ViewToggle({ is3D, onToggle }: ViewToggleProps) {
  return (
    <button
      onClick={onToggle}
      className={`flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-medium transition-all ${
        is3D
          ? 'bg-indigo-100 text-indigo-700 border border-indigo-300'
          : 'bg-gray-100 text-gray-600 border border-gray-200 hover:bg-gray-150'
      }`}
      title={is3D ? 'Switch to 2D view' : 'Switch to 3D view'}
    >
      {is3D ? (
        <>
          <Box size={13} />
          <span>3D</span>
        </>
      ) : (
        <>
          <Square size={13} />
          <span>2D</span>
        </>
      )}
    </button>
  );
}
