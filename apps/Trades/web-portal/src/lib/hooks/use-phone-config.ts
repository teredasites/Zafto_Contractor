'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface DaySchedule {
  open: string;
  close: string;
}

export interface BusinessHours {
  monday: DaySchedule | null;
  tuesday: DaySchedule | null;
  wednesday: DaySchedule | null;
  thursday: DaySchedule | null;
  friday: DaySchedule | null;
  saturday: DaySchedule | null;
  sunday: DaySchedule | null;
}

export interface Holiday {
  date: string;
  name: string;
  recurring: boolean;
}

export interface MenuOption {
  key: string;
  label: string;
  action: 'ring_user' | 'ring_group' | 'voicemail' | 'ai_receptionist' | 'external' | 'submenu';
  targetId?: string;
  externalNumber?: string;
  submenuOptions?: MenuOption[];
}

export interface AiReceptionistConfig {
  personality: 'professional' | 'friendly' | 'casual' | 'bilingual';
  primaryLanguage: string;
  secondaryLanguage: string | null;
  voice: 'male' | 'female' | 'neutral';
  speed: 'normal' | 'slow';
  customGreeting: string | null;
  servicesOffered: string[];
  serviceArea: string[];
  pricingGuidance: Record<string, { canQuote: boolean; min?: number; max?: number }>;
  capabilities: {
    checkAvailability: boolean;
    bookAppointments: boolean;
    lookupJobStatus: boolean;
    provideEtas: boolean;
    takeMessages: boolean;
    transferToTeam: boolean;
    emergencyRouting: boolean;
  };
}

export interface PhoneConfig {
  id: string;
  companyId: string;
  businessHours: BusinessHours;
  holidays: Holiday[];
  autoAttendantEnabled: boolean;
  greetingType: 'tts' | 'recorded' | 'ai_generated';
  greetingText: string | null;
  greetingAudioPath: string | null;
  greetingVoice: string;
  afterHoursGreetingText: string | null;
  afterHoursGreetingAudioPath: string | null;
  menuOptions: MenuOption[];
  emergencyEnabled: boolean;
  emergencyRingGroupId: string | null;
  callRecordingMode: 'off' | 'all' | 'on_demand' | 'inbound_only';
  recordingConsentState: string | null;
  recordingRetentionDays: number;
  aiReceptionistEnabled: boolean;
  aiReceptionistConfig: AiReceptionistConfig;
  createdAt: string;
  updatedAt: string;
}

const DEFAULT_AI_CONFIG: AiReceptionistConfig = {
  personality: 'professional',
  primaryLanguage: 'en',
  secondaryLanguage: null,
  voice: 'female',
  speed: 'normal',
  customGreeting: null,
  servicesOffered: [],
  serviceArea: [],
  pricingGuidance: {},
  capabilities: {
    checkAvailability: true,
    bookAppointments: true,
    lookupJobStatus: true,
    provideEtas: true,
    takeMessages: true,
    transferToTeam: true,
    emergencyRouting: false,
  },
};

