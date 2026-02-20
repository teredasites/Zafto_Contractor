// ZAFTO PDF Export — Floor plan with title block + room schedule
// SK9: Uses Konva stage.toDataURL() for the floor plan image,
// then builds a PDF with jsPDF (already in node_modules via web-portal).
// Landscape letter (11"x8.5") with title block, plan image, room schedule, trade legend.

import type Konva from 'konva';
import type { FloorPlanData, TradeLayer } from '../types';

export interface PdfExportOptions {
  companyName?: string;
  projectAddress?: string;
  projectTitle?: string;
  floorNumber?: number;
  pixelRatio?: number;
}

/**
 * Export floor plan to PDF with title block and room schedule.
 * Uses dynamic import of jsPDF to keep bundle size down.
 */
export async function exportPdf(
  stage: Konva.Stage,
  plan: FloorPlanData,
  options?: PdfExportOptions,
): Promise<void> {
  const { jsPDF } = await import('jspdf');

  const floorNumber = options?.floorNumber ?? 1;
  const pixelRatio = options?.pixelRatio ?? 2;

  // Landscape letter: 11" x 8.5" (279.4mm x 215.9mm)
  const doc = new jsPDF({ orientation: 'landscape', unit: 'mm', format: 'letter' });
  const pageW = 279.4;
  const pageH = 215.9;
  const margin = 10;
  const contentW = pageW - margin * 2;

  // Accessibility: set document properties for screen readers and PDF viewers
  doc.setProperties({
    title: options?.projectTitle
      ? `Floor Plan — ${options.projectTitle}`
      : 'Floor Plan',
    subject: options?.projectAddress
      ? `Floor plan for ${options.projectAddress}`
      : 'Floor plan export',
    author: options?.companyName || 'Zafto',
    creator: 'Zafto Floor Plan Export',
    keywords: 'floor plan, sketch, construction',
  });
  doc.setLanguage('en-US');

  // --- Title Block (top) ---
  const titleBlockH = 18;
  doc.setDrawColor(100);
  doc.setLineWidth(0.3);
  doc.rect(margin, margin, contentW, titleBlockH);

  doc.setFontSize(12);
  doc.setFont('helvetica', 'bold');
  if (options?.companyName) {
    doc.text(options.companyName, margin + 3, margin + 6);
  }
  doc.setFontSize(8);
  doc.setFont('helvetica', 'normal');
  if (options?.projectAddress) {
    doc.text(options.projectAddress, margin + 3, margin + 11);
  }
  if (options?.projectTitle) {
    doc.text(options.projectTitle, margin + 3, margin + 15);
  }

  // Right side of title block
  doc.setFontSize(10);
  doc.setFont('helvetica', 'bold');
  doc.text(`Floor ${floorNumber}`, pageW - margin - 3, margin + 6, { align: 'right' });
  doc.setFontSize(7);
  doc.setFont('helvetica', 'normal');
  doc.text(
    `Scale: 1" = ${(1 / plan.scale * 12).toFixed(0)}'`,
    pageW - margin - 3, margin + 11,
    { align: 'right' },
  );
  doc.text(
    `Date: ${new Date().toISOString().substring(0, 10)}`,
    pageW - margin - 3, margin + 15,
    { align: 'right' },
  );

  // --- Floor Plan Image ---
  const imageTop = margin + titleBlockH + 4;
  const scheduleH = Math.max(plan.rooms.length * 5 + 12, 20);
  const legendH = plan.tradeLayers.some((tl) => tl.visible) ? 10 : 0;
  const imageH = pageH - imageTop - margin - scheduleH - legendH - 4;

  try {
    const dataUrl = stage.toDataURL({ pixelRatio, mimeType: 'image/png' });
    const imgW = stage.width();
    const imgH = stage.height();
    const aspect = imgW / imgH;

    let drawW = contentW;
    let drawH = drawW / aspect;
    if (drawH > imageH) {
      drawH = imageH;
      drawW = drawH * aspect;
    }
    const drawX = margin + (contentW - drawW) / 2;

    doc.addImage(dataUrl, 'PNG', drawX, imageTop, drawW, drawH);
  } catch {
    doc.setFontSize(10);
    doc.text('Floor plan image could not be rendered.', margin + 3, imageTop + 10);
  }

  // --- Room Schedule Table ---
  const tableTop = pageH - margin - scheduleH - legendH;
  doc.setFontSize(8);
  doc.setFont('helvetica', 'bold');
  doc.text('Room Schedule', margin, tableTop - 2);

  const colWidths = [60, 30, 30];
  const headers = ['Room', 'Area (SF)', 'Walls'];
  let y = tableTop;

  // Header row
  doc.setFillColor(235, 235, 235);
  doc.rect(margin, y, contentW, 5, 'F');
  doc.setDrawColor(180);
  doc.rect(margin, y, contentW, 5);
  let x = margin + 2;
  for (let i = 0; i < headers.length; i++) {
    doc.text(headers[i], x, y + 3.5);
    x += colWidths[i];
  }
  y += 5;

  // Data rows
  doc.setFont('helvetica', 'normal');
  for (const room of plan.rooms) {
    doc.rect(margin, y, contentW, 5);
    x = margin + 2;
    doc.text(room.name, x, y + 3.5);
    x += colWidths[0];
    doc.text(room.area.toFixed(1), x, y + 3.5);
    x += colWidths[1];
    doc.text(`${room.wallIds.length}`, x, y + 3.5);
    y += 5;
  }

  // --- Trade Legend ---
  if (legendH > 0) {
    const legendTop = pageH - margin - legendH;
    doc.setFontSize(7);
    doc.setFont('helvetica', 'bold');
    doc.text('Trade Layers:', margin, legendTop + 5);

    const tradeColors: Record<string, [number, number, number]> = {
      electrical: [0, 0, 255],
      plumbing: [255, 0, 0],
      hvac: [0, 170, 0],
      damage: [255, 136, 0],
    };

    let lx = margin + 25;
    doc.setFont('helvetica', 'normal');
    for (const tl of plan.tradeLayers) {
      if (!tl.visible) continue;
      const color = tradeColors[tl.type] ?? [100, 100, 100];
      doc.setFillColor(color[0], color[1], color[2]);
      doc.rect(lx, legendTop + 2, 3, 3, 'F');
      doc.text(tl.name, lx + 5, legendTop + 5);
      lx += 30;
    }
  }

  // Trigger download
  const filename = options?.projectTitle
    ? `${options.projectTitle.replace(/[^a-zA-Z0-9]/g, '_')}_f${floorNumber}.pdf`
    : `floor_plan_f${floorNumber}.pdf`;
  doc.save(filename);
}
