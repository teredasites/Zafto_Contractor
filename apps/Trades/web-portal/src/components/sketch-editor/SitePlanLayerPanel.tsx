'use client';

// ZAFTO Site Plan Layer Panel (SK12)
// Controls visibility, lock, opacity for 8 site plan layers.

import React from 'react';
import {
  Eye,
  EyeOff,
  Lock,
  Unlock,
  Pentagon,
  Home,
  TriangleRight,
  Fence,
  Grip,
  TreePine,
  Zap,
  Mountain,
  ParkingSquare,
  Flame,
  Accessibility,
  SignpostBig,
  type LucideIcon,
} from 'lucide-react';
import type { SitePlanLayer, SitePlanLayerType } from '@/lib/sketch-engine/types';

const LAYER_ICONS: Record<SitePlanLayerType, LucideIcon> = {
  boundary: Pentagon,
  structures: Home,
  roof: TriangleRight,
  fencing: Fence,
  hardscape: Grip,
  landscape: TreePine,
  utilities: Zap,
  grading: Mountain,
  // Commercial
  parking: ParkingSquare,
  fireProtection: Flame,
  ada: Accessibility,
  signage: SignpostBig,
};

const LAYER_COLORS: Record<SitePlanLayerType, string> = {
  boundary: '#EF4444',
  structures: '#6366F1',
  roof: '#F59E0B',
  fencing: '#8B5CF6',
  hardscape: '#6B7280',
  landscape: '#22C55E',
  utilities: '#0EA5E9',
  grading: '#059669',
  // Commercial
  parking: '#6366F1',
  fireProtection: '#DC2626',
  ada: '#2563EB',
  signage: '#D97706',
};

interface SitePlanLayerPanelProps {
  layers: SitePlanLayer[];
  activeLayerId: string | null;
  onActiveLayerChange: (id: string | null) => void;
  onToggleVisibility: (id: string) => void;
  onToggleLock: (id: string) => void;
  onOpacityChange: (id: string, opacity: number) => void;
}

export default function SitePlanLayerPanel({
  layers,
  activeLayerId,
  onActiveLayerChange,
  onToggleVisibility,
  onToggleLock,
  onOpacityChange,
}: SitePlanLayerPanelProps) {
  return (
    <div className="w-56 bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden">
      <div className="px-3 py-2 border-b border-gray-100 text-xs font-semibold text-gray-700">
        Site Layers
      </div>
      <div className="divide-y divide-gray-50">
        {layers.map((layer) => {
          const Icon = LAYER_ICONS[layer.type] ?? Pentagon;
          const color = LAYER_COLORS[layer.type] ?? '#666';
          const isActive = activeLayerId === layer.id;

          return (
            <div
              key={layer.id}
              className={`flex items-center gap-1.5 px-2 py-1.5 text-xs cursor-pointer transition-colors ${
                isActive ? 'bg-indigo-50' : 'hover:bg-gray-50'
              }`}
              onClick={() => onActiveLayerChange(isActive ? null : layer.id)}
            >
              <Icon size={12} style={{ color }} />
              <span
                className={`flex-1 truncate ${
                  layer.visible ? 'text-gray-700' : 'text-gray-400 line-through'
                }`}
              >
                {layer.name}
              </span>

              {/* Visibility */}
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onToggleVisibility(layer.id);
                }}
                className="p-0.5 rounded hover:bg-gray-200"
                title={layer.visible ? 'Hide' : 'Show'}
              >
                {layer.visible ? (
                  <Eye size={11} className="text-gray-500" />
                ) : (
                  <EyeOff size={11} className="text-gray-400" />
                )}
              </button>

              {/* Lock */}
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onToggleLock(layer.id);
                }}
                className="p-0.5 rounded hover:bg-gray-200"
                title={layer.locked ? 'Unlock' : 'Lock'}
              >
                {layer.locked ? (
                  <Lock size={11} className="text-amber-500" />
                ) : (
                  <Unlock size={11} className="text-gray-400" />
                )}
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
}
