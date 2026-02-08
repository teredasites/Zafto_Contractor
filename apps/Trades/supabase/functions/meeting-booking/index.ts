// Supabase Edge Function: meeting-booking
// Public + authenticated booking engine for meetings
// Actions: availability (public), book (public), configure (authenticated)

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
  const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

  try {
    const body = await req.json()
    const { action } = body

    switch (action) {
      case 'availability':
        return await handleAvailability(supabase, body)
      case 'book':
        return await handleBook(supabase, body)
      case 'cancel':
        return await handleCancel(supabase, body)
      case 'booking_types':
        return await handleBookingTypes(supabase, body)
      default:
        return new Response(JSON.stringify({ error: 'Invalid action' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
    }
  } catch (err) {
    console.error('meeting-booking error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

// ============================================================================
// PUBLIC: GET AVAILABLE SLOTS
// ============================================================================
async function handleAvailability(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  const { companyId, bookingTypeSlug, startDate, endDate } = body as {
    companyId: string
    bookingTypeSlug: string
    startDate: string // YYYY-MM-DD
    endDate: string   // YYYY-MM-DD
  }

  if (!companyId || !bookingTypeSlug || !startDate || !endDate) {
    return new Response(JSON.stringify({ error: 'companyId, bookingTypeSlug, startDate, endDate required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Fetch booking type config
  const { data: bookingType } = await supabase
    .from('meeting_booking_types')
    .select('*')
    .eq('company_id', companyId)
    .eq('slug', bookingTypeSlug)
    .eq('is_active', true)
    .single()

  if (!bookingType) {
    return new Response(JSON.stringify({ error: 'Booking type not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Fetch existing meetings in the date range to find conflicts
  const { data: existingMeetings } = await supabase
    .from('meetings')
    .select('scheduled_at, duration_minutes, status')
    .eq('company_id', companyId)
    .gte('scheduled_at', `${startDate}T00:00:00Z`)
    .lte('scheduled_at', `${endDate}T23:59:59Z`)
    .in('status', ['scheduled', 'in_progress'])

  const conflicts = (existingMeetings || []).map(m => ({
    start: new Date(m.scheduled_at).getTime(),
    end: new Date(m.scheduled_at).getTime() + (m.duration_minutes || 30) * 60000,
  }))

  // Generate available slots
  const availableDays: string[] = (bookingType.available_days as string[]) || ['mon', 'tue', 'wed', 'thu', 'fri']
  const availableHours: Array<{ start: string; end: string }> = (bookingType.available_hours as Array<{ start: string; end: string }>) || [{ start: '09:00', end: '17:00' }]
  const duration = bookingType.duration_minutes || 15
  const buffer = bookingType.buffer_minutes || 15
  const maxPerDay = bookingType.max_per_day || 4
  const advanceNoticeMs = (bookingType.advance_notice_hours || 2) * 3600000

  const dayMap: Record<string, number> = { sun: 0, mon: 1, tue: 2, wed: 3, thu: 4, fri: 5, sat: 6 }
  const allowedDayNumbers = availableDays.map(d => dayMap[d]).filter(n => n !== undefined)

  const slots: Array<{ date: string; time: string; datetime: string }> = []
  const start = new Date(startDate + 'T00:00:00')
  const end = new Date(endDate + 'T23:59:59')
  const now = Date.now()

  for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
    if (!allowedDayNumbers.includes(d.getDay())) continue

    const dateStr = d.toISOString().split('T')[0]
    let daySlotCount = 0

    // Count existing bookings on this day
    const dayStart = new Date(`${dateStr}T00:00:00Z`).getTime()
    const dayEnd = dayStart + 86400000
    const dayConflicts = conflicts.filter(c => c.start >= dayStart && c.start < dayEnd)
    daySlotCount = dayConflicts.length

    if (daySlotCount >= maxPerDay) continue

    for (const hours of availableHours) {
      const [startH, startM] = hours.start.split(':').map(Number)
      const [endH, endM] = hours.end.split(':').map(Number)

      let slotTime = new Date(d)
      slotTime.setHours(startH, startM, 0, 0)
      const windowEnd = new Date(d)
      windowEnd.setHours(endH, endM, 0, 0)

      while (slotTime.getTime() + duration * 60000 <= windowEnd.getTime()) {
        const slotStart = slotTime.getTime()
        const slotEnd = slotStart + duration * 60000

        // Check advance notice
        if (slotStart - now < advanceNoticeMs) {
          slotTime = new Date(slotStart + (duration + buffer) * 60000)
          continue
        }

        // Check conflicts
        const hasConflict = conflicts.some(c => {
          const bufferStart = c.start - buffer * 60000
          const bufferEnd = c.end + buffer * 60000
          return slotStart < bufferEnd && slotEnd > bufferStart
        })

        if (!hasConflict && daySlotCount < maxPerDay) {
          const timeStr = `${slotTime.getHours().toString().padStart(2, '0')}:${slotTime.getMinutes().toString().padStart(2, '0')}`
          slots.push({
            date: dateStr,
            time: timeStr,
            datetime: slotTime.toISOString(),
          })
          daySlotCount++
        }

        slotTime = new Date(slotStart + (duration + buffer) * 60000)
      }
    }
  }

  return new Response(JSON.stringify({
    bookingType: {
      name: bookingType.name,
      description: bookingType.description,
      durationMinutes: bookingType.duration_minutes,
      meetingType: bookingType.meeting_type,
    },
    slots,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// ============================================================================
// PUBLIC: BOOK A MEETING
// ============================================================================
async function handleBook(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  const { companyId, bookingTypeSlug, datetime, name, email, phone, description } = body as {
    companyId: string
    bookingTypeSlug: string
    datetime: string
    name: string
    email?: string
    phone?: string
    description?: string
  }

  if (!companyId || !bookingTypeSlug || !datetime || !name) {
    return new Response(JSON.stringify({ error: 'companyId, bookingTypeSlug, datetime, name required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Fetch booking type
  const { data: bookingType } = await supabase
    .from('meeting_booking_types')
    .select('*')
    .eq('company_id', companyId)
    .eq('slug', bookingTypeSlug)
    .eq('is_active', true)
    .single()

  if (!bookingType) {
    return new Response(JSON.stringify({ error: 'Booking type not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Generate room code
  const roomCode = generateRoomCode()
  const roomName = `zafto-${companyId.substring(0, 8)}-${roomCode}`

  // Determine status based on approval requirement
  const status = bookingType.requires_approval ? 'scheduled' : 'scheduled'

  // Create the meeting
  const { data: meeting, error: insertErr } = await supabase
    .from('meetings')
    .insert({
      company_id: companyId,
      title: `${bookingType.name} — ${name}`,
      meeting_type: bookingType.meeting_type,
      room_code: roomCode,
      scheduled_at: datetime,
      duration_minutes: bookingType.duration_minutes,
      livekit_room_name: roomName,
      booking_type_id: bookingType.id,
      booked_by_name: name,
      booked_by_email: email || null,
      booked_by_phone: phone || null,
      status,
      metadata: { description: description || null, source: 'booking_page' },
    })
    .select()
    .single()

  if (insertErr || !meeting) {
    console.error('Failed to create booking:', insertErr)
    return new Response(JSON.stringify({ error: 'Failed to create booking' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Add booker as client participant
  await supabase.from('meeting_participants').insert({
    company_id: companyId,
    meeting_id: meeting.id,
    participant_type: 'client',
    name,
    email: email || null,
    phone: phone || null,
    can_see_context_panel: false,
    can_see_financials: false,
    can_annotate: true,
    can_record: false,
    can_share_documents: false,
  })

  // Try to match to existing customer
  if (email || phone) {
    const matchQuery = supabase.from('customers').select('id, name').eq('company_id', companyId)
    if (email) {
      matchQuery.eq('email', email)
    } else if (phone) {
      matchQuery.eq('phone', phone)
    }
    const { data: customer } = await matchQuery.maybeSingle()
    if (customer) {
      // Could link to customer record — deferred to full CRM integration
    }
  }

  return new Response(JSON.stringify({
    success: true,
    meetingId: meeting.id,
    roomCode,
    joinUrl: `https://zafto.cloud/meet/${roomCode}`,
    scheduledAt: datetime,
    durationMinutes: bookingType.duration_minutes,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// ============================================================================
// PUBLIC: CANCEL A BOOKING
// ============================================================================
async function handleCancel(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  const { meetingId, roomCode, email, reason } = body as {
    meetingId?: string
    roomCode?: string
    email: string
    reason?: string
  }

  if ((!meetingId && !roomCode) || !email) {
    return new Response(JSON.stringify({ error: 'meetingId or roomCode + email required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  let query = supabase.from('meetings').select('id, booked_by_email, status')
  if (meetingId) query = query.eq('id', meetingId)
  else if (roomCode) query = query.eq('room_code', roomCode)

  const { data: meeting } = await query.single()

  if (!meeting) {
    return new Response(JSON.stringify({ error: 'Meeting not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Verify email matches booker
  if (meeting.booked_by_email !== email) {
    return new Response(JSON.stringify({ error: 'Email does not match booking' }), {
      status: 403,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  if (meeting.status !== 'scheduled') {
    return new Response(JSON.stringify({ error: 'Only scheduled meetings can be cancelled' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  await supabase
    .from('meetings')
    .update({
      status: 'cancelled',
      cancelled_at: new Date().toISOString(),
      cancel_reason: reason || 'Cancelled by booker',
    })
    .eq('id', meeting.id)

  return new Response(JSON.stringify({ success: true }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// ============================================================================
// PUBLIC: GET BOOKING TYPES FOR A COMPANY
// ============================================================================
async function handleBookingTypes(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  const { companyId, surface } = body as { companyId: string; surface?: string }

  if (!companyId) {
    return new Response(JSON.stringify({ error: 'companyId required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  let query = supabase
    .from('meeting_booking_types')
    .select('name, slug, description, duration_minutes, meeting_type')
    .eq('company_id', companyId)
    .eq('is_active', true)
    .order('name')

  if (surface === 'website') {
    query = query.eq('show_on_website', true)
  } else if (surface === 'client_portal') {
    query = query.eq('show_on_client_portal', true)
  }

  const { data: types, error } = await query

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ bookingTypes: types || [] }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function generateRoomCode(): string {
  const chars = 'abcdefghjkmnpqrstuvwxyz23456789'
  const parts: string[] = []
  for (let p = 0; p < 3; p++) {
    let segment = ''
    for (let i = 0; i < 3; i++) {
      segment += chars[Math.floor(Math.random() * chars.length)]
    }
    parts.push(segment)
  }
  return parts.join('-')
}
