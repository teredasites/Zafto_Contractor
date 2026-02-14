'use client';

// ZAFTO Export Modal — Floor plan export format selection (SK9)
// PDF, PNG (1x/2x/4x), DXF (AutoCAD), FML (open format), SVG

import React, { useState, useCallback } from 'react';
import {
  X,
  FileText,
  Image,
  Code,
  FileCode,
  Pen,
  Download,
  Loader2,
  type LucideIcon,
} from 'lucide-react';
import type Konva from 'konva';
import type { FloorPlanData } from '@/lib/sketch-engine/types';
import { exportPdf } from '@/lib/sketch-engine/export/pdf-export';
import { exportPng } from '@/lib/sketch-engine/export/png-export';
import { generateDxf } from '@/lib/sketch-engine/export/dxf-export';
import { generateFml } from '@/lib/sketch-engine/export/fml-export';
import { generateSvg } from '@/lib/sketch-engine/export/svg-export';

type ExportFormat = 'pdf' | 'png' | 'dxf' | 'fml' | 'svg';

interface ExportModalProps {
  planData: FloorPlanData;
  stageRef: React.RefObject<Konva.Stage | null>;
  companyName?: string;
  projectAddress?: string;
  projectTitle?: string;
  floorNumber?: number;
  onClose: () => void;
}

const FORMAT_OPTIONS: {
  format: ExportFormat;
  icon: LucideIcon;
  label: string;
  description: string;
}[] = [
  {
    format: 'pdf',
    icon: FileText,
    label: 'PDF',
    description: 'Print-ready with title block & room schedule',
  },
  {
    format: 'png',
    icon: Image,
    label: 'PNG Image',
    description: 'High-resolution raster image',
  },
  {
    format: 'dxf',
    icon: Code,
    label: 'DXF (AutoCAD)',
    description: 'Opens in AutoCAD, LibreCAD, DraftSight',
  },
  {
    format: 'fml',
    icon: FileCode,
    label: 'FML (Open Format)',
    description: 'Symbility/Cotality compatible XML',
  },
  {
    format: 'svg',
    icon: Pen,
    label: 'SVG',
    description: 'Scalable vector — Inkscape, browsers',
  },
];

const PNG_SCALES = [
  { ratio: 1, label: '1x Standard' },
  { ratio: 2, label: '2x High Resolution' },
  { ratio: 4, label: '4x Ultra-High Resolution' },
];

export default function ExportModal({
  planData,
  stageRef,
  companyName,
  projectAddress,
  projectTitle,
  floorNumber = 1,
  onClose,
}: ExportModalProps) {
  const [exporting, setExporting] = useState(false);
  const [showPngScale, setShowPngScale] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleExport = useCallback(
    async (format: ExportFormat, pngPixelRatio?: number) => {
      setError(null);
      setExporting(true);
      try {
        switch (format) {
          case 'pdf': {
            const stage = stageRef.current;
            if (!stage) throw new Error('Canvas not ready');
            await exportPdf(stage, planData, {
              companyName,
              projectAddress,
              projectTitle,
              floorNumber,
            });
            break;
          }
          case 'png': {
            const stage = stageRef.current;
            if (!stage) throw new Error('Canvas not ready');
            exportPng(stage, {
              pixelRatio: pngPixelRatio ?? 2,
              filename: `floor_plan_f${floorNumber}.png`,
            });
            break;
          }
          case 'dxf': {
            const content = generateDxf(planData, {
              projectTitle,
              companyName,
            });
            downloadText(content, `floor_plan_f${floorNumber}.dxf`, 'application/dxf');
            break;
          }
          case 'fml': {
            const content = generateFml(planData, {
              projectTitle,
              companyName,
              address: projectAddress,
              floorNumber,
            });
            downloadText(content, `floor_plan_f${floorNumber}.fml`, 'application/xml');
            break;
          }
          case 'svg': {
            const content = generateSvg(planData);
            downloadText(content, `floor_plan_f${floorNumber}.svg`, 'image/svg+xml');
            break;
          }
        }
        onClose();
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Export failed');
      } finally {
        setExporting(false);
      }
    },
    [planData, stageRef, companyName, projectAddress, projectTitle, floorNumber, onClose],
  );

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md mx-4 overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100">
          <h2 className="text-lg font-semibold text-gray-900">Export Floor Plan</h2>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg hover:bg-gray-100 text-gray-400 transition-colors"
          >
            <X size={18} />
          </button>
        </div>

        {/* Content */}
        <div className="p-3">
          {error && (
            <div className="mx-2 mb-3 px-3 py-2 bg-red-50 border border-red-200 rounded-lg text-sm text-red-600">
              {error}
            </div>
          )}

          {showPngScale ? (
            <>
              <button
                onClick={() => setShowPngScale(false)}
                className="ml-2 mb-2 text-sm text-blue-600 hover:text-blue-800"
              >
                &larr; Back to formats
              </button>
              <p className="ml-2 mb-3 text-sm text-gray-500">Choose PNG resolution:</p>
              {PNG_SCALES.map(({ ratio, label }) => (
                <button
                  key={ratio}
                  onClick={() => handleExport('png', ratio)}
                  disabled={exporting}
                  className="w-full flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-gray-50 transition-colors text-left disabled:opacity-50"
                >
                  <div className="w-9 h-9 flex items-center justify-center rounded-lg bg-emerald-50">
                    <Image size={18} className="text-emerald-600" />
                  </div>
                  <div className="flex-1">
                    <div className="font-medium text-gray-900">{label}</div>
                    <div className="text-xs text-gray-400">
                      {ratio === 2 ? 'Recommended' : ratio === 4 ? 'Large file size' : 'Smallest file'}
                    </div>
                  </div>
                  {exporting ? (
                    <Loader2 size={16} className="animate-spin text-gray-400" />
                  ) : (
                    <Download size={16} className="text-gray-300" />
                  )}
                </button>
              ))}
            </>
          ) : (
            FORMAT_OPTIONS.map(({ format, icon: Icon, label, description }) => (
              <button
                key={format}
                onClick={() => {
                  if (format === 'png') {
                    setShowPngScale(true);
                  } else {
                    handleExport(format);
                  }
                }}
                disabled={exporting}
                className="w-full flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-gray-50 transition-colors text-left disabled:opacity-50"
              >
                <div className="w-9 h-9 flex items-center justify-center rounded-lg bg-orange-50">
                  <Icon size={18} className="text-orange-500" />
                </div>
                <div className="flex-1">
                  <div className="font-medium text-gray-900">{label}</div>
                  <div className="text-xs text-gray-400">{description}</div>
                </div>
                {exporting ? (
                  <Loader2 size={16} className="animate-spin text-gray-400" />
                ) : (
                  <Download size={16} className="text-gray-300" />
                )}
              </button>
            ))
          )}
        </div>

        {/* Footer */}
        <div className="px-5 py-3 border-t border-gray-100 bg-gray-50">
          <p className="text-xs text-gray-400 text-center">
            {planData.walls.length} walls &middot; {planData.rooms.length} rooms &middot;{' '}
            {planData.doors.length} doors &middot; {planData.windows.length} windows
          </p>
        </div>
      </div>
    </div>
  );
}

function downloadText(content: string, filename: string, mimeType: string): void {
  const blob = new Blob([content], { type: mimeType });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.download = filename;
  link.href = url;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}
