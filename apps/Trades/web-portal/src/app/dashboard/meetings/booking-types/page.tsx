'use client';

import { useState, useEffect, useCallback } from 'react';
import {
  Video,
  Plus,
  Edit2,
  Trash2,
  ToggleLeft,
  ToggleRight,
  Globe,
  Users,
  Clock,
  Calendar,
  Copy,
  Loader2,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { getSupabase } from '@/lib/supabase';

interface BookingType {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  durationMinutes: number;
  meetingType: string;
  availableDays: string[];
  availableHours: Array<{ start: string; end: string }>;
  bufferMinutes: number;
  maxPerDay: number;
  advanceNoticeHours: number;
  maxAdvanceDays: number;
  requiresApproval: boolean;
  autoConfirm: boolean;
  isActive: boolean;
  showOnWebsite: boolean;
  showOnClientPortal: boolean;
}

const meetingTypeLabels: Record<string, string> = {
  site_walk: 'Site Walk',
  virtual_estimate: 'Virtual Estimate',
  document_review: 'Document Review',
  team_huddle: 'Team Huddle',
  insurance_conference: 'Insurance Conference',
  subcontractor_consult: 'Subcontractor',
  expert_consult: 'Expert Consult',
};

const dayLabels: Record<string, string> = {
  mon: 'Mon', tue: 'Tue', wed: 'Wed', thu: 'Thu', fri: 'Fri', sat: 'Sat', sun: 'Sun',
};

function mapRow(r: Record<string, unknown>): BookingType {
  return {
    id: r.id as string,
    name: r.name as string,
    slug: r.slug as string,
    description: (r.description as string) || null,
    durationMinutes: (r.duration_minutes as number) || 15,
    meetingType: r.meeting_type as string,
    availableDays: (r.available_days as string[]) || ['mon', 'tue', 'wed', 'thu', 'fri'],
    availableHours: (r.available_hours as Array<{ start: string; end: string }>) || [{ start: '09:00', end: '17:00' }],
    bufferMinutes: (r.buffer_minutes as number) || 15,
    maxPerDay: (r.max_per_day as number) || 4,
    advanceNoticeHours: (r.advance_notice_hours as number) || 2,
    maxAdvanceDays: (r.max_advance_days as number) || 30,
    requiresApproval: (r.requires_approval as boolean) || false,
    autoConfirm: (r.auto_confirm as boolean) ?? true,
    isActive: (r.is_active as boolean) ?? true,
    showOnWebsite: (r.show_on_website as boolean) ?? true,
    showOnClientPortal: (r.show_on_client_portal as boolean) ?? true,
  };
}

export default function BookingTypesPage() {
  const [types, setTypes] = useState<BookingType[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTypes = useCallback(async () => {
    try {
      setLoading(true);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('meeting_booking_types')
        .select('*')
        .order('name');
      if (err) throw err;
      setTypes((data || []).map(mapRow));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load booking types');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchTypes(); }, [fetchTypes]);

  const toggleActive = async (bt: BookingType) => {
    const supabase = getSupabase();
    await supabase
      .from('meeting_booking_types')
      .update({ is_active: !bt.isActive })
      .eq('id', bt.id);
    fetchTypes();
  };

  const deleteType = async (id: string) => {
    const supabase = getSupabase();
    await supabase.from('meeting_booking_types').delete().eq('id', id);
    fetchTypes();
  };

  const copyBookingLink = (slug: string) => {
    navigator.clipboard.writeText(`https://zafto.cloud/book/${slug}`);
  };

  return (
    <>
      <CommandPalette />
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-zinc-100">Booking Types</h1>
            <p className="text-sm text-zinc-500 mt-1">Configure meeting types for client self-scheduling</p>
          </div>
        </div>

        {loading ? (
          <div className="flex items-center justify-center py-12 text-zinc-500">
            <Loader2 className="h-5 w-5 animate-spin mr-2" />Loading...
          </div>
        ) : error ? (
          <div className="text-red-400 text-center py-12">{error}</div>
        ) : types.length === 0 ? (
          <Card className="bg-zinc-900 border-zinc-800">
            <CardContent className="p-8 text-center">
              <Video className="h-10 w-10 text-zinc-600 mx-auto mb-3" />
              <h3 className="font-medium text-zinc-100">No booking types configured</h3>
              <p className="text-sm text-zinc-500 mt-1">Create booking types to let clients schedule meetings</p>
            </CardContent>
          </Card>
        ) : (
          <div className="space-y-4">
            {types.map(bt => (
              <Card key={bt.id} className="bg-zinc-900 border-zinc-800">
                <CardContent className="p-5">
                  <div className="flex items-start justify-between">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <h3 className="font-medium text-zinc-100">{bt.name}</h3>
                        <Badge className={bt.isActive
                          ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
                          : 'bg-zinc-500/10 text-zinc-400 border-zinc-500/20'
                        }>
                          {bt.isActive ? 'Active' : 'Inactive'}
                        </Badge>
                        <Badge className="bg-blue-500/10 text-blue-400 border-blue-500/20">
                          {meetingTypeLabels[bt.meetingType] || bt.meetingType}
                        </Badge>
                      </div>
                      {bt.description && (
                        <p className="text-sm text-zinc-400 mt-1">{bt.description}</p>
                      )}
                      <div className="flex flex-wrap items-center gap-4 mt-3 text-xs text-zinc-500">
                        <span className="flex items-center gap-1">
                          <Clock className="h-3 w-3" />
                          {bt.durationMinutes} min
                        </span>
                        <span className="flex items-center gap-1">
                          <Calendar className="h-3 w-3" />
                          {bt.availableDays.map(d => dayLabels[d] || d).join(', ')}
                        </span>
                        <span>
                          {bt.availableHours.map(h => `${h.start}–${h.end}`).join(', ')}
                        </span>
                        <span>{bt.bufferMinutes}min buffer</span>
                        <span>Max {bt.maxPerDay}/day</span>
                        {bt.showOnWebsite && (
                          <span className="flex items-center gap-1">
                            <Globe className="h-3 w-3" />
                            Website
                          </span>
                        )}
                        {bt.showOnClientPortal && (
                          <span className="flex items-center gap-1">
                            <Users className="h-3 w-3" />
                            Client Portal
                          </span>
                        )}
                      </div>
                    </div>
                    <div className="flex items-center gap-1 ml-4">
                      <Button
                        variant="ghost"
                        size="sm"
                        className="h-8 w-8 p-0"
                        onClick={() => copyBookingLink(bt.slug)}
                        title="Copy booking link"
                      >
                        <Copy className="h-3.5 w-3.5" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="h-8 w-8 p-0"
                        onClick={() => toggleActive(bt)}
                        title={bt.isActive ? 'Deactivate' : 'Activate'}
                      >
                        {bt.isActive
                          ? <ToggleRight className="h-4 w-4 text-emerald-400" />
                          : <ToggleLeft className="h-4 w-4 text-zinc-500" />
                        }
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="h-8 w-8 p-0 text-red-400 hover:text-red-300"
                        onClick={() => deleteType(bt.id)}
                      >
                        <Trash2 className="h-3.5 w-3.5" />
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </div>
    </>
  );
}