function mapConfig(row: Record<string, unknown>): PhoneConfig {
  const aiConfig = (row.ai_receptionist_config as AiReceptionistConfig) || DEFAULT_AI_CONFIG;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    businessHours: (row.business_hours as BusinessHours) || {
      monday: { open: '07:00', close: '17:00' },
      tuesday: { open: '07:00', close: '17:00' },
      wednesday: { open: '07:00', close: '17:00' },
      thursday: { open: '07:00', close: '17:00' },
      friday: { open: '07:00', close: '17:00' },
      saturday: null,
      sunday: null,
    },
    holidays: (row.holidays as Holiday[]) || [],
    autoAttendantEnabled: row.auto_attendant_enabled as boolean,
    greetingType: (row.greeting_type as PhoneConfig['greetingType']) || 'tts',
    greetingText: row.greeting_text as string | null,
    greetingAudioPath: row.greeting_audio_path as string | null,
    greetingVoice: (row.greeting_voice as string) || 'professional_female',
    afterHoursGreetingText: row.after_hours_greeting_text as string | null,
    afterHoursGreetingAudioPath: row.after_hours_greeting_audio_path as string | null,
    menuOptions: (row.menu_options as MenuOption[]) || [],
    emergencyEnabled: row.emergency_enabled as boolean,
    emergencyRingGroupId: row.emergency_ring_group_id as string | null,
    callRecordingMode: (row.call_recording_mode as PhoneConfig['callRecordingMode']) || 'off',
    recordingConsentState: row.recording_consent_state as string | null,
    recordingRetentionDays: Number(row.recording_retention_days) || 90,
    aiReceptionistEnabled: row.ai_receptionist_enabled as boolean,
    aiReceptionistConfig: { ...DEFAULT_AI_CONFIG, ...aiConfig },
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

export function usePhoneConfig() {
  const [config, setConfig] = useState<PhoneConfig | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const fetchConfig = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('phone_config')
        .select('*')
        .limit(1)
        .maybeSingle();

      if (err) throw err;
      setConfig(data ? mapConfig(data) : null);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load phone config');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchConfig();

    const supabase = getSupabase();
    const channel = supabase
      .channel('phone-config-rt')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'phone_config' }, () => fetchConfig())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchConfig]);

  const updateConfig = async (updates: Partial<Record<string, unknown>>) => {
    setSaving(true);
    try {
      const supabase = getSupabase();
      if (config) {
        const { error: err } = await supabase
          .from('phone_config')
          .update(updates)
          .eq('id', config.id);
        if (err) throw err;
      } else {
        const { data: { user } } = await supabase.auth.getUser();
        const companyId = user?.app_metadata?.company_id;
        if (!companyId) throw new Error('No company');
        const { error: err } = await supabase
          .from('phone_config')
          .insert({ company_id: companyId, ...updates });
        if (err) throw err;
      }
      await fetchConfig();
    } catch (e: unknown) {
      throw e instanceof Error ? e : new Error('Failed to save');
    } finally {
      setSaving(false);
    }
  };

  const updateBusinessHours = (hours: BusinessHours) =>
    updateConfig({ business_hours: hours });

  const updateHolidays = (holidays: Holiday[]) =>
    updateConfig({ holidays });

  const updateMenuOptions = (options: MenuOption[]) =>
    updateConfig({ menu_options: options });

  const updateAiConfig = (aiConfig: AiReceptionistConfig) =>
    updateConfig({ ai_receptionist_config: aiConfig });

  const updateRecording = (mode: string, retentionDays: number, consentState: string | null) =>
    updateConfig({
      call_recording_mode: mode,
      recording_retention_days: retentionDays,
      recording_consent_state: consentState,
    });

  return {
    config,
    loading,
    error,
    saving,
    updateConfig,
    updateBusinessHours,
    updateHolidays,
    updateMenuOptions,
    updateAiConfig,
    updateRecording,
    refetch: fetchConfig,
  };
}

// ============================================================
// Trade Presets
// ============================================================

export interface TradePreset {
  id: string;
  name: string;
  description: string;
  trade: string;
  menuOptions: MenuOption[];
  aiConfig: Partial<AiReceptionistConfig>;
  emergencyEnabled: boolean;
  afterHoursGreeting: string;
  greetingText: string;
}

