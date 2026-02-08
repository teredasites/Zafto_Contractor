'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';

// ============================================================
// ZAFTO Home — Homeowner property intelligence hook
// Tables: homeowner_properties, homeowner_equipment, service_history,
//         maintenance_schedules, homeowner_documents
// ============================================================

export interface HomeProperty {
  id: string;
  address: string;
  city: string;
  state: string;
  zipCode: string;
  propertyType: string;
  yearBuilt: number | null;
  squareFootage: number | null;
  lotSizeSqft: number | null;
  stories: number;
  bedrooms: number | null;
  bathrooms: number | null;
  garageSpaces: number;
  photoPath: string | null;
  isPrimary: boolean;
  nickname: string | null;
  notes: string | null;
  createdAt: string;
}

export interface HomeEquipment {
  id: string;
  propertyId: string;
  category: string;
  name: string;
  manufacturer: string | null;
  modelNumber: string | null;
  serialNumber: string | null;
  installDate: string | null;
  purchaseDate: string | null;
  estimatedLifespanYears: number | null;
  condition: string;
  lastServiceDate: string | null;
  nextServiceDue: string | null;
  warrantyExpiry: string | null;
  warrantyProvider: string | null;
  aiHealthScore: number | null;
  photoPath: string | null;
  location: string | null;
  notes: string | null;
  createdAt: string;
}

export interface ServiceRecord {
  id: string;
  propertyId: string;
  equipmentId: string | null;
  serviceType: string;
  tradeCategory: string;
  title: string;
  description: string | null;
  contractorName: string | null;
  contractorPhone: string | null;
  totalCost: number | null;
  serviceDate: string;
  warrantyUntil: string | null;
  rating: number | null;
  reviewText: string | null;
  createdAt: string;
}

export interface MaintenanceSchedule {
  id: string;
  propertyId: string;
  equipmentId: string | null;
  title: string;
  description: string | null;
  category: string;
  frequency: string;
  nextDueDate: string;
  lastCompletedDate: string | null;
  remindDaysBefore: number;
  status: string;
  aiRecommended: boolean;
  aiPriority: string | null;
  aiReason: string | null;
}

export interface HomeDocument {
  id: string;
  propertyId: string;
  equipmentId: string | null;
  name: string;
  documentType: string;
  fileType: string | null;
  fileSizeBytes: number;
  storagePath: string;
  description: string | null;
  expiryDate: string | null;
  createdAt: string;
}

function mapProperty(row: Record<string, unknown>): HomeProperty {
  return {
    id: row.id as string,
    address: row.address as string,
    city: row.city as string,
    state: row.state as string,
    zipCode: row.zip_code as string,
    propertyType: row.property_type as string,
    yearBuilt: row.year_built as number | null,
    squareFootage: row.square_footage as number | null,
    lotSizeSqft: row.lot_size_sqft as number | null,
    stories: (row.stories as number) || 1,
    bedrooms: row.bedrooms as number | null,
    bathrooms: row.bathrooms as number | null,
    garageSpaces: (row.garage_spaces as number) || 0,
    photoPath: row.photo_path as string | null,
    isPrimary: row.is_primary as boolean,
    nickname: row.nickname as string | null,
    notes: row.notes as string | null,
    createdAt: row.created_at as string,
  };
}

function mapEquipment(row: Record<string, unknown>): HomeEquipment {
  return {
    id: row.id as string,
    propertyId: row.property_id as string,
    category: row.category as string,
    name: row.name as string,
    manufacturer: row.manufacturer as string | null,
    modelNumber: row.model_number as string | null,
    serialNumber: row.serial_number as string | null,
    installDate: row.install_date as string | null,
    purchaseDate: row.purchase_date as string | null,
    estimatedLifespanYears: row.estimated_lifespan_years as number | null,
    condition: row.condition as string,
    lastServiceDate: row.last_service_date as string | null,
    nextServiceDue: row.next_service_due as string | null,
    warrantyExpiry: row.warranty_expiry as string | null,
    warrantyProvider: row.warranty_provider as string | null,
    aiHealthScore: row.ai_health_score as number | null,
    photoPath: row.photo_path as string | null,
    location: row.location as string | null,
    notes: row.notes as string | null,
    createdAt: row.created_at as string,
  };
}

