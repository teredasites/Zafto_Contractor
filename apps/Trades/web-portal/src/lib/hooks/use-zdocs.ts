'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// ZDocs Hook — Templates, Renders, Sections, Signatures + Real-time
// ============================================================

// ==================== TYPES ====================

export interface TemplateVariable {
  name: string;
  label: string;
  type: string;
  defaultValue: string | null;
}

export interface ZDocsTemplate {
  id: string;
  companyId: string;
  name: string;
  description: string | null;
  templateType: string;
  contentHtml: string | null;
  variables: TemplateVariable[];
  isActive: boolean;
  isSystem: boolean;
  requiresSignature: boolean;
  isShared: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface ZDocsSection {
  id: string;
  templateId: string;
  sectionType: string;
  title: string;
  contentHtml: string | null;
  config: Record<string, unknown> | null;
  sortOrder: number;
  isRequired: boolean;
  isConditional: boolean;
  conditionField: string | null;
  conditionValue: string | null;
  createdAt: string;
}

export interface ZDocsRender {
  id: string;
  companyId: string;
  templateId: string;
  entityType: string | null;
  entityId: string | null;
  title: string;
  renderedHtml: string | null;
  pdfStoragePath: string | null;
  dataSnapshot: Record<string, unknown> | null;
  variablesUsed: Record<string, unknown> | null;
  status: string;
  requiresSignature: boolean;
  signatureStatus: string | null;
  signatureRequestedAt: string | null;
  signedAt: string | null;
  sentToEmail: string | null;
  sentAt: string | null;
  renderedByUserId: string | null;
  createdAt: string;
  // Joined data
  templateName?: string;
  templateType?: string;
}

export interface ZDocsSignatureRequest {
  id: string;
  renderId: string;
  signerName: string;
  signerEmail: string;
  signerRole: string | null;
  status: string;
  sentAt: string | null;
  viewedAt: string | null;
  signedAt: string | null;
  accessToken: string | null;
  expiresAt: string | null;
}

export const ZDOCS_TEMPLATE_TYPES = [
  'contract', 'proposal', 'lien_waiver', 'change_order', 'invoice',
  'warranty', 'scope_of_work', 'safety_plan', 'daily_report',
  'inspection_report', 'completion_cert', 'notice', 'insurance',
  'letter', 'property_preservation', 'permit', 'compliance', 'other',
] as const;

export const ZDOCS_TEMPLATE_TYPE_LABELS: Record<string, string> = {
  contract: 'Contract',
  proposal: 'Proposal',
  lien_waiver: 'Lien Waiver',
  change_order: 'Change Order',
  invoice: 'Invoice',
  warranty: 'Warranty',
  scope_of_work: 'Scope of Work',
  safety_plan: 'Safety Plan',
  daily_report: 'Daily Report',
  inspection_report: 'Inspection Report',
  completion_cert: 'Completion Certificate',
  notice: 'Notice',
  insurance: 'Insurance',
  letter: 'Letter',
  property_preservation: 'Property Preservation',
  permit: 'Permit',
  compliance: 'Compliance',
  other: 'Other',
};

export interface TemplateVersion {
  id: string;
  templateId: string;
  versionNumber: number;
  contentHtml: string | null;
  changeNote: string | null;
  createdBy: string | null;
  createdAt: string;
}

export const ZDOCS_ENTITY_TYPES = [
  'job', 'customer', 'estimate', 'invoice', 'bid', 'property',
] as const;

export const ZDOCS_ENTITY_TYPE_LABELS: Record<string, string> = {
  job: 'Job',
  customer: 'Customer',
  estimate: 'Estimate',
  invoice: 'Invoice',
  bid: 'Bid',
  property: 'Property',
};

export const ZDOCS_RENDER_STATUSES = [
  'draft', 'rendered', 'sent', 'signed',
] as const;

export const ZDOCS_SIGNATURE_STATUSES = [
  'pending', 'sent', 'viewed', 'signed', 'declined', 'expired',
] as const;

// ==================== MAPPERS ====================

function mapTemplate(row: Record<string, unknown>): ZDocsTemplate {
  const rawVars = row.variables;
  let variables: TemplateVariable[] = [];
  if (Array.isArray(rawVars)) {
    variables = rawVars as TemplateVariable[];
  } else if (rawVars && typeof rawVars === 'object') {
    variables = [];
  }

  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    name: (row.name as string) || '',
    description: row.description as string | null,
    templateType: (row.template_type as string) || 'other',
    contentHtml: row.content_html as string | null,
    variables,
    isActive: (row.is_active as boolean) ?? true,
    isSystem: (row.is_system as boolean) ?? false,
    requiresSignature: (row.requires_signature as boolean) ?? false,
    isShared: (row.is_shared as boolean) ?? true,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

function mapRender(row: Record<string, unknown>): ZDocsRender {
  const templateData = row.document_templates as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    templateId: (row.template_id as string) || '',
    entityType: row.entity_type as string | null,
    entityId: row.entity_id as string | null,
    title: (row.title as string) || '',
    renderedHtml: row.rendered_html as string | null,
    pdfStoragePath: row.pdf_storage_path as string | null,
    dataSnapshot: row.data_snapshot as Record<string, unknown> | null,
    variablesUsed: row.variables_used as Record<string, unknown> | null,
    status: (row.status as string) || 'draft',
    requiresSignature: (row.requires_signature as boolean) ?? false,
    signatureStatus: row.signature_status as string | null,
    signatureRequestedAt: row.signature_requested_at as string | null,
    signedAt: row.signed_at as string | null,
    sentToEmail: row.sent_to_email as string | null,
    sentAt: row.sent_at as string | null,
    renderedByUserId: row.rendered_by_user_id as string | null,
    createdAt: row.created_at as string,
    templateName: templateData ? (templateData.name as string) || '' : undefined,
    templateType: templateData ? (templateData.template_type as string) || '' : undefined,
  };
}

function mapSignatureRequest(row: Record<string, unknown>): ZDocsSignatureRequest {
  return {
    id: row.id as string,
    renderId: (row.render_id as string) || '',
    signerName: (row.signer_name as string) || '',
    signerEmail: (row.signer_email as string) || '',
    signerRole: row.signer_role as string | null,
    status: (row.status as string) || 'pending',
    sentAt: row.sent_at as string | null,
    viewedAt: row.viewed_at as string | null,
    signedAt: row.signed_at as string | null,
    accessToken: row.access_token as string | null,
    expiresAt: row.expires_at as string | null,
  };
}

// ==================== PROPERTY TEMPLATE VARIABLES ====================

/**
 * Build template variables from property scan and features data.
 * Use in ZDocs templates with {{property_year_built}}, {{property_sqft}}, etc.
 */
export function buildPropertyTemplateVariables(
  scan: { address: string; city: string | null; state: string | null; zip: string | null; confidenceScore: number; floodZone: string | null; floodRisk: string | null; hazardFlags: Array<{ severity: string; title: string }>; environmentalData: Record<string, unknown>; codeRequirements: Record<string, unknown>; weatherHistory: Record<string, unknown>; computedMeasurements: Record<string, unknown> } | null,
  features: { yearBuilt: number | null; livingSqft: number | null; lotSqft: number | null; stories: number | null; beds: number | null; bathsFull: number | null; bathsHalf: number | null; constructionType: string | null; roofMaterial: string | null; heatingType: string | null; coolingType: string | null; foundationType: string | null; basementType: string | null; exteriorMaterial: string | null; garageSpaces: number; assessedValue: number | null; lastSalePrice: number | null; lastSaleDate: string | null; climateZone: string | null; frostLineDepthIn: number | null; soilType: string | null; radonZone: number | null; wildfireRisk: string | null; termiteZone: string | null; designWindSpeedMph: number | null; snowLoadPsf: number | null; seismicCategory: string | null; lawnAreaSqft: number | null; wallAreaSqft: number | null; boundaryPerimeterFt: number | null } | null,
  roof?: { totalAreaSqft: number; totalAreaSquares: number; pitchPrimary: string | null; facetCount: number; predominantShape: string | null } | null,
): Record<string, string> {
  const vars: Record<string, string> = {};
  if (!scan) return vars;

  // Property address
  vars.property_address = scan.address;
  vars.property_city = scan.city || '';
  vars.property_state = scan.state || '';
  vars.property_zip = scan.zip || '';
  vars.property_full_address = [scan.address, scan.city, scan.state, scan.zip].filter(Boolean).join(', ');

  // Confidence
  vars.property_confidence_score = String(scan.confidenceScore);

  // Flood
  vars.property_flood_zone = scan.floodZone || 'N/A';
  vars.property_flood_risk = scan.floodRisk || 'N/A';

  // Hazards summary
  const hazards = scan.hazardFlags || [];
  vars.property_hazard_count = String(hazards.length);
  vars.property_hazard_red_count = String(hazards.filter(h => h.severity === 'red').length);
  vars.property_hazard_yellow_count = String(hazards.filter(h => h.severity === 'yellow').length);
  vars.property_hazard_list = hazards.map(h => h.title).join(', ') || 'None';

  // Features
  if (features) {
    vars.property_year_built = features.yearBuilt ? String(features.yearBuilt) : '';
    vars.property_sqft = features.livingSqft ? features.livingSqft.toLocaleString() : '';
    vars.property_lot_sqft = features.lotSqft ? features.lotSqft.toLocaleString() : '';
    vars.property_stories = features.stories ? String(features.stories) : '';
    vars.property_beds = features.beds ? String(features.beds) : '';
    vars.property_baths = String((features.bathsFull || 0) + (features.bathsHalf || 0) * 0.5 || '');
    vars.property_construction_type = features.constructionType || '';
    vars.property_roof_material = features.roofMaterial || '';
    vars.property_heating = features.heatingType || '';
    vars.property_cooling = features.coolingType || '';
    vars.property_foundation = features.foundationType || '';
    vars.property_basement = features.basementType || '';
    vars.property_exterior = features.exteriorMaterial || '';
    vars.property_garage_spaces = String(features.garageSpaces);
    vars.property_assessed_value = features.assessedValue ? `$${features.assessedValue.toLocaleString()}` : '';
    vars.property_last_sale_price = features.lastSalePrice ? `$${features.lastSalePrice.toLocaleString()}` : '';
    vars.property_last_sale_date = features.lastSaleDate || '';
    // Environmental
    vars.property_climate_zone = features.climateZone || '';
    vars.property_frost_line = features.frostLineDepthIn ? `${features.frostLineDepthIn}"` : '';
    vars.property_soil_type = features.soilType || '';
    vars.property_radon_zone = features.radonZone ? `Zone ${features.radonZone}` : '';
    vars.property_wildfire_risk = features.wildfireRisk ? features.wildfireRisk.replace(/_/g, ' ') : '';
    vars.property_termite_zone = features.termiteZone ? features.termiteZone.replace(/_/g, ' ') : '';
    vars.property_wind_speed = features.designWindSpeedMph ? `${features.designWindSpeedMph} mph` : '';
    vars.property_snow_load = features.snowLoadPsf ? `${features.snowLoadPsf} PSF` : '';
    vars.property_seismic_category = features.seismicCategory || '';
    // Measurements
    vars.property_lawn_area = features.lawnAreaSqft ? `${features.lawnAreaSqft.toLocaleString()} sqft` : '';
    vars.property_wall_area = features.wallAreaSqft ? `${features.wallAreaSqft.toLocaleString()} sqft` : '';
    vars.property_boundary_perimeter = features.boundaryPerimeterFt ? `${features.boundaryPerimeterFt.toLocaleString()} ft` : '';
  }

  // Roof
  if (roof) {
    vars.property_roof_area_sqft = roof.totalAreaSqft.toLocaleString();
    vars.property_roof_area_squares = roof.totalAreaSquares.toFixed(1);
    vars.property_roof_pitch = roof.pitchPrimary || '';
    vars.property_roof_facets = String(roof.facetCount);
    vars.property_roof_shape = roof.predominantShape || '';
  }

  // Weather
  const w = scan.weatherHistory;
  if (w.freeze_thaw_cycles) vars.property_freeze_thaw = `${w.freeze_thaw_cycles}/yr`;
  if (w.annual_precip_in) vars.property_annual_precip = `${w.annual_precip_in}"`;
  if (w.avg_wind_mph) vars.property_avg_wind = `${w.avg_wind_mph} mph`;

  // Code
  const c = scan.codeRequirements;
  if (c.energy_code) vars.property_energy_code = String(c.energy_code);

  return vars;
}

// ==================== HOOK ====================

export function useZDocs() {
  const [templates, setTemplates] = useState<ZDocsTemplate[]>([]);
  const [renders, setRenders] = useState<ZDocsRender[]>([]);
  const [signatureRequests, setSignatureRequests] = useState<ZDocsSignatureRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTemplates = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('document_templates')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(100);

      if (err) throw err;
      setTemplates((data || []).map((r: Record<string, unknown>) => mapTemplate(r)));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load templates';
      setError(msg);
    }
  }, []);

  const fetchRenders = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('zdocs_renders')
        .select('*, document_templates(name, template_type)')
        .order('created_at', { ascending: false })
        .limit(100);

      if (err) throw err;
      setRenders((data || []).map((r: Record<string, unknown>) => mapRender(r)));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load renders';
      setError(msg);
    }
  }, []);

  const fetchSignatureRequests = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('zdocs_signature_requests')
        .select('*')
        .order('sent_at', { ascending: false });

      if (err) throw err;
      setSignatureRequests((data || []).map((r: Record<string, unknown>) => mapSignatureRequest(r)));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load signature requests';
      setError(msg);
    }
  }, []);

  const fetchAll = useCallback(async () => {
    setLoading(true);
    setError(null);
    await Promise.all([fetchTemplates(), fetchRenders(), fetchSignatureRequests()]);
    setLoading(false);
  }, [fetchTemplates, fetchRenders, fetchSignatureRequests]);

  useEffect(() => {
    fetchAll();

    const supabase = getSupabase();
    const channel = supabase
      .channel('zdocs-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'zdocs_renders' }, () => {
        fetchRenders();
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'zdocs_signature_requests' }, () => {
        fetchSignatureRequests();
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'document_templates' }, () => {
        fetchTemplates();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchAll, fetchTemplates, fetchRenders, fetchSignatureRequests]);

  // ==================== MUTATIONS ====================

  const createTemplate = async (data: {
    name: string;
    description?: string;
    templateType: string;
    contentHtml?: string;
    variables?: TemplateVariable[];
    requiresSignature?: boolean;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('document_templates')
      .insert({
        company_id: companyId,
        name: data.name,
        description: data.description || null,
        template_type: data.templateType,
        content_html: data.contentHtml || null,
        variables: data.variables || [],
        is_active: true,
        is_system: false,
        requires_signature: data.requiresSignature || false,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateTemplate = async (id: string, data: Partial<{
    name: string;
    description: string | null;
    templateType: string;
    contentHtml: string | null;
    variables: TemplateVariable[];
    isActive: boolean;
    requiresSignature: boolean;
    isShared: boolean;
  }>, changeNote?: string) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();

    // If content changed, save version snapshot first
    if (data.contentHtml !== undefined) {
      const existing = templates.find(t => t.id === id);
      if (existing && existing.contentHtml !== data.contentHtml) {
        // Get current version number
        const { data: versions } = await supabase
          .from('document_template_versions')
          .select('version_number')
          .eq('template_id', id)
          .order('version_number', { ascending: false })
          .limit(1);

        const nextVersion = (versions?.[0]?.version_number || 0) + 1;

        // Save the new version
        await supabase.from('document_template_versions').insert({
          template_id: id,
          version_number: nextVersion,
          content_html: data.contentHtml,
          variables: data.variables || existing.variables || [],
          change_note: changeNote || null,
          created_by: user?.id || null,
        });
      }
    }

    const update: Record<string, unknown> = {};
    if (data.name !== undefined) update.name = data.name;
    if (data.description !== undefined) update.description = data.description;
    if (data.templateType !== undefined) update.template_type = data.templateType;
    if (data.contentHtml !== undefined) update.content_html = data.contentHtml;
    if (data.variables !== undefined) update.variables = data.variables;
    if (data.isActive !== undefined) update.is_active = data.isActive;
    if (data.requiresSignature !== undefined) update.requires_signature = data.requiresSignature;
    if (data.isShared !== undefined) update.is_shared = data.isShared;

    const { error: err } = await supabase.from('document_templates').update(update).eq('id', id);
    if (err) throw err;
  };

  const fetchTemplateVersions = async (templateId: string): Promise<TemplateVersion[]> => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase
      .from('document_template_versions')
      .select('*')
      .eq('template_id', templateId)
      .order('version_number', { ascending: false });

    if (err) throw err;
    return (data || []).map((row: Record<string, unknown>) => ({
      id: row.id as string,
      templateId: row.template_id as string,
      versionNumber: row.version_number as number,
      contentHtml: row.content_html as string | null,
      changeNote: row.change_note as string | null,
      createdBy: row.created_by as string | null,
      createdAt: row.created_at as string,
    }));
  };

  const revertToVersion = async (templateId: string, versionId: string) => {
    const supabase = getSupabase();
    const { data: version, error: fetchErr } = await supabase
      .from('document_template_versions')
      .select('content_html, variables')
      .eq('id', versionId)
      .single();

    if (fetchErr || !version) throw fetchErr || new Error('Version not found');

    await updateTemplate(templateId, {
      contentHtml: version.content_html as string | null,
      variables: version.variables as TemplateVariable[],
    }, `Reverted to version`);
  };

  const deleteTemplate = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('document_templates')
      .update({ is_active: false })
      .eq('id', id);
    if (err) throw err;
  };

  const renderDocument = async (data: {
    templateId: string;
    entityType?: string;
    entityId?: string;
    title?: string;
    customVariables?: Record<string, unknown>;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // Fetch the template to get content
    const template = templates.find((t) => t.id === data.templateId);
    const templateName = template?.name || 'Untitled';
    const title = data.title || templateName;

    const { data: result, error: err } = await supabase
      .from('zdocs_renders')
      .insert({
        company_id: companyId,
        template_id: data.templateId,
        entity_type: data.entityType || null,
        entity_id: data.entityId || null,
        title,
        rendered_html: template?.contentHtml || null,
        status: 'rendered',
        requires_signature: template?.requiresSignature || false,
        signature_status: template?.requiresSignature ? 'pending' : null,
        variables_used: data.customVariables || null,
        rendered_by_user_id: user.id,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const sendForSignature = async (renderId: string, signers: {
    name: string;
    email: string;
    role?: string;
  }[]) => {
    const supabase = getSupabase();

    const inserts = signers.map((signer) => ({
      render_id: renderId,
      signer_name: signer.name,
      signer_email: signer.email,
      signer_role: signer.role || null,
      status: 'sent',
      sent_at: new Date().toISOString(),
      expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(), // 30 days
    }));

    const { error: insertErr } = await supabase
      .from('zdocs_signature_requests')
      .insert(inserts);

    if (insertErr) throw insertErr;

    // Update render signature status
    const { error: updateErr } = await supabase
      .from('zdocs_renders')
      .update({
        signature_status: 'sent',
        signature_requested_at: new Date().toISOString(),
      })
      .eq('id', renderId);

    if (updateErr) throw updateErr;
  };

  const duplicateTemplate = async (id: string): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const template = templates.find((t) => t.id === id);
    if (!template) throw new Error('Template not found');

    const { data: result, error: err } = await supabase
      .from('document_templates')
      .insert({
        company_id: companyId,
        name: `Copy of ${template.name}`,
        description: template.description,
        template_type: template.templateType,
        content_html: template.contentHtml,
        variables: template.variables,
        is_active: true,
        is_system: false,
        requires_signature: template.requiresSignature,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const generatePdf = async (renderId: string, options?: {
    companyName?: string;
    companyPhone?: string;
    companyEmail?: string;
    companyAddress?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // Fetch the render to get HTML content
    const render = renders.find(r => r.id === renderId);
    if (!render) throw new Error('Render not found');
    if (!render.renderedHtml) throw new Error('No content to generate PDF from');

    const { jsPDF } = await import('jspdf');

    // Create portrait letter-size PDF
    const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'letter' });
    const pageW = 215.9;
    const margin = 15;
    const contentW = pageW - margin * 2;

    doc.setProperties({
      title: render.title,
      subject: `Document: ${render.title}`,
      author: options?.companyName || 'Zafto',
      creator: 'Zafto ZDocs',
    });

    let y = margin;

    // Company header
    if (options?.companyName) {
      doc.setFontSize(16);
      doc.setFont('helvetica', 'bold');
      doc.text(options.companyName, margin, y + 6);
      y += 8;

      doc.setFontSize(8);
      doc.setFont('helvetica', 'normal');
      const contactParts = [options.companyAddress, options.companyPhone, options.companyEmail].filter(Boolean);
      if (contactParts.length > 0) {
        doc.text(contactParts.join('  |  '), margin, y + 4);
        y += 6;
      }

      // Separator line
      doc.setDrawColor(200);
      doc.setLineWidth(0.3);
      doc.line(margin, y + 2, margin + contentW, y + 2);
      y += 6;
    }

    // Document title
    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.text(render.title, margin, y + 5);
    y += 8;

    // Date
    doc.setFontSize(8);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(120, 120, 120);
    doc.text(`Generated: ${new Date().toLocaleDateString()}`, margin, y + 3);
    y += 8;
    doc.setTextColor(0, 0, 0);

    // Parse HTML content to plain text sections for PDF
    const tempDiv = document.createElement('div');
    tempDiv.innerHTML = render.renderedHtml;

    const walkNode = (node: Node) => {
      if (y > 260) {
        doc.addPage();
        y = margin;
      }

      if (node.nodeType === Node.TEXT_NODE) {
        const text = (node.textContent || '').trim();
        if (text) {
          doc.setFontSize(10);
          doc.setFont('helvetica', 'normal');
          const lines = doc.splitTextToSize(text, contentW);
          for (const line of lines) {
            if (y > 260) {
              doc.addPage();
              y = margin;
            }
            doc.text(line, margin, y);
            y += 4.5;
          }
        }
        return;
      }

      if (node.nodeType !== Node.ELEMENT_NODE) return;
      const el = node as HTMLElement;
      const tag = el.tagName.toLowerCase();

      // Headings
      if (['h1', 'h2', 'h3', 'h4'].includes(tag)) {
        y += 3;
        const sizes: Record<string, number> = { h1: 16, h2: 14, h3: 12, h4: 11 };
        doc.setFontSize(sizes[tag] || 12);
        doc.setFont('helvetica', 'bold');
        const headText = (el.textContent || '').trim();
        if (headText) {
          const lines = doc.splitTextToSize(headText, contentW);
          for (const line of lines) {
            if (y > 260) { doc.addPage(); y = margin; }
            doc.text(line, margin, y);
            y += (sizes[tag] || 12) * 0.45;
          }
        }
        y += 2;
        return;
      }

      // Horizontal rule
      if (tag === 'hr') {
        y += 2;
        doc.setDrawColor(200);
        doc.setLineWidth(0.2);
        doc.line(margin, y, margin + contentW, y);
        y += 4;
        return;
      }

      // List items
      if (tag === 'li') {
        const text = (el.textContent || '').trim();
        if (text) {
          doc.setFontSize(10);
          doc.setFont('helvetica', 'normal');
          const bullet = el.parentElement?.tagName.toLowerCase() === 'ol' ? `${Array.from(el.parentElement.children).indexOf(el) + 1}. ` : '  \u2022  ';
          const lines = doc.splitTextToSize(bullet + text, contentW - 5);
          for (const line of lines) {
            if (y > 260) { doc.addPage(); y = margin; }
            doc.text(line, margin + 3, y);
            y += 4.5;
          }
        }
        return;
      }

      // Bold/strong
      if (tag === 'strong' || tag === 'b') {
        doc.setFont('helvetica', 'bold');
        const text = (el.textContent || '').trim();
        if (text) {
          doc.setFontSize(10);
          const lines = doc.splitTextToSize(text, contentW);
          for (const line of lines) {
            if (y > 260) { doc.addPage(); y = margin; }
            doc.text(line, margin, y);
            y += 4.5;
          }
        }
        doc.setFont('helvetica', 'normal');
        return;
      }

      // Paragraph / div / blockquote — recurse into children
      if (['p', 'div', 'blockquote', 'section'].includes(tag)) {
        for (const child of Array.from(el.childNodes)) {
          walkNode(child);
        }
        y += 2; // paragraph spacing
        return;
      }

      // Table — simplified rendering
      if (tag === 'table') {
        const rows = el.querySelectorAll('tr');
        const cellW = contentW / Math.max(1, (rows[0]?.children.length || 1));
        doc.setFontSize(8);
        for (const row of Array.from(rows)) {
          if (y > 260) { doc.addPage(); y = margin; }
          const cells = row.querySelectorAll('th, td');
          let cx = margin;
          const isHeader = row.querySelector('th') !== null;
          if (isHeader) {
            doc.setFillColor(240, 240, 240);
            doc.rect(margin, y - 3, contentW, 5, 'F');
            doc.setFont('helvetica', 'bold');
          } else {
            doc.setFont('helvetica', 'normal');
          }
          for (const cell of Array.from(cells)) {
            const text = (cell.textContent || '').trim();
            doc.text(text, cx + 1, y, { maxWidth: cellW - 2 });
            cx += cellW;
          }
          y += 5;
        }
        y += 2;
        doc.setFont('helvetica', 'normal');
        doc.setFontSize(10);
        return;
      }

      // Default: recurse into children
      for (const child of Array.from(el.childNodes)) {
        walkNode(child);
      }
    };

    for (const child of Array.from(tempDiv.childNodes)) {
      walkNode(child);
    }

    // Footer on last page
    const pageCount = doc.getNumberOfPages();
    for (let i = 1; i <= pageCount; i++) {
      doc.setPage(i);
      doc.setFontSize(7);
      doc.setFont('helvetica', 'normal');
      doc.setTextColor(150, 150, 150);
      doc.text(
        `Page ${i} of ${pageCount}`,
        pageW / 2,
        279.4 - 8,
        { align: 'center' }
      );
      doc.text(
        `Generated by Zafto ZDocs`,
        pageW - margin,
        279.4 - 8,
        { align: 'right' }
      );
      doc.setTextColor(0, 0, 0);
    }

    // Convert to blob and upload to Supabase Storage
    const pdfBlob = doc.output('blob');
    const storagePath = `${companyId}/zdocs/${renderId}.pdf`;

    const { error: uploadErr } = await supabase.storage
      .from('documents')
      .upload(storagePath, pdfBlob, {
        contentType: 'application/pdf',
        upsert: true,
      });

    if (uploadErr) throw new Error(`PDF upload failed: ${uploadErr.message}`);

    // Update render record with storage path
    const { error: updateErr } = await supabase
      .from('zdocs_renders')
      .update({ pdf_storage_path: storagePath })
      .eq('id', renderId);

    if (updateErr) throw new Error(`Failed to update render: ${updateErr.message}`);

    // Refresh renders to reflect the new pdf_storage_path
    await fetchRenders();

    return storagePath;
  };

  const downloadPdf = async (renderId: string): Promise<void> => {
    const supabase = getSupabase();
    const render = renders.find(r => r.id === renderId);
    if (!render?.pdfStoragePath) throw new Error('No PDF available');

    const { data, error: err } = await supabase.storage
      .from('documents')
      .createSignedUrl(render.pdfStoragePath, 60 * 60); // 1 hour

    if (err || !data?.signedUrl) throw new Error('Failed to get download URL');

    // Trigger browser download
    const a = document.createElement('a');
    a.href = data.signedUrl;
    a.download = `${render.title.replace(/[^a-zA-Z0-9]/g, '_')}.pdf`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
  };

  const captureSignature = async (
    renderId: string,
    signatureRequestId: string,
    signatureImageDataUrl: string,
    signerName: string,
  ): Promise<void> => {
    const supabase = getSupabase();
    const render = renders.find(r => r.id === renderId);
    if (!render) throw new Error('Render not found');

    // 1. Compute SHA-256 document hash for tamper evidence
    const docContent = render.renderedHtml || '';
    const encoder = new TextEncoder();
    const hashBuffer = await crypto.subtle.digest('SHA-256', encoder.encode(docContent));
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const documentHash = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

    // 2. Upload signature image to storage
    const { data: { user } } = await supabase.auth.getUser();
    const companyId = user?.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // Convert data URL to blob
    const response = await fetch(signatureImageDataUrl);
    const signatureBlob = await response.blob();
    const sigPath = `${companyId}/signatures/${renderId}_${Date.now()}.png`;

    await supabase.storage
      .from('signatures')
      .upload(sigPath, signatureBlob, { contentType: 'image/png', upsert: true });

    // 3. Update signature request
    const now = new Date().toISOString();
    const { error: reqErr } = await supabase
      .from('zdocs_signature_requests')
      .update({
        status: 'signed',
        signed_at: now,
        document_hash: documentHash,
        device_info: navigator.userAgent.substring(0, 200),
      })
      .eq('id', signatureRequestId);

    if (reqErr) throw reqErr;

    // 4. Check if all signers for this render have signed
    const { data: allReqs } = await supabase
      .from('zdocs_signature_requests')
      .select('id, status')
      .eq('render_id', renderId);

    const allSigned = (allReqs || []).every((r: { id: string; status: string }) => r.status === 'signed');

    // 5. Generate certificate of completion HTML
    const certificateHtml = `
      <div style="font-family: Inter, sans-serif; max-width: 600px; margin: 0 auto; padding: 40px;">
        <h2 style="text-align: center; color: #1a1a1a; border-bottom: 2px solid #e5e7eb; padding-bottom: 16px;">
          Certificate of Completion
        </h2>
        <p style="text-align: center; color: #6b7280; font-size: 14px; margin-top: 8px;">
          Electronic Signature Verification
        </p>
        <table style="width: 100%; margin-top: 24px; border-collapse: collapse;">
          <tr><td style="padding: 8px 0; color: #6b7280; font-size: 13px;">Document</td><td style="padding: 8px 0; font-weight: 600;">${render.title}</td></tr>
          <tr><td style="padding: 8px 0; color: #6b7280; font-size: 13px;">Document Hash (SHA-256)</td><td style="padding: 8px 0; font-family: monospace; font-size: 11px; word-break: break-all;">${documentHash}</td></tr>
          <tr><td style="padding: 8px 0; color: #6b7280; font-size: 13px;">Signer</td><td style="padding: 8px 0; font-weight: 600;">${signerName}</td></tr>
          <tr><td style="padding: 8px 0; color: #6b7280; font-size: 13px;">Signed At</td><td style="padding: 8px 0;">${new Date().toLocaleString()}</td></tr>
          <tr><td style="padding: 8px 0; color: #6b7280; font-size: 13px;">Status</td><td style="padding: 8px 0; color: #059669; font-weight: 600;">${allSigned ? 'All Parties Signed' : 'Partially Signed'}</td></tr>
        </table>
        <div style="margin-top: 24px; padding: 16px; background: #f9fafb; border-radius: 8px; font-size: 12px; color: #6b7280;">
          This document was electronically signed in compliance with the ESIGN Act (15 U.S.C. § 7001)
          and the Uniform Electronic Transactions Act (UETA). The SHA-256 hash above can be used to verify
          document integrity — any modification to the document after signing will produce a different hash.
        </div>
      </div>
    `;

    // 6. Update render status
    const renderUpdate: Record<string, unknown> = {
      document_hash: documentHash,
    };
    if (allSigned) {
      renderUpdate.signature_status = 'signed';
      renderUpdate.signed_at = now;
      renderUpdate.certificate_html = certificateHtml;
      renderUpdate.status = 'signed';
    }
    await supabase.from('zdocs_renders').update(renderUpdate).eq('id', renderId);

    // 7. Log audit event
    await supabase.from('signature_audit_events').insert({
      company_id: companyId,
      signature_request_id: signatureRequestId,
      render_id: renderId,
      event_type: 'signed',
      actor_type: 'signer',
      actor_name: signerName,
      ip_address: null, // Would need server-side to get real IP
      user_agent: navigator.userAgent.substring(0, 500),
      document_hash: documentHash,
    });

    // Refresh data
    await fetchAll();
  };

  const deleteRender = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase.from('zdocs_renders').update({ deleted_at: new Date().toISOString() }).eq('id', id);
    if (err) throw err;
  };

  // ==================== COMPUTED ====================

  const activeTemplates = useMemo(
    () => templates.filter((t) => t.isActive),
    [templates]
  );

  const totalRenders = useMemo(() => renders.length, [renders]);

  const pendingSignatures = useMemo(
    () => renders.filter((r) => r.signatureStatus === 'sent' || r.signatureStatus === 'viewed'),
    [renders]
  );

  const recentRenders = useMemo(() => {
    const thirtyDaysAgo = Date.now() - 30 * 24 * 60 * 60 * 1000;
    return renders.filter((r) => new Date(r.createdAt).getTime() > thirtyDaysAgo);
  }, [renders]);

  return {
    templates,
    renders,
    signatureRequests,
    loading,
    error,
    // Mutations
    createTemplate,
    updateTemplate,
    deleteTemplate,
    renderDocument,
    sendForSignature,
    duplicateTemplate,
    deleteRender,
    // PDF
    generatePdf,
    downloadPdf,
    // Signatures
    captureSignature,
    // Versioning
    fetchTemplateVersions,
    revertToVersion,
    // Computed
    activeTemplates,
    totalRenders,
    pendingSignatures,
    recentRenders,
    // Refetch
    refetch: fetchAll,
  };
}
