'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapProperty, formatPropertyAddress, propertyTypeLabels } from './pm-mappers';
import type { PropertyData } from './pm-mappers';

export interface PropertyStats {
  totalProperties: number;
  totalUnits: number;
  vacantUnits: number;
  occupancyRate: number;
  totalRentCollected: number;
}

export function useProperties() {
  const [properties, setProperties] = useState<PropertyData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchProperties = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('properties')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setProperties((data || []).map(mapProperty));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load properties';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchProperties();

    const supabase = getSupabase();
    const channel = supabase
      .channel('properties-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'properties' }, () => {
        fetchProperties();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchProperties]);

  const createProperty = async (data: Partial<PropertyData>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('properties')
      .insert({
        company_id: companyId,
        address_line1: data.addressLine1 || '',
        address_line2: data.addressLine2 || null,
        city: data.city || '',
        state: data.state || '',
        zip: data.zip || '',
        country: data.country || 'US',
        property_type: data.propertyType || 'single_family',
        unit_count: data.unitCount || 1,
        year_built: data.yearBuilt || null,
        square_footage: data.squareFootage || null,
        lot_size: data.lotSize || null,
        purchase_date: data.purchaseDate || null,
        purchase_price: data.purchasePrice || null,
        current_value: data.currentValue || null,
        mortgage_lender: data.mortgageLender || null,
        mortgage_rate: data.mortgageRate || null,
        mortgage_payment: data.mortgagePayment || null,
        mortgage_escrow: data.mortgageEscrow || null,
        mortgage_principal_balance: data.mortgagePrincipalBalance || null,
        insurance_carrier: data.insuranceCarrier || null,
        insurance_policy_number: data.insurancePolicyNumber || null,
        insurance_premium: data.insurancePremium || null,
        insurance_expiry: data.insuranceExpiry || null,
        property_tax_annual: data.propertyTaxAnnual || null,
        notes: data.notes || null,
        photos: data.photos || [],
        status: data.status || 'active',
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateProperty = async (id: string, data: Partial<PropertyData>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.addressLine1 !== undefined) updateData.address_line1 = data.addressLine1;
    if (data.addressLine2 !== undefined) updateData.address_line2 = data.addressLine2;
    if (data.city !== undefined) updateData.city = data.city;
    if (data.state !== undefined) updateData.state = data.state;
    if (data.zip !== undefined) updateData.zip = data.zip;
    if (data.country !== undefined) updateData.country = data.country;
    if (data.propertyType !== undefined) updateData.property_type = data.propertyType;
    if (data.unitCount !== undefined) updateData.unit_count = data.unitCount;
    if (data.yearBuilt !== undefined) updateData.year_built = data.yearBuilt;
    if (data.squareFootage !== undefined) updateData.square_footage = data.squareFootage;
    if (data.lotSize !== undefined) updateData.lot_size = data.lotSize;
    if (data.purchaseDate !== undefined) updateData.purchase_date = data.purchaseDate;
    if (data.purchasePrice !== undefined) updateData.purchase_price = data.purchasePrice;
    if (data.currentValue !== undefined) updateData.current_value = data.currentValue;
    if (data.mortgageLender !== undefined) updateData.mortgage_lender = data.mortgageLender;
    if (data.mortgageRate !== undefined) updateData.mortgage_rate = data.mortgageRate;
    if (data.mortgagePayment !== undefined) updateData.mortgage_payment = data.mortgagePayment;
    if (data.mortgageEscrow !== undefined) updateData.mortgage_escrow = data.mortgageEscrow;
    if (data.mortgagePrincipalBalance !== undefined) updateData.mortgage_principal_balance = data.mortgagePrincipalBalance;
    if (data.insuranceCarrier !== undefined) updateData.insurance_carrier = data.insuranceCarrier;
    if (data.insurancePolicyNumber !== undefined) updateData.insurance_policy_number = data.insurancePolicyNumber;
    if (data.insurancePremium !== undefined) updateData.insurance_premium = data.insurancePremium;
    if (data.insuranceExpiry !== undefined) updateData.insurance_expiry = data.insuranceExpiry;
    if (data.propertyTaxAnnual !== undefined) updateData.property_tax_annual = data.propertyTaxAnnual;
    if (data.notes !== undefined) updateData.notes = data.notes;
    if (data.photos !== undefined) updateData.photos = data.photos;
    if (data.status !== undefined) updateData.status = data.status;

    const { error: err } = await supabase.from('properties').update(updateData).eq('id', id);
    if (err) throw err;
  };

  const deleteProperty = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('properties')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
  };

  const getPropertyStats = async (): Promise<PropertyStats> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    // Fetch all active properties for the company
    const { data: propertyRows, error: propErr } = await supabase
      .from('properties')
      .select('id, unit_count')
      .eq('company_id', companyId)
      .is('deleted_at', null);

    if (propErr) throw propErr;

    const propertyIds = (propertyRows || []).map((p: { id: string }) => p.id);
    const totalProperties = propertyIds.length;
    const totalUnits = (propertyRows || []).reduce((sum: number, p: { unit_count: number }) => sum + (Number(p.unit_count) || 0), 0);

    if (propertyIds.length === 0) {
      return { totalProperties: 0, totalUnits: 0, vacantUnits: 0, occupancyRate: 0, totalRentCollected: 0 };
    }

    // Count vacant units across all properties
    const { count: vacantCount, error: unitErr } = await supabase
      .from('units')
      .select('*', { count: 'exact', head: true })
      .inFilter('property_id', propertyIds)
      .eq('status', 'vacant')
      .is('deleted_at', null);

    if (unitErr) throw unitErr;

    const vacantUnits = vacantCount || 0;
    const occupancyRate = totalUnits > 0 ? ((totalUnits - vacantUnits) / totalUnits) * 100 : 0;

    // Sum rent collected (paid rent charges) across all properties
    const { data: rentData, error: rentErr } = await supabase
      .from('rent_charges')
      .select('paid_amount')
      .inFilter('property_id', propertyIds)
      .eq('status', 'paid');

    if (rentErr) throw rentErr;

    const totalRentCollected = (rentData || []).reduce(
      (sum: number, r: { paid_amount: number }) => sum + (Number(r.paid_amount) || 0),
      0
    );

    return {
      totalProperties,
      totalUnits,
      vacantUnits,
      occupancyRate: Math.round(occupancyRate * 100) / 100,
      totalRentCollected,
    };
  };

  return {
    properties,
    loading,
    error,
    createProperty,
    updateProperty,
    deleteProperty,
    getPropertyStats,
    refetch: fetchProperties,
    formatPropertyAddress,
    propertyTypeLabels,
  };
}

export function useProperty(id: string | undefined) {
  const [property, setProperty] = useState<PropertyData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) {
      setLoading(false);
      return;
    }

    let ignore = false;

    const fetchProperty = async () => {
      try {
        setLoading(true);
        setError(null);
        const supabase = getSupabase();
        const { data, error: err } = await supabase
          .from('properties')
          .select('*')
          .eq('id', id)
          .single();

        if (ignore) return;
        if (err) throw err;
        setProperty(data ? mapProperty(data) : null);
      } catch (e: unknown) {
        if (ignore) return;
        const msg = e instanceof Error ? e.message : 'Property not found';
        setError(msg);
      } finally {
        if (!ignore) setLoading(false);
      }
    };

    fetchProperty();
    return () => { ignore = true; };
  }, [id]);

  return { property, loading, error };
}
