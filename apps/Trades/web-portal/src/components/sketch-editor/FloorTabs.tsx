'use client';

// ZAFTO Floor Tabs — SK7
// Floor switcher above canvas. Each floor is a separate property_floor_plans row
// linked by property_id. Shows floor labels with add/remove controls.

import { useState, useCallback } from 'react';
import { Plus, X, Layers } from 'lucide-react';

export interface FloorTab {
  id: string;
  name: string;
  floorNumber: number;
}

interface FloorTabsProps {
  floors: FloorTab[];
  activeFloorId: string;
  onSelectFloor: (floorId: string) => void;
  onAddFloor: () => void;
  onRemoveFloor: (floorId: string) => void;
  onRenameFloor: (floorId: string, name: string) => void;
}

export default function FloorTabs({
  floors,
  activeFloorId,
  onSelectFloor,
  onAddFloor,
  onRemoveFloor,
  onRenameFloor,
}: FloorTabsProps) {
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editValue, setEditValue] = useState('');

  const startEditing = useCallback((floor: FloorTab) => {
    setEditingId(floor.id);
    setEditValue(floor.name);
  }, []);

  const finishEditing = useCallback(() => {
    if (editingId && editValue.trim()) {
      onRenameFloor(editingId, editValue.trim());
    }
    setEditingId(null);
    setEditValue('');
  }, [editingId, editValue, onRenameFloor]);

  if (floors.length <= 1) {
    // Single floor — no tabs needed, just show label
    return null;
  }

  return (
    <div className="flex items-center gap-0.5 px-2 py-1 bg-gray-50 border-b border-gray-200">
      <Layers className="h-3.5 w-3.5 text-gray-400 mr-1" />

      {floors.map((floor) => {
        const isActive = floor.id === activeFloorId;
        const isEditing = editingId === floor.id;

        return (
          <div
            key={floor.id}
            className={`
              flex items-center gap-1 px-2.5 py-1 rounded text-xs cursor-pointer transition-colors group
              ${isActive
                ? 'bg-white border border-gray-200 text-gray-800 font-medium shadow-sm'
                : 'text-gray-500 hover:bg-gray-100 hover:text-gray-700'
              }
            `}
            onClick={() => !isEditing && onSelectFloor(floor.id)}
            onDoubleClick={() => startEditing(floor)}
          >
            {isEditing ? (
              <input
                type="text"
                value={editValue}
                onChange={(e) => setEditValue(e.target.value)}
                onBlur={finishEditing}
                onKeyDown={(e) => { if (e.key === 'Enter') finishEditing(); if (e.key === 'Escape') setEditingId(null); }}
                className="w-20 px-1 py-0 text-xs bg-transparent border-b border-blue-400 outline-none"
                autoFocus
                onClick={(e) => e.stopPropagation()}
              />
            ) : (
              <span>{floor.name}</span>
            )}

            {/* Remove floor — only show on hover, only if more than 1 floor */}
            {isActive && floors.length > 1 && !isEditing && (
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onRemoveFloor(floor.id);
                }}
                className="opacity-0 group-hover:opacity-100 p-0.5 rounded hover:bg-gray-200 text-gray-400 hover:text-red-500 transition-all"
                title="Remove floor"
              >
                <X size={10} />
              </button>
            )}
          </div>
        );
      })}

      {/* Add floor button */}
      <button
        onClick={onAddFloor}
        className="flex items-center gap-0.5 px-2 py-1 rounded text-xs text-gray-400 hover:bg-gray-100 hover:text-gray-600 transition-colors"
        title="Add floor"
      >
        <Plus size={12} />
      </button>
    </div>
  );
}