export const TRADE_PRESETS: TradePreset[] = [
  {
    id: 'plumber',
    name: 'Plumber',
    description: 'Emergency routing for burst pipes/floods, after-hours AI, standard IVR menu',
    trade: 'plumbing',
    menuOptions: [
      { key: '1', label: 'Service Call', action: 'ring_group' },
      { key: '2', label: 'New Estimate', action: 'ring_user' },
      { key: '3', label: 'Billing', action: 'ring_user' },
    ],
    aiConfig: {
      personality: 'professional',
      capabilities: {
        checkAvailability: true,
        bookAppointments: true,
        lookupJobStatus: true,
        provideEtas: true,
        takeMessages: true,
        transferToTeam: true,
        emergencyRouting: true,
      },
    },
    emergencyEnabled: true,
    afterHoursGreeting: "Thank you for calling. We're currently closed but our AI assistant can help you with emergencies, scheduling, and job status.",
    greetingText: "Thank you for calling! Press 1 for a service call, 2 for a new estimate, or 3 for billing.",
  },
  {
    id: 'electrician',
    name: 'Electrician',
    description: 'Safety disclaimer, emergency routing for no power/sparking, AI answers with safety awareness',
    trade: 'electrical',
    menuOptions: [
      { key: '1', label: 'Emergency (No Power/Sparking)', action: 'ring_group' },
      { key: '2', label: 'Service Call', action: 'ring_group' },
      { key: '3', label: 'New Construction', action: 'ring_user' },
    ],
    aiConfig: {
      personality: 'professional',
      capabilities: {
        checkAvailability: true,
        bookAppointments: true,
        lookupJobStatus: true,
        provideEtas: true,
        takeMessages: true,
        transferToTeam: true,
        emergencyRouting: true,
      },
    },
    emergencyEnabled: true,
    afterHoursGreeting: "For electrical emergencies involving sparking, burning smell, or complete power loss, press 1 for our emergency line. Otherwise, our AI assistant can help.",
    greetingText: "Thank you for calling! If this is an electrical emergency, press 1 immediately. For service calls press 2, for new construction press 3.",
  },
  {
    id: 'hvac',
    name: 'HVAC',
    description: 'Seasonal greetings, AI checks equipment warranty, emergency heating/cooling',
    trade: 'hvac',
    menuOptions: [
      { key: '1', label: 'No Heat / No AC Emergency', action: 'ring_group' },
      { key: '2', label: 'Schedule Service', action: 'ai_receptionist' },
      { key: '3', label: 'Billing', action: 'ring_user' },
    ],
    aiConfig: {
      personality: 'friendly',
      capabilities: {
        checkAvailability: true,
        bookAppointments: true,
        lookupJobStatus: true,
        provideEtas: true,
        takeMessages: true,
        transferToTeam: true,
        emergencyRouting: true,
      },
    },
    emergencyEnabled: true,
    afterHoursGreeting: "Thank you for calling. For heating or cooling emergencies, press 1. For all other inquiries, our AI assistant can help you schedule service.",
    greetingText: "Thank you for calling! Press 1 for a heating or cooling emergency, 2 to schedule service, or 3 for billing.",
  },
  {
    id: 'general_contractor',
    name: 'General Contractor',
    description: 'Deeper IVR menu, AI looks up project schedule, subcontractor routing',
    trade: 'general',
    menuOptions: [
      { key: '1', label: 'New Project Inquiry', action: 'ring_user' },
      { key: '2', label: 'Existing Project Status', action: 'ai_receptionist' },
      { key: '3', label: 'Billing / Invoices', action: 'ring_user' },
      { key: '4', label: 'Subcontractor Line', action: 'ring_group' },
    ],
    aiConfig: {
      personality: 'professional',
      capabilities: {
        checkAvailability: true,
        bookAppointments: false,
        lookupJobStatus: true,
        provideEtas: true,
        takeMessages: true,
        transferToTeam: true,
        emergencyRouting: false,
      },
    },
    emergencyEnabled: false,
    afterHoursGreeting: "Thank you for calling. We're currently closed. Our AI assistant can check your project status or take a message.",
    greetingText: "Thank you for calling! Press 1 for a new project, 2 for existing project status, 3 for billing, or 4 for our subcontractor line.",
  },
  {
    id: 'restoration',
    name: 'Restoration',
    description: '24/7 AI ON, emergency always rings, urgency detection highest, auto-TPA assignment',
    trade: 'restoration',
    menuOptions: [
      { key: '1', label: 'Emergency (Water/Fire/Mold)', action: 'ring_group' },
      { key: '2', label: 'Existing Claim Status', action: 'ai_receptionist' },
      { key: '3', label: 'Insurance / TPA', action: 'ring_user' },
    ],
    aiConfig: {
      personality: 'professional',
      capabilities: {
        checkAvailability: true,
        bookAppointments: true,
        lookupJobStatus: true,
        provideEtas: true,
        takeMessages: true,
        transferToTeam: true,
        emergencyRouting: true,
      },
    },
    emergencyEnabled: true,
    afterHoursGreeting: "Thank you for calling. We provide 24/7 emergency restoration services. Press 1 for an emergency, or our AI assistant can help with claim status.",
    greetingText: "Thank you for calling! For water, fire, or mold emergencies, press 1. For existing claim status press 2, or press 3 for insurance inquiries.",
  },
];
