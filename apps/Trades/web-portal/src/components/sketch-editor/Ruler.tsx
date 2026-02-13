'use client';

// ZAFTO Ruler — Top and left edge rulers for measurement reference (SK6)
// Shows tick marks and labels in current unit system (imperial ft/in or metric m/cm).
// Adapts tick density to zoom level. Syncs with canvas pan offset.

import React, { useMemo } from 'react';
import type { MeasurementUnit } from '@/lib/sketch-engine/types';

const RULER_THICKNESS = 22;
const BG = 'rgba(255, 255, 255, 0.94)';
const TICK_COLOR = '#94A3B8';
const LABEL_COLOR = '#475569';
const FONT = '9px Inter, system-ui, sans-serif';

// ============================================================================
// LABEL FORMATTER
// ============================================================================

function formatRulerLabel(canvasInches: number, units: MeasurementUnit): string {
  if (Math.abs(canvasInches) < 0.01) return '0';

  if (units === 'imperial') {
    const totalInches = Math.round(canvasInches);
    const feet = Math.floor(Math.abs(totalInches) / 12);
    const inches = Math.abs(totalInches) % 12;
    const sign = totalInches < 0 ? '-' : '';
    if (inches === 0) return `${sign}${feet}'`;
    if (feet === 0) return `${sign}${inches}"`;
    return `${sign}${feet}'${inches}"`;
  }

  // Metric: canvas units are inches, convert to cm
  const cm = canvasInches * 2.54;
  if (Math.abs(cm) >= 100) {
    const m = cm / 100;
    return `${Number.isInteger(m) ? m : m.toFixed(1)}m`;
  }
  return `${Math.round(cm)}cm`;
}

// ============================================================================
// TICK INTERVAL CALCULATOR — adaptive to zoom level
// ============================================================================

interface TickMark {
  screenPos: number;
  label: string | null;
  size: 'major' | 'medium' | 'minor';
}

function computeTicks(
  length: number,
  zoom: number,
  panOffset: number,
  units: MeasurementUnit,
): TickMark[] {
  // Minimum pixels between labeled (major) ticks
  const minLabelSpacing = 60;

  // Nice intervals in canvas inches
  const intervals =
    units === 'imperial'
      ? [1, 3, 6, 12, 24, 60, 120, 240, 600, 1200]
      : [
          2.54,     // 1cm
          5.08,     // 2cm
          12.7,     // 5cm
          25.4,     // 10cm
          50.8,     // 20cm
          127,      // 50cm
          254,      // 1m
          508,      // 2m
          1270,     // 5m
          2540,     // 10m
        ];

  // Find the smallest interval that gives enough spacing
  let majorInterval = intervals[intervals.length - 1];
  for (const interval of intervals) {
    if (interval * zoom >= minLabelSpacing) {
      majorInterval = interval;
      break;
    }
  }

  // Minor tick subdivisions
  let minorDivisions: number;
  if (units === 'imperial') {
    if (majorInterval >= 60) minorDivisions = 5;      // 5ft → 1ft ticks
    else if (majorInterval >= 12) minorDivisions = 4;  // 1ft → 3in ticks
    else if (majorInterval >= 6) minorDivisions = 3;   // 6in → 2in ticks
    else minorDivisions = majorInterval;               // inch-level
  } else {
    minorDivisions = 5; // metric: always 5 subdivisions
  }

  const minorInterval = majorInterval / minorDivisions;

  // Visible canvas range
  const startCanvas = -panOffset / zoom;
  const endCanvas = (length - panOffset) / zoom;

  // Start from the first major tick before the visible area
  const firstMajor = Math.floor(startCanvas / majorInterval) * majorInterval;

  const ticks: TickMark[] = [];

  for (
    let canvasPos = firstMajor - majorInterval;
    canvasPos <= endCanvas + majorInterval;
    canvasPos += minorInterval
  ) {
    const screenPos = canvasPos * zoom + panOffset;

    // Skip ticks outside the visible ruler
    if (screenPos < -2 || screenPos > length + 2) continue;

    // Determine tick type
    const majorRemainder = Math.abs(canvasPos % majorInterval);
    const isMajor =
      majorRemainder < 0.01 || Math.abs(majorRemainder - majorInterval) < 0.01;

    const halfMajor = majorInterval / 2;
    const halfRemainder = Math.abs(canvasPos % halfMajor);
    const isMedium =
      !isMajor &&
      minorDivisions >= 2 &&
      (halfRemainder < 0.01 || Math.abs(halfRemainder - halfMajor) < 0.01);

    if (isMajor) {
      ticks.push({
        screenPos,
        label: formatRulerLabel(canvasPos, units),
        size: 'major',
      });
    } else if (isMedium) {
      ticks.push({ screenPos, label: null, size: 'medium' });
    } else {
      // Only show minor ticks if there's enough room
      if (minorInterval * zoom >= 6) {
        ticks.push({ screenPos, label: null, size: 'minor' });
      }
    }
  }

  return ticks;
}

