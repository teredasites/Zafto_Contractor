'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapLead } from './mappers';
import type { LeadData } from './mappers';

export function useLeads() {
  const [leads, setLeads] = useState<LeadData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchLeads = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('leads')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setLeads((data || []).map(mapLead));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load leads';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchLeads();

    const supabase = getSupabase();
    const channel = supabase
      .channel('leads-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'leads' }, () => {
        fetchLeads();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchLeads]);

  const createLead = async (input: {
    name: string;
    email?: string;
    phone?: string;
    companyName?: string;
    source?: string;
    value?: number;
    notes?: string;
    address?: { street: string; city: string; state: string; zip: string };
    trade?: string;
    urgency?: string;
    tags?: string[];
    nextFollowUp?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('leads')
      .insert({
        company_id: companyId,
        created_by_user_id: user.id,
        name: input.name,
        email: input.email || null,
        phone: input.phone || null,
        company_name: input.companyName || null,
        source: input.source?.toLowerCase() || 'website',
        stage: 'new',
        value: input.value || 0,
        notes: input.notes || null,
        address: input.address?.street || null,
        city: input.address?.city || null,
        state: input.address?.state || null,
        zip_code: input.address?.zip || null,
        trade: input.trade || null,
        urgency: input.urgency || 'normal',
        tags: input.tags || [],
        next_follow_up: input.nextFollowUp ? new Date(input.nextFollowUp).toISOString() : null,
      })
      .select('id')
      .single();

    if (err) throw err;
    fetchLeads();
    return result.id;
  };

  const updateLeadStage = async (id: string, stage: string) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = { stage };
    if (stage === 'contacted') updateData.last_contacted_at = new Date().toISOString();
    if (stage === 'won') updateData.won_at = new Date().toISOString();
    if (stage === 'lost') updateData.lost_at = new Date().toISOString();
    const { error: err } = await supabase.from('leads').update(updateData).eq('id', id);
    if (err) throw err;
    fetchLeads();
  };

  const updateLead = async (id: string, data: Partial<LeadData>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.email !== undefined) updateData.email = data.email;
    if (data.phone !== undefined) updateData.phone = data.phone;
    if (data.companyName !== undefined) updateData.company_name = data.companyName;
    if (data.source !== undefined) updateData.source = data.source;
    if (data.value !== undefined) updateData.value = data.value;
    if (data.notes !== undefined) updateData.notes = data.notes;
    if (data.nextFollowUp !== undefined) updateData.next_follow_up = data.nextFollowUp ? data.nextFollowUp.toISOString() : null;
    if (data.assignedToUserId !== undefined) updateData.assigned_to_user_id = data.assignedToUserId;
    const { error: err } = await supabase.from('leads').update(updateData).eq('id', id);
    if (err) throw err;
    fetchLeads();
  };

  const deleteLead = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase.from('leads').update({ deleted_at: new Date().toISOString() }).eq('id', id);
    if (err) throw err;
    fetchLeads();
  };

  // Convert lead to customer — checks for existing match by email/phone
  const convertLeadToCustomer = async (leadId: string): Promise<string | null> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    const lead = leads.find((l) => l.id === leadId);
    if (!lead) throw new Error('Lead not found');

    // Check for existing customer by email or phone
    let existingCustomer: Record<string, unknown> | null = null;
    if (lead.email) {
      const { data } = await supabase
        .from('customers')
        .select('id')
        .eq('company_id', companyId)
        .eq('email', lead.email)
        .is('deleted_at', null)
        .single();
      if (data) existingCustomer = data;
    }
    if (!existingCustomer && lead.phone) {
      const { data } = await supabase
        .from('customers')
        .select('id')
        .eq('company_id', companyId)
        .eq('phone', lead.phone)
        .is('deleted_at', null)
        .single();
      if (data) existingCustomer = data;
    }

    let customerId: string;
    if (existingCustomer) {
      customerId = existingCustomer.id as string;
    } else {
      // Create new customer from lead
      const { data: newCustomer, error: custErr } = await supabase
        .from('customers')
        .insert({
          company_id: companyId,
          name: lead.name,
          email: lead.email || null,
          phone: lead.phone || null,
          source: lead.source || 'lead',
          address: lead.address || null,
        })
        .select('id')
        .single();
      if (custErr || !newCustomer) throw new Error('Failed to create customer');
      customerId = newCustomer.id;
    }

    // Update lead with conversion info
    await supabase
      .from('leads')
      .update({
        stage: 'won',
        won_at: new Date().toISOString(),
        converted_to_customer_id: customerId,
      })
      .eq('id', leadId);

    fetchLeads();
    return customerId;
  };

  // Convert lead to job — creates customer if needed, then creates job pre-filled from lead
  const convertLeadToJob = async (leadId: string): Promise<{ customerId: string; jobId: string }> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    const lead = leads.find((l) => l.id === leadId);
    if (!lead) throw new Error('Lead not found');

    // Get or create customer
    const customerId = await convertLeadToCustomer(leadId);
    if (!customerId) throw new Error('Failed to convert lead to customer');

    // Create job pre-filled from lead data
    const { data: job, error: jobErr } = await supabase
      .from('jobs')
      .insert({
        company_id: companyId,
        customer_id: customerId,
        created_by_user_id: user.id,
        title: `${lead.name} - ${lead.notes?.substring(0, 50) || 'New Job'}`,
        description: lead.notes || null,
        status: 'pending',
        address: lead.address || null,
        city: lead.city || null,
        state: lead.state || null,
        zip_code: lead.zipCode || null,
        trade: lead.tags?.[0] || null,
        priority: lead.tags?.includes('urgent') ? 'high' : 'normal',
      })
      .select('id')
      .single();

    if (jobErr || !job) throw new Error('Failed to create job');

    // Update lead with job link
    await supabase.from('leads').update({ converted_to_job_id: job.id }).eq('id', leadId);

    fetchLeads();
    return { customerId, jobId: job.id };
  };

  // Mark lost with reason
  const markLost = async (id: string, reason: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('leads')
      .update({
        stage: 'lost',
        lost_at: new Date().toISOString(),
        lost_reason: reason,
      })
      .eq('id', id);
    if (err) throw err;
    fetchLeads();
  };

  // Log activity on lead
  const logActivity = async (leadId: string, type: string, note: string) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Update last_contacted_at
    await supabase.from('leads').update({ last_contacted_at: new Date().toISOString() }).eq('id', leadId);

    // Try to insert into lead_activities if table exists, otherwise store in notes
    try {
      await supabase.from('lead_activities').insert({
        lead_id: leadId,
        company_id: user.app_metadata?.company_id,
        user_id: user.id,
        type,
        note,
      });
    } catch {
      // Table may not exist — append to lead notes as fallback
      const lead = leads.find(l => l.id === leadId);
      const timestamp = new Date().toLocaleString();
      const updatedNotes = `${lead?.notes || ''}\n[${timestamp}] ${type}: ${note}`.trim();
      await supabase.from('leads').update({ notes: updatedNotes }).eq('id', leadId);
    }

    fetchLeads();
  };

  return {
    leads, loading, error,
    createLead, updateLeadStage, updateLead,
    convertLeadToCustomer, convertLeadToJob,
    markLost, logActivity, deleteLead,
    refetch: fetchLeads,
  };
}
