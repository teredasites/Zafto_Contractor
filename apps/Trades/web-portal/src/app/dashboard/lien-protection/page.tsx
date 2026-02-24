'use client';

// 9A: Mechanic's Lien Engine — 50-state rules, auto-deadline tracking, preliminary notice
// generation, lien waiver management, deadline alerts, lien filing preparation.

import { useState, useMemo } from 'react';
import {
  Shield,
  AlertTriangle,
  Clock,
  DollarSign,
  FileText,
  ChevronRight,
  ChevronDown,
  MapPin,
  Calendar,
  CheckCircle,
  XCircle,
  Search,
  Bell,
  Scale,
  Gavel,
  BookOpen,
  Send,
  Download,
  Eye,
  Filter,
  ArrowUpRight,
  Timer,
  Landmark,
  CircleDot,
  Info,
  Plus,
  Building2,
  ClipboardCheck,
  FileWarning,
  FilePlus,
  TriangleAlert,
  Hourglass,
  CalendarClock,
  ArrowRight,
  Stamp,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput } from '@/components/ui/input';
import { useLienProtection, type LienRecord } from '@/lib/hooks/use-lien-protection';
import { useTranslation } from '@/lib/translations';
import { formatCurrency, formatDateLocale } from '@/lib/format-locale';
import { CommandPalette } from '@/components/command-palette';

// ── Tab type ──────────────────────────────────────────────
type Tab = 'dashboard' | 'rules' | 'waivers' | 'deadlines' | 'notices';

const TABS: { id: Tab; label: string; icon: React.ComponentType<{ className?: string }> }[] = [
  { id: 'dashboard', label: 'Dashboard', icon: Shield },
  { id: 'rules', label: 'State Rules', icon: BookOpen },
  { id: 'waivers', label: 'Waivers', icon: ClipboardCheck },
  { id: 'deadlines', label: 'Deadlines', icon: CalendarClock },
  { id: 'notices', label: 'Notices', icon: Send },
];

// ── Status helpers ────────────────────────────────────────
function statusVariant(status: string): 'success' | 'error' | 'warning' | 'info' | 'secondary' {
  switch (status) {
    case 'notice_due': case 'enforcement': return 'error';
    case 'lien_eligible': case 'lien_filed': return 'warning';
    case 'notice_sent': return 'info';
    case 'payment_received': case 'lien_released': case 'resolved': return 'success';
    default: return 'secondary';
  }
}

function urgencyVariant(days: number): 'error' | 'warning' | 'info' | 'secondary' {
  if (days <= 3) return 'error';
  if (days <= 7) return 'error';
  if (days <= 14) return 'warning';
  if (days <= 30) return 'info';
  return 'secondary';
}

function urgencyColor(days: number): string {
  if (days <= 3) return 'text-red-400';
  if (days <= 7) return 'text-red-400';
  if (days <= 14) return 'text-amber-400';
  if (days <= 30) return 'text-blue-400';
  return 'text-muted';
}

function formatStatusLabel(status: string): string {
  return status.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
}

// ── Demo Data: 50-State Rules ─────────────────────────────
interface StateRule {
  stateCode: string;
  stateName: string;
  prelimNoticeRequired: boolean;
  prelimNoticeDeadlineDays: number | null;
  prelimNoticeFrom: string;
  lienFilingDeadlineDays: number;
  lienFilingFrom: string;
  lienEnforcementDeadlineDays: number;
  lienEnforcementFrom: string;
  requiredForms: string[];
  recordingOffice: string;
  specialRequirements: string[];
  notarizationRequired: boolean;
  residentialDifferent: boolean;
  statutoryRef: string;
}