// ============================================================================
// TICK HEIGHTS
// ============================================================================

const TICK_HEIGHTS: Record<string, number> = {
  major: RULER_THICKNESS * 0.6,
  medium: RULER_THICKNESS * 0.35,
  minor: RULER_THICKNESS * 0.18,
};

// ============================================================================
// HORIZONTAL RULER (top edge)
// ============================================================================

export function HorizontalRuler({
  width,
  zoom,
  panOffsetX,
  units,
}: {
  width: number;
  zoom: number;
  panOffsetX: number;
  units: MeasurementUnit;
}) {
  const ticks = useMemo(
    () => computeTicks(width, zoom, panOffsetX, units),
    [width, zoom, panOffsetX, units],
  );

  return (
    <svg
      width={width}
      height={RULER_THICKNESS}
      className="select-none pointer-events-none"
      style={{ display: 'block' }}
    >
      {/* Background */}
      <rect width={width} height={RULER_THICKNESS} fill={BG} />

      {/* Bottom border */}
      <line
        x1={0}
        y1={RULER_THICKNESS - 0.5}
        x2={width}
        y2={RULER_THICKNESS - 0.5}
        stroke="#CBD5E1"
        strokeWidth={0.5}
      />

      {/* Ticks */}
      {ticks.map((tick, i) => {
        const h = TICK_HEIGHTS[tick.size];
        return (
          <g key={i}>
            <line
              x1={tick.screenPos}
              y1={RULER_THICKNESS - h}
              x2={tick.screenPos}
              y2={RULER_THICKNESS}
              stroke={TICK_COLOR}
              strokeWidth={tick.size === 'major' ? 1 : 0.5}
            />
            {tick.label && (
              <text
                x={tick.screenPos + 3}
                y={RULER_THICKNESS - h - 2}
                fill={LABEL_COLOR}
                style={{ font: FONT }}
              >
                {tick.label}
              </text>
            )}
          </g>
        );
      })}
    </svg>
  );
}

// ============================================================================
// VERTICAL RULER (left edge)
// ============================================================================

export function VerticalRuler({
  height,
  zoom,
  panOffsetY,
  units,
}: {
  height: number;
  zoom: number;
  panOffsetY: number;
  units: MeasurementUnit;
}) {
  const ticks = useMemo(
    () => computeTicks(height, zoom, panOffsetY, units),
    [height, zoom, panOffsetY, units],
  );

  return (
    <svg
      width={RULER_THICKNESS}
      height={height}
      className="select-none pointer-events-none"
      style={{ display: 'block' }}
    >
      {/* Background */}
      <rect width={RULER_THICKNESS} height={height} fill={BG} />

      {/* Right border */}
      <line
        x1={RULER_THICKNESS - 0.5}
        y1={0}
        x2={RULER_THICKNESS - 0.5}
        y2={height}
        stroke="#CBD5E1"
        strokeWidth={0.5}
      />

      {/* Ticks */}
      {ticks.map((tick, i) => {
        const h = TICK_HEIGHTS[tick.size];
        return (
          <g key={i}>
            <line
              x1={RULER_THICKNESS - h}
              y1={tick.screenPos}
              x2={RULER_THICKNESS}
              y2={tick.screenPos}
              stroke={TICK_COLOR}
              strokeWidth={tick.size === 'major' ? 1 : 0.5}
            />
            {tick.label && (
              <text
                x={2}
                y={tick.screenPos - 3}
                fill={LABEL_COLOR}
                style={{ font: FONT }}
              >
                {tick.label}
              </text>
            )}
          </g>
        );
      })}
    </svg>
  );
}

// ============================================================================
// CORNER PIECE — fills the gap where rulers meet
// ============================================================================

export function RulerCorner() {
  return (
    <div
      style={{
        width: RULER_THICKNESS,
        height: RULER_THICKNESS,
        background: BG,
        borderRight: '0.5px solid #CBD5E1',
        borderBottom: '0.5px solid #CBD5E1',
      }}
    />
  );
}

export { RULER_THICKNESS };
