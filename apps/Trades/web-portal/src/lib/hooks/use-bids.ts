'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapBid } from './mappers';
import type { Bid } from '@/types';

export function useBids() {
  const [bids, setBids] = useState<Bid[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchBids = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('bids')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setBids((data || []).map(mapBid));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load bids';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchBids();

    const supabase = getSupabase();
    const channel = supabase
      .channel('bids-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'bids' }, () => {
        fetchBids();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchBids]);

  const createBid = async (data: Partial<Bid>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // Auto-generate bid number
    const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const { count } = await supabase
      .from('bids')
      .select('*', { count: 'exact', head: true })
      .is('deleted_at', null)
      .ilike('bid_number', `BID-${dateStr}-%`);

    const seq = String((count || 0) + 1).padStart(3, '0');
    const bidNumber = `BID-${dateStr}-${seq}`;

    const lineItemsJson = {
      options: data.options || [],
      addOns: data.addOns || [],
    };

    const { data: result, error: err } = await supabase
      .from('bids')
      .insert({
        company_id: companyId,
        created_by_user_id: user.id,
        customer_id: data.customerId || null,
        bid_number: bidNumber,
        title: data.title || '',
        customer_name: data.customerName || '',
        customer_email: data.customerEmail || null,
        customer_address: data.customerAddress?.street || null,
        line_items: lineItemsJson,
        scope_of_work: data.scopeOfWork || null,
        terms: data.termsAndConditions || null,
        subtotal: data.subtotal || 0,
        tax_rate: data.taxRate || 0,
        tax_amount: data.tax || 0,
        total: data.total || 0,
        valid_until: data.validUntil ? new Date(data.validUntil).toISOString() : null,
        status: 'draft',
        notes: data.internalNotes || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    fetchBids();
    return result.id;
  };

  const updateBid = async (id: string, data: Partial<Bid>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.title !== undefined) updateData.title = data.title;
    if (data.status !== undefined) updateData.status = data.status;
    if (data.options !== undefined || data.addOns !== undefined) {
      updateData.line_items = { options: data.options || [], addOns: data.addOns || [] };
    }
    if (data.subtotal !== undefined) updateData.subtotal = data.subtotal;
    if (data.taxRate !== undefined) updateData.tax_rate = data.taxRate;
    if (data.tax !== undefined) updateData.tax_amount = data.tax;
    if (data.total !== undefined) updateData.total = data.total;
    if (data.scopeOfWork !== undefined) updateData.scope_of_work = data.scopeOfWork;
    if (data.termsAndConditions !== undefined) updateData.terms = data.termsAndConditions;
    if (data.validUntil !== undefined) {
      updateData.valid_until = data.validUntil ? new Date(data.validUntil).toISOString() : null;
    }

    const { error: err } = await supabase.from('bids').update(updateData).eq('id', id);
    if (err) throw err;
    fetchBids();
  };

  const sendBid = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('bids')
      .update({ status: 'sent', sent_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;

    // U22: Actually send email via SendGrid EF
    try {
      await supabase.functions.invoke('sendgrid-email', {
        body: { action: 'send_bid', entityId: id },
      });
    } catch {
      // Email send is best-effort — don't fail the status update
    }
    fetchBids();
  };

  const acceptBid = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('bids')
      .update({ status: 'accepted', accepted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
    fetchBids();
  };

  const rejectBid = async (id: string, reason?: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('bids')
      .update({
        status: 'rejected',
        rejected_at: new Date().toISOString(),
        rejection_reason: reason || null,
      })
      .eq('id', id);
    if (err) throw err;
    fetchBids();
  };

  const convertToJob = async (bidId: string): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // Fetch bid data
    const { data: bid, error: fetchErr } = await supabase.from('bids').select('*').eq('id', bidId).is('deleted_at', null).single();
    if (fetchErr) throw fetchErr;

    // Create job from bid
    const { data: job, error: jobErr } = await supabase
      .from('jobs')
      .insert({
        company_id: companyId,
        created_by_user_id: user.id,
        customer_id: bid.customer_id,
        title: bid.title || 'Job from bid',
        description: bid.scope_of_work || null,
        status: 'scheduled',
        priority: 'normal',
        address: bid.customer_address || '',
        customer_name: bid.customer_name || '',
        customer_email: bid.customer_email || null,
        customer_phone: null,
        estimated_amount: bid.total || 0,
        quote_id: bidId,
        tags: [],
      })
      .select('id')
      .single();

    if (jobErr) throw jobErr;

    // Update bid to converted
    await supabase
      .from('bids')
      .update({ status: 'accepted', job_id: job.id })
      .eq('id', bidId);

    fetchBids();
    return job.id;
  };

  const deleteBid = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('bids')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
    fetchBids();
  };

  // Convert estimate to bid — reads estimate + line items, creates bid
  const convertEstimateToBid = async (estimateId: string): Promise<string | null> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    // Fetch estimate
    const { data: estimate, error: estErr } = await supabase
      .from('estimates')
      .select('*')
      .eq('id', estimateId)
      .is('deleted_at', null)
      .single();
    if (estErr || !estimate) throw new Error('Estimate not found');

    // Fetch estimate line items
    const { data: lineItems } = await supabase
      .from('estimate_line_items')
      .select('*')
      .eq('estimate_id', estimateId)
      .is('deleted_at', null)
      .order('sort_order', { ascending: true });

    // Build bid options from line items
    const options = [{
      name: 'Option A',
      description: estimate.title || 'From Estimate',
      lineItems: (lineItems || []).map((li: Record<string, unknown>) => ({
        description: (li.description as string) || '',
        quantity: (li.quantity as number) || 1,
        unit: (li.unit_code as string) || 'each',
        unitPrice: ((li.material_cost as number) || 0) + ((li.labor_cost as number) || 0) + ((li.equipment_cost as number) || 0),
        category: 'materials',
      })),
    }];

    const subtotal = (estimate.subtotal as number) || 0;
    const taxRate = (estimate.tax_percent as number) || 0;
    const tax = subtotal * (taxRate / 100);

    // Generate bid number
    const today = new Date();
    const dateStr = today.toISOString().slice(2, 10).replace(/-/g, '');
    const { count } = await supabase
      .from('bids')
      .select('id', { count: 'exact', head: true })
      .eq('company_id', companyId)
      .is('deleted_at', null);
    const seq = String((count || 0) + 1).padStart(3, '0');
    const bidNumber = `BID-${dateStr}-${seq}`;

    const { data: bid, error: bidErr } = await supabase
      .from('bids')
      .insert({
        company_id: companyId,
        bid_number: bidNumber,
        customer_id: estimate.customer_id || null,
        job_id: estimate.job_id || null,
        lead_id: estimate.lead_id || null,
        title: estimate.title || 'From Estimate',
        status: 'draft',
        scope_of_work: estimate.notes || '',
        options: options,
        subtotal,
        tax_rate: taxRate,
        tax,
        total: (estimate.grand_total as number) || subtotal + tax,
        valid_until: new Date(Date.now() + 30 * 86400000).toISOString(),
      })
      .select('id')
      .single();
    if (bidErr) throw bidErr;
    fetchBids();
    return bid?.id || null;
  };

  // Reject with win/loss analysis — record competitor, price difference, detailed reason
  const rejectWithAnalysis = async (id: string, analysis: {
    reason: string;
    competitor?: string;
    competitorPrice?: number;
    feedback?: string;
  }) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('bids')
      .update({
        status: 'rejected',
        rejected_at: new Date().toISOString(),
        rejection_reason: analysis.reason,
        lost_to_competitor: analysis.competitor || null,
        competitor_price: analysis.competitorPrice || null,
        loss_feedback: analysis.feedback || null,
      })
      .eq('id', id);
    if (err) throw err;
    fetchBids();
  };

  // Save bid as template
  const saveBidAsTemplate = async (bidId: string, templateName: string) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;

    const bid = bids.find(b => b.id === bidId);
    if (!bid) throw new Error('Bid not found');

    const { error: err } = await supabase.from('bid_templates').insert({
      company_id: companyId,
      name: templateName,
      scope_of_work: bid.scopeOfWork || '',
      terms: bid.termsAndConditions || '',
      line_items: { options: bid.options, addOns: bid.addOns },
      created_by_user_id: user.id,
    });
    if (err) throw err;
  };

  // Create bid from template
  const createBidFromTemplate = async (templateId: string, customerId?: string): Promise<string | null> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company');

    const { data: template, error: tErr } = await supabase
      .from('bid_templates')
      .select('*')
      .eq('id', templateId)
      .is('deleted_at', null)
      .single();
    if (tErr || !template) throw new Error('Template not found');

    const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const { count } = await supabase
      .from('bids')
      .select('*', { count: 'exact', head: true })
      .is('deleted_at', null)
      .ilike('bid_number', `BID-${dateStr}-%`);
    const seq = String((count || 0) + 1).padStart(3, '0');

    const lineItems = template.line_items as Record<string, unknown> || {};
    const options = (lineItems.options || []) as Array<Record<string, unknown>>;
    const subtotal = options.reduce((sum: number, opt: Record<string, unknown>) => {
      const items = (opt.lineItems || []) as Array<Record<string, unknown>>;
      return sum + items.reduce((s: number, li: Record<string, unknown>) =>
        s + ((li.quantity as number) || 1) * ((li.unitPrice as number) || 0), 0);
    }, 0);

    const { data: bid, error: err } = await supabase
      .from('bids')
      .insert({
        company_id: companyId,
        created_by_user_id: user.id,
        customer_id: customerId || null,
        bid_number: `BID-${dateStr}-${seq}`,
        title: template.name || 'From Template',
        scope_of_work: template.scope_of_work || '',
        terms: template.terms || '',
        line_items: template.line_items || {},
        subtotal,
        tax_rate: 0,
        tax_amount: 0,
        total: subtotal,
        valid_until: new Date(Date.now() + 30 * 86400000).toISOString(),
        status: 'draft',
      })
      .select('id')
      .single();
    if (err) throw err;
    fetchBids();
    return bid?.id || null;
  };

  return {
    bids,
    loading,
    error,
    createBid,
    updateBid,
    sendBid,
    acceptBid,
    rejectBid,
    rejectWithAnalysis,
    convertToJob,
    convertEstimateToBid,
    saveBidAsTemplate,
    createBidFromTemplate,
    deleteBid,
    refetch: fetchBids,
  };
}

export function useBid(id: string | undefined) {
  const [bid, setBid] = useState<Bid | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) {
      setLoading(false);
      return;
    }

    let ignore = false;

    const fetchBid = async () => {
      try {
        setLoading(true);
        setError(null);
        const supabase = getSupabase();
        const { data, error: err } = await supabase.from('bids').select('*').eq('id', id).is('deleted_at', null).single();

        if (ignore) return;
        if (err) throw err;
        setBid(data ? mapBid(data) : null);
      } catch (e: unknown) {
        if (ignore) return;
        const msg = e instanceof Error ? e.message : 'Bid not found';
        setError(msg);
      } finally {
        if (!ignore) setLoading(false);
      }
    };

    fetchBid();
    return () => { ignore = true; };
  }, [id]);

  return { bid, loading, error };
}
