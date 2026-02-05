'use client';

import { cn, formatCurrency } from '@/lib/utils';

// Simple chart components that work without external dependencies
// Can be enhanced with Recharts later

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

  const points = data.map((d, i) => {
    const x = (i / (data.length - 1)) * 100;
    const y = 100 - ((d.value - minValue) / range) * 80 - 10;
    return `${x},${y}`;
  }).join(' ');

  const areaPath = `M0,100 L0,${100 - ((data[0].value - minValue) / range) * 80 - 10} L${points.split(' ').map((p, i) => `${p.split(',')[0]},${p.split(',')[1]}`).join(' L')} L100,100 Z`;

  return (
    <div className={cn('relative', className)} style={{ height }}>
      <svg viewBox="0 0 100 100" preserveAspectRatio="none" className="w-full h-full">
        {showGrid && (
          <>
            <line x1="0" y1="25" x2="100" y2="25" stroke="currentColor" strokeOpacity="0.1" strokeWidth="0.5" />
            <line x1="0" y1="50" x2="100" y2="50" stroke="currentColor" strokeOpacity="0.1" strokeWidth="0.5" />
            <line x1="0" y1="75" x2="100" y2="75" stroke="currentColor" strokeOpacity="0.1" strokeWidth="0.5" />
          </>
        )}
        <path
          d={areaPath}
          fill={color}
          fillOpacity="0.1"
        />
        <polyline
          points={points}
          fill="none"
          stroke={color}
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
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
    <div className={cn('flex items-end gap-2', className)} style={{ height }}>
      {data.map((item, index) => {
        const barHeight = (item.value / maxValue) * 100;
        return (
          <div key={index} className="flex-1 flex flex-col items-center gap-2">
            <div className="relative w-full flex-1 flex items-end">
              <div
                className="w-full rounded-t-md transition-all hover:opacity-80"
                style={{
                  height: `${barHeight}%`,
                  backgroundColor: item.color || '#3b82f6',
                  minHeight: '4px',
                }}
              />
            </div>
            {showLabels && (
              <span className="text-xs text-muted truncate max-w-full">{item.label}</span>
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
  const radius = (size - thickness) / 2;
  const circumference = 2 * Math.PI * radius;

  let currentOffset = 0;

  return (
    <div className={cn('relative inline-flex items-center justify-center', className)}>
      <svg width={size} height={size} className="transform -rotate-90">
        {data.map((item, index) => {
          const percentage = item.value / total;
          const strokeDasharray = `${circumference * percentage} ${circumference}`;
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
              className="transition-all"
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
              className="w-3 h-3 rounded-full"
              style={{ backgroundColor: item.color }}
            />
            <span className="text-sm text-muted">{item.name}</span>
          </div>
          <span className="text-sm font-medium text-main">{formatValue(item.value)}</span>
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

  const points = data.map((value, i) => {
    const x = (i / (data.length - 1)) * width;
    const y = height - ((value - minValue) / range) * (height - 4) - 2;
    return `${x},${y}`;
  }).join(' ');

  return (
    <svg width={width} height={height} className={className}>
      <polyline
        points={points}
        fill="none"
        stroke={color}
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
