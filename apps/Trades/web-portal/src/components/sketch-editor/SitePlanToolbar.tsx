'use client';

// ZAFTO Site Plan Toolbar (SK12)
// Drawing tools for exterior property: boundary, structures, roof, fencing,
// hardscape, landscape, utilities, grading.

import React, { useState } from 'react';
import {
  MousePointer,
  Pentagon,
  Home,
  TriangleRight,
  Fence,
  Grip,
  Droplets,
  TreePine,
  Shovel,
  Mountain,
  MapPin,
  Ruler,
  Type,
  Hand,
  Eraser,
  Undo2,
  Redo2,
  ZoomIn,
  ZoomOut,
  Grid3x3,
  ChevronDown,
  type LucideIcon,
} from 'lucide-react';
import type { SitePlanTool, SiteSymbolType, LinearFeatureType, AreaFeatureType } from '@/lib/sketch-engine/types';

interface SitePlanToolbarProps {
  activeTool: SitePlanTool;
  canUndo: boolean;
  canRedo: boolean;
  onToolChange: (tool: SitePlanTool) => void;
  onSymbolTypeChange: (type: SiteSymbolType) => void;
  onUndo: () => void;
  onRedo: () => void;
  onZoomIn: () => void;
  onZoomOut: () => void;
  onToggleGrid: () => void;
}

interface ToolDef {
  tool: SitePlanTool;
  icon: LucideIcon;
  label: string;
  group: string;
}

const TOOLS: ToolDef[] = [
  { tool: 'select', icon: MousePointer, label: 'Select', group: 'general' },
  { tool: 'boundary', icon: Pentagon, label: 'Property Line', group: 'boundary' },
  { tool: 'structure', icon: Home, label: 'Structure', group: 'structures' },
  { tool: 'roofPlane', icon: TriangleRight, label: 'Roof Plane', group: 'roof' },
  { tool: 'fence', icon: Fence, label: 'Fence', group: 'linear' },
  { tool: 'retainingWall', icon: Grip, label: 'Retaining Wall', group: 'linear' },
  { tool: 'gutter', icon: Droplets, label: 'Gutter', group: 'linear' },
  { tool: 'concrete', icon: Grip, label: 'Concrete', group: 'area' },
  { tool: 'lawn', icon: TreePine, label: 'Lawn/Sod', group: 'area' },
  { tool: 'paver', icon: Grid3x3, label: 'Pavers', group: 'area' },
  { tool: 'landscape', icon: Shovel, label: 'Landscape', group: 'area' },
  { tool: 'gravel', icon: Mountain, label: 'Gravel', group: 'area' },
  { tool: 'elevation', icon: MapPin, label: 'Elevation', group: 'grading' },
  { tool: 'symbol', icon: MapPin, label: 'Symbol', group: 'symbols' },
  { tool: 'label', icon: Type, label: 'Label', group: 'general' },
  { tool: 'pan', icon: Hand, label: 'Pan', group: 'general' },
  { tool: 'erase', icon: Eraser, label: 'Erase', group: 'general' },
];

const SYMBOL_OPTIONS: { type: SiteSymbolType; label: string }[] = [
  { type: 'treeDeciduous', label: 'Deciduous Tree' },
  { type: 'treeEvergreen', label: 'Evergreen' },
  { type: 'treePalm', label: 'Palm Tree' },
  { type: 'shrub', label: 'Shrub' },
  { type: 'acUnit', label: 'A/C Unit' },
  { type: 'utilityBox', label: 'Utility Box' },
  { type: 'electricMeter', label: 'Electric Meter' },
  { type: 'gasMeter', label: 'Gas Meter' },
  { type: 'waterShutoff', label: 'Water Shutoff' },
  { type: 'hoseBib', label: 'Hose Bib' },
  { type: 'irrigationHead', label: 'Irrigation Head' },
  { type: 'lightPole', label: 'Light Pole' },
  { type: 'mailbox', label: 'Mailbox' },
  { type: 'downspoutSymbol', label: 'Downspout' },
  { type: 'cleanoutSite', label: 'Cleanout' },
];

export default function SitePlanToolbar({
  activeTool,
  canUndo,
  canRedo,
  onToolChange,
  onSymbolTypeChange,
  onUndo,
  onRedo,
  onZoomIn,
  onZoomOut,
  onToggleGrid,
}: SitePlanToolbarProps) {
  const [showSymbolPicker, setShowSymbolPicker] = useState(false);

  return (
    <div className="flex flex-col gap-0.5 p-1 bg-white border border-gray-200 rounded-lg shadow-sm">
      {/* Drawing tools */}
      {TOOLS.map((t) => {
        const Icon = t.icon;
        const isActive = activeTool === t.tool;
        return (
          <div key={t.tool} className="relative">
            <button
              onClick={() => {
                onToolChange(t.tool);
                if (t.tool === 'symbol') setShowSymbolPicker(!showSymbolPicker);
                else setShowSymbolPicker(false);
              }}
              className={`flex items-center justify-center w-8 h-8 rounded transition-colors ${
                isActive
                  ? 'bg-indigo-100 text-indigo-700'
                  : 'text-gray-500 hover:bg-gray-100 hover:text-gray-700'
              }`}
              title={t.label}
            >
              <Icon size={16} />
            </button>
            {/* Symbol sub-picker */}
            {t.tool === 'symbol' && showSymbolPicker && isActive && (
              <div className="absolute left-10 top-0 z-50 w-44 max-h-64 overflow-y-auto bg-white border border-gray-200 rounded-lg shadow-lg p-1">
                {SYMBOL_OPTIONS.map((s) => (
                  <button
                    key={s.type}
                    onClick={() => {
                      onSymbolTypeChange(s.type);
                      setShowSymbolPicker(false);
                    }}
                    className="w-full text-left px-2 py-1 text-xs text-gray-700 rounded hover:bg-gray-100"
                  >
                    {s.label}
                  </button>
                ))}
              </div>
            )}
          </div>
        );
      })}

      {/* Divider */}
      <div className="h-px bg-gray-200 my-1" />

      {/* Undo/Redo */}
      <button
        onClick={onUndo}
        disabled={!canUndo}
        className="flex items-center justify-center w-8 h-8 rounded text-gray-500 hover:bg-gray-100 disabled:opacity-30 disabled:cursor-not-allowed"
        title="Undo"
      >
        <Undo2 size={14} />
      </button>
      <button
        onClick={onRedo}
        disabled={!canRedo}
        className="flex items-center justify-center w-8 h-8 rounded text-gray-500 hover:bg-gray-100 disabled:opacity-30 disabled:cursor-not-allowed"
        title="Redo"
      >
        <Redo2 size={14} />
      </button>

      {/* Divider */}
      <div className="h-px bg-gray-200 my-1" />

      {/* Zoom/Grid */}
      <button
        onClick={onZoomIn}
        className="flex items-center justify-center w-8 h-8 rounded text-gray-500 hover:bg-gray-100"
        title="Zoom In"
      >
        <ZoomIn size={14} />
      </button>
      <button
        onClick={onZoomOut}
        className="flex items-center justify-center w-8 h-8 rounded text-gray-500 hover:bg-gray-100"
        title="Zoom Out"
      >
        <ZoomOut size={14} />
      </button>
      <button
        onClick={onToggleGrid}
        className="flex items-center justify-center w-8 h-8 rounded text-gray-500 hover:bg-gray-100"
        title="Toggle Grid"
      >
        <Grid3x3 size={14} />
      </button>
    </div>
  );
}
