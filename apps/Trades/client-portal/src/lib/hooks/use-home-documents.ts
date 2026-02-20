'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';

// ============================================================
// ZAFTO Home Documents — Homeowner document management hook
// Table: homeowner_documents
// Extends the home hook with document CRUD + Storage signed URLs
// ============================================================

export type DocumentType = 'warranty' | 'manual' | 'permit' | 'receipt' | 'inspection' | 'other';

export interface HomeDocument {
  id: string;
  propertyId: string;
  equipmentId: string | null;
  name: string;
  documentType: DocumentType;
  fileType: string | null;
  fileSizeBytes: number;
  storagePath: string;
  description: string | null;
  expiryDate: string | null;
  createdAt: string;
  signedUrl?: string;
}

export interface EquipmentOption {
  id: string;
  name: string;
  category: string;
}

function mapDocument(row: Record<string, unknown>): HomeDocument {
  return {
    id: row.id as string,
    propertyId: row.property_id as string,
    equipmentId: row.equipment_id as string | null,
    name: row.name as string,
    documentType: row.document_type as DocumentType,
    fileType: row.file_type as string | null,
    fileSizeBytes: (row.file_size_bytes as number) || 0,
    storagePath: row.storage_path as string,
    description: row.description as string | null,
    expiryDate: row.expiry_date as string | null,
    createdAt: row.created_at as string,
  };
}

function mapEquipmentOption(row: Record<string, unknown>): EquipmentOption {
  return {
    id: row.id as string,
    name: row.name as string,
    category: row.category as string,
  };
}

function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 B';
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export function useHomeDocuments() {
  const { user } = useAuth();
  const [documents, setDocuments] = useState<HomeDocument[]>([]);
  const [equipmentOptions, setEquipmentOptions] = useState<EquipmentOption[]>([]);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);

  const fetchDocuments = useCallback(async () => {
    if (!user) { setLoading(false); return; }
    const supabase = getSupabase();

    const [docRes, equipRes] = await Promise.all([
      supabase.from('homeowner_documents').select('*')
        .eq('owner_user_id', user.id)
        .is('deleted_at', null)
        .order('created_at', { ascending: false }),
      supabase.from('homeowner_equipment').select('id, name, category')
        .eq('owner_user_id', user.id)
        .is('deleted_at', null)
        .order('name'),
    ]);

    const docs = (docRes.data || []).map(mapDocument);

    // Generate signed URLs for all documents
    const docsWithUrls = await Promise.all(
      docs.map(async (doc: HomeDocument) => {
        if (!doc.storagePath) return doc;
        const { data } = await supabase.storage
          .from('homeowner-documents')
          .createSignedUrl(doc.storagePath, 3600);
        return { ...doc, signedUrl: data?.signedUrl || undefined };
      })
    );

    setDocuments(docsWithUrls);
    setEquipmentOptions((equipRes.data || []).map(mapEquipmentOption));
    setLoading(false);
  }, [user]);

  useEffect(() => {
    fetchDocuments();
    if (!user) return;

    const supabase = getSupabase();
    const channel = supabase.channel('home-documents-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'homeowner_documents' }, () => fetchDocuments())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchDocuments, user]);

  // Upload document
  const uploadDocument = async (input: {
    propertyId: string;
    equipmentId?: string;
    name: string;
    documentType: DocumentType;
    description?: string;
    expiryDate?: string;
    file: File;
  }) => {
    if (!user) throw new Error('Not authenticated');
    setUploading(true);
    try {
      const supabase = getSupabase();
      const ext = input.file.name.split('.').pop() || 'bin';
      const storagePath = `${user.id}/${Date.now()}_${input.name.replace(/\s+/g, '_').toLowerCase()}.${ext}`;

      // Upload file to Storage
      const { error: uploadError } = await supabase.storage
        .from('homeowner-documents')
        .upload(storagePath, input.file, {
          contentType: input.file.type,
          upsert: false,
        });
      if (uploadError) throw uploadError;

      // Insert metadata row
      const { error: insertError } = await supabase.from('homeowner_documents').insert({
        owner_user_id: user.id,
        property_id: input.propertyId,
        equipment_id: input.equipmentId || null,
        name: input.name,
        document_type: input.documentType,
        file_type: ext,
        file_size_bytes: input.file.size,
        storage_path: storagePath,
        description: input.description || null,
        expiry_date: input.expiryDate || null,
      });
      if (insertError) throw insertError;
    } finally {
      setUploading(false);
    }
  };

  // Delete document
  const deleteDocument = async (id: string) => {
    if (!user) throw new Error('Not authenticated');
    const supabase = getSupabase();
    const doc = documents.find(d => d.id === id);
    if (doc?.storagePath) {
      await supabase.storage.from('homeowner-documents').remove([doc.storagePath]);
    }
    const { error } = await supabase.from('homeowner_documents').update({ deleted_at: new Date().toISOString() }).eq('id', id);
    if (error) throw error;
  };

  // Computed
  const documentsByType = (type: DocumentType) => documents.filter(d => d.documentType === type);
  const documentsByEquipment = (equipmentId: string) => documents.filter(d => d.equipmentId === equipmentId);

  return {
    documents,
    equipmentOptions,
    loading,
    uploading,
    uploadDocument,
    deleteDocument,
    refetch: fetchDocuments,
    documentsByType,
    documentsByEquipment,
    formatFileSize,
  };
}
