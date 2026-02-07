'use client';

import { cn, formatCurrency } from '@/lib/utils';

// Utility: Generate smooth cubic bezier path from points
function smoothPath(points: [number, number][]): string {
  if (points.length < 2) return '';
  if (points.length === 2) {
    return `M${points[0][0]},${points[0][1]} L${points[1][0]},${points[1][1]}`;
  }

  let d = `M${points[0][0]},${points[0][1]}`;

  for (let i = 0; i < points.length - 1; i++) {
    const p0 = points[Math.max(i - 1, 0)];
    const p1 = points[i];
    const p2 = points[i + 1];
    const p3 = points[Math.min(i + 2, points.length - 1)];

    const tension = 0.3;
    const cp1x = p1[0] + (p2[0] - p0[0]) * tension;
    const cp1y = p1[1] + (p2[1] - p0[1]) * tension;
    const cp2x = p2[0] - (p3[0] - p1[0]) * tension;
    const cp2y = p2[1] - (p3[1] - p1[1]) * tension;

    d += ` C${cp1x},${cp1y} ${cp2x},${cp2y} ${p2[0]},${p2[1]}`;
  }

  return d;
}

interface AreaChartProps {
  data: { date: string; value: number }[];
  height?: number;
  color?: string;
  showGrid?: boolean;
  className?: string;
}

export function SimpleAreaChart({ data, height = 200, color = '#3b82f6', showGrid = true, className }: AreaChartProps) {
  if (data.length === 0) return null;

  const maxValue = Math.max(...data.map(d => d.value));
  const minValue = Math.min(...data.map(d => d.value));
  const range = maxValue - minValue || 1;

  const points: [number, number][] = data.map((d, i) => {
    const x = (i / (data.length - 1)) * 100;
    const y = 100 - ((d.value - minValue) / range) * 80 - 10;
    return [x, y];
  });

  const linePath = smoothPath(points);
  const areaPath = `${linePath} L${points[points.length - 1][0]},100 L${points[0][0]},100 Z`;

  const gradientId = `area-gradient-${color.replace('#', '')}`;

  return (
    <div className={cn('relative', className)} style={{ height }}>
      <svg viewBox="0 0 100 100" preserveAspectRatio="none" className="w-full h-full">
        <defs>
          <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={color} stopOpacity="0.15" />
            <stop offset="100%" stopColor={color} stopOpacity="0" />
          </linearGradient>
        </defs>
        {showGrid && (
          <>
            <line x1="0" y1="25" x2="100" y2="25" stroke="currentColor" strokeOpacity="0.06" strokeWidth="0.3" />
            <line x1="0" y1="50" x2="100" y2="50" stroke="currentColor" strokeOpacity="0.06" strokeWidth="0.3" />
            <line x1="0" y1="75" x2="100" y2="75" stroke="currentColor" strokeOpacity="0.06" strokeWidth="0.3" />
          </>
        )}
        <path
          d={areaPath}
          fill={`url(#${gradientId})`}
        />
        <path
          d={linePath}
          fill="none"
          stroke={color}
          strokeWidth="1.5"
          strokeLinecap="round"
          strokeLinejoin="round"
          vectorEffect="non-scaling-stroke"
          className="animate-draw-line"
        />
      </svg>
    </div>
  );
}

interface BarChartData {
  label: string;
  value: number;
  color?: string;
}

interface BarChartProps {
  data: BarChartData[];
  height?: number;
  className?: string;
  showLabels?: boolean;
  formatValue?: (value: number) => string;
}

export function SimpleBarChart({
  data,
  height = 200,
  className,
  showLabels = true,
  formatValue = (v) => formatCurrency(v)
}: BarChartProps) {
  if (data.length === 0) return null;

  const maxValue = Math.max(...data.map(d => d.value));

  return (
    <div className={cn('flex items-end gap-1.5', className)} style={{ height }}>
      {data.map((item, index) => {
        const barHeight = maxValue > 0 ? (item.value / maxValue) * 100 : 0;
        return (
          <div key={index} className="flex-1 flex flex-col items-center gap-1.5">
            <div className="relative w-full flex-1 flex items-end">
              <div
                className="w-full rounded-t transition-all duration-300 hover:opacity-80"
                style={{
                  height: `${barHeight}%`,
                  backgroundColor: item.color || '#3b82f6',
                  minHeight: item.value > 0 ? '2px' : '0px',
                }}
              />
            </div>
            {showLabels && (
              <span className="text-[11px] text-muted truncate max-w-full">{item.label}</span>
            )}
          </div>
        );
      })}
    </div>
  );
}

