'use client';

// ZAFTO Generate Estimate Modal — SK8
// Select rooms, select trade, preview measurements, generate estimate.
// Creates estimate with pre-filled areas and suggested line items.

import { useState, useMemo, useCallback } from 'react';
import {
  X,
  Calculator,
  Check,
  Loader2,
  ChevronRight,
  Square,
  CheckSquare,
} from 'lucide-react';
import type { FloorPlanData } from '@/lib/sketch-engine/types';
import {
  calculateAllRooms,
  formatSf,
  formatLf,
  type RoomMeasurements,
} from '@/lib/sketch-engine/measurement-calculator';
import { generateEstimate } from '@/lib/sketch-engine/estimate-generator';

interface GenerateEstimateModalProps {
  planData: FloorPlanData;
  floorPlanId: string;
  onClose: () => void;
  onGenerated: (estimateId: string) => void;
}

const TRADE_OPTIONS = [
  { value: '', label: 'All Trades' },
  { value: 'electrical', label: 'Electrical' },
  { value: 'plumbing', label: 'Plumbing' },
  { value: 'hvac', label: 'HVAC' },
  { value: 'painting', label: 'Painting' },
  { value: 'flooring', label: 'Flooring' },
  { value: 'roofing', label: 'Roofing' },
  { value: 'restoration', label: 'Restoration' },
  { value: 'carpentry', label: 'Carpentry' },
  { value: 'general', label: 'General' },
];

