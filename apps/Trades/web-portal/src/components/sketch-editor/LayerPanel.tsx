'use client';

// ZAFTO Layer Panel — Layer management sidebar (SK6)
// Visibility, lock, opacity, active layer selection, add/remove.

import React, { useState } from 'react';
import {
  Eye,
  EyeOff,
  Lock,
  Unlock,
  Trash2,
  Plus,
  Zap,
  Droplet,
  Wind,
  AlertTriangle,
  ChevronDown,
  ChevronRight,
  type LucideIcon,
} from 'lucide-react';
import type { TradeLayer, TradeLayerType } from '@/lib/sketch-engine/types';

interface LayerPanelProps {
  layers: TradeLayer[];
  activeLayerId: string | null;
  onActiveLayerChange: (id: string | null) => void;
  onToggleVisibility: (id: string) => void;
  onToggleLock: (id: string) => void;
  onOpacityChange: (id: string, opacity: number) => void;
  onAddLayer: (type: TradeLayerType) => void;
  onRemoveLayer: (id: string) => void;
}

const LAYER_ICONS: Record<TradeLayerType, LucideIcon> = {
  electrical: Zap,
  plumbing: Droplet,
  hvac: Wind,
  damage: AlertTriangle,
};

const LAYER_COLORS: Record<TradeLayerType, string> = {
  electrical: '#F59E0B',
  plumbing: '#3B82F6',
  hvac: '#10B981',
  damage: '#EF4444',
};

export default function LayerPanel({
  layers,
  activeLayerId,
  onActiveLayerChange,
  onToggleVisibility,
  onToggleLock,
  onOpacityChange,
  onAddLayer,
  onRemoveLayer,
}: LayerPanelProps) {
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [showAddMenu, setShowAddMenu] = useState(false);

  return (
    <div className="w-52 bg-white/95 backdrop-blur border border-gray-200 rounded-xl shadow-lg overflow-hidden">
      {/* Header */}
      <div className="px-3 py-2 border-b border-gray-100 flex items-center justify-between">
        <span className="text-xs font-semibold text-gray-700">Layers</span>
        <div className="relative">
          <button
            onClick={() => setShowAddMenu(!showAddMenu)}
            className="w-5 h-5 flex items-center justify-center rounded text-gray-400 hover:text-gray-600 hover:bg-gray-100"
          >
            <Plus size={12} />
          </button>
          {showAddMenu && (
            <div className="absolute right-0 top-6 w-36 bg-white border border-gray-200 rounded-lg shadow-lg z-50 py-1">
              {(
                ['electrical', 'plumbing', 'hvac', 'damage'] as TradeLayerType[]
              ).map((type) => {
                const Icon = LAYER_ICONS[type];
                return (
                  <button
                    key={type}
                    onClick={() => {
                      onAddLayer(type);
                      setShowAddMenu(false);
                    }}
                    className="w-full px-3 py-1.5 flex items-center gap-2 text-xs text-gray-600 hover:bg-gray-50"
                  >
                    <Icon size={12} color={LAYER_COLORS[type]} />
                    <span className="capitalize">{type}</span>
                  </button>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* Base layer */}
      <button
        onClick={() => onActiveLayerChange(null)}
        className={`w-full px-3 py-2 flex items-center gap-2 text-xs border-b border-gray-50 ${
          activeLayerId === null
            ? 'bg-blue-50 border-l-2 border-l-blue-500'
            : 'hover:bg-gray-50'
        }`}
      >
        <div className="w-3 h-3 rounded border border-gray-300 bg-gray-100" />
        <span className="font-medium text-gray-700">Base Layer</span>
      </button>

      {/* Trade layers */}
      <div className="max-h-64 overflow-y-auto">
        {layers.map((layer) => {
          const Icon = LAYER_ICONS[layer.type];
          const color = LAYER_COLORS[layer.type];
          const isActive = activeLayerId === layer.id;
          const isExpanded = expandedId === layer.id;

          return (
            <div
              key={layer.id}
              className={`border-b border-gray-50 ${
                isActive ? 'bg-blue-50/50' : ''
              }`}
              style={{
                borderLeftWidth: isActive ? 2 : 0,
                borderLeftColor: isActive ? color : 'transparent',
              }}
            >
              {/* Layer row */}
              <div className="flex items-center gap-1 px-2 py-1.5">
                <button
                  onClick={() =>
                    setExpandedId(isExpanded ? null : layer.id)
                  }
                  className="text-gray-400"
                >
                  {isExpanded ? (
                    <ChevronDown size={10} />
                  ) : (
                    <ChevronRight size={10} />
                  )}
                </button>
                <button
                  onClick={() => onActiveLayerChange(layer.id)}
                  className="flex-1 flex items-center gap-1.5 min-w-0"
                >
                  <Icon size={12} color={color} />
                  <span
                    className="text-xs font-medium truncate"
                    style={{ color: isActive ? color : '#374151' }}
                  >
                    {layer.name}
                  </span>
                </button>
                <button
                  onClick={() => onToggleVisibility(layer.id)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  {layer.visible ? (
                    <Eye size={11} />
                  ) : (
                    <EyeOff size={11} />
                  )}
                </button>
                <button
                  onClick={() => onToggleLock(layer.id)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  {layer.locked ? (
                    <Lock size={11} />
                  ) : (
                    <Unlock size={11} />
                  )}
                </button>
              </div>

              {/* Expanded controls */}
              {isExpanded && (
                <div className="px-3 pb-2 flex items-center gap-2">
                  <span className="text-[10px] text-gray-400 w-8">
                    {Math.round(layer.opacity * 100)}%
                  </span>
                  <input
                    type="range"
                    min={0}
                    max={100}
                    value={Math.round(layer.opacity * 100)}
                    onChange={(e) =>
                      onOpacityChange(
                        layer.id,
                        parseInt(e.target.value) / 100,
                      )
                    }
                    className="flex-1 h-1 accent-blue-500"
                  />
                  <button
                    onClick={() => onRemoveLayer(layer.id)}
                    className="text-gray-300 hover:text-red-500"
                  >
                    <Trash2 size={11} />
                  </button>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {layers.length === 0 && (
        <div className="px-3 py-4 text-center text-[10px] text-gray-400">
          No trade layers yet.
          <br />
          Click + to add one.
        </div>
      )}
    </div>
  );
}