interface DonutChartData {
  name: string;
  value: number;
  color: string;
}

interface DonutChartProps {
  data: DonutChartData[];
  size?: number;
  thickness?: number;
  className?: string;
  centerLabel?: string;
  centerValue?: string;
}

export function DonutChart({
  data,
  size = 200,
  thickness = 30,
  className,
  centerLabel,
  centerValue
}: DonutChartProps) {
  const total = data.reduce((sum, item) => sum + item.value, 0);
  if (total === 0) {
    return (
      <div className={cn('relative inline-flex items-center justify-center', className)}>
        <svg width={size} height={size}>
          <circle
            cx={size / 2}
            cy={size / 2}
            r={(size - thickness) / 2}
            fill="none"
            stroke="currentColor"
            strokeOpacity="0.08"
            strokeWidth={thickness}
          />
        </svg>
        {(centerLabel || centerValue) && (
          <div className="absolute inset-0 flex flex-col items-center justify-center">
            {centerValue && <span className="text-xl font-semibold text-muted">{centerValue}</span>}
            {centerLabel && <span className="text-xs text-muted">{centerLabel}</span>}
          </div>
        )}
      </div>
    );
  }

  const radius = (size - thickness) / 2;
  const circumference = 2 * Math.PI * radius;
  let currentOffset = 0;

  return (
    <div className={cn('relative inline-flex items-center justify-center', className)}>
      <svg width={size} height={size} className="transform -rotate-90">
        {data.map((item, index) => {
          const percentage = item.value / total;
          const strokeDasharray = `${circumference * percentage - 1} ${circumference}`;
          const strokeDashoffset = -currentOffset;
          currentOffset += circumference * percentage;

          return (
            <circle
              key={index}
              cx={size / 2}
              cy={size / 2}
              r={radius}
              fill="none"
              stroke={item.color}
              strokeWidth={thickness}
              strokeDasharray={strokeDasharray}
              strokeDashoffset={strokeDashoffset}
              strokeLinecap="round"
              className="transition-all duration-500"
            />
          );
        })}
      </svg>
      {(centerLabel || centerValue) && (
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          {centerValue && <span className="text-2xl font-semibold text-main">{centerValue}</span>}
          {centerLabel && <span className="text-sm text-muted">{centerLabel}</span>}
        </div>
      )}
    </div>
  );
}

interface DonutLegendProps {
  data: DonutChartData[];
  className?: string;
  formatValue?: (value: number) => string;
}

export function DonutLegend({ data, className, formatValue = (v) => v.toString() }: DonutLegendProps) {
  return (
    <div className={cn('space-y-2', className)}>
      {data.map((item, index) => (
        <div key={index} className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <span
              className="w-2.5 h-2.5 rounded-full"
              style={{ backgroundColor: item.color }}
            />
            <span className="text-[13px] text-muted">{item.name}</span>
          </div>
          <span className="text-[13px] font-medium text-main">{formatValue(item.value)}</span>
        </div>
      ))}
    </div>
  );
}

interface SparklineProps {
  data: number[];
  width?: number;
  height?: number;
  color?: string;
  className?: string;
}

export function Sparkline({ data, width = 100, height = 30, color = '#3b82f6', className }: SparklineProps) {
  if (data.length < 2) return null;

  const maxValue = Math.max(...data);
  const minValue = Math.min(...data);
  const range = maxValue - minValue || 1;

  const points: [number, number][] = data.map((value, i) => {
    const x = (i / (data.length - 1)) * width;
    const y = height - ((value - minValue) / range) * (height - 4) - 2;
    return [x, y];
  });

  const path = smoothPath(points);

  return (
    <svg width={width} height={height} className={className}>
      <path
        d={path}
        fill="none"
        stroke={color}
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