export default function GenerateEstimateModal({
  planData,
  floorPlanId,
  onClose,
  onGenerated,
}: GenerateEstimateModalProps) {
  const [selectedRoomIds, setSelectedRoomIds] = useState<Set<string>>(
    new Set(planData.rooms.map((r) => r.id)),
  );
  const [selectedTrade, setSelectedTrade] = useState('');
  const [title, setTitle] = useState('Floor Plan Estimate');
  const [generating, setGenerating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Calculate measurements for all rooms
  const allMeasurements = useMemo(
    () => calculateAllRooms(planData),
    [planData],
  );

  // Filter to selected rooms
  const selectedMeasurements = useMemo(
    () => allMeasurements.filter((m) => selectedRoomIds.has(m.roomId)),
    [allMeasurements, selectedRoomIds],
  );

  // Totals
  const totals = useMemo(() => {
    return selectedMeasurements.reduce(
      (acc, m) => ({
        floorSf: acc.floorSf + m.floorSf,
        wallSf: acc.wallSf + m.wallSf,
        ceilingSf: acc.ceilingSf + m.ceilingSf,
        baseboardLf: acc.baseboardLf + m.baseboardLf,
        doors: acc.doors + m.doorCount,
        windows: acc.windows + m.windowCount,
      }),
      { floorSf: 0, wallSf: 0, ceilingSf: 0, baseboardLf: 0, doors: 0, windows: 0 },
    );
  }, [selectedMeasurements]);

  const toggleRoom = useCallback((roomId: string) => {
    setSelectedRoomIds((prev) => {
      const next = new Set(prev);
      if (next.has(roomId)) {
        next.delete(roomId);
      } else {
        next.add(roomId);
      }
      return next;
    });
  }, []);

  const toggleAll = useCallback(() => {
    if (selectedRoomIds.size === allMeasurements.length) {
      setSelectedRoomIds(new Set());
    } else {
      setSelectedRoomIds(new Set(allMeasurements.map((m) => m.roomId)));
    }
  }, [selectedRoomIds.size, allMeasurements]);

  const handleGenerate = useCallback(async () => {
    if (selectedMeasurements.length === 0) return;

    setGenerating(true);
    setError(null);

    try {
      const result = await generateEstimate({
        floorPlanId,
        measurements: selectedMeasurements,
        planData,
        selectedTrade: selectedTrade || undefined,
        title,
      });

      if (result) {
        onGenerated(result.estimateId);
      } else {
        setError('Failed to generate estimate. Please try again.');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Generation failed');
    } finally {
      setGenerating(false);
    }
  }, [selectedMeasurements, floorPlanId, planData, selectedTrade, title, onGenerated]);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
      <div className="w-full max-w-2xl bg-white rounded-xl shadow-2xl border border-gray-200 max-h-[85vh] flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100">
          <div className="flex items-center gap-2.5">
            <Calculator className="h-5 w-5 text-emerald-500" />
            <h2 className="text-base font-semibold text-gray-800">
              Generate Estimate
            </h2>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg hover:bg-gray-100 text-gray-400"
          >
            <X size={16} />
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto px-5 py-4 space-y-5">
          {/* Title input */}
          <div>
            <label className="block text-xs font-medium text-gray-500 mb-1.5">
              Estimate Title
            </label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-400"
            />
          </div>

          {/* Trade filter */}
          <div>
            <label className="block text-xs font-medium text-gray-500 mb-1.5">
              Trade Filter
            </label>
            <select
              value={selectedTrade}
              onChange={(e) => setSelectedTrade(e.target.value)}
              className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-400"
            >
              {TRADE_OPTIONS.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
          </div>

          {/* Room selection */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <label className="text-xs font-medium text-gray-500">
                Rooms ({selectedRoomIds.size}/{allMeasurements.length})
              </label>
              <button
                onClick={toggleAll}
                className="text-xs text-emerald-600 hover:text-emerald-700 font-medium"
              >
                {selectedRoomIds.size === allMeasurements.length
                  ? 'Deselect All'
                  : 'Select All'}
              </button>
            </div>

            {allMeasurements.length === 0 && (
              <div className="text-sm text-gray-400 py-4 text-center">
                No rooms detected. Draw enclosed rooms on the floor plan first.
              </div>
            )}

            <div className="space-y-1">
              {allMeasurements.map((m) => (
                <RoomRow
                  key={m.roomId}
                  measurement={m}
                  selected={selectedRoomIds.has(m.roomId)}
                  onToggle={() => toggleRoom(m.roomId)}
                />
              ))}
            </div>
          </div>

          {/* Measurement totals */}
          {selectedMeasurements.length > 0 && (
            <div className="bg-gray-50 rounded-lg p-4">
              <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3">
                Total Measurements
              </h3>
              <div className="grid grid-cols-3 gap-3">
                <MeasurementStat label="Floor" value={formatSf(totals.floorSf)} />
                <MeasurementStat label="Walls" value={formatSf(totals.wallSf)} />
                <MeasurementStat label="Ceiling" value={formatSf(totals.ceilingSf)} />
                <MeasurementStat label="Baseboard" value={formatLf(totals.baseboardLf)} />
                <MeasurementStat label="Doors" value={`${totals.doors}`} />
                <MeasurementStat label="Windows" value={`${totals.windows}`} />
              </div>
            </div>
          )}

          {/* Error */}
          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg px-4 py-3 text-sm text-red-600">
              {error}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-end gap-3 px-5 py-4 border-t border-gray-100">
          <button
            onClick={onClose}
            className="px-4 py-2 text-sm text-gray-500 hover:text-gray-700 rounded-lg hover:bg-gray-50"
          >
            Cancel
          </button>
          <button
            onClick={handleGenerate}
            disabled={generating || selectedMeasurements.length === 0}
            className="flex items-center gap-2 px-5 py-2 text-sm font-medium text-white bg-emerald-600 hover:bg-emerald-500 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {generating ? (
              <>
                <Loader2 className="h-4 w-4 animate-spin" />
                Generating...
              </>
            ) : (
              <>
                <Calculator className="h-4 w-4" />
                Generate Estimate
                <ChevronRight className="h-4 w-4" />
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
}

// =============================================================================
// SUB-COMPONENTS
// =============================================================================

function RoomRow({
  measurement,
  selected,
  onToggle,
}: {
  measurement: RoomMeasurements;
  selected: boolean;
  onToggle: () => void;
}) {
  return (
    <button
      onClick={onToggle}
      className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-left transition-colors ${
        selected
          ? 'bg-emerald-50 border border-emerald-200'
          : 'bg-white border border-gray-100 hover:bg-gray-50'
      }`}
    >
      {selected ? (
        <CheckSquare className="h-4 w-4 text-emerald-500 flex-shrink-0" />
      ) : (
        <Square className="h-4 w-4 text-gray-300 flex-shrink-0" />
      )}

      <div className="flex-1 min-w-0">
        <div className="text-sm font-medium text-gray-700 truncate">
          {measurement.roomName}
        </div>
        <div className="flex items-center gap-3 text-xs text-gray-400 mt-0.5">
          <span>{formatSf(measurement.floorSf)}</span>
          <span>{formatLf(measurement.perimeterLf)} perim</span>
          <span>{measurement.doorCount}D {measurement.windowCount}W</span>
        </div>
      </div>

      {selected && (
        <Check className="h-3.5 w-3.5 text-emerald-500 flex-shrink-0" />
      )}
    </button>
  );
}

function MeasurementStat({
  label,
  value,
}: {
  label: string;
  value: string;
}) {
  return (
    <div>
      <div className="text-xs text-gray-400">{label}</div>
      <div className="text-sm font-semibold text-gray-700">{value}</div>
    </div>
  );
}