const STATE_RULES_DATA: StateRule[] = [
  { stateCode: 'CA', stateName: 'California', prelimNoticeRequired: true, prelimNoticeDeadlineDays: 20, prelimNoticeFrom: 'first furnishing labor/materials', lienFilingDeadlineDays: 90, lienFilingFrom: 'completion of work', lienEnforcementDeadlineDays: 90, lienEnforcementFrom: 'recording of lien', requiredForms: ['Preliminary 20-Day Notice', 'Claim of Mechanics Lien', 'Notice of Mechanics Lien Release'], recordingOffice: 'County Recorder', specialRequirements: ['Must serve copy on owner within 10 days of recording', 'Preliminary notice must be sent via certified mail', 'Design professionals have separate rules'], notarizationRequired: false, residentialDifferent: true, statutoryRef: 'Cal. Civ. Code 8400-8494' },
  { stateCode: 'TX', stateName: 'Texas', prelimNoticeRequired: true, prelimNoticeDeadlineDays: 15, prelimNoticeFrom: 'each month for unpaid work', lienFilingDeadlineDays: 90, lienFilingFrom: 'last day of month in which work performed', lienEnforcementDeadlineDays: 365, lienEnforcementFrom: 'last day work performed', requiredForms: ['Monthly Notices', 'Affidavit Claiming Lien', 'Lien Release'], recordingOffice: 'County Clerk', specialRequirements: ['Monthly billing notices required for subcontractors', 'Retainage liens have separate rules', 'Fund trapping available for unpaid subs'], notarizationRequired: true, residentialDifferent: true, statutoryRef: 'Tex. Prop. Code Ch. 53' },
  { stateCode: 'FL', stateName: 'Florida', prelimNoticeRequired: true, prelimNoticeDeadlineDays: 45, prelimNoticeFrom: 'first furnishing labor/materials', lienFilingDeadlineDays: 90, lienFilingFrom: 'final furnishing of labor/materials', lienEnforcementDeadlineDays: 365, lienEnforcementFrom: 'recording of claim of lien', requiredForms: ['Notice to Owner', 'Claim of Lien', 'Notice of Contest of Lien'], recordingOffice: 'County Recorder/Clerk of Court', specialRequirements: ['Notice to Owner must be served before lien rights attach', 'Contractors in direct privity with owner exempt from NTO', 'Lien must be verified (sworn)'], notarizationRequired: true, residentialDifferent: false, statutoryRef: 'Fla. Stat. 713.001-713.37' },
  { stateCode: 'NY', stateName: 'New York', prelimNoticeRequired: false, prelimNoticeDeadlineDays: null, prelimNoticeFrom: '-', lienFilingDeadlineDays: 240, lienFilingFrom: 'last date of work', lienEnforcementDeadlineDays: 365, lienEnforcementFrom: 'filing of notice of lien', requiredForms: ['Notice of Lien', 'Notice of Mechanics Lien'], recordingOffice: 'County Clerk', specialRequirements: ['Private improvements: file within 8 months of completion', 'Public improvements: file within 30 days of completion', 'Must serve copy on owner within 30 days of filing'], notarizationRequired: true, residentialDifferent: true, statutoryRef: 'N.Y. Lien Law Art. 2' },
  { stateCode: 'IL', stateName: 'Illinois', prelimNoticeRequired: true, prelimNoticeDeadlineDays: 60, prelimNoticeFrom: 'first furnishing (subcontractors)', lienFilingDeadlineDays: 120, lienFilingFrom: 'completion of work', lienEnforcementDeadlineDays: 730, lienEnforcementFrom: 'recording of claim for lien', requiredForms: ['Notice of Lien Claim', 'Claim for Lien', 'Notice of Subcontractor Claim'], recordingOffice: 'County Recorder of Deeds', specialRequirements: ['Subcontractors must serve 60-day notice on owner', 'Contractor notice to owner within 90 days if subcontractor', 'Must include sworn statement of amounts due'], notarizationRequired: true, residentialDifferent: true, statutoryRef: '770 ILCS 60/1-39' },
  { stateCode: 'PA', stateName: 'Pennsylvania', prelimNoticeRequired: true, prelimNoticeDeadlineDays: 30, prelimNoticeFrom: 'starting work on residential', lienFilingDeadlineDays: 180, lienFilingFrom: 'last date of work', lienEnforcementDeadlineDays: 730, lienEnforcementFrom: 'filing of lien claim', requiredForms: ['Notice of Furnishing', 'Mechanics Lien Claim'], recordingOffice: 'Prothonotary (Court of Common Pleas)', specialRequirements: ['Residential: formal written contract required for GC lien rights', 'Notice of furnishing within 30 days for subs on residential', 'Must include legal description of property'], notarizationRequired: true, residentialDifferent: true, statutoryRef: '49 Pa. Cons. Stat. 1101-1902' },
  { stateCode: 'OH', stateName: 'Ohio', prelimNoticeRequired: true, prelimNoticeDeadlineDays: 21, prelimNoticeFrom: 'first furnishing (subcontractors)', lienFilingDeadlineDays: 75, lienFilingFrom: 'last date of work', lienEnforcementDeadlineDays: 180, lienEnforcementFrom: 'filing of affidavit', requiredForms: ['Notice of Furnishing', 'Affidavit for Mechanic\'s Lien', 'Notice of Commencement'], recordingOffice: 'County Recorder', specialRequirements: ['Notice of Commencement by owner affects deadlines', 'Sub-subs must serve notice within 21 days', 'Affidavit must be filed within 75 days after last work'], notarizationRequired: true, residentialDifferent: false, statutoryRef: 'Ohio Rev. Code 1311.01-1311.32' },
  { stateCode: 'GA', stateName: 'Georgia', prelimNoticeRequired: true, prelimNoticeDeadlineDays: 30, prelimNoticeFrom: 'start of work on project', lienFilingDeadlineDays: 90, lienFilingFrom: 'completion/abandonment of project', lienEnforcementDeadlineDays: 365, lienEnforcementFrom: 'filing of claim of lien', requiredForms: ['Notice of Commencement', 'Preliminary Notice', 'Claim of Lien'], recordingOffice: 'Superior Court Clerk', specialRequirements: ['Owner must file Notice of Commencement', 'All lien claimants must send preliminary notice within 30 days of project start', 'Lien must be commenced by filing verified complaint'], notarizationRequired: false, residentialDifferent: false, statutoryRef: 'O.C.G.A. 44-14-360 to 44-14-368' },
  { stateCode: 'NC', stateName: 'North Carolina', prelimNoticeRequired: true, prelimNoticeDeadlineDays: 15, prelimNoticeFrom: 'first furnishing (sub-subs only)', lienFilingDeadlineDays: 120, lienFilingFrom: 'last furnishing of labor/materials', lienEnforcementDeadlineDays: 180, lienEnforcementFrom: 'filing of claim of lien', requiredForms: ['Notice to Lien Agent', 'Claim of Lien on Real Property', 'Lien Waiver and Release'], recordingOffice: 'Clerk of Superior Court', specialRequirements: ['Owner must appoint Lien Agent for projects >$30k', 'Sub-subs must notify Lien Agent within 15 days of first furnishing', 'Separate rules for residential vs commercial'], notarizationRequired: false, residentialDifferent: true, statutoryRef: 'N.C. Gen. Stat. 44A-7 to 44A-23' },
  { stateCode: 'MI', stateName: 'Michigan', prelimNoticeRequired: true, prelimNoticeDeadlineDays: 20, prelimNoticeFrom: 'first furnishing (subcontractors)', lienFilingDeadlineDays: 90, lienFilingFrom: 'last furnishing of labor/materials', lienEnforcementDeadlineDays: 365, lienEnforcementFrom: 'recording of claim of lien', requiredForms: ['Notice of Furnishing', 'Statement of Account', 'Claim of Lien'], recordingOffice: 'County Register of Deeds', specialRequirements: ['Subcontractors must provide 20-day preliminary notice', 'Sworn statement must accompany each payment application', 'Residential: contractor must provide pre-lien notice'], notarizationRequired: true, residentialDifferent: true, statutoryRef: 'Mich. Comp. Laws 570.1101-570.1305' },
  { stateCode: 'NJ', stateName: 'New Jersey', prelimNoticeRequired: false, prelimNoticeDeadlineDays: null, prelimNoticeFrom: '-', lienFilingDeadlineDays: 90, lienFilingFrom: 'last date of work/materials', lienEnforcementDeadlineDays: 365, lienEnforcementFrom: 'last date of work', requiredForms: ['NJ Construction Lien Claim', 'Notice of Unpaid Balance and Right to File Lien'], recordingOffice: 'County Clerk', specialRequirements: ['Must send Notice of Unpaid Balance 10 days before filing', 'Residential improvements under $750k have special rules', 'Arbitration clause may limit enforcement options'], notarizationRequired: true, residentialDifferent: true, statutoryRef: 'N.J. Stat. Ann. 2A:44A-1 to 2A:44A-38' },
  { stateCode: 'VA', stateName: 'Virginia', prelimNoticeRequired: true, prelimNoticeDeadlineDays: 30, prelimNoticeFrom: 'start of work (subcontractors)', lienFilingDeadlineDays: 90, lienFilingFrom: 'last day of month in which work performed', lienEnforcementDeadlineDays: 180, lienEnforcementFrom: 'recording of memorandum of lien', requiredForms: ['Notice of Intent to File Lien', 'Memorandum of Mechanic\'s Lien'], recordingOffice: 'Circuit Court Clerk', specialRequirements: ['Must send Notice of Intent 30 days before filing', 'Residential owner-occupants: contractor must provide written contract', 'Filing limited to 150 days from last work for GCs'], notarizationRequired: true, residentialDifferent: true, statutoryRef: 'Va. Code Ann. 43-1 to 43-71' },
  { stateCode: 'WA', stateName: 'Washington', prelimNoticeRequired: true, prelimNoticeDeadlineDays: 60, prelimNoticeFrom: 'first delivery of materials/labor', lienFilingDeadlineDays: 90, lienFilingFrom: 'cessation of furnishing labor/materials', lienEnforcementDeadlineDays: 240, lienEnforcementFrom: 'recording of claim of lien', requiredForms: ['Pre-Claim Notice', 'Claim of Lien', 'Notice of Lien Filing'], recordingOffice: 'County Auditor', specialRequirements: ['Must give Pre-Claim Notice 60 days before filing', 'Residential: must also provide Notice to Customer', 'Owner may request lien claimant to commence suit'], notarizationRequired: false, residentialDifferent: true, statutoryRef: 'Wash. Rev. Code 60.04' },
  { stateCode: 'AZ', stateName: 'Arizona', prelimNoticeRequired: true, prelimNoticeDeadlineDays: 20, prelimNoticeFrom: 'first furnishing of labor/materials', lienFilingDeadlineDays: 120, lienFilingFrom: 'completion of work', lienEnforcementDeadlineDays: 180, lienEnforcementFrom: 'recording of claim of lien', requiredForms: ['Preliminary 20-Day Notice', 'Claim of Mechanics Lien', 'Notice of Completion'], recordingOffice: 'County Recorder', specialRequirements: ['Preliminary notice every 20 days for continued work', 'Owner may record Notice of Completion to shorten deadline', 'Must include legal description and property owner info'], notarizationRequired: false, residentialDifferent: false, statutoryRef: 'Ariz. Rev. Stat. 33-981 to 33-1008' },
  { stateCode: 'CO', stateName: 'Colorado', prelimNoticeRequired: true, prelimNoticeDeadlineDays: 10, prelimNoticeFrom: 'first furnishing (for subcontractors)', lienFilingDeadlineDays: 120, lienFilingFrom: 'last date of work', lienEnforcementDeadlineDays: 180, lienEnforcementFrom: 'filing of lien statement', requiredForms: ['Notice of Intent to File Lien', 'Statement of Lien', 'Lien Waiver'], recordingOffice: 'County Clerk and Recorder', specialRequirements: ['Must send Notice of Intent 10 business days before filing', 'Applies to both real and personal property', 'Trust fund statute protects subcontractor payments'], notarizationRequired: false, residentialDifferent: false, statutoryRef: 'Colo. Rev. Stat. 38-22-101 to 38-22-133' },
  { stateCode: 'MA', stateName: 'Massachusetts', prelimNoticeRequired: true, prelimNoticeDeadlineDays: 30, prelimNoticeFrom: 'start of work (for sub-subs)', lienFilingDeadlineDays: 90, lienFilingFrom: 'last date of work', lienEnforcementDeadlineDays: 30, lienEnforcementFrom: 'filing of statement of account', requiredForms: ['Notice of Identification', 'Statement of Account', 'Dissolution of Lien Bond'], recordingOffice: 'Registry of Deeds', specialRequirements: ['Sub-subs must file Notice of Identification with GC', 'Very short enforcement deadline of 30 days after filing', 'Public projects require 90-day bond claim'], notarizationRequired: false, residentialDifferent: false, statutoryRef: 'Mass. Gen. Laws ch. 254' },
  { stateCode: 'TN', stateName: 'Tennessee', prelimNoticeRequired: true, prelimNoticeDeadlineDays: 90, prelimNoticeFrom: 'completion of work (for subs)', lienFilingDeadlineDays: 90, lienFilingFrom: 'completion of the improvement', lienEnforcementDeadlineDays: 365, lienEnforcementFrom: 'date lien became effective', requiredForms: ['Notice of Non-Payment', 'Notice of Lien', 'Sworn Statement of Lien'], recordingOffice: 'Register of Deeds', specialRequirements: ['Remote contractors/suppliers must serve Notice of Non-Payment', 'Residential owner-occupied: contractor must have written contract', 'Lien attaches from date notice is served on owner'], notarizationRequired: true, residentialDifferent: true, statutoryRef: 'Tenn. Code Ann. 66-11-101 to 66-11-151' },
  { stateCode: 'MD', stateName: 'Maryland', prelimNoticeRequired: true, prelimNoticeDeadlineDays: 120, prelimNoticeFrom: 'doing work (for subcontractors)', lienFilingDeadlineDays: 180, lienFilingFrom: 'last date of work', lienEnforcementDeadlineDays: 365, lienEnforcementFrom: 'filing of petition', requiredForms: ['Notice to Owner', 'Petition to Establish Mechanic\'s Lien', 'Affidavit of Lien'], recordingOffice: 'Circuit Court Clerk', specialRequirements: ['Subcontractors must give written notice to owner', 'Petition must be filed in circuit court, not recorded', 'Owner-occupied residential: contractor must provide contract'], notarizationRequired: true, residentialDifferent: true, statutoryRef: 'Md. Code Real Prop. 9-101 to 9-113' },
  { stateCode: 'MN', stateName: 'Minnesota', prelimNoticeRequired: true, prelimNoticeDeadlineDays: 45, prelimNoticeFrom: 'first furnishing (for subcontractors)', lienFilingDeadlineDays: 120, lienFilingFrom: 'last date of labor/materials', lienEnforcementDeadlineDays: 365, lienEnforcementFrom: 'recording of lien statement', requiredForms: ['Pre-Lien Notice', 'Mechanic\'s Lien Statement', 'Notice of Lien Filing'], recordingOffice: 'County Recorder', specialRequirements: ['Pre-lien notice within 45 days for subs/suppliers', 'Must serve copy on owner within 5 days of recording', 'Residential: owner may demand sworn statement of amounts'], notarizationRequired: false, residentialDifferent: true, statutoryRef: 'Minn. Stat. 514.01-514.17' },
  { stateCode: 'NV', stateName: 'Nevada', prelimNoticeRequired: true, prelimNoticeDeadlineDays: 31, prelimNoticeFrom: 'first furnishing of labor/materials', lienFilingDeadlineDays: 90, lienFilingFrom: 'completion/cessation of work', lienEnforcementDeadlineDays: 180, lienEnforcementFrom: 'recording of notice of lien', requiredForms: ['Notice of Right to Lien', 'Notice of Mechanic\'s Lien', 'Notice to Owner of Pending Lien'], recordingOffice: 'County Recorder', specialRequirements: ['Must serve Notice of Right to Lien within 31 days', 'Must give owner 15-day pre-filing notice', 'Recording within 90 days after notice of completion or 180 if none'], notarizationRequired: true, residentialDifferent: false, statutoryRef: 'Nev. Rev. Stat. 108.221-108.246' },
];