function mapServiceRecord(row: Record<string, unknown>): ServiceRecord {
  return {
    id: row.id as string,
    propertyId: row.property_id as string,
    equipmentId: row.equipment_id as string | null,
    serviceType: row.service_type as string,
    tradeCategory: row.trade_category as string,
    title: row.title as string,
    description: row.description as string | null,
    contractorName: row.contractor_name as string | null,
    contractorPhone: row.contractor_phone as string | null,
    totalCost: row.total_cost as number | null,
    serviceDate: row.service_date as string,
    warrantyUntil: row.warranty_until as string | null,
    rating: row.rating as number | null,
    reviewText: row.review_text as string | null,
    createdAt: row.created_at as string,
  };
}

function mapMaintenanceSchedule(row: Record<string, unknown>): MaintenanceSchedule {
  return {
    id: row.id as string,
    propertyId: row.property_id as string,
    equipmentId: row.equipment_id as string | null,
    title: row.title as string,
    description: row.description as string | null,
    category: row.category as string,
    frequency: row.frequency as string,
    nextDueDate: row.next_due_date as string,
    lastCompletedDate: row.last_completed_date as string | null,
    remindDaysBefore: (row.remind_days_before as number) || 7,
    status: row.status as string,
    aiRecommended: row.ai_recommended as boolean,
    aiPriority: row.ai_priority as string | null,
    aiReason: row.ai_reason as string | null,
  };
}

function mapHomeDocument(row: Record<string, unknown>): HomeDocument {
  return {
    id: row.id as string,
    propertyId: row.property_id as string,
    equipmentId: row.equipment_id as string | null,
    name: row.name as string,
    documentType: row.document_type as string,
    fileType: row.file_type as string | null,
    fileSizeBytes: (row.file_size_bytes as number) || 0,
    storagePath: row.storage_path as string,
    description: row.description as string | null,
    expiryDate: row.expiry_date as string | null,
    createdAt: row.created_at as string,
  };
}

