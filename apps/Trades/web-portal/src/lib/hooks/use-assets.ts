'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapPropertyAsset, mapAssetServiceRecord } from './pm-mappers';
import type { PropertyAssetData, AssetServiceRecordData } from './pm-mappers';

export function useAssets() {
  const [assets, setAssets] = useState<PropertyAssetData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAssets = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('property_assets')
        .select('*, properties(address_line1), units(unit_number)')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setAssets((data || []).map(mapPropertyAsset));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load assets';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchAssets();

    const supabase = getSupabase();
    const channel = supabase
      .channel('property-assets-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'property_assets' }, () => {
        fetchAssets();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchAssets]);

  const createAsset = async (data: {
    propertyId: string;
    unitId?: string;
    assetType: PropertyAssetData['assetType'];
    manufacturer?: string;
    model?: string;
    serialNumber?: string;
    installDate?: string;
    purchasePrice?: number;
    warrantyExpiry?: string;
    expectedLifespanYears?: number;
    lastServiceDate?: string;
    nextServiceDue?: string;
    condition: PropertyAssetData['condition'];
    notes?: string;
    photos?: string[];
    recurringIssues?: string[];
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('property_assets')
      .insert({
        company_id: companyId,
        property_id: data.propertyId,
        unit_id: data.unitId || null,
        asset_type: data.assetType,
        manufacturer: data.manufacturer || null,
        model: data.model || null,
        serial_number: data.serialNumber || null,
        install_date: data.installDate || null,
        purchase_price: data.purchasePrice || null,
        warranty_expiry: data.warrantyExpiry || null,
        expected_lifespan_years: data.expectedLifespanYears || null,
        last_service_date: data.lastServiceDate || null,
        next_service_due: data.nextServiceDue || null,
        condition: data.condition,
        status: 'active',
        notes: data.notes || null,
        photos: data.photos || [],
        recurring_issues: data.recurringIssues || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateAsset = async (id: string, data: {
    assetType?: PropertyAssetData['assetType'];
    manufacturer?: string;
    model?: string;
    serialNumber?: string;
    installDate?: string;
    purchasePrice?: number;
    warrantyExpiry?: string;
    expectedLifespanYears?: number;
    lastServiceDate?: string;
    nextServiceDue?: string;
    condition?: PropertyAssetData['condition'];
    status?: PropertyAssetData['status'];
    notes?: string;
    photos?: string[];
    recurringIssues?: string[];
  }) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.assetType !== undefined) updateData.asset_type = data.assetType;
    if (data.manufacturer !== undefined) updateData.manufacturer = data.manufacturer;
    if (data.model !== undefined) updateData.model = data.model;
    if (data.serialNumber !== undefined) updateData.serial_number = data.serialNumber;
    if (data.installDate !== undefined) updateData.install_date = data.installDate;
    if (data.purchasePrice !== undefined) updateData.purchase_price = data.purchasePrice;
    if (data.warrantyExpiry !== undefined) updateData.warranty_expiry = data.warrantyExpiry;
    if (data.expectedLifespanYears !== undefined) updateData.expected_lifespan_years = data.expectedLifespanYears;
    if (data.lastServiceDate !== undefined) updateData.last_service_date = data.lastServiceDate;
    if (data.nextServiceDue !== undefined) updateData.next_service_due = data.nextServiceDue;
    if (data.condition !== undefined) updateData.condition = data.condition;
    if (data.status !== undefined) updateData.status = data.status;
    if (data.notes !== undefined) updateData.notes = data.notes;
    if (data.photos !== undefined) updateData.photos = data.photos;
    if (data.recurringIssues !== undefined) updateData.recurring_issues = data.recurringIssues;

    const { error: err } = await supabase
      .from('property_assets')
      .update(updateData)
      .eq('id', id);

    if (err) throw err;
  };

  const deleteAsset = async (id: string) => {
    const supabase = getSupabase();

    const { error: err } = await supabase
      .from('property_assets')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);

    if (err) throw err;
  };

  const getAssetsByProperty = async (propertyId: string): Promise<PropertyAssetData[]> => {
    const supabase = getSupabase();

    const { data, error: err } = await supabase
      .from('property_assets')
      .select('*, properties(address_line1), units(unit_number)')
      .eq('property_id', propertyId)
      .is('deleted_at', null)
      .order('created_at', { ascending: false });

    if (err) throw err;
    return (data || []).map(mapPropertyAsset);
  };

  const getServiceRecords = async (assetId: string): Promise<AssetServiceRecordData[]> => {
    const supabase = getSupabase();

    const { data, error: err } = await supabase
      .from('asset_service_records')
      .select('*')
      .eq('asset_id', assetId)
      .order('service_date', { ascending: false });

    if (err) throw err;
    return (data || []).map(mapAssetServiceRecord);
  };

  const addServiceRecord = async (assetId: string, data: {
    serviceDate: string;
    serviceType: AssetServiceRecordData['serviceType'];
    jobId?: string;
    vendorId?: string;
    performedByName?: string;
    cost?: number;
    partsUsed?: Record<string, unknown>[];
    notes?: string;
    beforePhotos?: string[];
    afterPhotos?: string[];
    nextServiceRecommended?: string;
    updatedCondition?: PropertyAssetData['condition'];
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('asset_service_records')
      .insert({
        company_id: companyId,
        asset_id: assetId,
        service_date: data.serviceDate,
        service_type: data.serviceType,
        job_id: data.jobId || null,
        vendor_id: data.vendorId || null,
        performed_by_user_id: user.id,
        performed_by_name: data.performedByName || null,
        cost: data.cost || null,
        parts_used: data.partsUsed || null,
        notes: data.notes || null,
        before_photos: data.beforePhotos || [],
        after_photos: data.afterPhotos || [],
        next_service_recommended: data.nextServiceRecommended || null,
      })
      .select('id')
      .single();

    if (err) throw err;

    // Update the asset's last_service_date, next_service_due, and condition
    const assetUpdate: Record<string, unknown> = {
      last_service_date: data.serviceDate,
    };
    if (data.nextServiceRecommended) {
      assetUpdate.next_service_due = data.nextServiceRecommended;
    }
    if (data.updatedCondition) {
      assetUpdate.condition = data.updatedCondition;
    }

    const { error: updateErr } = await supabase
      .from('property_assets')
      .update(assetUpdate)
      .eq('id', assetId);

    if (updateErr) throw updateErr;

    return result.id;
  };

  const getAssetsNeedingService = async (): Promise<PropertyAssetData[]> => {
    const supabase = getSupabase();
    const today = new Date().toISOString().split('T')[0];

    const { data, error: err } = await supabase
      .from('property_assets')
      .select('*, properties(address_line1), units(unit_number)')
      .is('deleted_at', null)
      .lte('next_service_due', today)
      .eq('status', 'active')
      .order('next_service_due', { ascending: true });

    if (err) throw err;
    return (data || []).map(mapPropertyAsset);
  };

  return {
    assets,
    loading,
    error,
    refetch: fetchAssets,
    createAsset,
    updateAsset,
    deleteAsset,
    getAssetsByProperty,
    getServiceRecords,
    addServiceRecord,
    getAssetsNeedingService,
  };
}