// ── Demo Data: Waivers ────────────────────────────────────
type WaiverType = 'conditional_progress' | 'unconditional_progress' | 'conditional_final' | 'unconditional_final';
type WaiverStatus = 'pending_send' | 'sent' | 'received' | 'missing' | 'overdue';

interface LienWaiver {
  id: string;
  jobName: string;
  propertyAddress: string;
  partyName: string;
  partyType: 'subcontractor' | 'supplier' | 'gc';
  waiverType: WaiverType;
  amount: number;
  status: WaiverStatus;
  dateSent: string | null;
  dateReceived: string | null;
  paymentReleasedWithoutWaiver: boolean;
}

const DEMO_WAIVERS: LienWaiver[] = [
  { id: 'w1', jobName: 'Kitchen Remodel — Johnson', propertyAddress: '1420 Elm St, Austin, TX', partyName: 'ABC Plumbing Co.', partyType: 'subcontractor', waiverType: 'conditional_progress', amount: 12500, status: 'sent', dateSent: '2026-02-10', dateReceived: null, paymentReleasedWithoutWaiver: false },
  { id: 'w2', jobName: 'Kitchen Remodel — Johnson', propertyAddress: '1420 Elm St, Austin, TX', partyName: 'Premium Granite Supply', partyType: 'supplier', waiverType: 'unconditional_progress', amount: 8200, status: 'received', dateSent: '2026-01-28', dateReceived: '2026-02-03', paymentReleasedWithoutWaiver: false },
  { id: 'w3', jobName: 'Roof Replacement — Davis', propertyAddress: '891 Oak Blvd, Tampa, FL', partyName: 'SunCoast Roofing Supply', partyType: 'supplier', waiverType: 'conditional_progress', amount: 18750, status: 'overdue', dateSent: '2026-01-15', dateReceived: null, paymentReleasedWithoutWaiver: true },
  { id: 'w4', jobName: 'Bathroom Renovation — Kim', propertyAddress: '302 Pine Ave, Los Angeles, CA', partyName: 'Elite Tile Installers', partyType: 'subcontractor', waiverType: 'unconditional_final', amount: 6400, status: 'received', dateSent: '2026-02-05', dateReceived: '2026-02-12', paymentReleasedWithoutWaiver: false },
  { id: 'w5', jobName: 'Commercial Build-Out — TechCorp', propertyAddress: '500 Commerce Dr, Chicago, IL', partyName: 'Midwest Electric LLC', partyType: 'subcontractor', waiverType: 'conditional_final', amount: 34200, status: 'pending_send', dateSent: null, dateReceived: null, paymentReleasedWithoutWaiver: false },
  { id: 'w6', jobName: 'HVAC Install — Martinez', propertyAddress: '7722 Maple Ct, Phoenix, AZ', partyName: 'Desert Cool HVAC', partyType: 'subcontractor', waiverType: 'unconditional_progress', amount: 15000, status: 'missing', dateSent: null, dateReceived: null, paymentReleasedWithoutWaiver: true },
  { id: 'w7', jobName: 'Office Renovation — StartupHQ', propertyAddress: '188 Broadway, New York, NY', partyName: 'Brooklyn Drywall Co.', partyType: 'subcontractor', waiverType: 'conditional_progress', amount: 22000, status: 'sent', dateSent: '2026-02-18', dateReceived: null, paymentReleasedWithoutWaiver: false },
];

// ── Demo Data: Deadlines ──────────────────────────────────
interface LienDeadline {
  id: string;
  jobName: string;
  propertyAddress: string;
  stateCode: string;
  deadlineType: 'preliminary_notice' | 'lien_filing' | 'lien_enforcement' | 'notice_of_intent';
  deadlineDate: string;
  daysRemaining: number;
  status: 'upcoming' | 'urgent' | 'critical' | 'overdue' | 'completed';
  amountAtRisk: number;
}

const DEMO_DEADLINES: LienDeadline[] = [
  { id: 'd1', jobName: 'Kitchen Remodel — Johnson', propertyAddress: '1420 Elm St, Austin, TX', stateCode: 'TX', deadlineType: 'lien_filing', deadlineDate: '2026-03-01', daysRemaining: 5, status: 'critical', amountAtRisk: 24500 },
  { id: 'd2', jobName: 'Roof Replacement — Davis', propertyAddress: '891 Oak Blvd, Tampa, FL', stateCode: 'FL', deadlineType: 'preliminary_notice', deadlineDate: '2026-02-28', daysRemaining: 4, status: 'critical', amountAtRisk: 18750 },
  { id: 'd3', jobName: 'Bathroom Renovation — Kim', propertyAddress: '302 Pine Ave, Los Angeles, CA', stateCode: 'CA', deadlineType: 'lien_enforcement', deadlineDate: '2026-03-15', daysRemaining: 19, status: 'urgent', amountAtRisk: 6400 },
  { id: 'd4', jobName: 'Commercial Build-Out — TechCorp', propertyAddress: '500 Commerce Dr, Chicago, IL', stateCode: 'IL', deadlineType: 'lien_filing', deadlineDate: '2026-04-10', daysRemaining: 45, status: 'upcoming', amountAtRisk: 85000 },
  { id: 'd5', jobName: 'HVAC Install — Martinez', propertyAddress: '7722 Maple Ct, Phoenix, AZ', stateCode: 'AZ', deadlineType: 'preliminary_notice', deadlineDate: '2026-02-25', daysRemaining: 1, status: 'critical', amountAtRisk: 15000 },
  { id: 'd6', jobName: 'Office Renovation — StartupHQ', propertyAddress: '188 Broadway, New York, NY', stateCode: 'NY', deadlineType: 'lien_filing', deadlineDate: '2026-06-20', daysRemaining: 116, status: 'upcoming', amountAtRisk: 45000 },
  { id: 'd7', jobName: 'Deck Build — Thompson', propertyAddress: '4510 Birch Rd, Denver, CO', stateCode: 'CO', deadlineType: 'notice_of_intent', deadlineDate: '2026-03-08', daysRemaining: 12, status: 'urgent', amountAtRisk: 9200 },
  { id: 'd8', jobName: 'Foundation Repair — Garcia', propertyAddress: '912 Vine St, San Antonio, TX', stateCode: 'TX', deadlineType: 'lien_enforcement', deadlineDate: '2026-02-20', daysRemaining: -4, status: 'overdue', amountAtRisk: 31000 },
  { id: 'd9', jobName: 'Siding Install — Lee', propertyAddress: '665 Spruce Ln, Seattle, WA', stateCode: 'WA', deadlineType: 'preliminary_notice', deadlineDate: '2026-03-22', daysRemaining: 26, status: 'upcoming', amountAtRisk: 11200 },
  { id: 'd10', jobName: 'Electrical Upgrade — Patel', propertyAddress: '330 Ash Dr, Atlanta, GA', stateCode: 'GA', deadlineType: 'lien_filing', deadlineDate: '2026-03-05', daysRemaining: 9, status: 'urgent', amountAtRisk: 7800 },
];

// ── Demo Data: Notices ────────────────────────────────────
interface PrelimNotice {
  id: string;
  jobName: string;
  propertyAddress: string;
  stateCode: string;
  ownerName: string;
  generalContractor: string;
  lenderName: string | null;
  amountDue: number;
  firstFurnishingDate: string;
  noticeSentDate: string | null;
  noticeDeadline: string;
  status: 'draft' | 'generated' | 'sent' | 'confirmed' | 'expired';
  deliveryMethod: 'certified_mail' | 'personal_service' | 'registered_mail' | null;
}

