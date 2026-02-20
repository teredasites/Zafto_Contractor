-- LEGAL-1: Legal disclaimers table + template version tracking
-- S143: Legal defense foundation layer

-- ============================================================
-- legal_disclaimers — Single source of truth for ALL disclaimer text
-- ============================================================
CREATE TABLE legal_disclaimers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  category TEXT NOT NULL CHECK (category IN (
    'calculator', 'code_reference', 'inspection', 'estimation',
    'insurance', 'property_data', 'pricing', 'compliance',
    'tax', 'payroll', 'general', 'restoration'
  )),
  short_text TEXT NOT NULL,
  long_text TEXT NOT NULL,
  display_context TEXT, -- where this disclaimer appears (e.g., 'calculator_result_footer')
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE legal_disclaimers ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER legal_disclaimers_updated_at BEFORE UPDATE ON legal_disclaimers FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Public read — disclaimers are non-sensitive reference data
CREATE POLICY "legal_disclaimers_select" ON legal_disclaimers FOR SELECT USING (true);
-- Only super_admin can modify
CREATE POLICY "legal_disclaimers_insert" ON legal_disclaimers FOR INSERT WITH CHECK (
  requesting_user_role() = 'super_admin'
);
CREATE POLICY "legal_disclaimers_update" ON legal_disclaimers FOR UPDATE USING (
  requesting_user_role() = 'super_admin'
);
CREATE POLICY "legal_disclaimers_delete" ON legal_disclaimers FOR DELETE USING (
  requesting_user_role() = 'super_admin'
);

-- ============================================================
-- Seed ~25 disclaimer entries
-- ============================================================
INSERT INTO legal_disclaimers (key, category, short_text, long_text, display_context) VALUES

-- Calculator disclaimers
('calculator_general', 'calculator',
  'Reference calculation based on inputs provided',
  'This calculation uses published formulas and industry standards. Results should be verified by a licensed professional before use in design, permitting, or construction decisions. Zafto provides calculation tools to assist licensed professionals — not replace professional engineering judgment.',
  'calculator_result_footer'),

('calculator_electrical', 'calculator',
  'Based on NEC formulas — verify with local AHJ',
  'Electrical calculations are based on National Electrical Code (NFPA 70) formulas and tables. Local jurisdictions may adopt different editions or amendments. Wire sizing, conduit fill, voltage drop, and load calculations should be verified by a licensed electrician and confirmed with the Authority Having Jurisdiction (AHJ).',
  'calculator_result_footer'),

('calculator_hvac', 'calculator',
  'Based on ACCA/ASHRAE standards — verify sizing with manufacturer data',
  'HVAC calculations reference ACCA Manual J, Manual D, and ASHRAE standards. Equipment sizing, duct design, and refrigerant charge calculations are estimates based on standard conditions. Actual requirements vary by climate zone, building construction, equipment specifications, and local code requirements.',
  'calculator_result_footer'),

('calculator_plumbing', 'calculator',
  'Based on IPC/UPC standards — verify with local plumbing code',
  'Plumbing calculations reference the International Plumbing Code (IPC) or Uniform Plumbing Code (UPC). Fixture unit counts, pipe sizing, and water heater calculations should be verified against the locally adopted plumbing code edition.',
  'calculator_result_footer'),

('calculator_structural', 'calculator',
  'Preliminary estimate only — requires licensed engineer review',
  'Structural calculations provide preliminary estimates based on standard engineering formulas. All structural designs must be reviewed, stamped, and approved by a licensed Professional Engineer (PE) in the project jurisdiction before use in construction.',
  'calculator_result_footer'),

-- Code reference disclaimers
('nec_code_ref', 'code_reference',
  'NEC 2023 — verify with local AHJ for adopted edition',
  'Code references are based on the National Electrical Code (NFPA 70) 2023 edition. Local jurisdictions may adopt different editions or amendments. Always verify applicable codes with your Authority Having Jurisdiction (AHJ). Zafto aggregates code references for professional convenience — this is not legal advice.',
  'code_result_metadata'),

('ibc_code_ref', 'code_reference',
  'IBC 2021 — verify with local building department',
  'Code references are based on the International Building Code (IBC) 2021 edition. Local jurisdictions adopt and amend the IBC on their own schedules. Verify the locally adopted edition and any local amendments with your building department.',
  'code_result_metadata'),

('osha_code_ref', 'code_reference',
  'OSHA 29 CFR — federal minimum, state plans may exceed',
  'Safety references are based on OSHA 29 CFR Part 1926 (Construction) and Part 1910 (General Industry). States with OSHA-approved state plans may have additional or stricter requirements. Verify applicable standards with your state occupational safety agency.',
  'code_result_metadata'),

-- Inspection disclaimers
('inspection_template', 'inspection',
  'Industry-standard checklist — does not replace licensed inspection',
  'Inspection checklists are based on published standards (IBC, IRC, NFPA, OSHA). This tool assists qualified inspectors in documenting findings. It does not constitute a licensed inspection and should not be relied upon as such. The inspector performing the assessment is responsible for all findings and conclusions.',
  'inspection_report_footer'),

('inspection_report', 'inspection',
  'Findings documented by inspector using Zafto tools',
  'This report documents findings by the named inspector using industry-standard checklists. It does not constitute a licensed inspection unless performed by a licensed inspector under applicable state law. All observations and recommendations are the professional opinion of the inspector.',
  'inspection_pdf_footer'),

