'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================
// Procurement Hook — Vendor Directory, PO Line Items, Receiving
// NOTE: This is SEPARATE from use-vendors.ts (ZBooks accounting vendors).
// This hooks into vendor_directory (procurement) + po_line_items + receiving_records.
// ============================================================

export interface ProcurementVendor {
  id: string;
  companyId: string;
  name: string;
  contactName: string | null;
  email: string | null;
  phone: string | null;
  address: string | null;
  city: string | null;
  state: string | null;
  zipCode: string | null;
  website: string | null;
  paymentTerms: string;
  creditLimit: number | null;
  taxId: string | null;
  vendorType: string;
  tradeCategories: string[];
  rating: number | null;
  notes: string | null;
  isActive: boolean;
  unwrangleVendorId: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface POLineItem {
  id: string;
  companyId: string;
  purchaseOrderId: string;
  itemDescription: string;
  quantity: number;
  unit: string | null;
  unitPrice: number;
  totalPrice: number;
  receivedQuantity: number;
  catalogItemId: string | null;
  catalogSource: string | null;
  status: string;
  notes: string | null;
  createdAt: string;
}

export interface ReceivingRecord {
  id: string;
  companyId: string;
  purchaseOrderId: string;
  receivedByUserId: string | null;
  receivedAt: string;
  deliveryMethod: string | null;
  trackingNumber: string | null;
  packingSlipPath: string | null;
  items: { line_item_id: string; quantity_received: number; condition: string; notes: string }[];
  allItemsReceived: boolean;
  discrepancyNotes: string | null;
  photos: string[];
  createdAt: string;
}

export const VENDOR_TYPES = [
  'supplier', 'subcontractor', 'rental', 'distributor', 'manufacturer', 'other',
] as const;

export const VENDOR_TYPE_LABELS: Record<string, string> = {
  supplier: 'Supplier',
  subcontractor: 'Subcontractor',
  rental: 'Rental',
  distributor: 'Distributor',
  manufacturer: 'Manufacturer',
  other: 'Other',
};

export const PAYMENT_TERMS = [
  'cod', 'net_15', 'net_30', 'net_45', 'net_60', 'net_90', 'prepaid',
] as const;

export const PAYMENT_TERMS_LABELS: Record<string, string> = {
  cod: 'COD',
  net_15: 'Net 15',
  net_30: 'Net 30',
  net_45: 'Net 45',
  net_60: 'Net 60',
  net_90: 'Net 90',
  prepaid: 'Prepaid',
};

export const LINE_ITEM_STATUSES = ['pending', 'partial', 'received', 'cancelled'] as const;

function mapVendor(row: Record<string, unknown>): ProcurementVendor {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    name: row.name as string,
    contactName: row.contact_name as string | null,
    email: row.email as string | null,
    phone: row.phone as string | null,
    address: row.address as string | null,
    city: row.city as string | null,
    state: row.state as string | null,
    zipCode: row.zip_code as string | null,
    website: row.website as string | null,
    paymentTerms: (row.payment_terms as string) || 'net_30',
    creditLimit: row.credit_limit as number | null,
    taxId: row.tax_id as string | null,
    vendorType: (row.vendor_type as string) || 'supplier',
    tradeCategories: (row.trade_categories as string[]) || [],
    rating: row.rating as number | null,
    notes: row.notes as string | null,
    isActive: row.is_active as boolean,
    unwrangleVendorId: row.unwrangle_vendor_id as string | null,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

function mapLineItem(row: Record<string, unknown>): POLineItem {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    purchaseOrderId: row.purchase_order_id as string,
    itemDescription: row.item_description as string,
    quantity: (row.quantity as number) || 0,
    unit: row.unit as string | null,
    unitPrice: (row.unit_price as number) || 0,
    totalPrice: (row.total_price as number) || 0,
    receivedQuantity: (row.received_quantity as number) || 0,
    catalogItemId: row.catalog_item_id as string | null,
    catalogSource: row.catalog_source as string | null,
    status: (row.status as string) || 'pending',
    notes: row.notes as string | null,
    createdAt: row.created_at as string,
  };
}

function mapReceivingRecord(row: Record<string, unknown>): ReceivingRecord {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    purchaseOrderId: row.purchase_order_id as string,
    receivedByUserId: row.received_by_user_id as string | null,
    receivedAt: row.received_at as string,
    deliveryMethod: row.delivery_method as string | null,
    trackingNumber: row.tracking_number as string | null,
    packingSlipPath: row.packing_slip_path as string | null,
    items: (row.items as ReceivingRecord['items']) || [],
    allItemsReceived: row.all_items_received as boolean,
    discrepancyNotes: row.discrepancy_notes as string | null,
    photos: (row.photos as string[]) || [],
    createdAt: row.created_at as string,
  };
}

