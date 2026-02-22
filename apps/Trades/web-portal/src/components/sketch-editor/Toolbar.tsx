'use client';

// ZAFTO Sketch Toolbar — Drawing tools, trade tools, undo/redo, zoom (SK6)

import React from 'react';
import {
  MousePointer,
  Minus,
  Spline,
  DoorOpen,
  AppWindow,
  LayoutGrid,
  Type,
  Ruler,
  Lasso,
  Eraser,
  Move,
  Undo2,
  Redo2,
  ZoomIn,
  ZoomOut,
  Grid3x3,
  Layers,
  type LucideIcon,
} from 'lucide-react';
import type { SketchTool, EditorState } from '@/lib/sketch-engine/types';

interface ToolbarProps {
  editorState: EditorState;
  canUndo: boolean;
  canRedo: boolean;
  onToolChange: (tool: SketchTool) => void;
  onUndo: () => void;
  onRedo: () => void;
  onZoomIn: () => void;
  onZoomOut: () => void;
  onToggleGrid: () => void;
  onToggleLayers: () => void;
}

const TOOLS: { tool: SketchTool; icon: LucideIcon; label: string }[] = [
  { tool: 'select', icon: MousePointer, label: 'Select' },
  { tool: 'wall', icon: Minus, label: 'Wall' },
  { tool: 'arcWall', icon: Spline, label: 'Arc Wall' },
  { tool: 'door', icon: DoorOpen, label: 'Door' },
  { tool: 'window', icon: AppWindow, label: 'Window' },
  { tool: 'fixture', icon: LayoutGrid, label: 'Fixture' },
  { tool: 'label', icon: Type, label: 'Label' },
  { tool: 'dimension', icon: Ruler, label: 'Measure' },
  { tool: 'lasso', icon: Lasso, label: 'Lasso' },
  { tool: 'erase', icon: Eraser, label: 'Erase' },
  { tool: 'pan', icon: Move, label: 'Pan' },
];

export default function Toolbar({
  editorState,
  canUndo,
  canRedo,
  onToolChange,
  onUndo,
  onRedo,
  onZoomIn,
  onZoomOut,
  onToggleGrid,
  onToggleLayers,
}: ToolbarProps) {
  return (
    <div className="flex flex-col gap-1 p-1.5 bg-[#1a1a2e]/95 backdrop-blur border border-[#2a2a4a] rounded-xl shadow-2xl">
      {/* Drawing tools */}
      {TOOLS.map(({ tool, icon: Icon, label }) => (
        <button
          key={tool}
          onClick={() => onToolChange(tool)}
          title={label}
          className={`w-9 h-9 flex items-center justify-center rounded-lg transition-colors ${
            editorState.activeTool === tool
              ? 'bg-blue-900/40 text-blue-400'
              : 'text-neutral-400 hover:bg-[#2a2a4a] hover:text-neutral-200'
          }`}
        >
          <Icon size={16} />
        </button>
      ))}

      {/* Divider */}
      <div className="mx-2 my-1 h-px bg-[#2a2a4a]" />

      {/* Undo/Redo */}
      <button
        onClick={onUndo}
        disabled={!canUndo}
        title="Undo (Ctrl+Z)"
        className="w-9 h-9 flex items-center justify-center rounded-lg text-neutral-400 hover:bg-[#2a2a4a] hover:text-neutral-200 disabled:opacity-30 disabled:cursor-not-allowed"
      >
        <Undo2 size={16} />
      </button>
      <button
        onClick={onRedo}
        disabled={!canRedo}
        title="Redo (Ctrl+Y)"
        className="w-9 h-9 flex items-center justify-center rounded-lg text-neutral-400 hover:bg-[#2a2a4a] hover:text-neutral-200 disabled:opacity-30 disabled:cursor-not-allowed"
      >
        <Redo2 size={16} />
      </button>

      {/* Divider */}
      <div className="mx-2 my-1 h-px bg-[#2a2a4a]" />

      {/* Zoom */}
      <button
        onClick={onZoomIn}
        title="Zoom In"
        className="w-9 h-9 flex items-center justify-center rounded-lg text-neutral-400 hover:bg-[#2a2a4a] hover:text-neutral-200"
      >
        <ZoomIn size={16} />
      </button>
      <button
        onClick={onZoomOut}
        title="Zoom Out"
        className="w-9 h-9 flex items-center justify-center rounded-lg text-neutral-400 hover:bg-[#2a2a4a] hover:text-neutral-200"
      >
        <ZoomOut size={16} />
      </button>

      {/* Divider */}
      <div className="mx-2 my-1 h-px bg-[#2a2a4a]" />

      {/* Grid toggle */}
      <button
        onClick={onToggleGrid}
        title="Toggle Grid"
        className={`w-9 h-9 flex items-center justify-center rounded-lg transition-colors ${
          editorState.showGrid
            ? 'bg-blue-900/40 text-blue-400'
            : 'text-neutral-400 hover:bg-[#2a2a4a] hover:text-neutral-200'
        }`}
      >
        <Grid3x3 size={16} />
      </button>

      {/* Layer panel toggle */}
      <button
        onClick={onToggleLayers}
        title="Layers"
        className="w-9 h-9 flex items-center justify-center rounded-lg text-neutral-400 hover:bg-[#2a2a4a] hover:text-neutral-200"
      >
        <Layers size={16} />
      </button>

      {/* Zoom level display */}
      <div className="text-center text-[10px] text-neutral-500 font-medium mt-1">
        {Math.round(editorState.zoom * 100)}%
      </div>
    </div>
  );
}
