// ZAFTO PNG Export — High-resolution raster export via Konva stage
// SK9: Captures the canvas at configurable pixel ratio (1x, 2x, 4x).

import type Konva from 'konva';

export interface PngExportOptions {
  pixelRatio?: number; // 1 = standard, 2 = high-res, 4 = ultra
  filename?: string;
}

/**
 * Export a Konva Stage to PNG and trigger browser download.
 * Call with a ref to the Konva Stage.
 */
export function exportPng(
  stage: Konva.Stage,
  options?: PngExportOptions,
): void {
  const pixelRatio = options?.pixelRatio ?? 2;
  const filename = options?.filename ?? 'floor_plan.png';

  const dataUrl = stage.toDataURL({ pixelRatio, mimeType: 'image/png' });
  triggerDownload(dataUrl, filename);
}

/**
 * Get PNG as Blob (for upload or further processing).
 */
export async function exportPngBlob(
  stage: Konva.Stage,
  pixelRatio = 2,
): Promise<Blob> {
  return new Promise((resolve, reject) => {
    try {
      stage.toBlob({
        pixelRatio,
        mimeType: 'image/png',
        callback: (blob) => {
          if (blob) resolve(blob);
          else reject(new Error('Failed to generate PNG blob'));
        },
      });
    } catch (err) {
      reject(err);
    }
  });
}

function triggerDownload(dataUrl: string, filename: string): void {
  const link = document.createElement('a');
  link.download = filename;
  link.href = dataUrl;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}