export function useHome() {
  const { user } = useAuth();
  const [properties, setProperties] = useState<HomeProperty[]>([]);
  const [equipment, setEquipment] = useState<HomeEquipment[]>([]);
  const [serviceHistory, setServiceHistory] = useState<ServiceRecord[]>([]);
  const [maintenanceSchedules, setMaintenanceSchedules] = useState<MaintenanceSchedule[]>([]);
  const [documents, setDocuments] = useState<HomeDocument[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchAll = useCallback(async () => {
    if (!user) { setLoading(false); return; }
    const supabase = getSupabase();

    const [propRes, equipRes, svcRes, maintRes, docRes] = await Promise.all([
      supabase.from('homeowner_properties').select('*').eq('owner_user_id', user.id).order('is_primary', { ascending: false }),
      supabase.from('homeowner_equipment').select('*').eq('owner_user_id', user.id).order('category'),
      supabase.from('service_history').select('*').eq('owner_user_id', user.id).order('service_date', { ascending: false }).limit(50),
      supabase.from('maintenance_schedules').select('*').eq('owner_user_id', user.id).eq('status', 'active').order('next_due_date'),
      supabase.from('homeowner_documents').select('*').eq('owner_user_id', user.id).order('created_at', { ascending: false }),
    ]);

    setProperties((propRes.data || []).map(mapProperty));
    setEquipment((equipRes.data || []).map(mapEquipment));
    setServiceHistory((svcRes.data || []).map(mapServiceRecord));
    setMaintenanceSchedules((maintRes.data || []).map(mapMaintenanceSchedule));
    setDocuments((docRes.data || []).map(mapHomeDocument));
    setLoading(false);
  }, [user]);

  useEffect(() => {
    fetchAll();
    if (!user) return;

    const supabase = getSupabase();
    const channel = supabase.channel('home-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'homeowner_properties' }, () => fetchAll())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'homeowner_equipment' }, () => fetchAll())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchAll, user]);

  // Mutations
  const addProperty = async (input: {
    address: string; city: string; state: string; zipCode: string;
    propertyType?: string; yearBuilt?: number; squareFootage?: number;
    bedrooms?: number; bathrooms?: number; nickname?: string;
  }) => {
    if (!user) throw new Error('Not authenticated');
    const supabase = getSupabase();
    const { error } = await supabase.from('homeowner_properties').insert({
      owner_user_id: user.id,
      address: input.address,
      city: input.city,
      state: input.state,
      zip_code: input.zipCode,
      property_type: input.propertyType || 'single_family',
      year_built: input.yearBuilt || null,
      square_footage: input.squareFootage || null,
      bedrooms: input.bedrooms || null,
      bathrooms: input.bathrooms || null,
      nickname: input.nickname || null,
    });
    if (error) throw error;
  };

  const addEquipment = async (input: {
    propertyId: string; category: string; name: string;
    manufacturer?: string; modelNumber?: string; installDate?: string;
    condition?: string; location?: string;
  }) => {
    if (!user) throw new Error('Not authenticated');
    const supabase = getSupabase();
    const { error } = await supabase.from('homeowner_equipment').insert({
      property_id: input.propertyId,
      owner_user_id: user.id,
      category: input.category,
      name: input.name,
      manufacturer: input.manufacturer || null,
      model_number: input.modelNumber || null,
      install_date: input.installDate || null,
      condition: input.condition || 'good',
      location: input.location || null,
    });
    if (error) throw error;
  };

  const addServiceRecord = async (input: {
    propertyId: string; equipmentId?: string; serviceType: string;
    tradeCategory: string; title: string; description?: string;
    contractorName?: string; totalCost?: number; serviceDate: string;
    rating?: number; reviewText?: string;
  }) => {
    if (!user) throw new Error('Not authenticated');
    const supabase = getSupabase();
    const { error } = await supabase.from('service_history').insert({
      property_id: input.propertyId,
      owner_user_id: user.id,
      equipment_id: input.equipmentId || null,
      service_type: input.serviceType,
      trade_category: input.tradeCategory,
      title: input.title,
      description: input.description || null,
      contractor_name: input.contractorName || null,
      total_cost: input.totalCost || null,
      service_date: input.serviceDate,
      rating: input.rating || null,
      review_text: input.reviewText || null,
    });
    if (error) throw error;
  };

  const completeMaintenanceTask = async (id: string) => {
    const supabase = getSupabase();
    const { error } = await supabase.from('maintenance_schedules')
      .update({ status: 'completed', last_completed_date: new Date().toISOString().split('T')[0] })
      .eq('id', id);
    if (error) throw error;
  };

  // Computed
  const primaryProperty = properties.find(p => p.isPrimary) || properties[0] || null;
  const equipmentByProperty = (propertyId: string) => equipment.filter(e => e.propertyId === propertyId);
  const serviceForProperty = (propertyId: string) => serviceHistory.filter(s => s.propertyId === propertyId);
  const maintenanceDue = maintenanceSchedules.filter(m => {
    const due = new Date(m.nextDueDate);
    const now = new Date();
    const thirtyDays = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
    return due <= thirtyDays;
  });
  const alertCount = equipment.filter(e => e.condition === 'poor' || e.condition === 'critical').length + maintenanceDue.length;
  const healthScore = equipment.length > 0
    ? Math.round(equipment.reduce((sum, e) => sum + (e.aiHealthScore || (e.condition === 'excellent' ? 95 : e.condition === 'good' ? 85 : e.condition === 'fair' ? 65 : e.condition === 'poor' ? 35 : 15)), 0) / equipment.length)
    : null;

  return {
    properties,
    equipment,
    serviceHistory,
    maintenanceSchedules,
    documents,
    loading,
    // Mutations
    addProperty,
    addEquipment,
    addServiceRecord,
    completeMaintenanceTask,
    refetch: fetchAll,
    // Computed
    primaryProperty,
    equipmentByProperty,
    serviceForProperty,
    maintenanceDue,
    alertCount,
    healthScore,
  };
}
