'use client';

// ZAFTO Property Inspector — Right sidebar for selected element properties (SK6)
// Shows properties of selected wall/door/window/fixture/label.
// All edits route through UndoRedoManager for Ctrl+Z support.

import React from 'react';
import { X } from 'lucide-react';
import type {
  FloorPlanData,
  Wall,
  DoorPlacement,
  WindowPlacement,
  FixturePlacement,
  DoorType,
  WindowType,
  SelectionState,
  MeasurementUnit,
} from '@/lib/sketch-engine/types';
import { wallLength, formatLength } from '@/lib/sketch-engine/geometry';
import {
  UndoRedoManager,
  UpdateWallCommand,
  UpdateDoorCommand,
  UpdateWindowCommand,
  UpdateFixtureCommand,
} from '@/lib/sketch-engine/commands';

interface PropertyInspectorProps {
  planData: FloorPlanData;
  selection: SelectionState;
  units: MeasurementUnit;
  undoManager: UndoRedoManager;
  onPlanDataChange: (data: FloorPlanData) => void;
  onClose: () => void;
}

export default function PropertyInspector({
  planData,
  selection,
  units,
  undoManager,
  onPlanDataChange,
  onClose,
}: PropertyInspectorProps) {
  if (!selection.selectedId) return null;

  // Find the selected element
  const wall = planData.walls.find((w) => w.id === selection.selectedId);
  const door = planData.doors.find((d) => d.id === selection.selectedId);
  const win = planData.windows.find((w) => w.id === selection.selectedId);
  const fixture = planData.fixtures.find(
    (f) => f.id === selection.selectedId,
  );

  if (!wall && !door && !win && !fixture) return null;

  // All mutations route through the command system for undo/redo support
  const updateWall = (updates: Partial<Wall>) => {
    if (!wall) return;
    const cmd = new UpdateWallCommand(wall.id, updates);
    onPlanDataChange(undoManager.execute(cmd, planData));
  };

  const updateDoor = (updates: Partial<DoorPlacement>) => {
    if (!door) return;
    const cmd = new UpdateDoorCommand(door.id, updates);
    onPlanDataChange(undoManager.execute(cmd, planData));
  };

  const updateWindow = (updates: Partial<WindowPlacement>) => {
    if (!win) return;
    const cmd = new UpdateWindowCommand(win.id, updates);
    onPlanDataChange(undoManager.execute(cmd, planData));
  };

  const updateFixture = (updates: Partial<FixturePlacement>) => {
    if (!fixture) return;
    const cmd = new UpdateFixtureCommand(fixture.id, updates);
    onPlanDataChange(undoManager.execute(cmd, planData));
  };

  return (
    <div className="w-56 bg-white/95 backdrop-blur border border-gray-200 rounded-xl shadow-lg overflow-hidden">
      {/* Header */}
      <div className="px-3 py-2 border-b border-gray-100 flex items-center justify-between">
        <span className="text-xs font-semibold text-gray-700">
          {wall ? 'Wall' : door ? 'Door' : win ? 'Window' : 'Fixture'}
        </span>
        <button
          onClick={onClose}
          className="text-gray-400 hover:text-gray-600"
        >
          <X size={12} />
        </button>
      </div>

      <div className="p-3 space-y-3">
        {/* Wall properties */}
        {wall && (
          <>
            <PropertyRow label="Length">
              <span className="text-xs text-gray-700 font-medium">
                {formatLength(wallLength(wall), units)}
              </span>
            </PropertyRow>
            <PropertyRow label="Thickness">
              <input
                type="number"
                value={wall.thickness}
                onChange={(e) =>
                  updateWall({ thickness: parseFloat(e.target.value) || 6 })
                }
                className="w-16 text-xs text-right border border-gray-200 rounded px-1.5 py-0.5"
                min={2}
                max={24}
                step={1}
              />
              <span className="text-[10px] text-gray-400 ml-1">in</span>
            </PropertyRow>
            <PropertyRow label="Height">
              <input
                type="number"
                value={wall.height}
                onChange={(e) =>
                  updateWall({ height: parseFloat(e.target.value) || 96 })
                }
                className="w-16 text-xs text-right border border-gray-200 rounded px-1.5 py-0.5"
                min={24}
                max={240}
                step={1}
              />
              <span className="text-[10px] text-gray-400 ml-1">in</span>
            </PropertyRow>
          </>
        )}

        {/* Door properties */}
        {door && (
          <>
            <PropertyRow label="Type">
              <select
                value={door.type}
                onChange={(e) =>
                  updateDoor({ type: e.target.value as DoorType })
                }
                className="text-xs border border-gray-200 rounded px-1.5 py-0.5"
              >
                {(
                  [
                    'single',
                    'double',
                    'sliding',
                    'pocket',
                    'bifold',
                    'barn',
                    'french',
                  ] as DoorType[]
                ).map((t) => (
                  <option key={t} value={t}>
                    {t.charAt(0).toUpperCase() + t.slice(1)}
                  </option>
                ))}
              </select>
            </PropertyRow>
            <PropertyRow label="Width">
              <input
                type="number"
                value={door.width}
                onChange={(e) =>
                  updateDoor({
                    width: parseFloat(e.target.value) || 36,
                  })
                }
                className="w-16 text-xs text-right border border-gray-200 rounded px-1.5 py-0.5"
                min={18}
                max={96}
                step={1}
              />
              <span className="text-[10px] text-gray-400 ml-1">in</span>
            </PropertyRow>
          </>
        )}

        {/* Window properties */}
        {win && (
          <>
            <PropertyRow label="Type">
              <select
                value={win.type}
                onChange={(e) =>
                  updateWindow({ type: e.target.value as WindowType })
                }
                className="text-xs border border-gray-200 rounded px-1.5 py-0.5"
              >
                {(['standard', 'bay', 'skylight'] as WindowType[]).map(
                  (t) => (
                    <option key={t} value={t}>
                      {t.charAt(0).toUpperCase() + t.slice(1)}
                    </option>
                  ),
                )}
              </select>
            </PropertyRow>
            <PropertyRow label="Width">
              <input
                type="number"
                value={win.width}
                onChange={(e) =>
                  updateWindow({
                    width: parseFloat(e.target.value) || 36,
                  })
                }
                className="w-16 text-xs text-right border border-gray-200 rounded px-1.5 py-0.5"
                min={12}
                max={120}
                step={1}
              />
              <span className="text-[10px] text-gray-400 ml-1">in</span>
            </PropertyRow>
          </>
        )}

        {/* Fixture properties */}
        {fixture && (
          <>
            <PropertyRow label="Type">
              <span className="text-xs text-gray-700 capitalize">
                {fixture.type.replace(/([A-Z])/g, ' $1').trim()}
              </span>
            </PropertyRow>
            <PropertyRow label="Rotation">
              <input
                type="number"
                value={fixture.rotation}
                onChange={(e) =>
                  updateFixture({
                    rotation: parseFloat(e.target.value) || 0,
                  })
                }
                className="w-16 text-xs text-right border border-gray-200 rounded px-1.5 py-0.5"
                min={0}
                max={360}
                step={15}
              />
              <span className="text-[10px] text-gray-400 ml-1">deg</span>
            </PropertyRow>
            <PropertyRow label="Position">
              <span className="text-[10px] text-gray-500">
                ({Math.round(fixture.position.x)},{' '}
                {Math.round(fixture.position.y)})
              </span>
            </PropertyRow>
          </>
        )}
      </div>
    </div>
  );
}

function PropertyRow({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div className="flex items-center justify-between">
      <span className="text-[10px] text-gray-500 uppercase tracking-wide">
        {label}
      </span>
      <div className="flex items-center">{children}</div>
    </div>
  );
}