-- Estimation disclaimers
('estimate_general', 'estimation',
  'Estimate based on regional market data — subject to site conditions',
  'This estimate uses regional market data for material pricing and labor rates. Final costs are subject to site conditions, material availability, supplier pricing, scope changes, and market fluctuations. Material pricing reflects aggregated market data as of the date shown. Obtain current supplier quotes before committing to project budgets.',
  'estimate_pdf_footer'),

('bid_document', 'estimation',
  'Prepared using Zafto estimation tools — pricing subject to confirmation',
  'Prepared using Zafto estimation tools. Material pricing and labor rates are estimates based on regional market data. Final pricing subject to site conditions, material availability, and scope confirmation. This bid is valid for the period specified and subject to the terms and conditions stated herein.',
  'bid_pdf_footer'),

-- Insurance disclaimers
('insurance_estimate', 'insurance',
  'Contractor estimate — not a carrier assessment',
  'Insurance-related estimates are generated for contractor planning purposes using industry pricing data. These are not carrier-approved assessments and may differ from adjuster determinations. Zafto is not an insurance company, adjuster, or claims administrator. Submission to insurance carriers is the responsibility of the contractor.',
  'insurance_result_footer'),

-- Property data disclaimers
('property_data', 'property_data',
  'Public record data — verify for accuracy',
  'Property information is aggregated from public records, satellite imagery, and third-party data providers. Data freshness and accuracy vary by source. Verify critical details through official county records or on-site assessment. Zafto aggregates available data for professional convenience but does not guarantee completeness or accuracy.',
  'recon_scan_footer'),

('roof_measurement', 'property_data',
  'Satellite-derived measurement — verify on-site',
  'Roof measurements are derived from satellite imagery and elevation data. Accuracy depends on image quality, roof complexity, and data freshness. On-site verification recommended before material ordering or bid submission.',
  'recon_roof_footer'),

('lead_score', 'property_data',
  'Calculated from property data — not a guarantee of opportunity',
  'Lead scores are calculated from property age, roof condition, storm history, area demographics, and other factors. Scores indicate relative opportunity potential and are not a guarantee of conversion or project viability.',
  'recon_lead_footer'),

-- Pricing disclaimers
('labor_rate', 'pricing',
  'Regional average — adjust for your market',
  'Labor rates are based on Bureau of Labor Statistics (BLS) OEWS data and industry surveys. Actual rates vary by market, experience level, union status, project complexity, and prevailing wage requirements. Use as a starting reference and adjust for local conditions.',
  'pricing_footer'),

('material_pricing', 'pricing',
  'Market pricing as of date shown — obtain current quotes',
  'Material pricing reflects aggregated market data as of the date shown. Prices fluctuate based on supply, demand, location, and supplier relationships. Obtain current quotes from suppliers before committing to project budgets. Zafto pricing data is provided for estimating purposes only.',
  'pricing_footer'),

-- Tax/payroll disclaimers
('tax_calculation', 'tax',
  'Estimated tax — consult your tax professional',
  'Tax calculations are estimates based on published rates and general rules. Tax obligations depend on business structure, jurisdiction, exemptions, and current regulations. Consult a qualified tax professional for tax planning and filing. Zafto is not a tax advisor.',
  'tax_result_footer'),

('payroll_calculation', 'payroll',
  'Estimated payroll — verify with your payroll provider',
  'Payroll calculations use published tax tables and standard withholding formulas. Actual withholdings depend on employee elections, benefit deductions, garnishments, and jurisdiction-specific rules. Verify with your payroll provider or CPA. Zafto is not a payroll service provider.',
  'payroll_result_footer'),

-- Restoration disclaimers
('restoration_protocol', 'restoration',
  'Based on IICRC standards — follow current edition',
  'Restoration protocols reference IICRC S500 (Water Damage), S520 (Mold Remediation), and related standards. Actual procedures must follow the current edition of applicable standards, manufacturer guidelines, and local health department requirements. Restoration work should be performed by certified professionals.',
  'restoration_protocol_footer'),

('mold_assessment', 'restoration',
  'Assessment tool — does not replace certified mold inspection',
  'Mold assessment tools assist in documenting conditions and following IICRC S520 protocols. This does not constitute a certified mold inspection or clearance test. Clearance testing should be performed by an independent certified industrial hygienist or mold assessor as required by state regulations.',
  'mold_result_footer'),

-- General disclaimers
('general_tool', 'general',
  'Professional tool — not professional advice',
  'Zafto provides professional-grade tools for licensed tradespeople, contractors, inspectors, adjusters, and real estate professionals. Our tools are designed to support your expertise — not replace it. All outputs should be verified against current local requirements and professional standards. Use of Zafto does not create a professional-client relationship with Tereda Software LLC.',
  'general_footer'),

('data_freshness', 'general',
  'Data current as of date shown',
  'Data displayed reflects the most recent information available from our sources as of the date shown. Building codes, regulations, pricing, and other data change over time. Users are responsible for verifying that information is current for their specific use case and jurisdiction.',
  'general_metadata');

-- ============================================================
-- Template version tracking (add to existing tables)
-- ============================================================
ALTER TABLE document_templates
  ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS last_verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS legal_standard_edition TEXT,
  ADD COLUMN IF NOT EXISTS jurisdiction TEXT;

ALTER TABLE form_templates
  ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS last_verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS legal_standard_edition TEXT,
  ADD COLUMN IF NOT EXISTS jurisdiction TEXT,
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
