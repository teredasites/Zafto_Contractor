'use client';

import { useRef, useEffect, useMemo } from 'react';

// ══════════════════════════════════════════════════════════════
// TYPES
// ══════════════════════════════════════════════════════════════

export interface MiniGanttTask {
  id: string;
  name: string;
  start: string | null;
  finish: string | null;
  percent_complete: number;
  is_critical: boolean;
  is_milestone: boolean;
}

interface MiniGanttProps {
  tasks: MiniGanttTask[];
  height?: number;
  onClick?: () => void;
  className?: string;
}

// ══════════════════════════════════════════════════════════════
// COMPONENT
// ══════════════════════════════════════════════════════════════

export function MiniGantt({ tasks, height = 120, onClick, className = '' }: MiniGanttProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  const visibleTasks = useMemo(
    () => tasks.filter((t) => t.start && t.finish),
    [tasks]
  );

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const dpr = window.devicePixelRatio || 1;
    const rect = canvas.getBoundingClientRect();
    canvas.width = rect.width * dpr;
    canvas.height = rect.height * dpr;
    ctx.scale(dpr, dpr);
    ctx.clearRect(0, 0, rect.width, rect.height);

    if (visibleTasks.length === 0) {
      ctx.fillStyle = 'var(--color-text-quaternary, #666)';
      ctx.font = '11px Inter, sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText('No scheduled tasks', rect.width / 2, rect.height / 2);
      return;
    }

    // Compute date range
    let earliest = Infinity;
    let latest = -Infinity;
    for (const t of visibleTasks) {
      const s = new Date(t.start!).getTime();
      const f = new Date(t.finish!).getTime();
      if (s < earliest) earliest = s;
      if (f > latest) latest = f;
    }

    const DAY = 86400000;
    const rangeStart = earliest - DAY;
    const rangeEnd = latest + DAY;
    const totalDays = (rangeEnd - rangeStart) / DAY;
    if (totalDays <= 0) return;

    const dayWidth = rect.width / totalDays;
    const maxRows = Math.min(visibleTasks.length, Math.max(1, Math.floor(rect.height / 18)));
    const displayTasks = visibleTasks.slice(0, maxRows);
    const barHeight = Math.min(14, rect.height / maxRows - 4);
    const rowHeight = barHeight + 4;

    // CSS variable colors (fallback to reasonable defaults)
    const style = getComputedStyle(canvas);
    const accentColor = style.getPropertyValue('--color-accent').trim() || '#3b82f6';
    const errorColor = style.getPropertyValue('--color-error').trim() || '#ef4444';

    // Today line
    const todayMs = Date.now();
    if (todayMs > rangeStart && todayMs < rangeEnd) {
      const todayX = ((todayMs - rangeStart) / DAY) * dayWidth;
      ctx.strokeStyle = errorColor + '80';
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(todayX, 0);
      ctx.lineTo(todayX, rect.height);
      ctx.stroke();
    }

    // Draw task bars
    for (let i = 0; i < displayTasks.length; i++) {
      const task = displayTasks[i];
      const startMs = new Date(task.start!).getTime();
      const finishMs = new Date(task.finish!).getTime();
      const startX = ((startMs - rangeStart) / DAY) * dayWidth;
      const endX = ((finishMs - rangeStart) / DAY) * dayWidth;
      const y = i * rowHeight + 2;
      const taskWidth = Math.max(endX - startX, 4);

      const baseColor = task.is_critical ? errorColor : accentColor;

      if (task.is_milestone) {
        // Diamond
        const cx = startX;
        const cy = y + barHeight / 2;
        const r = barHeight / 2 - 1;
        ctx.fillStyle = baseColor;
        ctx.beginPath();
        ctx.moveTo(cx, cy - r);
        ctx.lineTo(cx + r, cy);
        ctx.lineTo(cx, cy + r);
        ctx.lineTo(cx - r, cy);
        ctx.closePath();
        ctx.fill();
      } else {
        // Background bar
        ctx.fillStyle = baseColor + (task.is_critical ? '33' : '26');
        roundRect(ctx, startX, y, taskWidth, barHeight, 2);
        ctx.fill();

        // Progress fill
        if (task.percent_complete > 0) {
          const pw = taskWidth * Math.min(task.percent_complete / 100, 1);
          ctx.fillStyle = baseColor + 'B3';
          roundRect(ctx, startX, y, pw, barHeight, 2);
          ctx.fill();
        }

        // Border
        ctx.strokeStyle = baseColor + (task.is_critical ? '80' : '4D');
        ctx.lineWidth = 0.5;
        roundRect(ctx, startX, y, taskWidth, barHeight, 2);
        ctx.stroke();
      }
    }

    // Truncation indicator
    if (visibleTasks.length > maxRows) {
      const remaining = visibleTasks.length - maxRows;
      ctx.fillStyle = style.getPropertyValue('--color-text-quaternary').trim() || '#888';
      ctx.font = '9px Inter, sans-serif';
      ctx.textAlign = 'right';
      ctx.fillText(`+${remaining} more`, rect.width - 4, rect.height - 3);
    }
  }, [visibleTasks]);

  if (tasks.length === 0) {
    return (
      <div
        className={`flex items-center justify-center bg-base border border-main rounded-lg ${className}`}
        style={{ height }}
      >
        <span className="text-xs text-quaternary">No scheduled tasks</span>
      </div>
    );
  }

  return (
    <canvas
      ref={canvasRef}
      onClick={onClick}
      className={`w-full bg-base border border-main rounded-lg ${onClick ? 'cursor-pointer hover:border-accent/30' : ''} ${className}`}
      style={{ height }}
    />
  );
}

function roundRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.quadraticCurveTo(x + w, y, x + w, y + r);
  ctx.lineTo(x + w, y + h - r);
  ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  ctx.lineTo(x + r, y + h);
  ctx.quadraticCurveTo(x, y + h, x, y + h - r);
  ctx.lineTo(x, y + r);
  ctx.quadraticCurveTo(x, y, x + r, y);
  ctx.closePath();
}
