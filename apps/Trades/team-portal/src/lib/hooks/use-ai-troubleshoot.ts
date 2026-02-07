'use client';

import { useState, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ==================== TYPES ====================

export type Trade =
  | 'electrical'
  | 'hvac'
  | 'plumbing'
  | 'carpentry'
  | 'roofing'
  | 'painting'
  | 'general';

export type SkillLevel = 'apprentice' | 'journeyman' | 'master';

export type CodeSystem = 'NEC' | 'IRC' | 'IPC' | 'IMC' | 'OSHA';

export interface AiMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: number;
}

export interface DiagnoseOptions {
  trade: Trade;
  issue: string;
  equipmentBrand?: string;
  equipmentModel?: string;
  buildingType?: string;
}

export interface DiagnosisResult {
  diagnosis: string;
  probability: string;
  codeReferences: string[];
  safetyWarnings: string[];
  steps: string[];
  partsNeeded: string[];
  specialistAdvisory: string | null;
}

export interface PhotoAnalysisResult {
  overallCondition: number;
  issues: {
    title: string;
    description: string;
    severity: 'low' | 'medium' | 'high' | 'critical';
    location: string;
  }[];
  priorityRepairs: string[];
  codeViolations: string[];
  annotations: string[];
}

export interface PartIdentification {
  name: string;
  manufacturer: string;
  partNumber: string;
  description: string;
  alternatives: { name: string; partNumber: string; manufacturer: string }[];
  suppliers: string[];
  priceRange: string;
  compatibilityNotes: string;
}

export interface RepairGuideResult {
  title: string;
  safetyPrecautions: { text: string; severity: 'info' | 'warning' | 'critical' }[];
  steps: { instruction: string; tip?: string; warning?: string }[];
  tools: string[];
  materials: string[];
  codeReferences: string[];
  whenToStop: string;
  estimatedTime: string;
}

export interface CodeLookupResult {
  code: string;
  title: string;
  system: string;
  fullText: string;
  explanation: string;
  examples: string[];
  relatedCodes: string[];
}

// ==================== EDGE FUNCTION CALLER ====================

async function callEdgeFunction<T>(
  functionName: string,
  payload: Record<string, unknown>
): Promise<T> {
  const supabase = getSupabase();
  const { data: sessionData } = await supabase.auth.getSession();
  const token = sessionData?.session?.access_token;

  if (!token) {
    throw new Error('Authentication required. Please sign in again.');
  }

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!supabaseUrl) {
    throw new Error('Service configuration error.');
  }

  const response = await fetch(
    `${supabaseUrl}/functions/v1/${functionName}`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify(payload),
    }
  );

  if (!response.ok) {
    const errorBody = await response.text();
    let message = 'AI service unavailable. Please try again.';
    try {
      const parsed = JSON.parse(errorBody);
      if (parsed.error) message = parsed.error;
    } catch {
      // Use default message
    }
    throw new Error(message);
  }

  return response.json() as Promise<T>;
}

// ==================== HOOK ====================