export function useProcurement() {
  const [vendors, setVendors] = useState<ProcurementVendor[]>([]);
  const [lineItems, setLineItems] = useState<POLineItem[]>([]);
  const [receivingRecords, setReceivingRecords] = useState<ReceivingRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAll = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const [vendorsRes, lineItemsRes, receivingRes] = await Promise.all([
        supabase
          .from('vendor_directory')
          .select('*')
          .order('name'),
        supabase
          .from('po_line_items')
          .select('*')
          .order('created_at', { ascending: false }),
        supabase
          .from('receiving_records')
          .select('*')
          .order('received_at', { ascending: false }),
      ]);

      if (vendorsRes.error) throw vendorsRes.error;
      if (lineItemsRes.error) throw lineItemsRes.error;
      if (receivingRes.error) throw receivingRes.error;

      setVendors((vendorsRes.data || []).map((r: Record<string, unknown>) => mapVendor(r)));
      setLineItems((lineItemsRes.data || []).map((r: Record<string, unknown>) => mapLineItem(r)));
      setReceivingRecords((receivingRes.data || []).map((r: Record<string, unknown>) => mapReceivingRecord(r)));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load procurement data');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchAll();

    const supabase = getSupabase();
    const channel = supabase
      .channel('procurement-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'vendor_directory' }, () => {
        fetchAll();
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'po_line_items' }, () => {
        fetchAll();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchAll]);

  // Mutations

  const createVendor = async (data: {
    name: string;
    contactName?: string;
    email?: string;
    phone?: string;
    address?: string;
    city?: string;
    state?: string;
    zipCode?: string;
    website?: string;
    paymentTerms?: string;
    creditLimit?: number;
    taxId?: string;
    vendorType: string;
    tradeCategories?: string[];
    rating?: number;
    notes?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('vendor_directory')
      .insert({
        company_id: companyId,
        name: data.name,
        contact_name: data.contactName || null,
        email: data.email || null,
        phone: data.phone || null,
        address: data.address || null,
        city: data.city || null,
        state: data.state || null,
        zip_code: data.zipCode || null,
        website: data.website || null,
        payment_terms: data.paymentTerms || 'net_30',
        credit_limit: data.creditLimit || null,
        tax_id: data.taxId || null,
        vendor_type: data.vendorType,
        trade_categories: data.tradeCategories || [],
        rating: data.rating || null,
        notes: data.notes || null,
        is_active: true,
      })
      .select('id')
      .single();

    if (err) throw err;
    await fetchAll();
    return result.id;
  };

  const updateVendor = async (id: string, data: Partial<{
    name: string;
    contactName: string | null;
    email: string | null;
    phone: string | null;
    address: string | null;
    city: string | null;
    state: string | null;
    zipCode: string | null;
    website: string | null;
    paymentTerms: string;
    creditLimit: number | null;
    taxId: string | null;
    vendorType: string;
    tradeCategories: string[];
    rating: number | null;
    notes: string | null;
    isActive: boolean;
  }>) => {
    const supabase = getSupabase();
    const update: Record<string, unknown> = {};
    if (data.name !== undefined) update.name = data.name;
    if (data.contactName !== undefined) update.contact_name = data.contactName;
    if (data.email !== undefined) update.email = data.email;
    if (data.phone !== undefined) update.phone = data.phone;
    if (data.address !== undefined) update.address = data.address;
    if (data.city !== undefined) update.city = data.city;
    if (data.state !== undefined) update.state = data.state;
    if (data.zipCode !== undefined) update.zip_code = data.zipCode;
    if (data.website !== undefined) update.website = data.website;
    if (data.paymentTerms !== undefined) update.payment_terms = data.paymentTerms;
    if (data.creditLimit !== undefined) update.credit_limit = data.creditLimit;
    if (data.taxId !== undefined) update.tax_id = data.taxId;
    if (data.vendorType !== undefined) update.vendor_type = data.vendorType;
    if (data.tradeCategories !== undefined) update.trade_categories = data.tradeCategories;
    if (data.rating !== undefined) update.rating = data.rating;
    if (data.notes !== undefined) update.notes = data.notes;
    if (data.isActive !== undefined) update.is_active = data.isActive;

    const { error: err } = await supabase.from('vendor_directory').update(update).eq('id', id);
    if (err) throw err;
    await fetchAll();
  };

  const addLineItem = async (data: {
    purchaseOrderId: string;
    itemDescription: string;
    quantity: number;
    unit?: string;
    unitPrice: number;
    catalogItemId?: string;
    catalogSource?: string;
    notes?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const totalPrice = data.quantity * data.unitPrice;

    const { data: result, error: err } = await supabase
      .from('po_line_items')
      .insert({
        company_id: companyId,
        purchase_order_id: data.purchaseOrderId,
        item_description: data.itemDescription,
        quantity: data.quantity,
        unit: data.unit || null,
        unit_price: data.unitPrice,
        total_price: totalPrice,
        received_quantity: 0,
        catalog_item_id: data.catalogItemId || null,
        catalog_source: data.catalogSource || null,
        status: 'pending',
        notes: data.notes || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    await fetchAll();
    return result.id;
  };

  const updateLineItem = async (id: string, data: Partial<{
    itemDescription: string;
    quantity: number;
    unitPrice: number;
    receivedQuantity: number;
    status: string;
    notes: string | null;
  }>) => {
    const supabase = getSupabase();
    const update: Record<string, unknown> = {};
    if (data.itemDescription !== undefined) update.item_description = data.itemDescription;
    if (data.quantity !== undefined) update.quantity = data.quantity;
    if (data.unitPrice !== undefined) update.unit_price = data.unitPrice;
    if (data.quantity !== undefined && data.unitPrice !== undefined) {
      update.total_price = data.quantity * data.unitPrice;
    }
    if (data.receivedQuantity !== undefined) update.received_quantity = data.receivedQuantity;
    if (data.status !== undefined) update.status = data.status;
    if (data.notes !== undefined) update.notes = data.notes;

    const { error: err } = await supabase.from('po_line_items').update(update).eq('id', id);
    if (err) throw err;
    await fetchAll();
  };

  const createReceivingRecord = async (data: {
    purchaseOrderId: string;
    deliveryMethod?: string;
    trackingNumber?: string;
    items: { line_item_id: string; quantity_received: number; condition: string; notes: string }[];
    allItemsReceived?: boolean;
    discrepancyNotes?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('receiving_records')
      .insert({
        company_id: companyId,
        purchase_order_id: data.purchaseOrderId,
        received_by_user_id: user.id,
        received_at: new Date().toISOString(),
        delivery_method: data.deliveryMethod || null,
        tracking_number: data.trackingNumber || null,
        items: data.items,
        all_items_received: data.allItemsReceived || false,
        discrepancy_notes: data.discrepancyNotes || null,
        photos: [],
      })
      .select('id')
      .single();

    if (err) throw err;
    await fetchAll();
    return result.id;
  };

  // Computed

  const activeVendors = useMemo(() => {
    return vendors.filter((v) => v.isActive);
  }, [vendors]);

  const pendingDeliveries = useMemo(() => {
    return lineItems.filter((li) => li.status === 'pending' || li.status === 'partial');
  }, [lineItems]);

  const receivedThisMonth = useMemo(() => {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).getTime();
    return receivingRecords.filter((r) => new Date(r.receivedAt).getTime() >= startOfMonth);
  }, [receivingRecords]);

  // Helper to get line items for a specific PO
  const getLineItemsForPO = useCallback((purchaseOrderId: string) => {
    return lineItems.filter((li) => li.purchaseOrderId === purchaseOrderId);
  }, [lineItems]);

  // Helper to get receiving records for a specific PO
  const getReceivingForPO = useCallback((purchaseOrderId: string) => {
    return receivingRecords.filter((r) => r.purchaseOrderId === purchaseOrderId);
  }, [receivingRecords]);

  return {
    vendors,
    lineItems,
    receivingRecords,
    loading,
    error,
    // Mutations
    createVendor,
    updateVendor,
    addLineItem,
    updateLineItem,
    createReceivingRecord,
    // Computed
    activeVendors,
    pendingDeliveries,
    receivedThisMonth,
    // Helpers
    getLineItemsForPO,
    getReceivingForPO,
    // Refetch
    refetch: fetchAll,
  };
}
