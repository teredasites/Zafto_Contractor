'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ── Types ──────────────────────────────────────────────────────────
export interface ImportBatch {
  id: string;
  importType: string;
  fileName: string;
  fileFormat: string;
  columnMapping: Record<string, string>;
  totalRows: number;
  successCount: number;
  errorCount: number;
  status: 'pending' | 'processing' | 'completed' | 'failed' | 'undone';
  startedAt: string | null;
  completedAt: string | null;
  undoneAt: string | null;
  createdAt: string;
}

export interface ImportError {
  id: string;
  rowNumber: number;
  rowData: Record<string, unknown>;
  errorMessage: string;
  fieldName: string | null;
}

export interface ColumnMapping {
  sourceColumn: string;
  targetField: string;
}

// ── Target field definitions per entity ────────────────────────────
export const TARGET_FIELDS: Record<string, { key: string; label: string; required?: boolean }[]> = {
  customers: [
    { key: 'name', label: 'Name', required: true },
    { key: 'email', label: 'Email' },
    { key: 'phone', label: 'Phone' },
    { key: 'address', label: 'Address' },
    { key: 'city', label: 'City' },
    { key: 'state', label: 'State' },
    { key: 'zip', label: 'Zip Code' },
    { key: 'company_name', label: 'Company Name' },
    { key: 'notes', label: 'Notes' },
    { key: 'tags', label: 'Tags' },
  ],
  jobs: [
    { key: 'title', label: 'Title', required: true },
    { key: 'description', label: 'Description' },
    { key: 'customer_name', label: 'Customer Name/Email' },
    { key: 'status', label: 'Status' },
    { key: 'scheduled_start', label: 'Start Date' },
    { key: 'scheduled_end', label: 'End Date' },
    { key: 'estimated_value', label: 'Estimated Amount' },
    { key: 'actual_cost', label: 'Actual Amount' },
    { key: 'address', label: 'Address' },
  ],
  invoices: [
    { key: 'customer_name', label: 'Customer Name/Email' },
    { key: 'total', label: 'Amount', required: true },
    { key: 'status', label: 'Status' },
    { key: 'created_at', label: 'Invoice Date' },
    { key: 'due_date', label: 'Due Date' },
    { key: 'amount_paid', label: 'Paid Amount' },
  ],
  contacts: [
    { key: 'name', label: 'Name', required: true },
    { key: 'email', label: 'Email' },
    { key: 'phone', label: 'Phone' },
    { key: 'role', label: 'Role' },
    { key: 'company', label: 'Company' },
    { key: 'notes', label: 'Notes' },
  ],
  estimates: [
    { key: 'title', label: 'Title', required: true },
    { key: 'customer_name', label: 'Customer Name/Email' },
    { key: 'total', label: 'Total Amount' },
    { key: 'status', label: 'Status' },
    { key: 'notes', label: 'Notes' },
  ],
};

// ── Status mapping from competitor systems ─────────────────────────
const STATUS_MAP: Record<string, string> = {
  // Jobber
  'requires invoicing': 'completed',
  'late': 'overdue',
  'action required': 'in_progress',
  'awaiting payment': 'invoiced',
  // HousecallPro
  'unscheduled': 'pending',
  'scheduled': 'scheduled',
  'dispatched': 'in_progress',
  'in progress': 'in_progress',
  'on my way': 'in_progress',
  'completed': 'completed',
  'canceled': 'cancelled',
  'cancelled': 'cancelled',
  // ServiceTitan
  'hold': 'on_hold',
  'open': 'pending',
  'done': 'completed',
  // Generic
  'active': 'in_progress',
  'closed': 'completed',
  'paid': 'paid',
  'unpaid': 'sent',
  'overdue': 'overdue',
  'draft': 'draft',
  'sent': 'sent',
  'pending': 'pending',
  'new': 'new',
  'won': 'won',
  'lost': 'lost',
};

function mapStatus(raw: string): string {
  const lower = (raw || '').toLowerCase().trim();
  return STATUS_MAP[lower] || lower || 'pending';
}