export function useAiTroubleshoot() {
  const [messages, setMessages] = useState<AiMessage[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // --- Diagnose ---
  const diagnose = useCallback(async (options: DiagnoseOptions): Promise<DiagnosisResult | null> => {
    setLoading(true);
    setError(null);
    try {
      const result = await callEdgeFunction<DiagnosisResult>('ai-troubleshoot', {
        action: 'diagnose',
        trade: options.trade,
        issue: options.issue,
        equipmentBrand: options.equipmentBrand || undefined,
        equipmentModel: options.equipmentModel || undefined,
        buildingType: options.buildingType || undefined,
      });

      // Add to conversation history
      const userMsg: AiMessage = {
        id: crypto.randomUUID(),
        role: 'user',
        content: `[Diagnose] Trade: ${options.trade}, Issue: ${options.issue}`,
        timestamp: Date.now(),
      };
      const aiMsg: AiMessage = {
        id: crypto.randomUUID(),
        role: 'assistant',
        content: result.diagnosis,
        timestamp: Date.now(),
      };
      setMessages((prev) => [...prev, userMsg, aiMsg]);

      return result;
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Diagnosis failed. Please try again.';
      setError(msg);
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  // --- Photo Analysis ---
  const analyzePhoto = useCallback(async (
    photoUrl: string,
    trade?: Trade
  ): Promise<PhotoAnalysisResult | null> => {
    setLoading(true);
    setError(null);
    try {
      const result = await callEdgeFunction<PhotoAnalysisResult>('ai-photo-diagnose', {
        action: 'analyze_photo',
        photoUrl,
        trade: trade || undefined,
      });

      const userMsg: AiMessage = {
        id: crypto.randomUUID(),
        role: 'user',
        content: `[Photo Analysis] ${trade ? `Trade: ${trade}` : 'General analysis'}`,
        timestamp: Date.now(),
      };
      const aiMsg: AiMessage = {
        id: crypto.randomUUID(),
        role: 'assistant',
        content: `Found ${result.issues.length} issue(s). Condition: ${result.overallCondition}/5`,
        timestamp: Date.now(),
      };
      setMessages((prev) => [...prev, userMsg, aiMsg]);

      return result;
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Photo analysis failed. Please try again.';
      setError(msg);
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  // --- Parts ID ---
  const identifyPart = useCallback(async (
    description: string,
    photoUrl?: string
  ): Promise<PartIdentification | null> => {
    setLoading(true);
    setError(null);
    try {
      const result = await callEdgeFunction<PartIdentification>('ai-parts-identify', {
        action: 'identify_part',
        description,
        photoUrl: photoUrl || undefined,
      });

      const userMsg: AiMessage = {
        id: crypto.randomUUID(),
        role: 'user',
        content: `[Parts ID] ${description}`,
        timestamp: Date.now(),
      };
      const aiMsg: AiMessage = {
        id: crypto.randomUUID(),
        role: 'assistant',
        content: `Identified: ${result.name} (${result.manufacturer})`,
        timestamp: Date.now(),
      };
      setMessages((prev) => [...prev, userMsg, aiMsg]);

      return result;
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Part identification failed. Please try again.';
      setError(msg);
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  // --- Repair Guide ---
  const getRepairGuide = useCallback(async (
    trade: Trade,
    issue: string,
    skillLevel?: SkillLevel
  ): Promise<RepairGuideResult | null> => {
    setLoading(true);
    setError(null);
    try {
      const result = await callEdgeFunction<RepairGuideResult>('ai-repair-guide', {
        action: 'repair_guide',
        trade,
        issue,
        skillLevel: skillLevel || 'journeyman',
      });

      const userMsg: AiMessage = {
        id: crypto.randomUUID(),
        role: 'user',
        content: `[Repair Guide] Trade: ${trade}, Issue: ${issue}, Skill: ${skillLevel || 'journeyman'}`,
        timestamp: Date.now(),
      };
      const aiMsg: AiMessage = {
        id: crypto.randomUUID(),
        role: 'assistant',
        content: result.title,
        timestamp: Date.now(),
      };
      setMessages((prev) => [...prev, userMsg, aiMsg]);

      return result;
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Guide generation failed. Please try again.';
      setError(msg);
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  // --- Code Lookup ---
  const lookupCode = useCallback(async (
    query: string,
    system?: CodeSystem
  ): Promise<CodeLookupResult | null> => {
    setLoading(true);
    setError(null);
    try {
      const result = await callEdgeFunction<CodeLookupResult>('ai-troubleshoot', {
        action: 'code_lookup',
        query,
        system: system || undefined,
      });

      const userMsg: AiMessage = {
        id: crypto.randomUUID(),
        role: 'user',
        content: `[Code Lookup] ${query}${system ? ` (${system})` : ''}`,
        timestamp: Date.now(),
      };
      const aiMsg: AiMessage = {
        id: crypto.randomUUID(),
        role: 'assistant',
        content: `${result.code}: ${result.title}`,
        timestamp: Date.now(),
      };
      setMessages((prev) => [...prev, userMsg, aiMsg]);

      return result;
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Code lookup failed. Please try again.';
      setError(msg);
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  // --- Clear History ---
  const clearHistory = useCallback(() => {
    setMessages([]);
    setError(null);
  }, []);

  return {
    messages,
    loading,
    error,
    diagnose,
    analyzePhoto,
    identifyPart,
    getRepairGuide,
    lookupCode,
    clearHistory,
  };
}
