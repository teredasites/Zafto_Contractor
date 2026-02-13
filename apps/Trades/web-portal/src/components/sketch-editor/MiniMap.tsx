'use client';

// ZAFTO MiniMap — Corner navigation for large floor plans (SK6)
// Shows a miniature view of the entire canvas with viewport indicator.

import React, { useMemo } from 'react';
import type { FloorPlanData, Point } from '@/lib/sketch-engine/types';

interface MiniMapProps {
  planData: FloorPlanData;
  viewportOffset: Point;
  viewportSize: { width: number; height: number };
  zoom: number;
  canvasSize: number;
  onNavigate: (point: Point) => void;
}

const MINIMAP_SIZE = 120;

export default function MiniMap({
  planData,
  viewportOffset,
  viewportSize,
  zoom,
  canvasSize,
  onNavigate,
}: MiniMapProps) {
  const scale = MINIMAP_SIZE / canvasSize;

  // Compute bounding box of all elements for context
  const bounds = useMemo(() => {
    let minX = canvasSize;
    let minY = canvasSize;
    let maxX = 0;
    let maxY = 0;

    for (const wall of planData.walls) {
      minX = Math.min(minX, wall.start.x, wall.end.x);
      minY = Math.min(minY, wall.start.y, wall.end.y);
      maxX = Math.max(maxX, wall.start.x, wall.end.x);
      maxY = Math.max(maxY, wall.start.y, wall.end.y);
    }

    return { minX, minY, maxX, maxY };
  }, [planData.walls, canvasSize]);

  // Viewport rectangle in minimap coordinates
  const vpX = (-viewportOffset.x / zoom) * scale;
  const vpY = (-viewportOffset.y / zoom) * scale;
  const vpW = (viewportSize.width / zoom) * scale;
  const vpH = (viewportSize.height / zoom) * scale;

  const handleClick = (e: React.MouseEvent<HTMLDivElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const x = (e.clientX - rect.left) / scale;
    const y = (e.clientY - rect.top) / scale;
    onNavigate({ x, y });
  };

  return (
    <div
      className="bg-white/90 backdrop-blur border border-gray-200 rounded-lg shadow-md overflow-hidden cursor-crosshair"
      style={{ width: MINIMAP_SIZE, height: MINIMAP_SIZE }}
      onClick={handleClick}
    >
      <svg
        width={MINIMAP_SIZE}
        height={MINIMAP_SIZE}
        viewBox={`0 0 ${MINIMAP_SIZE} ${MINIMAP_SIZE}`}
      >
        {/* Walls */}
        {planData.walls.map((wall) => (
          <line
            key={wall.id}
            x1={wall.start.x * scale}
            y1={wall.start.y * scale}
            x2={wall.end.x * scale}
            y2={wall.end.y * scale}
            stroke="#475569"
            strokeWidth={1}
          />
        ))}

        {/* Rooms (filled) */}
        {planData.rooms.map((room) => (
          <circle
            key={room.id}
            cx={room.center.x * scale}
            cy={room.center.y * scale}
            r={2}
            fill="#94A3B8"
            opacity={0.5}
          />
        ))}

        {/* Viewport indicator */}
        <rect
          x={vpX}
          y={vpY}
          width={vpW}
          height={vpH}
          fill="none"
          stroke="#3B82F6"
          strokeWidth={1.5}
          rx={1}
        />
      </svg>
    </div>
  );
}
