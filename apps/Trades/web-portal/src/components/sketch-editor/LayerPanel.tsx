'use client';

// ZAFTO Layer Panel — Layer management sidebar (SK6)
// Visibility, lock, opacity, active layer selection, add/remove.

import React, { useState, useRef, useEffect } from 'react';
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
  Flame,
  ChevronDown,
  ChevronRight,
  Home,
  Layers,
  PaintBucket,
  Wrench,
  Sun,
  Wifi,
  Fuel,
  Snowflake,
  Hammer,
  Square,
  CircleDot,
  Paintbrush,
  TreeDeciduous,
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
  fire: Flame,
  roofing: Home,
  siding: Layers,
  insulation: Snowflake,
  framing: Wrench,
  drywall: Square,
  flooring: CircleDot,
  painting: Paintbrush,
  concrete: Hammer,
  demolition: AlertTriangle,
  solar: Sun,
  low_voltage: Wifi,
  gas: Fuel,
  irrigation: TreeDeciduous,
};

const LAYER_COLORS: Record<TradeLayerType, string> = {
  electrical: '#F59E0B',
  plumbing: '#3B82F6',
  hvac: '#10B981',
  damage: '#EF4444',
  fire: '#DC2626',
  roofing: '#8B5CF6',
  siding: '#06B6D4',
  insulation: '#EC4899',
  framing: '#D97706',
  drywall: '#6B7280',
  flooring: '#14B8A6',
  painting: '#F472B6',
  concrete: '#78716C',
  demolition: '#F97316',
  solar: '#FBBF24',
  low_voltage: '#818CF8',
  gas: '#EAB308',
  irrigation: '#22C55E',
};

const LAYER_LABELS: Record<TradeLayerType, string> = {
  electrical: 'Electrical',
  plumbing: 'Plumbing',
  hvac: 'HVAC',
  damage: 'Damage',
  fire: 'Fire Protection',
  roofing: 'Roofing',
  siding: 'Siding',
  insulation: 'Insulation',
  framing: 'Framing',
  drywall: 'Drywall',
  flooring: 'Flooring',
  painting: 'Painting',
  concrete: 'Concrete',
  demolition: 'Demo',
  solar: 'Solar',
  low_voltage: 'Low Voltage',
  gas: 'Gas',
  irrigation: 'Irrigation',
};

// Group trade types for the add menu
const TRADE_GROUPS: { label: string; types: TradeLayerType[] }[] = [
  { label: 'MEP', types: ['electrical', 'plumbing', 'hvac', 'gas', 'fire'] },
  { label: 'Structural', types: ['framing', 'concrete', 'roofing', 'insulation'] },
  { label: 'Finishes', types: ['drywall', 'flooring', 'painting', 'siding'] },
  { label: 'Specialty', types: ['solar', 'low_voltage', 'irrigation', 'demolition', 'damage'] },
];

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
  const menuRef = useRef<HTMLDivElement>(null);

  // Close dropdown on outside click
  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setShowAddMenu(false);
      }
    }
    if (showAddMenu) {
      document.addEventListener('mousedown', handleClick);
      return () => document.removeEventListener('mousedown', handleClick);
    }
  }, [showAddMenu]);

  return (
    <div className="w-56 bg-[#1a1a2e]/95 backdrop-blur border border-[#2a2a4a] rounded-xl shadow-2xl overflow-visible">
      {/* Header */}
      <div className="px-3 py-2.5 border-b border-[#2a2a4a] flex items-center justify-between">
        <span className="text-xs font-semibold text-neutral-200">Trade Layers</span>
        <div className="relative" ref={menuRef}>
          <button
            onClick={() => setShowAddMenu(!showAddMenu)}
            className="w-6 h-6 flex items-center justify-center rounded-md text-neutral-400 hover:text-white hover:bg-[#2a2a4a] transition-colors"
          >
            <Plus size={14} />
          </button>
          {showAddMenu && (
            <div className="absolute right-0 top-8 w-48 bg-[#1e1e36] border border-[#3a3a5a] rounded-lg shadow-2xl z-[9999] py-1 max-h-80 overflow-y-auto">
              {TRADE_GROUPS.map((group) => (
                <div key={group.label}>
                  <div className="px-3 py-1 text-[10px] font-semibold text-neutral-500 uppercase tracking-wider">
                    {group.label}
                  </div>
                  {group.types.map((type) => {
                    const Icon = LAYER_ICONS[type];
                    const alreadyAdded = layers.some((l) => l.type === type);
                    return (
                      <button
                        key={type}
                        onClick={() => {
                          onAddLayer(type);
                          setShowAddMenu(false);
                        }}
                        disabled={alreadyAdded}
                        className="w-full px-3 py-1.5 flex items-center gap-2 text-xs text-neutral-300 hover:bg-[#2a2a4a] disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                      >
                        <Icon size={12} color={LAYER_COLORS[type]} />
                        <span>{LAYER_LABELS[type]}</span>
                        {alreadyAdded && (
                          <span className="ml-auto text-[9px] text-neutral-500">added</span>
                        )}
                      </button>
                    );
                  })}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Base layer */}
      <button
        onClick={() => onActiveLayerChange(null)}
        className={`w-full px-3 py-2 flex items-center gap-2 text-xs border-b border-[#2a2a4a] transition-colors ${
          activeLayerId === null
            ? 'bg-blue-900/30 border-l-2 border-l-blue-500'
            : 'hover:bg-[#2a2a4a]/50'
        }`}
      >
        <div className="w-3 h-3 rounded border border-neutral-600 bg-neutral-800" />
        <span className="font-medium text-neutral-200">Base Layer</span>
      </button>

      {/* Trade layers */}
      <div className="max-h-72 overflow-y-auto">
        {layers.map((layer) => {
          const Icon = LAYER_ICONS[layer.type];
          const color = LAYER_COLORS[layer.type];
          const isActive = activeLayerId === layer.id;
          const isExpanded = expandedId === layer.id;

          return (
            <div
              key={layer.id}
              className={`border-b border-[#2a2a4a]/50 transition-colors ${
                isActive ? 'bg-[#2a2a4a]/40' : ''
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
                  className="text-neutral-500 hover:text-neutral-300"
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
                    style={{ color: isActive ? color : '#d4d4d8' }}
                  >
                    {layer.name}
                  </span>
                </button>
                <button
                  onClick={() => onToggleVisibility(layer.id)}
                  className="text-neutral-500 hover:text-neutral-300 transition-colors"
                >
                  {layer.visible ? (
                    <Eye size={11} />
                  ) : (
                    <EyeOff size={11} />
                  )}
                </button>
                <button
                  onClick={() => onToggleLock(layer.id)}
                  className="text-neutral-500 hover:text-neutral-300 transition-colors"
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
                  <span className="text-[10px] text-neutral-500 w-8">
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
                    className="text-neutral-500 hover:text-red-400 transition-colors"
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
        <div className="px-3 py-4 text-center text-[10px] text-neutral-500">
          No trade layers yet.
          <br />
          Click + to add one.
        </div>
      )}
    </div>
  );
}