const DEMO_NOTICES: PrelimNotice[] = [
  { id: 'n1', jobName: 'Kitchen Remodel — Johnson', propertyAddress: '1420 Elm St, Austin, TX', stateCode: 'TX', ownerName: 'Robert Johnson', generalContractor: 'Self (Prime)', lenderName: 'First National Bank', amountDue: 24500, firstFurnishingDate: '2026-01-05', noticeSentDate: '2026-01-12', noticeDeadline: '2026-01-20', status: 'confirmed', deliveryMethod: 'certified_mail' },
  { id: 'n2', jobName: 'Roof Replacement — Davis', propertyAddress: '891 Oak Blvd, Tampa, FL', stateCode: 'FL', ownerName: 'Sarah Davis', generalContractor: 'Self (Prime)', lenderName: null, amountDue: 18750, firstFurnishingDate: '2026-02-01', noticeSentDate: null, noticeDeadline: '2026-03-18', status: 'draft', deliveryMethod: null },
  { id: 'n3', jobName: 'Bathroom Renovation — Kim', propertyAddress: '302 Pine Ave, Los Angeles, CA', stateCode: 'CA', ownerName: 'David Kim', generalContractor: 'Pacific Builders Inc.', lenderName: 'Wells Fargo', amountDue: 6400, firstFurnishingDate: '2026-01-20', noticeSentDate: '2026-01-28', noticeDeadline: '2026-02-09', status: 'sent', deliveryMethod: 'certified_mail' },
  { id: 'n4', jobName: 'HVAC Install — Martinez', propertyAddress: '7722 Maple Ct, Phoenix, AZ', stateCode: 'AZ', ownerName: 'Maria Martinez', generalContractor: 'Desert Build Corp.', lenderName: null, amountDue: 15000, firstFurnishingDate: '2026-02-10', noticeSentDate: null, noticeDeadline: '2026-03-02', status: 'generated', deliveryMethod: 'registered_mail' },
  { id: 'n5', jobName: 'Deck Build — Thompson', propertyAddress: '4510 Birch Rd, Denver, CO', stateCode: 'CO', ownerName: 'James Thompson', generalContractor: 'Self (Prime)', lenderName: 'Chase Bank', amountDue: 9200, firstFurnishingDate: '2026-02-15', noticeSentDate: null, noticeDeadline: '2026-02-25', status: 'draft', deliveryMethod: null },
  { id: 'n6', jobName: 'Siding Install — Lee', propertyAddress: '665 Spruce Ln, Seattle, WA', stateCode: 'WA', ownerName: 'Jennifer Lee', generalContractor: 'NW Construction Co.', lenderName: null, amountDue: 11200, firstFurnishingDate: '2026-01-30', noticeSentDate: '2026-02-15', noticeDeadline: '2026-03-31', status: 'sent', deliveryMethod: 'personal_service' },
];

