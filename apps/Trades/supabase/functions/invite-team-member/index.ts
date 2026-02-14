import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const VALID_ROLES = ['admin', 'office_manager', 'technician', 'apprentice'];

interface InviteRequest {
  email: string;
  firstName: string;
  lastName: string;
  phone?: string;
  role?: string;
  tradeSpecialties?: string[];
  title?: string;
  employmentType?: string;
  payType?: string;
  payRate?: number;
  certificationLevel?: string;
  emergencyContactName?: string;
  emergencyContactPhone?: string;
  emergencyContactRelation?: string;
  dateOfHire?: string;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Authenticate the requesting user
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Authentication required' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const token = authHeader.replace('Bearer ', '');
    const { data: { user: caller } } = await supabase.auth.getUser(token);
    if (!caller) {
      return new Response(JSON.stringify({ error: 'Invalid token' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const companyId = caller.app_metadata?.company_id;
    const callerRole = caller.app_metadata?.role;
    if (!companyId) {
      return new Response(JSON.stringify({ error: 'No company associated with user' }), {
        status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Only owner/admin can invite
    if (!['owner', 'admin'].includes(callerRole)) {
      return new Response(JSON.stringify({ error: 'Only owners and admins can invite team members' }), {
        status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const body: InviteRequest = await req.json();

    // Validate required fields
    if (!body.email || !body.firstName || !body.lastName) {
      return new Response(JSON.stringify({ error: 'email, firstName, and lastName are required' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const email = body.email.trim().toLowerCase();
    const role = body.role && VALID_ROLES.includes(body.role) ? body.role : 'technician';
    const fullName = `${body.firstName.trim()} ${body.lastName.trim()}`;

    // Check if user already exists in this company
    const { data: existingUser } = await supabase
      .from('users')
      .select('id, email, is_active, deleted_at')
      .eq('company_id', companyId)
      .eq('email', email)
      .maybeSingle();

    if (existingUser && existingUser.is_active && !existingUser.deleted_at) {
      return new Response(JSON.stringify({ error: 'A team member with this email already exists' }), {
        status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Check company tier limits
    const { data: company } = await supabase
      .from('companies')
      .select('max_users, subscription_tier')
      .eq('id', companyId)
      .single();

    if (company) {
      const { count: currentUsers } = await supabase
        .from('users')
        .select('id', { count: 'exact', head: true })
        .eq('company_id', companyId)
        .eq('is_active', true)
        .is('deleted_at', null);

      const maxUsers = company.max_users || 1;
      if ((currentUsers || 0) >= maxUsers) {
        return new Response(JSON.stringify({
          error: `Team limit reached (${maxUsers} members on ${company.subscription_tier} plan). Upgrade to add more.`,
        }), {
          status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }
    }

    // Create auth user (invited, no password yet — they'll set it via magic link)
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email,
      email_confirm: false,
      app_metadata: {
        company_id: companyId,
        role,
      },
      user_metadata: {
        full_name: fullName,
        phone: body.phone || null,
      },
    });

    if (authError) {
      // If user exists in auth but not in this company, we can't re-use them
      // (multi-company not supported yet)
      return new Response(JSON.stringify({ error: authError.message }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const newUserId = authData.user.id;

    // Insert into public.users table
    const { error: userInsertError } = await supabase.from('users').insert({
      id: newUserId,
      company_id: companyId,
      email,
      full_name: fullName,
      phone: body.phone || null,
      role,
      trade: body.tradeSpecialties?.[0] || null,
      is_active: true,
      settings: {
        trades: body.tradeSpecialties || [],
        title: body.title || null,
        status: 'invited',
        invited_by: caller.id,
        certification_level: body.certificationLevel || null,
      },
    });

    if (userInsertError) {
      // Rollback: delete the auth user
      await supabase.auth.admin.deleteUser(newUserId);
      return new Response(JSON.stringify({ error: `Failed to create user record: ${userInsertError.message}` }), {
        status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Create employee_records entry if HR fields provided
    const hasHrFields = body.employmentType || body.payType || body.dateOfHire ||
      body.emergencyContactName;

    if (hasHrFields) {
      await supabase.from('employee_records').insert({
        user_id: newUserId,
        company_id: companyId,
        hire_date: body.dateOfHire || new Date().toISOString().split('T')[0],
        employment_type: body.employmentType || 'full_time',
        job_title: body.title || role,
        pay_type: body.payType || 'hourly',
        pay_rate: body.payRate || 0,
        emergency_contact_name: body.emergencyContactName || null,
        emergency_contact_phone: body.emergencyContactPhone || null,
        emergency_contact_relation: body.emergencyContactRelation || null,
        status: 'active',
      }).then(({ error: hrErr }) => {
        if (hrErr) {
          console.error('Failed to create employee record (non-fatal):', hrErr.message);
        }
      });
    }

    // Send invite email via sendgrid-email EF (fire-and-forget)
    const sendgridApiKey = Deno.env.get('SENDGRID_API_KEY');
    if (sendgridApiKey) {
      // Generate magic link for the invited user
      const { data: magicLink } = await supabase.auth.admin.generateLink({
        type: 'magiclink',
        email,
      });

      if (magicLink?.properties?.hashed_token) {
        const inviteUrl = `${supabaseUrl}/auth/v1/verify?token=${magicLink.properties.hashed_token}&type=magiclink`;

        await fetch('https://api.sendgrid.com/v3/mail/send', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${sendgridApiKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            personalizations: [{ to: [{ email, name: fullName }] }],
            from: { email: 'noreply@zafto.app', name: 'ZAFTO' },
            subject: `You've been invited to join ZAFTO`,
            content: [{
              type: 'text/html',
              value: `
                <h2>Welcome to ZAFTO!</h2>
                <p>You've been invited to join your team on ZAFTO.</p>
                <p><a href="${inviteUrl}" style="background:#2563eb;color:white;padding:12px 24px;border-radius:8px;text-decoration:none;display:inline-block;">Accept Invitation</a></p>
                <p>If the button doesn't work, copy this link: ${inviteUrl}</p>
              `,
            }],
          }),
        }).catch((e: Error) => {
          console.error('Failed to send invite email:', e.message);
        });
      }
    }

    return new Response(JSON.stringify({
      success: true,
      userId: newUserId,
      email,
      role,
      fullName,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return new Response(JSON.stringify({ error: message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
