'use client';

import { useState } from 'react';
import { getSupabase } from '@/lib/supabase';

type ImportFormat = 'xer' | 'msp_xml' | 'csv';
type ExportFormat = 'xer' | 'msp_xml' | 'csv' | 'pdf';

interface ImportResult {
  tasks_imported: number;
  dependencies_imported: number;
  resources_imported: number;
  assignments_imported: number;
  warnings: string[];
}

interface ExportResult {
  download_url: string;
  filename: string;
  format: string;
  tasks_exported: number;
}

interface CSVMapping {
  name: string;
  start?: string;
  finish?: string;
  duration?: string;
  predecessors?: string;
  resources?: string;
  wbs?: string;
  percent_complete?: string;
  cost?: string;
}

export function useScheduleImportExport(projectId: string | undefined) {
  const [importing, setImporting] = useState(false);
  const [exporting, setExporting] = useState(false);
  const [importResult, setImportResult] = useState<ImportResult | null>(null);
  const [exportResult, setExportResult] = useState<ExportResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  const importSchedule = async (
    file: File,
    format: ImportFormat,
    csvMapping?: CSVMapping,
  ): Promise<ImportResult | null> => {
    if (!projectId) return null;
    setImporting(true);
    setError(null);
    setImportResult(null);

    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      // Upload file to storage
      const storagePath = `imports/${projectId}/${Date.now()}_${file.name}`;
      const { error: uploadErr } = await supabase.storage
        .from('documents')
        .upload(storagePath, file, { upsert: true });

      if (uploadErr) throw new Error(`Upload failed: ${uploadErr.message}`);

      // Call import Edge Function
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/schedule-import`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({
            project_id: projectId,
            format,
            file_path: storagePath,
            csv_mapping: csvMapping,
          }),
        },
      );

      if (!response.ok) {
        const err = await response.json();
        throw new Error(err.error || 'Import failed');
      }

      const result = await response.json();
      const importData: ImportResult = {
        tasks_imported: result.tasks_imported,
        dependencies_imported: result.dependencies_imported,
        resources_imported: result.resources_imported,
        assignments_imported: result.assignments_imported,
        warnings: result.warnings || [],
      };
      setImportResult(importData);
      return importData;
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Import failed';
      setError(msg);
      return null;
    } finally {
      setImporting(false);
    }
  };

  const exportSchedule = async (
    format: ExportFormat,
    options?: Record<string, unknown>,
  ): Promise<ExportResult | null> => {
    if (!projectId) return null;
    setExporting(true);
    setError(null);
    setExportResult(null);

    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/schedule-export`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({
            project_id: projectId,
            format,
            options: options || {},
          }),
        },
      );

      if (!response.ok) {
        const err = await response.json();
        throw new Error(err.error || 'Export failed');
      }

      const result = await response.json();
      const exportData: ExportResult = {
        download_url: result.download_url,
        filename: result.filename,
        format: result.format,
        tasks_exported: result.tasks_exported,
      };
      setExportResult(exportData);
      return exportData;
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Export failed';
      setError(msg);
      return null;
    } finally {
      setExporting(false);
    }
  };

  const detectFormat = (filename: string): ImportFormat | null => {
    const ext = filename.toLowerCase().split('.').pop();
    switch (ext) {
      case 'xer': return 'xer';
      case 'xml': return 'msp_xml';
      case 'csv': return 'csv';
      default: return null;
    }
  };

  return {
    importing,
    exporting,
    importResult,
    exportResult,
    error,
    importSchedule,
    exportSchedule,
    detectFormat,
    clearResults: () => { setImportResult(null); setExportResult(null); setError(null); },
  };
}