// ── Stat Card Component ───────────────────────────────────
function StatCard({ label, value, icon: Icon, variant }: {
  label: string; value: string | number;
  icon: React.ComponentType<{ className?: string }>;
  variant?: 'success' | 'warning' | 'error' | 'default';
}) {
  const colors = {
    success: { text: 'text-emerald-400', bg: 'bg-emerald-500/10' },
    warning: { text: 'text-amber-400', bg: 'bg-amber-500/10' },
    error: { text: 'text-red-400', bg: 'bg-red-500/10' },
    default: { text: 'text-muted', bg: 'bg-secondary' },
  }[variant || 'default'];

  return (
    <Card>
      <CardContent className="p-4">
        <div className="flex items-center gap-3">
          <div className={`p-2.5 rounded-lg ${colors.bg}`}>
            <Icon className={`h-5 w-5 ${colors.text}`} />
          </div>
          <div>
            <p className={`text-2xl font-bold ${colors.text}`}>{value}</p>
            <p className="text-xs text-muted">{label}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

// ── Timeline Indicator ────────────────────────────────────
function DeadlineTimeline({ daysRemaining, label }: { daysRemaining: number; label: string }) {
  const pct = daysRemaining <= 0 ? 100 : Math.min(100, Math.max(0, 100 - (daysRemaining / 120) * 100));
  const barColor = daysRemaining <= 3 ? 'bg-red-500' : daysRemaining <= 14 ? 'bg-amber-500' : daysRemaining <= 30 ? 'bg-blue-500' : 'bg-slate-600';

  return (
    <div className="space-y-1">
      <div className="flex items-center justify-between text-xs">
        <span className="text-muted">{label}</span>
        <span className={urgencyColor(daysRemaining)}>
          {daysRemaining <= 0 ? `${Math.abs(daysRemaining)}d overdue` : `${daysRemaining}d remaining`}
        </span>
      </div>
      <div className="h-1.5 bg-secondary rounded-full overflow-hidden">
        <div className={`h-full rounded-full transition-all ${barColor}`} style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}

// ══════════════════════════════════════════════════════════
// ── MAIN PAGE COMPONENT ──────────────────────────────────
// ══════════════════════════════════════════════════════════
export default function LienProtectionPage() {
  const { t } = useTranslation();
  const { activeLiens, summary, loading, error, rules, getRuleForState } = useLienProtection();
  const [activeTab, setActiveTab] = useState<Tab>('dashboard');
  const [searchQuery, setSearchQuery] = useState('');
  const [expandedState, setExpandedState] = useState<string | null>(null);
  const [deadlineFilter, setDeadlineFilter] = useState<'all' | 'critical' | 'urgent' | 'upcoming' | 'overdue'>('all');
  const [waiverFilter, setWaiverFilter] = useState<'all' | 'pending_send' | 'sent' | 'received' | 'missing' | 'overdue' | 'flagged'>('all');
  const [noticeFilter, setNoticeFilter] = useState<'all' | 'draft' | 'generated' | 'sent' | 'confirmed' | 'expired'>('all');

  // ── Filtered Liens (dashboard) ──
  const filteredLiens = useMemo(() => {
    if (!searchQuery) return activeLiens;
    const q = searchQuery.toLowerCase();
    return activeLiens.filter(l =>
      l.property_address.toLowerCase().includes(q) ||
      l.state_code.toLowerCase().includes(q) ||
      l.status.toLowerCase().includes(q)
    );
  }, [activeLiens, searchQuery]);

  // ── Filtered State Rules ──
  const filteredRules = useMemo(() => {
    if (!searchQuery) return STATE_RULES_DATA;
    const q = searchQuery.toLowerCase();
    return STATE_RULES_DATA.filter(r =>
      r.stateName.toLowerCase().includes(q) ||
      r.stateCode.toLowerCase().includes(q) ||
      r.statutoryRef.toLowerCase().includes(q)
    );
  }, [searchQuery]);

  // ── Filtered Waivers ──
  const filteredWaivers = useMemo(() => {
    let list = DEMO_WAIVERS;
    if (waiverFilter === 'flagged') {
      list = list.filter(w => w.paymentReleasedWithoutWaiver);
    } else if (waiverFilter !== 'all') {
      list = list.filter(w => w.status === waiverFilter);
    }
    if (!searchQuery) return list;
    const q = searchQuery.toLowerCase();
    return list.filter(w =>
      w.jobName.toLowerCase().includes(q) ||
      w.partyName.toLowerCase().includes(q) ||
      w.propertyAddress.toLowerCase().includes(q)
    );
  }, [searchQuery, waiverFilter]);

  // ── Filtered Deadlines ──
  const filteredDeadlines = useMemo(() => {
    let list = DEMO_DEADLINES;
    if (deadlineFilter !== 'all') {
      list = list.filter(d => d.status === deadlineFilter);
    }
    if (!searchQuery) return list;
    const q = searchQuery.toLowerCase();
    return list.filter(d =>
      d.jobName.toLowerCase().includes(q) ||
      d.propertyAddress.toLowerCase().includes(q) ||
      d.stateCode.toLowerCase().includes(q)
    );
  }, [searchQuery, deadlineFilter]);

  // ── Filtered Notices ──
  const filteredNotices = useMemo(() => {
    let list = DEMO_NOTICES;
    if (noticeFilter !== 'all') {
      list = list.filter(n => n.status === noticeFilter);
    }
    if (!searchQuery) return list;
    const q = searchQuery.toLowerCase();
    return list.filter(n =>
      n.jobName.toLowerCase().includes(q) ||
      n.propertyAddress.toLowerCase().includes(q) ||
      n.ownerName.toLowerCase().includes(q)
    );
  }, [searchQuery, noticeFilter]);

  // ── Loading State ──
  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500" />
      </div>
    );
  }

  // ── Error State ──
  if (error) {
    return (
      <div className="p-6">
        <Card>
          <CardContent className="p-8 text-center">
            <AlertTriangle className="h-10 w-10 text-red-400 mx-auto mb-3" />
            <p className="text-red-400 font-medium">Failed to load lien data</p>
            <p className="text-sm text-muted mt-1">{error}</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  // ── Aggregate counts for deadline tabs ──
  const criticalCount = DEMO_DEADLINES.filter(d => d.status === 'critical').length;
  const urgentCount = DEMO_DEADLINES.filter(d => d.status === 'urgent').length;
  const overdueCount = DEMO_DEADLINES.filter(d => d.status === 'overdue').length;
  const flaggedWaiverCount = DEMO_WAIVERS.filter(w => w.paymentReleasedWithoutWaiver).length;

  return (
    <div className="p-6 space-y-6">
      <CommandPalette />
      {/* ── Header ── */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-main flex items-center gap-2">
            <Shield className="h-6 w-6 text-blue-400" />
            Lien Protection Engine
          </h1>
          <p className="text-sm text-muted mt-1">
            50-state rules, auto-deadline tracking, preliminary notices, waiver management
          </p>
        </div>
        <div className="flex items-center gap-2">
          {(criticalCount + overdueCount) > 0 && (
            <div className="flex items-center gap-1.5 px-3 py-1.5 bg-red-500/10 border border-red-500/20 rounded-lg">
              <Bell className="h-4 w-4 text-red-400" />
              <span className="text-sm font-medium text-red-400">
                {criticalCount + overdueCount} critical deadline{criticalCount + overdueCount !== 1 ? 's' : ''}
              </span>
            </div>
          )}
          <Button variant="primary" className="gap-2">
            <Plus className="h-4 w-4" />
            New Lien Record
          </Button>
        </div>
      </div>

      {/* ── Tabs ── */}
      <div className="flex items-center gap-1 border-b border-main pb-0">
        {TABS.map(tab => {
          const TabIcon = tab.icon;
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => { setActiveTab(tab.id); setSearchQuery(''); }}
              className={`flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 transition-colors ${
                isActive
                  ? 'border-blue-500 text-blue-400'
                  : 'border-transparent text-muted hover:text-main'
              }`}
            >
              <TabIcon className="h-4 w-4" />
              {tab.label}
              {tab.id === 'deadlines' && (criticalCount + overdueCount) > 0 && (
                <span className="ml-1 text-xs bg-red-500/20 text-red-400 px-1.5 py-0.5 rounded-full font-semibold">
                  {criticalCount + overdueCount}
                </span>
              )}
              {tab.id === 'waivers' && flaggedWaiverCount > 0 && (
                <span className="ml-1 text-xs bg-amber-500/20 text-amber-400 px-1.5 py-0.5 rounded-full font-semibold">
                  {flaggedWaiverCount}
                </span>
              )}
            </button>
          );
        })}
      </div>

      {/* ═══════════════════════════════════════════════════════ */}
      {/* ── TAB: DASHBOARD ──────────────────────────────────── */}
      {/* ═══════════════════════════════════════════════════════ */}
      {activeTab === 'dashboard' && (
        <div className="space-y-6">
          {/* Stats Row */}
          <div className="grid grid-cols-2 lg:grid-cols-6 gap-4">
            <StatCard label="Active Liens" value={summary.totalActive} icon={Shield} />
            <StatCard label="At Risk" value={summary.totalAtRisk} icon={AlertTriangle} variant="warning" />
            <StatCard label="Amount Owed" value={formatCurrency(summary.totalAmountOwed)} icon={DollarSign} variant="error" />
            <StatCard label="Urgent" value={summary.urgentCount} icon={Clock} variant="error" />
            <StatCard label="Liens Filed" value={summary.liensFiled} icon={FileText} />
            <StatCard label="Approaching" value={summary.approachingDeadlines} icon={Timer} variant="warning" />
          </div>

          {/* Search */}
          <SearchInput
            placeholder="Search liens by address, state, or status..."
            value={searchQuery}
            onChange={setSearchQuery}
          />

          {/* Active Liens List */}
          {filteredLiens.length === 0 ? (
            <Card>
              <CardContent className="p-8 text-center">
                <Shield className="h-12 w-12 text-muted opacity-50 mx-auto mb-3" />
                <p className="text-muted font-medium">No active lien records</p>
                <p className="text-sm text-muted mt-1">Lien tracking starts when jobs have outstanding payments</p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-3">
              {filteredLiens.map((lien: LienRecord) => {
                const rule = getRuleForState(lien.state_code);
                let daysToDeadline: number | null = null;
                let deadlineLabel = '';
                if (rule && lien.last_work_date) {
                  const deadline = new Date(lien.last_work_date);
                  deadline.setDate(deadline.getDate() + rule.lien_filing_deadline_days);
                  daysToDeadline = Math.ceil((deadline.getTime() - Date.now()) / 86400000);
                  deadlineLabel = 'Lien Filing';
                }

                return (
                  <Card key={lien.id} className="hover:border-accent/30 transition-colors">
                    <CardContent className="p-4">
                      <div className="flex items-start justify-between">
                        <div className="flex items-start gap-3 flex-1">
                          <div className="p-2 rounded-lg bg-secondary mt-0.5">
                            <Shield className="h-4 w-4 text-muted" />
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2 flex-wrap">
                              <h3 className="text-sm font-semibold text-main">{lien.property_address}</h3>
                              <Badge variant={statusVariant(lien.status)} size="sm">
                                {formatStatusLabel(lien.status)}
                              </Badge>
                              {lien.lien_filed && (
                                <Badge variant="purple" size="sm">Lien Filed</Badge>
                              )}
                            </div>
                            <div className="flex items-center gap-3 mt-1.5 text-xs text-muted flex-wrap">
                              <span className="flex items-center gap-1">
                                <MapPin className="h-3 w-3" />{lien.state_code}
                              </span>
                              {lien.amount_owed != null && lien.amount_owed > 0 && (
                                <span className="text-amber-400 font-medium">
                                  {formatCurrency(lien.amount_owed)} owed
                                </span>
                              )}
                              {lien.contract_amount != null && (
                                <span className="flex items-center gap-1">
                                  <DollarSign className="h-3 w-3" />
                                  Contract: {formatCurrency(lien.contract_amount)}
                                </span>
                              )}
                              {lien.last_work_date && (
                                <span className="flex items-center gap-1">
                                  <Calendar className="h-3 w-3" />
                                  Last work: {lien.last_work_date}
                                </span>
                              )}
                              {lien.preliminary_notice_sent && (
                                <span className="flex items-center gap-1 text-emerald-400">
                                  <CheckCircle className="h-3 w-3" />
                                  Prelim sent
                                </span>
                              )}
                            </div>

                            {/* Deadline Timeline */}
                            {daysToDeadline !== null && !lien.lien_filed && (
                              <div className="mt-3 max-w-md">
                                <DeadlineTimeline daysRemaining={daysToDeadline} label={deadlineLabel} />
                              </div>
                            )}
                          </div>
                        </div>

                        <div className="flex items-center gap-2 ml-4">
                          {daysToDeadline !== null && daysToDeadline > 0 && !lien.lien_filed && (
                            <div className={`text-xs font-semibold px-2 py-1 rounded ${
                              daysToDeadline <= 7 ? 'bg-red-500/10 text-red-400' :
                              daysToDeadline <= 30 ? 'bg-amber-500/10 text-amber-400' :
                              'bg-secondary text-muted'
                            }`}>
                              {daysToDeadline}d to file
                            </div>
                          )}
                          <Button variant="ghost" className="h-8 w-8 p-0">
                            <ChevronRight className="h-4 w-4 text-muted" />
                          </Button>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* ═══════════════════════════════════════════════════════ */}
      {/* ── TAB: STATE RULES ────────────────────────────────── */}
      {/* ═══════════════════════════════════════════════════════ */}
      {activeTab === 'rules' && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-semibold text-main">50-State Lien Rules Database</h2>
              <p className="text-sm text-muted">{STATE_RULES_DATA.length} states with detailed mechanic&apos;s lien requirements</p>
            </div>
          </div>

          <SearchInput
            placeholder="Search by state name, code, or statute..."
            value={searchQuery}
            onChange={setSearchQuery}
          />

          {filteredRules.length === 0 ? (
            <Card>
              <CardContent className="p-8 text-center">
                <BookOpen className="h-12 w-12 text-muted opacity-50 mx-auto mb-3" />
                <p className="text-muted font-medium">No states match your search</p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-2">
              {filteredRules.map(rule => {
                const isExpanded = expandedState === rule.stateCode;
                return (
                  <Card key={rule.stateCode} className="overflow-hidden">
                    <button
                      className="w-full text-left"
                      onClick={() => setExpandedState(isExpanded ? null : rule.stateCode)}
                    >
                      <CardContent className="p-4">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-3">
                            <div className="w-10 h-10 rounded-lg bg-blue-500/10 flex items-center justify-center">
                              <span className="text-sm font-bold text-blue-400">{rule.stateCode}</span>
                            </div>
                            <div>
                              <h3 className="text-sm font-semibold text-main">{rule.stateName}</h3>
                              <p className="text-xs text-muted">{rule.statutoryRef}</p>
                            </div>
                          </div>
                          <div className="flex items-center gap-3">
                            <div className="hidden sm:flex items-center gap-2">
                              {rule.prelimNoticeRequired && (
                                <Badge variant="info" size="sm">Prelim Required</Badge>
                              )}
                              {rule.notarizationRequired && (
                                <Badge variant="purple" size="sm">Notarization</Badge>
                              )}
                              {rule.residentialDifferent && (
                                <Badge variant="warning" size="sm">Res. Different</Badge>
                              )}
                            </div>
                            <div className="flex items-center gap-4 text-xs text-muted">
                              <span className="hidden md:inline">{rule.lienFilingDeadlineDays}d filing</span>
                              <span className="hidden md:inline">{rule.lienEnforcementDeadlineDays}d enforcement</span>
                            </div>
                            {isExpanded ? (
                              <ChevronDown className="h-4 w-4 text-muted" />
                            ) : (
                              <ChevronRight className="h-4 w-4 text-muted" />
                            )}
                          </div>
                        </div>
                      </CardContent>
                    </button>

                    {isExpanded && (
                      <div className="border-t border-main bg-surface/50">
                        <CardContent className="p-5 space-y-5">
                          {/* Key Deadlines Grid */}
                          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                            {/* Preliminary Notice */}
                            <div className="p-3 rounded-lg bg-secondary/50 border border-main">
                              <div className="flex items-center gap-2 mb-2">
                                <Send className="h-4 w-4 text-blue-400" />
                                <span className="text-xs font-semibold text-blue-400 uppercase tracking-wider">Preliminary Notice</span>
                              </div>
                              {rule.prelimNoticeRequired ? (
                                <>
                                  <p className="text-lg font-bold text-main">{rule.prelimNoticeDeadlineDays} days</p>
                                  <p className="text-xs text-muted mt-1">From: {rule.prelimNoticeFrom}</p>
                                </>
                              ) : (
                                <p className="text-sm text-muted">Not required in this state</p>
                              )}
                            </div>
                            {/* Lien Filing */}
                            <div className="p-3 rounded-lg bg-secondary/50 border border-main">
                              <div className="flex items-center gap-2 mb-2">
                                <Gavel className="h-4 w-4 text-amber-400" />
                                <span className="text-xs font-semibold text-amber-400 uppercase tracking-wider">Lien Filing</span>
                              </div>
                              <p className="text-lg font-bold text-main">{rule.lienFilingDeadlineDays} days</p>
                              <p className="text-xs text-muted mt-1">From: {rule.lienFilingFrom}</p>
                            </div>
                            {/* Enforcement */}
                            <div className="p-3 rounded-lg bg-secondary/50 border border-main">
                              <div className="flex items-center gap-2 mb-2">
                                <Scale className="h-4 w-4 text-red-400" />
                                <span className="text-xs font-semibold text-red-400 uppercase tracking-wider">Enforcement</span>
                              </div>
                              <p className="text-lg font-bold text-main">{rule.lienEnforcementDeadlineDays} days</p>
                              <p className="text-xs text-muted mt-1">From: {rule.lienEnforcementFrom}</p>
                            </div>
                          </div>

                          {/* Required Forms */}
                          <div>
                            <h4 className="text-xs font-semibold text-muted uppercase tracking-wider mb-2 flex items-center gap-1.5">
                              <FileText className="h-3.5 w-3.5" /> Required Forms
                            </h4>
                            <div className="flex flex-wrap gap-2">
                              {rule.requiredForms.map((form, i) => (
                                <span key={i} className="text-xs bg-secondary text-main px-2.5 py-1 rounded-md border border-main">
                                  {form}
                                </span>
                              ))}
                            </div>
                          </div>

                          {/* Recording Office & Details */}
                          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                              <h4 className="text-xs font-semibold text-muted uppercase tracking-wider mb-2 flex items-center gap-1.5">
                                <Landmark className="h-3.5 w-3.5" /> Recording Office
                              </h4>
                              <p className="text-sm text-main">{rule.recordingOffice}</p>
                            </div>
                            <div>
                              <h4 className="text-xs font-semibold text-muted uppercase tracking-wider mb-2 flex items-center gap-1.5">
                                <Info className="h-3.5 w-3.5" /> Key Attributes
                              </h4>
                              <div className="flex flex-wrap gap-2 text-xs">
                                <span className={`px-2 py-0.5 rounded ${rule.notarizationRequired ? 'bg-purple-500/10 text-purple-400' : 'bg-secondary text-muted'}`}>
                                  {rule.notarizationRequired ? 'Notarization Required' : 'No Notarization'}
                                </span>
                                <span className={`px-2 py-0.5 rounded ${rule.residentialDifferent ? 'bg-amber-500/10 text-amber-400' : 'bg-secondary text-muted'}`}>
                                  {rule.residentialDifferent ? 'Residential Rules Differ' : 'Same for All Projects'}
                                </span>
                              </div>
                            </div>
                          </div>

                          {/* Special Requirements */}
                          <div>
                            <h4 className="text-xs font-semibold text-muted uppercase tracking-wider mb-2 flex items-center gap-1.5">
                              <AlertTriangle className="h-3.5 w-3.5" /> Special Requirements
                            </h4>
                            <ul className="space-y-1.5">
                              {rule.specialRequirements.map((req, i) => (
                                <li key={i} className="flex items-start gap-2 text-sm text-main">
                                  <CircleDot className="h-3 w-3 text-muted opacity-50 mt-1 flex-shrink-0" />
                                  {req}
                                </li>
                              ))}
                            </ul>
                          </div>
                        </CardContent>
                      </div>
                    )}
                  </Card>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* ═══════════════════════════════════════════════════════ */}
      {/* ── TAB: WAIVERS ────────────────────────────────────── */}
      {/* ═══════════════════════════════════════════════════════ */}
      {activeTab === 'waivers' && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-semibold text-main">Lien Waiver Management</h2>
              <p className="text-sm text-muted">Track conditional and unconditional waivers sent and received</p>
            </div>
            <Button variant="primary" className="gap-2">
              <Plus className="h-4 w-4" />
              Request Waiver
            </Button>
          </div>

          {/* Waiver Stats */}
          <div className="grid grid-cols-2 lg:grid-cols-5 gap-3">
            <Card>
              <CardContent className="p-3 text-center">
                <p className="text-xl font-bold text-main">{DEMO_WAIVERS.length}</p>
                <p className="text-xs text-muted">Total Waivers</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-3 text-center">
                <p className="text-xl font-bold text-emerald-400">{DEMO_WAIVERS.filter(w => w.status === 'received').length}</p>
                <p className="text-xs text-muted">Received</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-3 text-center">
                <p className="text-xl font-bold text-blue-400">{DEMO_WAIVERS.filter(w => w.status === 'sent').length}</p>
                <p className="text-xs text-muted">Sent / Pending</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-3 text-center">
                <p className="text-xl font-bold text-red-400">{DEMO_WAIVERS.filter(w => w.status === 'overdue' || w.status === 'missing').length}</p>
                <p className="text-xs text-muted">Overdue / Missing</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-3 text-center">
                <p className="text-xl font-bold text-amber-400">{flaggedWaiverCount}</p>
                <p className="text-xs text-muted">Payment w/o Waiver</p>
              </CardContent>
            </Card>
          </div>

          {/* Filter Pills */}
          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-xs text-muted mr-1">Filter:</span>
            {([
              { key: 'all', label: 'All' },
              { key: 'pending_send', label: 'Pending' },
              { key: 'sent', label: 'Sent' },
              { key: 'received', label: 'Received' },
              { key: 'missing', label: 'Missing' },
              { key: 'overdue', label: 'Overdue' },
              { key: 'flagged', label: 'Flagged' },
            ] as { key: typeof waiverFilter; label: string }[]).map(f => (
              <button
                key={f.key}
                onClick={() => setWaiverFilter(f.key)}
                className={`text-xs px-3 py-1 rounded-full border transition-colors ${
                  waiverFilter === f.key
                    ? 'border-blue-500 bg-blue-500/10 text-blue-400'
                    : 'border-main text-muted hover:border-accent/30'
                }`}
              >
                {f.label}
              </button>
            ))}
          </div>

          <SearchInput
            placeholder="Search by job, party name, or address..."
            value={searchQuery}
            onChange={setSearchQuery}
          />

          {/* Waiver List */}
          {filteredWaivers.length === 0 ? (
            <Card>
              <CardContent className="p-8 text-center">
                <ClipboardCheck className="h-12 w-12 text-muted opacity-50 mx-auto mb-3" />
                <p className="text-muted font-medium">No waivers match your filters</p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-2">
              {filteredWaivers.map(waiver => {
                const waiverTypeLabel: Record<WaiverType, string> = {
                  conditional_progress: 'Conditional Progress',
                  unconditional_progress: 'Unconditional Progress',
                  conditional_final: 'Conditional Final',
                  unconditional_final: 'Unconditional Final',
                };
                const statusMap: Record<WaiverStatus, { variant: 'success' | 'info' | 'warning' | 'error' | 'secondary'; label: string }> = {
                  pending_send: { variant: 'secondary', label: 'Pending Send' },
                  sent: { variant: 'info', label: 'Sent' },
                  received: { variant: 'success', label: 'Received' },
                  missing: { variant: 'error', label: 'Missing' },
                  overdue: { variant: 'error', label: 'Overdue' },
                };

                return (
                  <Card key={waiver.id} className={`${waiver.paymentReleasedWithoutWaiver ? 'border-amber-500/30' : ''}`}>
                    <CardContent className="p-4">
                      <div className="flex items-start justify-between gap-4">
                        <div className="flex items-start gap-3 flex-1 min-w-0">
                          <div className={`p-2 rounded-lg mt-0.5 ${
                            waiver.paymentReleasedWithoutWaiver ? 'bg-amber-500/10' : 'bg-secondary'
                          }`}>
                            {waiver.paymentReleasedWithoutWaiver ? (
                              <FileWarning className="h-4 w-4 text-amber-400" />
                            ) : (
                              <ClipboardCheck className="h-4 w-4 text-muted" />
                            )}
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2 flex-wrap">
                              <h3 className="text-sm font-semibold text-main">{waiver.partyName}</h3>
                              <Badge variant={statusMap[waiver.status].variant} size="sm">
                                {statusMap[waiver.status].label}
                              </Badge>
                              <Badge variant="secondary" size="sm">
                                {waiverTypeLabel[waiver.waiverType]}
                              </Badge>
                            </div>
                            <div className="flex items-center gap-3 mt-1 text-xs text-muted flex-wrap">
                              <span>{waiver.jobName}</span>
                              <span className="flex items-center gap-1">
                                <MapPin className="h-3 w-3" />{waiver.propertyAddress}
                              </span>
                              <span className="flex items-center gap-1">
                                <Building2 className="h-3 w-3" />{waiver.partyType === 'gc' ? 'General Contractor' : waiver.partyType === 'subcontractor' ? 'Subcontractor' : 'Supplier'}
                              </span>
                            </div>
                            {waiver.paymentReleasedWithoutWaiver && (
                              <div className="flex items-center gap-1.5 mt-2 text-xs text-amber-400 bg-amber-500/5 px-2 py-1 rounded w-fit">
                                <TriangleAlert className="h-3 w-3" />
                                Payment released without waiver on file
                              </div>
                            )}
                          </div>
                        </div>
                        <div className="text-right flex-shrink-0">
                          <p className="text-sm font-semibold text-main">{formatCurrency(waiver.amount)}</p>
                          <div className="text-xs text-muted mt-1 space-y-0.5">
                            {waiver.dateSent && <p>Sent: {waiver.dateSent}</p>}
                            {waiver.dateReceived && <p className="text-emerald-400">Received: {waiver.dateReceived}</p>}
                          </div>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* ═══════════════════════════════════════════════════════ */}
      {/* ── TAB: DEADLINES ──────────────────────────────────── */}
      {/* ═══════════════════════════════════════════════════════ */}
      {activeTab === 'deadlines' && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-semibold text-main">Deadline Calendar</h2>
              <p className="text-sm text-muted">Auto-calculated lien deadlines with urgency alerts</p>
            </div>
          </div>

          {/* Urgency Summary Cards */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
            <button onClick={() => setDeadlineFilter('overdue')} className="text-left">
              <Card className={`${deadlineFilter === 'overdue' ? 'border-red-500/50' : ''} hover:border-accent/30 transition-colors`}>
                <CardContent className="p-3">
                  <div className="flex items-center gap-2">
                    <div className="p-1.5 rounded bg-red-500/10">
                      <XCircle className="h-4 w-4 text-red-400" />
                    </div>
                    <div>
                      <p className="text-lg font-bold text-red-400">{overdueCount}</p>
                      <p className="text-xs text-muted">Overdue</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </button>
            <button onClick={() => setDeadlineFilter('critical')} className="text-left">
              <Card className={`${deadlineFilter === 'critical' ? 'border-red-500/50' : ''} hover:border-accent/30 transition-colors`}>
                <CardContent className="p-3">
                  <div className="flex items-center gap-2">
                    <div className="p-1.5 rounded bg-red-500/10">
                      <AlertTriangle className="h-4 w-4 text-red-400" />
                    </div>
                    <div>
                      <p className="text-lg font-bold text-red-400">{criticalCount}</p>
                      <p className="text-xs text-muted">Critical (0-7d)</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </button>
            <button onClick={() => setDeadlineFilter('urgent')} className="text-left">
              <Card className={`${deadlineFilter === 'urgent' ? 'border-amber-500/50' : ''} hover:border-accent/30 transition-colors`}>
                <CardContent className="p-3">
                  <div className="flex items-center gap-2">
                    <div className="p-1.5 rounded bg-amber-500/10">
                      <Clock className="h-4 w-4 text-amber-400" />
                    </div>
                    <div>
                      <p className="text-lg font-bold text-amber-400">{urgentCount}</p>
                      <p className="text-xs text-muted">Urgent (8-14d)</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </button>
            <button onClick={() => setDeadlineFilter(deadlineFilter === 'all' ? 'upcoming' : 'all')} className="text-left">
              <Card className={`${deadlineFilter === 'upcoming' || deadlineFilter === 'all' ? 'border-accent/30' : ''} hover:border-accent/30 transition-colors`}>
                <CardContent className="p-3">
                  <div className="flex items-center gap-2">
                    <div className="p-1.5 rounded bg-blue-500/10">
                      <Calendar className="h-4 w-4 text-blue-400" />
                    </div>
                    <div>
                      <p className="text-lg font-bold text-blue-400">{DEMO_DEADLINES.filter(d => d.status === 'upcoming').length}</p>
                      <p className="text-xs text-muted">Upcoming (15+d)</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </button>
          </div>

          {/* Active Filter Indicator */}
          {deadlineFilter !== 'all' && (
            <div className="flex items-center gap-2">
              <Badge variant="info" size="sm">Filtered: {deadlineFilter}</Badge>
              <button onClick={() => setDeadlineFilter('all')} className="text-xs text-muted hover:text-main">
                Clear filter
              </button>
            </div>
          )}

          <SearchInput
            placeholder="Search deadlines by job, address, or state..."
            value={searchQuery}
            onChange={setSearchQuery}
          />

          {/* Deadline List */}
          {filteredDeadlines.length === 0 ? (
            <Card>
              <CardContent className="p-8 text-center">
                <CalendarClock className="h-12 w-12 text-muted opacity-50 mx-auto mb-3" />
                <p className="text-muted font-medium">No deadlines match your filters</p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-2">
              {filteredDeadlines
                .sort((a, b) => a.daysRemaining - b.daysRemaining)
                .map(deadline => {
                  const typeLabels: Record<string, string> = {
                    preliminary_notice: 'Preliminary Notice',
                    lien_filing: 'Lien Filing',
                    lien_enforcement: 'Lien Enforcement',
                    notice_of_intent: 'Notice of Intent',
                  };
                  const typeIcons: Record<string, React.ComponentType<{ className?: string }>> = {
                    preliminary_notice: Send,
                    lien_filing: Gavel,
                    lien_enforcement: Scale,
                    notice_of_intent: FileText,
                  };
                  const TypeIcon = typeIcons[deadline.deadlineType] || FileText;

                  return (
                    <Card key={deadline.id} className={`${
                      deadline.status === 'overdue' ? 'border-red-500/30' :
                      deadline.status === 'critical' ? 'border-red-500/20' :
                      ''
                    }`}>
                      <CardContent className="p-4">
                        <div className="flex items-start justify-between gap-4">
                          <div className="flex items-start gap-3 flex-1 min-w-0">
                            <div className={`p-2 rounded-lg mt-0.5 ${
                              deadline.status === 'overdue' ? 'bg-red-500/10' :
                              deadline.status === 'critical' ? 'bg-red-500/10' :
                              deadline.status === 'urgent' ? 'bg-amber-500/10' :
                              'bg-secondary'
                            }`}>
                              <TypeIcon className={`h-4 w-4 ${
                                deadline.status === 'overdue' || deadline.status === 'critical' ? 'text-red-400' :
                                deadline.status === 'urgent' ? 'text-amber-400' :
                                'text-blue-400'
                              }`} />
                            </div>
                            <div className="flex-1 min-w-0">
                              <div className="flex items-center gap-2 flex-wrap">
                                <h3 className="text-sm font-semibold text-main">{deadline.jobName}</h3>
                                <Badge variant={urgencyVariant(deadline.daysRemaining)} size="sm">
                                  {typeLabels[deadline.deadlineType]}
                                </Badge>
                                {deadline.status === 'overdue' && (
                                  <Badge variant="error" size="sm">OVERDUE</Badge>
                                )}
                              </div>
                              <div className="flex items-center gap-3 mt-1 text-xs text-muted">
                                <span className="flex items-center gap-1">
                                  <MapPin className="h-3 w-3" />{deadline.propertyAddress}
                                </span>
                                <span className="flex items-center gap-1">
                                  <Landmark className="h-3 w-3" />{deadline.stateCode}
                                </span>
                              </div>

                              {/* Timeline bar */}
                              <div className="mt-3 max-w-sm">
                                <DeadlineTimeline
                                  daysRemaining={deadline.daysRemaining}
                                  label={`Deadline: ${deadline.deadlineDate}`}
                                />
                              </div>

                              {/* Urgency Alerts */}
                              {deadline.daysRemaining <= 7 && deadline.daysRemaining > 0 && (
                                <div className="flex items-center gap-4 mt-2 text-xs">
                                  {[30, 14, 7, 3, 1].filter(d => d >= deadline.daysRemaining).map(d => (
                                    <span key={d} className={`flex items-center gap-1 ${
                                      d <= 3 ? 'text-red-400' : d <= 7 ? 'text-red-400' : d <= 14 ? 'text-amber-400' : 'text-blue-400'
                                    }`}>
                                      <Bell className="h-3 w-3" />
                                      {d}d alert triggered
                                    </span>
                                  ))}
                                </div>
                              )}
                            </div>
                          </div>
                          <div className="text-right flex-shrink-0">
                            <p className={`text-lg font-bold ${urgencyColor(deadline.daysRemaining)}`}>
                              {deadline.daysRemaining <= 0
                                ? `${Math.abs(deadline.daysRemaining)}d late`
                                : `${deadline.daysRemaining}d`
                              }
                            </p>
                            <p className="text-xs text-muted mt-0.5">
                              {formatCurrency(deadline.amountAtRisk)} at risk
                            </p>
                            <Button variant="ghost" className="mt-2 h-7 text-xs gap-1 px-2">
                              <Eye className="h-3 w-3" />
                              View
                            </Button>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  );
                })}
            </div>
          )}

          {/* Total At Risk Summary */}
          <Card>
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <DollarSign className="h-5 w-5 text-amber-400" />
                  <span className="text-sm font-medium text-main">Total Amount at Risk (Filtered)</span>
                </div>
                <span className="text-xl font-bold text-amber-400">
                  {formatCurrency(filteredDeadlines.reduce((s, d) => s + d.amountAtRisk, 0))}
                </span>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* ═══════════════════════════════════════════════════════ */}
      {/* ── TAB: NOTICES ────────────────────────────────────── */}
      {/* ═══════════════════════════════════════════════════════ */}
      {activeTab === 'notices' && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-semibold text-main">Preliminary Notice Generation</h2>
              <p className="text-sm text-muted">Generate, track, and send preliminary notices pre-filled from job data</p>
            </div>
            <Button variant="primary" className="gap-2">
              <FilePlus className="h-4 w-4" />
              Generate Notice
            </Button>
          </div>

          {/* Notice Stats */}
          <div className="grid grid-cols-2 lg:grid-cols-5 gap-3">
            <Card>
              <CardContent className="p-3 text-center">
                <p className="text-xl font-bold text-main">{DEMO_NOTICES.length}</p>
                <p className="text-xs text-muted">Total Notices</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-3 text-center">
                <p className="text-xl font-bold text-muted">{DEMO_NOTICES.filter(n => n.status === 'draft').length}</p>
                <p className="text-xs text-muted">Drafts</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-3 text-center">
                <p className="text-xl font-bold text-blue-400">{DEMO_NOTICES.filter(n => n.status === 'generated').length}</p>
                <p className="text-xs text-muted">Generated</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-3 text-center">
                <p className="text-xl font-bold text-amber-400">{DEMO_NOTICES.filter(n => n.status === 'sent').length}</p>
                <p className="text-xs text-muted">Sent</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-3 text-center">
                <p className="text-xl font-bold text-emerald-400">{DEMO_NOTICES.filter(n => n.status === 'confirmed').length}</p>
                <p className="text-xs text-muted">Confirmed</p>
              </CardContent>
            </Card>
          </div>

          {/* Filter Pills */}
          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-xs text-muted mr-1">Filter:</span>
            {([
              { key: 'all', label: 'All' },
              { key: 'draft', label: 'Draft' },
              { key: 'generated', label: 'Generated' },
              { key: 'sent', label: 'Sent' },
              { key: 'confirmed', label: 'Confirmed' },
              { key: 'expired', label: 'Expired' },
            ] as { key: typeof noticeFilter; label: string }[]).map(f => (
              <button
                key={f.key}
                onClick={() => setNoticeFilter(f.key)}
                className={`text-xs px-3 py-1 rounded-full border transition-colors ${
                  noticeFilter === f.key
                    ? 'border-blue-500 bg-blue-500/10 text-blue-400'
                    : 'border-main text-muted hover:border-accent/30'
                }`}
              >
                {f.label}
              </button>
            ))}
          </div>

          <SearchInput
            placeholder="Search by job, address, or owner name..."
            value={searchQuery}
            onChange={setSearchQuery}
          />

          {/* Notice List */}
          {filteredNotices.length === 0 ? (
            <Card>
              <CardContent className="p-8 text-center">
                <Send className="h-12 w-12 text-muted opacity-50 mx-auto mb-3" />
                <p className="text-muted font-medium">No notices match your filters</p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-2">
              {filteredNotices.map(notice => {
                const statusConfig: Record<string, { variant: 'success' | 'info' | 'warning' | 'error' | 'secondary' | 'default'; label: string }> = {
                  draft: { variant: 'secondary', label: 'Draft' },
                  generated: { variant: 'info', label: 'Generated' },
                  sent: { variant: 'warning', label: 'Sent' },
                  confirmed: { variant: 'success', label: 'Confirmed' },
                  expired: { variant: 'error', label: 'Expired' },
                };
                const cfg = statusConfig[notice.status] || statusConfig.draft;

                return (
                  <Card key={notice.id}>
                    <CardContent className="p-4">
                      <div className="flex items-start justify-between gap-4">
                        <div className="flex items-start gap-3 flex-1 min-w-0">
                          <div className={`p-2 rounded-lg mt-0.5 ${
                            notice.status === 'confirmed' ? 'bg-emerald-500/10' :
                            notice.status === 'sent' ? 'bg-amber-500/10' :
                            notice.status === 'generated' ? 'bg-blue-500/10' :
                            'bg-secondary'
                          }`}>
                            <Send className={`h-4 w-4 ${
                              notice.status === 'confirmed' ? 'text-emerald-400' :
                              notice.status === 'sent' ? 'text-amber-400' :
                              notice.status === 'generated' ? 'text-blue-400' :
                              'text-muted'
                            }`} />
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2 flex-wrap">
                              <h3 className="text-sm font-semibold text-main">{notice.jobName}</h3>
                              <Badge variant={cfg.variant} size="sm">{cfg.label}</Badge>
                              <Badge variant="secondary" size="sm">{notice.stateCode}</Badge>
                            </div>

                            {/* Property & Parties */}
                            <div className="flex items-center gap-3 mt-1.5 text-xs text-muted flex-wrap">
                              <span className="flex items-center gap-1">
                                <MapPin className="h-3 w-3" />{notice.propertyAddress}
                              </span>
                              <span className="flex items-center gap-1">
                                <Building2 className="h-3 w-3" />Owner: {notice.ownerName}
                              </span>
                              <span className="flex items-center gap-1">
                                <Stamp className="h-3 w-3" />GC: {notice.generalContractor}
                              </span>
                              {notice.lenderName && (
                                <span className="flex items-center gap-1">
                                  <Landmark className="h-3 w-3" />Lender: {notice.lenderName}
                                </span>
                              )}
                            </div>

                            {/* Key Dates & Amount */}
                            <div className="flex items-center gap-4 mt-2 text-xs flex-wrap">
                              <span className="text-muted">
                                First furnishing: <span className="text-main">{notice.firstFurnishingDate}</span>
                              </span>
                              <span className="text-muted">
                                Deadline: <span className={`font-medium ${
                                  new Date(notice.noticeDeadline) < new Date() ? 'text-red-400' : 'text-main'
                                }`}>{notice.noticeDeadline}</span>
                              </span>
                              <span className="text-amber-400 font-medium">
                                {formatCurrency(notice.amountDue)} due
                              </span>
                            </div>

                            {/* Delivery Method */}
                            {notice.deliveryMethod && (
                              <div className="mt-2">
                                <span className="text-xs bg-secondary text-main px-2 py-0.5 rounded border border-main">
                                  {notice.deliveryMethod === 'certified_mail' ? 'Certified Mail' :
                                   notice.deliveryMethod === 'personal_service' ? 'Personal Service' :
                                   'Registered Mail'}
                                </span>
                              </div>
                            )}
                          </div>
                        </div>

                        <div className="flex flex-col items-end gap-2 flex-shrink-0">
                          {notice.noticeSentDate && (
                            <p className="text-xs text-muted">
                              Sent: <span className="text-main">{notice.noticeSentDate}</span>
                            </p>
                          )}
                          <div className="flex items-center gap-2">
                            {notice.status === 'draft' && (
                              <Button variant="primary" className="h-7 text-xs gap-1 px-2">
                                <FilePlus className="h-3 w-3" />
                                Generate
                              </Button>
                            )}
                            {notice.status === 'generated' && (
                              <Button variant="primary" className="h-7 text-xs gap-1 px-2">
                                <Send className="h-3 w-3" />
                                Send
                              </Button>
                            )}
                            {(notice.status === 'sent' || notice.status === 'confirmed') && (
                              <Button variant="ghost" className="h-7 text-xs gap-1 px-2">
                                <Download className="h-3 w-3" />
                                PDF
                              </Button>
                            )}
                            <Button variant="ghost" className="h-7 text-xs gap-1 px-2">
                              <Eye className="h-3 w-3" />
                              View
                            </Button>
                          </div>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          )}

          {/* Lien Filing Preparation Section */}
          <Card>
            <CardHeader>
              <CardTitle className="text-sm font-semibold text-main flex items-center gap-2">
                <Gavel className="h-4 w-4 text-amber-400" />
                Lien Filing Preparation
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <p className="text-sm text-muted">
                When a payment dispute cannot be resolved and deadlines are approaching, prepare a formal mechanic&apos;s lien filing with all required information from the job record.
              </p>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                <div className="p-3 rounded-lg bg-secondary/50 border border-main">
                  <div className="flex items-center gap-2 mb-2">
                    <FileText className="h-4 w-4 text-blue-400" />
                    <span className="text-xs font-semibold text-blue-400">Step 1</span>
                  </div>
                  <p className="text-sm text-main font-medium">Verify Job Data</p>
                  <p className="text-xs text-muted mt-1">Property address, owner info, work dates, and amounts are pulled from the job record automatically.</p>
                </div>
                <div className="p-3 rounded-lg bg-secondary/50 border border-main">
                  <div className="flex items-center gap-2 mb-2">
                    <Download className="h-4 w-4 text-amber-400" />
                    <span className="text-xs font-semibold text-amber-400">Step 2</span>
                  </div>
                  <p className="text-sm text-main font-medium">Generate Lien Document</p>
                  <p className="text-xs text-muted mt-1">State-specific lien form is generated with all required fields, legal descriptions, and statutory references.</p>
                </div>
                <div className="p-3 rounded-lg bg-secondary/50 border border-main">
                  <div className="flex items-center gap-2 mb-2">
                    <Landmark className="h-4 w-4 text-emerald-400" />
                    <span className="text-xs font-semibold text-emerald-400">Step 3</span>
                  </div>
                  <p className="text-sm text-main font-medium">File with County</p>
                  <p className="text-xs text-muted mt-1">Filing instructions for the specific state recording office, with notarization requirements if applicable.</p>
                </div>
              </div>
              <div className="flex items-center gap-2 pt-2">
                <Button variant="outline" className="gap-2">
                  <Gavel className="h-4 w-4" />
                  Prepare Lien Filing
                </Button>
                <span className="text-xs text-muted">Select a job with outstanding payment to begin</span>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}