// ── CSV Parser ─────────────────────────────────────────────────────
export function parseCSV(text: string): { headers: string[]; rows: Record<string, string>[] } {
  const lines = text.split(/\r?\n/).filter((l) => l.trim());
  if (lines.length === 0) return { headers: [], rows: [] };

  // Handle quoted fields properly
  const parseLine = (line: string): string[] => {
    const result: string[] = [];
    let current = '';
    let inQuotes = false;
    for (let i = 0; i < line.length; i++) {
      const ch = line[i];
      if (ch === '"') {
        if (inQuotes && line[i + 1] === '"') {
          current += '"';
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch === ',' && !inQuotes) {
        result.push(current.trim());
        current = '';
      } else {
        current += ch;
      }
    }
    result.push(current.trim());
    return result;
  };

  const headers = parseLine(lines[0]);
  const rows = lines.slice(1).map((line) => {
    const values = parseLine(line);
    const row: Record<string, string> = {};
    headers.forEach((h, i) => {
      row[h] = values[i] || '';
    });
    return row;
  });

  return { headers, rows };
}

// ── QBO/IIF Parser (simplified) ────────────────────────────────────
export function parseIIF(text: string): { headers: string[]; rows: Record<string, string>[] } {
  const lines = text.split(/\r?\n/).filter((l) => l.trim());
  // IIF files are tab-delimited, first row starting with ! defines headers
  const headerLine = lines.find((l) => l.startsWith('!'));
  if (!headerLine) return parseCSV(text); // fallback to CSV

  const headers = headerLine.replace(/^!/, '').split('\t').map((h) => h.trim());
  const dataLines = lines.filter((l) => !l.startsWith('!') && !l.startsWith('TRNS') && l.trim());

  const rows = dataLines.map((line) => {
    const values = line.split('\t');
    const row: Record<string, string> = {};
    headers.forEach((h, i) => {
      row[h] = (values[i] || '').trim();
    });
    return row;
  });

  return { headers, rows };
}

// ── Main Hook ──────────────────────────────────────────────────────
export function useDataImport() {
  const [batches, setBatches] = useState<ImportBatch[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [importProgress, setImportProgress] = useState<{
    current: number;
    total: number;
    successCount: number;
    errorCount: number;
  } | null>(null);

  const fetchBatches = useCallback(async () => {
    try {
      setLoading(true);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('import_batches')
        .select('*')
        .neq('status', 'undone')
        .order('created_at', { ascending: false });

      if (err) throw err;
      setBatches(
        (data || []).map((b: Record<string, unknown>) => ({
          id: b.id,
          importType: b.import_type,
          fileName: b.file_name,
          fileFormat: b.file_format,
          columnMapping: b.column_mapping || {},
          totalRows: b.total_rows,
          successCount: b.success_count,
          errorCount: b.error_count,
          status: b.status,
          startedAt: b.started_at,
          completedAt: b.completed_at,
          undoneAt: b.undone_at,
          createdAt: b.created_at,
        }))
      );
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load import history');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchBatches();
  }, [fetchBatches]);

  // ── Run Import ─────────────────────────────────────────────────
  const runImport = async (
    importType: string,
    fileName: string,
    fileFormat: string,
    rows: Record<string, string>[],
    mapping: Record<string, string>
  ): Promise<{ batchId: string; successCount: number; errorCount: number }> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    // Create batch record
    const { data: batch, error: batchErr } = await supabase
      .from('import_batches')
      .insert({
        company_id: companyId,
        user_id: user.id,
        import_type: importType,
        file_name: fileName,
        file_format: fileFormat,
        column_mapping: mapping,
        total_rows: rows.length,
        status: 'processing',
        started_at: new Date().toISOString(),
      })
      .select('id')
      .single();

    if (batchErr) throw batchErr;
    const batchId = batch.id;

    let successCount = 0;
    let errorCount = 0;
    const errors: { row_number: number; row_data: Record<string, unknown>; error_message: string; field_name: string | null }[] = [];

    setImportProgress({ current: 0, total: rows.length, successCount: 0, errorCount: 0 });

    // Process rows in batches of 25
    const CHUNK = 25;
    for (let i = 0; i < rows.length; i += CHUNK) {
      const chunk = rows.slice(i, i + CHUNK);
      const insertRows: Record<string, unknown>[] = [];

      for (let j = 0; j < chunk.length; j++) {
        const row = chunk[j];
        const rowNum = i + j + 1;
        try {
          const mapped = applyMapping(row, mapping, importType);
          insertRows.push({ ...mapped, company_id: companyId, import_batch_id: batchId });
        } catch (e: unknown) {
          errorCount++;
          errors.push({
            row_number: rowNum,
            row_data: row,
            error_message: e instanceof Error ? e.message : 'Mapping error',
            field_name: null,
          });
        }
      }

      if (insertRows.length > 0) {
        // Handle duplicate detection for customers
        if (importType === 'customers') {
          for (const record of insertRows) {
            const rowNum = i + insertRows.indexOf(record) + 1;
            try {
              const dupResult = await checkCustomerDuplicate(supabase, companyId, record.email, record.phone);
              if (dupResult) {
                // Skip duplicates — count as error with info message
                errorCount++;
                errors.push({
                  row_number: rowNum,
                  row_data: record,
                  error_message: `Duplicate: matches existing customer (${dupResult})`,
                  field_name: 'email/phone',
                });
                continue;
              }
              const { error: insErr } = await supabase.from(importType).insert(record);
              if (insErr) throw insErr;
              successCount++;
            } catch (e: unknown) {
              errorCount++;
              errors.push({
                row_number: rowNum,
                row_data: record,
                error_message: e instanceof Error ? e.message : 'Insert error',
                field_name: null,
              });
            }
          }
        } else {
          const { error: insErr } = await supabase.from(importType).insert(insertRows);
          if (insErr) {
            // Fallback: insert one by one to find the bad row
            for (let k = 0; k < insertRows.length; k++) {
              const { error: singleErr } = await supabase.from(importType).insert(insertRows[k]);
              if (singleErr) {
                errorCount++;
                errors.push({
                  row_number: i + k + 1,
                  row_data: chunk[k],
                  error_message: singleErr.message,
                  field_name: null,
                });
              } else {
                successCount++;
              }
            }
          } else {
            successCount += insertRows.length;
          }
        }
      }

      setImportProgress({ current: Math.min(i + CHUNK, rows.length), total: rows.length, successCount, errorCount });
    }

    // Log errors
    if (errors.length > 0) {
      const errorChunks = [];
      for (let i = 0; i < errors.length; i += 50) {
        errorChunks.push(errors.slice(i, i + 50));
      }
      for (const chunk of errorChunks) {
        await supabase.from('import_errors').insert(
          chunk.map((e) => ({ batch_id: batchId, ...e }))
        );
      }
    }

    // Finalize batch
    await supabase.from('import_batches').update({
      status: errorCount === rows.length ? 'failed' : 'completed',
      success_count: successCount,
      error_count: errorCount,
      completed_at: new Date().toISOString(),
    }).eq('id', batchId);

    setImportProgress(null);
    fetchBatches();
    return { batchId, successCount, errorCount };
  };

  // ── Undo Import ────────────────────────────────────────────────
  const undoImport = async (batchId: string) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const batch = batches.find((b) => b.id === batchId);
    if (!batch) throw new Error('Batch not found');

    // Soft-delete all records from this batch
    const table = batch.importType;
    const { error: delErr } = await supabase
      .from(table)
      .update({ deleted_at: new Date().toISOString() })
      .eq('import_batch_id', batchId);

    if (delErr) throw delErr;

    await supabase.from('import_batches').update({
      status: 'undone',
      undone_at: new Date().toISOString(),
      undone_by: user.id,
    }).eq('id', batchId);

    fetchBatches();
  };

  // ── Get Errors for a Batch ─────────────────────────────────────
  const getImportErrors = async (batchId: string): Promise<ImportError[]> => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase
      .from('import_errors')
      .select('*')
      .eq('batch_id', batchId)
      .order('row_number', { ascending: true });

    if (err) throw err;
    return (data || []).map((e: Record<string, unknown>) => ({
      id: e.id as string,
      rowNumber: e.row_number as number,
      rowData: (e.row_data || {}) as Record<string, unknown>,
      errorMessage: e.error_message as string,
      fieldName: e.field_name as string | null,
    }));
  };

  // ── Export errors as CSV ───────────────────────────────────────
  const exportErrorsCSV = async (batchId: string): Promise<string> => {
    const errors = await getImportErrors(batchId);
    const lines = ['Row,Field,Error'];
    for (const e of errors) {
      lines.push(`${e.rowNumber},"${e.fieldName || ''}","${e.errorMessage.replace(/"/g, '""')}"`);
    }
    return lines.join('\n');
  };

  return {
    batches,
    loading,
    error,
    importProgress,
    runImport,
    undoImport,
    getImportErrors,
    exportErrorsCSV,
    refetch: fetchBatches,
  };
}

