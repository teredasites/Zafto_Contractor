'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { mapUnit } from './pm-mappers';
import type { UnitData } from './pm-mappers';

export interface UnitWithProperty extends UnitData {
  propertyAddress?: string;
}

function mapUnitWithProperty(row: Record<string, unknown>): UnitWithProperty {
  const base = mapUnit(row);
  const property = row.properties as Record<string, unknown> | null;
  return {
    ...base,
    propertyAddress: property ? (property.address_line1 as string) : undefined,
  };
}

export function useUnits() {
  const [units, setUnits] = useState<UnitWithProperty[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchUnits = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('units')
        .select('*, properties(address_line1)')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (err) throw err;
      setUnits((data || []).map(mapUnitWithProperty));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load units';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchUnits();

    const supabase = getSupabase();
    const channel = supabase
      .channel('units-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'units' }, () => {
        fetchUnits();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchUnits]);

  const createUnit = async (data: Partial<UnitData>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    if (!data.propertyId) throw new Error('Property ID is required');

    const { data: result, error: err } = await supabase
      .from('units')
      .insert({
        company_id: companyId,
        property_id: data.propertyId,
        unit_number: data.unitNumber || '',
        bedrooms: data.bedrooms || 1,
        bathrooms: data.bathrooms || 1,
        square_footage: data.squareFootage || null,
        floor_level: data.floorLevel || null,
        amenities: data.amenities || [],
        market_rent: data.marketRent || null,
        photos: data.photos || [],
        notes: data.notes || null,
        status: data.status || 'vacant',
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateUnit = async (id: string, data: Partial<UnitData>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.unitNumber !== undefined) updateData.unit_number = data.unitNumber;
    if (data.propertyId !== undefined) updateData.property_id = data.propertyId;
    if (data.bedrooms !== undefined) updateData.bedrooms = data.bedrooms;
    if (data.bathrooms !== undefined) updateData.bathrooms = data.bathrooms;
    if (data.squareFootage !== undefined) updateData.square_footage = data.squareFootage;
    if (data.floorLevel !== undefined) updateData.floor_level = data.floorLevel;
    if (data.amenities !== undefined) updateData.amenities = data.amenities;
    if (data.marketRent !== undefined) updateData.market_rent = data.marketRent;
    if (data.photos !== undefined) updateData.photos = data.photos;
    if (data.notes !== undefined) updateData.notes = data.notes;
    if (data.status !== undefined) updateData.status = data.status;

    const { error: err } = await supabase.from('units').update(updateData).eq('id', id);
    if (err) throw err;
  };

  const updateUnitStatus = async (id: string, status: UnitData['status']) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('units')
      .update({ status })
      .eq('id', id);
    if (err) throw err;
  };

  const deleteUnit = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('units')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id);
    if (err) throw err;
  };

  const getUnitsByProperty = async (propertyId: string): Promise<UnitWithProperty[]> => {
    const supabase = getSupabase();
    const { data, error: err } = await supabase
      .from('units')
      .select('*, properties(address_line1)')
      .eq('property_id', propertyId)
      .is('deleted_at', null)
      .order('unit_number', { ascending: true });

    if (err) throw err;
    return (data || []).map(mapUnitWithProperty);
  };

  return {
    units,
    loading,
    error,
    createUnit,
    updateUnit,
    updateUnitStatus,
    deleteUnit,
    getUnitsByProperty,
    refetch: fetchUnits,
  };
}

export function useUnit(id: string | undefined) {
  const [unit, setUnit] = useState<UnitWithProperty | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) {
      setLoading(false);
      return;
    }

    let ignore = false;

    const fetchUnit = async () => {
      try {
        setLoading(true);
        setError(null);
        const supabase = getSupabase();
        const { data, error: err } = await supabase
          .from('units')
          .select('*, properties(address_line1)')
          .eq('id', id)
          .single();

        if (ignore) return;
        if (err) throw err;
        setUnit(data ? mapUnitWithProperty(data) : null);
      } catch (e: unknown) {
        if (ignore) return;
        const msg = e instanceof Error ? e.message : 'Unit not found';
        setError(msg);
      } finally {
        if (!ignore) setLoading(false);
      }
    };

    fetchUnit();
    return () => { ignore = true; };
  }, [id]);

  return { unit, loading, error };
}