// ── Helpers ────────────────────────────────────────────────────────

function applyMapping(
  row: Record<string, string>,
  mapping: Record<string, string>,
  importType: string
): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  const reverseMap: Record<string, string> = {};

  // mapping is sourceColumn -> targetField
  for (const [source, target] of Object.entries(mapping)) {
    if (target) reverseMap[target] = row[source] || '';
  }

  const fields = TARGET_FIELDS[importType] || [];
  const required = fields.filter((f) => f.required);
  for (const f of required) {
    if (!reverseMap[f.key]?.trim()) {
      throw new Error(`Required field "${f.label}" is empty`);
    }
  }

  for (const [target, value] of Object.entries(reverseMap)) {
    if (!value.trim()) continue;

    // Type coercion for specific fields
    if (['total', 'amount_paid', 'estimated_value', 'actual_cost', 'subtotal'].includes(target)) {
      result[target] = parseFloat(value.replace(/[$,]/g, '')) || 0;
    } else if (['scheduled_start', 'scheduled_end', 'due_date', 'created_at'].includes(target)) {
      const d = new Date(value);
      result[target] = isNaN(d.getTime()) ? null : d.toISOString();
    } else if (target === 'status') {
      result[target] = mapStatus(value);
    } else if (target === 'tags') {
      result[target] = value.split(/[,;]/).map((t) => t.trim()).filter(Boolean);
    } else {
      result[target] = value;
    }
  }

  // Set defaults
  if (importType === 'invoices' && !result.status) result.status = 'draft';
  if (importType === 'invoices' && !result.invoice_number) {
    result.invoice_number = `IMP-${Date.now().toString(36).toUpperCase()}`;
  }
  if (importType === 'invoices') {
    result.subtotal = result.total || 0;
    result.amount_due = (result.total as number || 0) - (result.amount_paid as number || 0);
    result.tax_rate = 0;
    result.tax_amount = 0;
  }
  if (importType === 'jobs' && !result.status) result.status = 'pending';
  if (importType === 'jobs') result.job_type = 'project';
  if (importType === 'estimates' && !result.status) result.status = 'draft';

  return result;
}

async function checkCustomerDuplicate(
  supabase: ReturnType<typeof getSupabase>,
  companyId: string,
  email: unknown,
  phone: unknown
): Promise<string | null> {
  if (email && typeof email === 'string' && email.trim()) {
    const { data } = await supabase
      .from('customers')
      .select('id')
      .eq('company_id', companyId)
      .eq('email', email.trim())
      .is('deleted_at', null)
      .limit(1)
      .single();
    if (data) return `email: ${email}`;
  }
  if (phone && typeof phone === 'string' && phone.trim()) {
    const { data } = await supabase
      .from('customers')
      .select('id')
      .eq('company_id', companyId)
      .eq('phone', phone.trim())
      .is('deleted_at', null)
      .limit(1)
      .single();
    if (data) return `phone: ${phone}`;
  }
  return null;
}
