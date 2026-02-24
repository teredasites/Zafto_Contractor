'use client';

import { useState, useEffect, useRef } from 'react';
import {
  User,
  Building,
  CreditCard,
  Bell,
  Palette,
  Shield,
  Link,
  FileText,
  ChevronRight,
  Check,
  Camera,
  Mail,
  Phone,
  MapPin,
  Sparkles,
  Info,
  Users,
  Plus,
  MoreHorizontal,
  Edit,
  Trash2,
  Send,
  GitBranch,
  UserCog,
  Wrench,
  ClipboardList,
  Key,
  Award,
  Lock,
  Layers,
  DollarSign,
  ExternalLink,
  RefreshCw,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  X,
  Upload,
  Calendar,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Avatar } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { cn, formatRelativeTime } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';
import { locales, localeNames, localeFlags, type Locale } from '@/lib/i18n-config';
import { useTranslation, setLocale as setAppLocale } from '@/lib/translations';
import { useTeam } from '@/lib/hooks/use-jobs';
import { usePermissions, PERMISSIONS, ROLE_PERMISSIONS, type Permission } from '@/components/permission-gate';
import { useBranches, useCustomRoles, useFormTemplates, useCertifications, useApiKeys } from '@/lib/hooks/use-enterprise';
import { useApprovals } from '@/lib/hooks/use-approvals';
import type { ApprovalThresholdData } from '@/lib/hooks/pm-mappers';
import type { Branch, CustomRole, FormTemplate, Certification } from '@/lib/hooks/use-enterprise';
import { useCustomFields, type CustomField, type EntityType, type FieldType } from '@/lib/hooks/use-custom-fields';
import { useNotificationPreferences, useGoogleCalendar, TRIGGER_LABELS, type NotificationPreferences } from '@/lib/hooks/use-notifications';
import {
  useCompanyConfig,
  type TaxRate,
  DEFAULT_JOB_STATUSES,
  DEFAULT_LEAD_SOURCES,
  DEFAULT_BID_STATUSES,
  DEFAULT_INVOICE_STATUSES,
  DEFAULT_PRIORITY_LEVELS,
} from '@/lib/hooks/use-company-config';
import { useZDocs, type ZDocsTemplate } from '@/lib/hooks/use-zdocs';
import { formatCurrency, formatDateLocale, formatNumber, formatPercent, formatDateTimeLocale, formatRelativeTimeLocale, formatCompactCurrency, formatTimeLocale } from '@/lib/format-locale';

type SettingsTab = 'profile' | 'company' | 'team' | 'billing' | 'payments' | 'notifications' | 'appearance' | 'security' | 'integrations' | 'branches' | 'roles' | 'trades' | 'forms' | 'apikeys' | 'templates' | 'custom_fields' | 'business';

const coreTabs: { id: SettingsTab; label: string; icon: React.ReactNode }[] = [
  { id: 'profile', label: 'Profile', icon: <User size={18} /> },
  { id: 'company', label: 'Company', icon: <Building size={18} /> },
  { id: 'team', label: 'Team', icon: <Users size={18} /> },
  { id: 'billing', label: 'Billing', icon: <CreditCard size={18} /> },
  { id: 'payments', label: 'Payments', icon: <Shield size={18} /> },
  { id: 'notifications', label: 'Notifications', icon: <Bell size={18} /> },
  { id: 'appearance', label: 'Appearance', icon: <Palette size={18} /> },
  { id: 'security', label: 'Security', icon: <Shield size={18} /> },
  { id: 'integrations', label: 'Integrations', icon: <Link size={18} /> },
  { id: 'templates', label: 'Templates', icon: <FileText size={18} /> },
  { id: 'custom_fields', label: 'Custom Fields', icon: <Layers size={18} /> },
  { id: 'business', label: 'Business Config', icon: <DollarSign size={18} /> },
];

const enterpriseTabs: { id: SettingsTab; label: string; icon: React.ReactNode; minTier: 'team' | 'business' | 'enterprise' }[] = [
  { id: 'branches', label: 'Branches', icon: <GitBranch size={18} />, minTier: 'team' },
  { id: 'trades', label: 'Trade Modules', icon: <Wrench size={18} />, minTier: 'team' },
  { id: 'roles', label: 'Roles & Permissions', icon: <UserCog size={18} />, minTier: 'business' },
  { id: 'forms', label: 'Compliance Forms', icon: <ClipboardList size={18} />, minTier: 'business' },
  { id: 'apikeys', label: 'API Keys', icon: <Key size={18} />, minTier: 'enterprise' },
];

export default function SettingsPage() {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState<SettingsTab>('profile');
  const { isTeamOrHigher, isBusinessOrHigher, isEnterprise } = usePermissions();

  const tierOrder = { team: 1, business: 2, enterprise: 3 };
  const visibleEnterpriseTabs = enterpriseTabs.filter((tab) => {
    const required = tierOrder[tab.minTier];
    if (isEnterprise) return true;
    if (isBusinessOrHigher) return required <= 2;
    if (isTeamOrHigher) return required <= 1;
    return false;
  });

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div>
        <h1 className="text-2xl font-semibold text-main">{t('settings.title')}</h1>
        <p className="text-[13px] text-muted mt-1">{t('settings.manageAccountPreferences')}</p>
      </div>

      <div className="flex flex-col lg:flex-row gap-6">
        {/* Sidebar */}
        <div className="lg:w-64 flex-shrink-0">
          <Card>
            <CardContent className="p-2">
              <nav className="space-y-1">
                {coreTabs.map((tab) => (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className={cn(
                      'w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors',
                      activeTab === tab.id
                        ? 'bg-accent-light text-accent'
                        : 'text-muted hover:text-main hover:bg-surface-hover'
                    )}
                  >
                    {tab.icon}
                    {tab.label}
                  </button>
                ))}

                {visibleEnterpriseTabs.length > 0 && (
                  <>
                    <div className="pt-3 pb-1 px-3">
                      <p className="text-[11px] font-semibold text-muted uppercase tracking-wider">{t('common.enterprise')}</p>
                    </div>
                    {visibleEnterpriseTabs.map((tab) => (
                      <button
                        key={tab.id}
                        onClick={() => setActiveTab(tab.id)}
                        className={cn(
                          'w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors',
                          activeTab === tab.id
                            ? 'bg-accent-light text-accent'
                            : 'text-muted hover:text-main hover:bg-surface-hover'
                        )}
                      >
                        {tab.icon}
                        {tab.label}
                      </button>
                    ))}
                  </>
                )}

                <div className="pt-3 pb-1 px-3">
                  <p className="text-[11px] font-semibold text-muted uppercase tracking-wider">{t('settings.data')}</p>
                </div>
                <a
                  href="/dashboard/settings/import"
                  className="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-muted hover:text-main hover:bg-surface-hover transition-colors"
                >
                  <Upload size={18} />
                  Import Data
                </a>
              </nav>
            </CardContent>
          </Card>
        </div>

        {/* Content */}
        <div className="flex-1">
          {activeTab === 'profile' && <ProfileSettings />}
          {activeTab === 'company' && <CompanySettings />}
          {activeTab === 'team' && <TeamSettings />}
          {activeTab === 'billing' && <BillingSettings />}
          {activeTab === 'payments' && <PaymentsSettings />}
          {activeTab === 'notifications' && <NotificationSettings />}
          {activeTab === 'appearance' && <AppearanceSettings />}
          {activeTab === 'security' && <SecuritySettings />}
          {activeTab === 'integrations' && <IntegrationSettings />}
          {activeTab === 'branches' && <BranchesSettings />}
          {activeTab === 'roles' && <RolesSettings />}
          {activeTab === 'trades' && <TradeModulesSettings />}
          {activeTab === 'forms' && <ComplianceFormsSettings />}
          {activeTab === 'apikeys' && <ApiKeysSettings />}
          {activeTab === 'templates' && <TemplatesSettings />}
          {activeTab === 'custom_fields' && <CustomFieldsSettings />}
          {activeTab === 'business' && <BusinessConfigSettings />}
        </div>
      </div>
    </div>
  );
}

function ProfileSettings() {
  const { t } = useTranslation();
  const [selectedLocale, setSelectedLocale] = useState<Locale>('en');
  const [savingLocale, setSavingLocale] = useState(false);

  useEffect(() => {
    const cookie = document.cookie.split('; ').find(c => c.startsWith('NEXT_LOCALE='));
    if (cookie) {
      const val = cookie.split('=')[1] as Locale;
      if (locales.includes(val)) setSelectedLocale(val);
    }
  }, []);

  const handleLocaleChange = async (locale: Locale) => {
    setSelectedLocale(locale);
    setSavingLocale(true);
    try {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        await supabase.from('users').update({ preferred_locale: locale }).eq('id', user.id);
      }
      // Set cookie + dispatch localeChange event — all components using useTranslation() update live
      setAppLocale(locale);
    } catch {
      // Revert on error
      setSelectedLocale(selectedLocale);
    } finally {
      setSavingLocale(false);
    }
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>{t('settings.profileInformation')}</CardTitle>
          <CardDescription>{t('settings.updatePersonalDetails')}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex items-center gap-6">
            <div className="relative">
              <Avatar name="Mike Johnson" size="xl" />
              <button className="absolute bottom-0 right-0 p-1.5 bg-accent text-white rounded-full hover:bg-accent-hover transition-colors">
                <Camera size={14} />
              </button>
            </div>
            <div>
              <h3 className="font-medium text-main">{t('settings.profilePhoto')}</h3>
              <p className="text-sm text-muted">JPG, PNG or GIF. Max 2MB</p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Input label={t('customers.firstName')} defaultValue="Mike" />
            <Input label={t('customers.lastName')} defaultValue="Johnson" />
            <Input label={t('email.title')} type="email" defaultValue="mike@mitchellelectric.com" icon={<Mail size={16} />} />
            <Input label={t('phone.title')} type="tel" defaultValue="(860) 555-1001" icon={<Phone size={16} />} />
          </div>

          <Button>{t('common.saveChanges')}</Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>{t('common.language')}</CardTitle>
          <CardDescription>{t('settings.chooseYourPreferredLanguageTheEntireAppWillSwitchT')}</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-2">
            {locales.map((loc) => (
              <button
                key={loc}
                onClick={() => handleLocaleChange(loc)}
                disabled={savingLocale}
                className={cn(
                  'flex items-center gap-2 px-3 py-2.5 rounded-lg border text-sm transition-all text-left',
                  selectedLocale === loc
                    ? 'border-accent bg-accent/10 text-accent font-medium'
                    : 'border-main bg-secondary hover:bg-surface-hover text-main'
                )}
              >
                <span className="text-base">{localeFlags[loc]}</span>
                <span className="truncate">{localeNames[loc]}</span>
                {selectedLocale === loc && <Check size={14} className="ml-auto flex-shrink-0" />}
              </button>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function CompanySettings() {
  const { t } = useTranslation();
  const [logo, setLogo] = useState<string | null>(() => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('zafto_company_logo');
    }
    return null;
  });
  const [companyName, setCompanyName] = useState('Mitchell Electric LLC');
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleLogoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Validate file size (max 2MB)
    if (file.size > 2 * 1024 * 1024) {
      alert('Logo must be less than 2MB');
      return;
    }

    const reader = new FileReader();
    reader.onload = (event) => {
      const dataUrl = event.target?.result as string;
      setLogo(dataUrl);
      // Store in localStorage for now - will be Firestore later
      localStorage.setItem('zafto_company_logo', dataUrl);
    };
    reader.readAsDataURL(file);
  };

  const removeLogo = () => {
    setLogo(null);
    localStorage.removeItem('zafto_company_logo');
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>{t('settings.companyInformation')}</CardTitle>
          <CardDescription>Update your business details. Logo appears on all bids, invoices, and client portal.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Logo Upload */}
          <div className="flex items-start gap-6">
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              onChange={handleLogoUpload}
              className="hidden"
            />
            <div
              onClick={() => fileInputRef.current?.click()}
              className={cn(
                'w-24 h-24 rounded-xl flex items-center justify-center cursor-pointer transition-colors border-2 border-dashed',
                logo
                  ? 'border-transparent'
                  : 'border-main hover:border-accent bg-secondary hover:bg-surface-hover'
              )}
            >
              {logo ? (
                <img src={logo} alt="Company logo" className="w-full h-full object-contain rounded-xl" />
              ) : (
                <div className="text-center">
                  <Camera size={24} className="mx-auto text-muted" />
                  <span className="text-xs text-muted mt-1 block">{t('settings.addLogo')}</span>
                </div>
              )}
            </div>
            <div>
              <h3 className="font-medium text-main">{t('settings.companyLogo')}</h3>
              <p className="text-sm text-muted">{t('settings.appearsOnBidsInvoices')}</p>
              <p className="text-xs text-muted mt-1">PNG, JPG, or SVG. Max 2MB. Square works best.</p>
              <div className="flex gap-2 mt-2">
                <Button variant="secondary" size="sm" onClick={() => fileInputRef.current?.click()}>
                  <Camera size={14} />
                  {logo ? 'Change' : 'Upload'}
                </Button>
                {logo && (
                  <Button variant="ghost" size="sm" onClick={removeLogo} className="text-red-500 hover:text-red-600">
                    Remove
                  </Button>
                )}
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Input label={t('settings.companyName')} defaultValue="Mitchell Electric LLC" />
            <Input label={t('common.trade')} defaultValue="Electrical" />
            <Input label={t('email.title')} type="email" defaultValue="info@mitchellelectric.com" />
            <Input label={t('phone.title')} type="tel" defaultValue="(860) 555-1000" />
            <Input label={t('leads.sources.website')} defaultValue="www.mitchellelectric.com" className="md:col-span-2" />
          </div>

          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('common.address')}</label>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Input placeholder="Street Address" defaultValue="123 Main Street" className="md:col-span-2" />
              <Input placeholder={t('common.city')} defaultValue="Hartford" />
              <div className="grid grid-cols-2 gap-4">
                <Input placeholder={t('common.state')} defaultValue="CT" />
                <Input placeholder={t('common.zip')} defaultValue="06103" />
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Input label="License Number" defaultValue="E.123456" />
            <Input label="Tax ID / EIN" defaultValue="12-3456789" />
          </div>

          <Button>{t('common.saveChanges')}</Button>
        </CardContent>
      </Card>

      <GoodBetterBestCard />
    </div>
  );
}

function TeamSettings() {
  const { t } = useTranslation();
  const [showInviteModal, setShowInviteModal] = useState(false);
  const { team: teamData } = useTeam();

  const teamMembers = teamData.map((m) => ({
    id: m.id,
    name: m.name || m.email,
    email: m.email,
    role: m.role,
    status: m.isActive ? 'active' : 'inactive',
    lastActive: m.lastActive ? formatRelativeTime(m.lastActive) : 'Never',
  }));

  const pendingInvites = [
    { id: 'i1', email: 'newtech@email.com', role: 'field_tech', sentAt: '2 days ago' },
  ];

  const roleLabels: Record<string, string> = {
    owner: 'Owner',
    admin: 'Admin',
    office: 'Office',
    field_tech: 'Field Tech',
    subcontractor: 'Subcontractor',
  };

  const roleColors: Record<string, string> = {
    owner: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-300',
    admin: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300',
    office: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300',
    field_tech: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300',
    subcontractor: 'bg-secondary text-main',
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>{t('settings.teamMembers')}</CardTitle>
            <CardDescription>{t('settings.manageAccess')}</CardDescription>
          </div>
          <Button onClick={() => setShowInviteModal(true)}>
            <Plus size={16} />
            Invite Member
          </Button>
        </CardHeader>
        <CardContent className="p-0">
          <div className="divide-y divide-main">
            {teamMembers.map((member) => (
              <TeamMemberRow key={member.id} member={member} roleLabels={roleLabels} roleColors={roleColors} />
            ))}
          </div>
        </CardContent>
      </Card>

      {pendingInvites.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>{t('settings.pendingInvites')}</CardTitle>
            <CardDescription>{t('settings.invitationsNotAccepted')}</CardDescription>
          </CardHeader>
          <CardContent className="p-0">
            <div className="divide-y divide-main">
              {pendingInvites.map((invite) => (
                <div key={invite.id} className="px-6 py-4 flex items-center justify-between">
                  <div className="flex items-center gap-4">
                    <div className="w-10 h-10 rounded-full bg-secondary flex items-center justify-center">
                      <Mail size={18} className="text-muted" />
                    </div>
                    <div>
                      <p className="font-medium text-main">{invite.email}</p>
                      <p className="text-sm text-muted">Invited {invite.sentAt}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className={cn('px-2.5 py-1 text-xs font-medium rounded-full', roleColors[invite.role])}>
                      {roleLabels[invite.role]}
                    </span>
                    <Button variant="ghost" size="sm">
                      <Send size={14} />
                      Resend
                    </Button>
                    <Button variant="ghost" size="sm" className="text-red-600 hover:text-red-700">
                      <Trash2 size={14} />
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader>
          <CardTitle>{t('settings.rolePermissions')}</CardTitle>
          <CardDescription>{t('settings.whatEachRoleCanAccess')}</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="grid grid-cols-6 gap-4 text-xs font-medium text-muted uppercase pb-2 border-b border-main">
              <span>{t('common.role')}</span>
              <span className="text-center">{t('common.bids')}</span>
              <span className="text-center">{t('common.jobs')}</span>
              <span className="text-center">{t('common.invoices')}</span>
              <span className="text-center">{t('common.team')}</span>
              <span className="text-center">{t('common.billing')}</span>
            </div>
            <PermissionRow role="Owner" permissions={[true, true, true, true, true]} roleColors={roleColors} />
            <PermissionRow role="Admin" permissions={[true, true, true, true, false]} roleColors={roleColors} />
            <PermissionRow role="Office" permissions={[true, true, true, false, false]} roleColors={roleColors} />
            <PermissionRow role="Field Tech" permissions={[false, 'assigned', false, false, false]} roleColors={roleColors} />
            <PermissionRow role="Subcontractor" permissions={[false, 'assigned', false, false, false]} roleColors={roleColors} />
          </div>
        </CardContent>
      </Card>

      {showInviteModal && <InviteModal onClose={() => setShowInviteModal(false)} roleLabels={roleLabels} />}
    </div>
  );
}

function TeamMemberRow({ member, roleLabels, roleColors }: { member: any; roleLabels: Record<string, string>; roleColors: Record<string, string> }) {
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <div className="px-6 py-4 flex items-center justify-between">
      <div className="flex items-center gap-4">
        <Avatar name={member.name} size="lg" />
        <div>
          <p className="font-medium text-main">{member.name}</p>
          <p className="text-sm text-muted">{member.email}</p>
        </div>
      </div>
      <div className="flex items-center gap-4">
        <span className="text-sm text-muted">{member.lastActive}</span>
        <span className={cn('px-2.5 py-1 text-xs font-medium rounded-full', roleColors[member.role])}>
          {roleLabels[member.role]}
        </span>
        <div className="relative">
          <button
            onClick={() => setMenuOpen(!menuOpen)}
            className="p-2 hover:bg-surface-hover rounded-lg transition-colors"
            disabled={member.role === 'owner'}
          >
            <MoreHorizontal size={18} className={member.role === 'owner' ? 'text-muted/30' : 'text-muted'} />
          </button>
          {menuOpen && member.role !== 'owner' && (
            <>
              <div className="fixed inset-0 z-40" onClick={() => setMenuOpen(false)} />
              <div className="absolute right-0 top-full mt-1 w-48 bg-surface border border-main rounded-lg shadow-lg py-1 z-50">
                <button className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                  <Edit size={14} />
                  Change Role
                </button>
                <button className="w-full px-4 py-2 text-left text-sm hover:bg-red-50 dark:hover:bg-red-900/20 text-red-600 flex items-center gap-2">
                  <Trash2 size={14} />
                  Remove
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

function PermissionRow({ role, permissions, roleColors }: { role: string; permissions: (boolean | string)[]; roleColors: Record<string, string> }) {
  const { t } = useTranslation();
  const roleKey = role.toLowerCase().replace(' ', '_');
  return (
    <div className="grid grid-cols-6 gap-4 py-2">
      <span className={cn('px-2.5 py-1 text-xs font-medium rounded-full w-fit', roleColors[roleKey])}>
        {role}
      </span>
      {permissions.map((perm, idx) => (
        <div key={idx} className="text-center">
          {perm === true ? (
            <Check size={16} className="mx-auto text-emerald-500" />
          ) : perm === 'assigned' ? (
            <span className="text-xs text-amber-600">{t('settings.assignedOnly')}</span>
          ) : (
            <span className="text-muted">-</span>
          )}
        </div>
      ))}
    </div>
  );
}

function InviteModal({ onClose, roleLabels }: { onClose: () => void; roleLabels: Record<string, string> }) {
  const { t } = useTranslation();
  const [email, setEmail] = useState('');
  const [role, setRole] = useState('field_tech');
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) return;

    setSending(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const companyId = user.app_metadata?.company_id;
      if (!companyId) throw new Error('No company associated');

      // Invite user via Edge Function (handles Supabase Auth invite + user record creation)
      const { error: fnErr } = await supabase.functions.invoke('invite-team-member', {
        body: { email: email.trim(), role, companyId },
      });

      if (fnErr) {
        // Fallback: create user record directly if EF doesn't exist
        const { error: insertErr } = await supabase.from('users').insert({
          email: email.trim(),
          role,
          company_id: companyId,
          is_active: false,
          invited_by: user.id,
          invited_at: new Date().toISOString(),
        });
        if (insertErr) throw insertErr;
      }
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to send invite');
    } finally {
      setSending(false);
    }
  };

  return (
    <>
      <div className="fixed inset-0 bg-black/50 z-50" onClick={onClose} />
      <div className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-md z-50">
        <Card>
          <CardHeader>
            <CardTitle>{t('common.inviteTeamMember')}</CardTitle>
            <CardDescription>{t('settings.sendInvitation')}</CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">{t('common.emailAddress')}</label>
                <Input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="teammate@email.com"
                  icon={<Mail size={16} />}
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">{t('common.role')}</label>
                <select
                  value={role}
                  onChange={(e) => setRole(e.target.value)}
                  className="w-full px-4 py-2.5 bg-secondary border border-main rounded-lg text-main focus:outline-none focus:ring-2 focus:ring-accent/50"
                >
                  <option value="admin">{roleLabels.admin}</option>
                  <option value="office">{roleLabels.office}</option>
                  <option value="field_tech">{roleLabels.field_tech}</option>
                  <option value="subcontractor">{roleLabels.subcontractor}</option>
                </select>
              </div>
              <div className="flex gap-3 pt-4">
                <Button type="button" variant="secondary" className="flex-1" onClick={onClose}>
                  Cancel
                </Button>
                <Button type="submit" className="flex-1">
                  <Send size={16} />
                  Send Invite
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </div>
    </>
  );
}

function BillingSettings() {
  const { t } = useTranslation();
  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>{t('settings.currentPlan')}</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-between p-4 bg-accent-light rounded-xl">
            <div>
              <div className="flex items-center gap-2">
                <h3 className="font-semibold text-main text-lg">{t('settings.proPlan')}</h3>
                <Badge variant="success">{t('common.active')}</Badge>
              </div>
              <p className="text-muted mt-1">$29.99/month - billed monthly</p>
            </div>
            <Button variant="secondary">{t('settings.changePlan')}</Button>
          </div>

          <div className="mt-6">
            <h4 className="font-medium text-main mb-3">{t('settings.planFeatures')}</h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
              {[
                'Unlimited bids & invoices',
                'Cloud sync across devices',
                'Web portal access',
                'All calculators & tools',
                'Customer portal',
                'PDF exports',
              ].map((feature) => (
                <div key={feature} className="flex items-center gap-2 text-sm text-muted">
                  <Check size={16} className="text-emerald-500" />
                  {feature}
                </div>
              ))}
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>{t('common.paymentMethod')}</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-between p-4 border border-main rounded-xl">
            <div className="flex items-center gap-4">
              <div className="p-2 bg-secondary rounded-lg">
                <CreditCard size={24} className="text-muted" />
              </div>
              <div>
                <p className="font-medium text-main">Visa ending in 4242</p>
                <p className="text-sm text-muted">Expires 12/2026</p>
              </div>
            </div>
            <Button variant="ghost" size="sm">{t('common.update')}</Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>{t('settings.billingHistory')}</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <div className="divide-y divide-main">
            {[
              { date: 'Feb 1, 2026', amount: 29.99, status: 'Paid' },
              { date: 'Jan 1, 2026', amount: 29.99, status: 'Paid' },
              { date: 'Dec 1, 2025', amount: 29.99, status: 'Paid' },
            ].map((invoice, i) => (
              <div key={i} className="flex items-center justify-between px-6 py-4">
                <div>
                  <p className="font-medium text-main">{formatCurrency(invoice.amount)}</p>
                  <p className="text-sm text-muted">{invoice.date}</p>
                </div>
                <div className="flex items-center gap-3">
                  <Badge variant="success">{invoice.status}</Badge>
                  <Button variant="ghost" size="sm">
                    <FileText size={14} />
                    Invoice
                  </Button>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function PaymentsSettings() {
  const { t } = useTranslation();
  const [connectStatus, setConnectStatus] = useState<{
    connected: boolean;
    status: string;
    details: { chargesEnabled?: boolean; payoutsEnabled?: boolean; detailsSubmitted?: boolean; requirements?: string[]; dashboardUrl?: string } | null;
  } | null>(null);
  const [loading, setLoading] = useState(true);
  const [connecting, setConnecting] = useState(false);

  useEffect(() => {
    checkStatus();
  }, []);

  const checkStatus = async () => {
    setLoading(true);
    try {
      const supabase = getSupabase();
      const { data, error } = await supabase.functions.invoke('stripe-payments', {
        body: { action: 'check_connect_status' },
      });
      if (!error && data) setConnectStatus(data);
    } catch {
      // Stripe not configured — show not connected
      setConnectStatus({ connected: false, status: 'not_connected', details: null });
    } finally {
      setLoading(false);
    }
  };

  const startOnboarding = async () => {
    setConnecting(true);
    try {
      const supabase = getSupabase();
      const { data, error } = await supabase.functions.invoke('stripe-payments', {
        body: {
          action: 'create_connect_account',
          returnUrl: `${window.location.origin}/dashboard/settings?tab=payments&connect=success`,
          refreshUrl: `${window.location.origin}/dashboard/settings?tab=payments&connect=refresh`,
        },
      });
      if (!error && data?.onboardingUrl) {
        window.location.href = data.onboardingUrl;
      }
    } catch {
      // Handle error gracefully
    } finally {
      setConnecting(false);
    }
  };

  const statusConfig: Record<string, { icon: React.ReactNode; color: string; label: string }> = {
    active: { icon: <CheckCircle2 size={20} />, color: 'text-emerald-500', label: 'Connected & Active' },
    onboarding_incomplete: { icon: <AlertTriangle size={20} />, color: 'text-amber-500', label: 'Onboarding Incomplete' },
    restricted: { icon: <XCircle size={20} />, color: 'text-red-500', label: 'Restricted' },
    disabled: { icon: <XCircle size={20} />, color: 'text-red-500', label: 'Disabled' },
    not_connected: { icon: <DollarSign size={20} />, color: 'text-muted', label: 'Not Connected' },
  };

  const currentStatus = statusConfig[connectStatus?.status || 'not_connected'] || statusConfig.not_connected;

  return (
    <div className="space-y-6">
      {/* Stripe Connect */}
      <Card>
        <CardHeader>
          <CardTitle>{t('settings.acceptPaymentsViaStripe')}</CardTitle>
          <CardDescription>{t('settings.connectBankAccountDesc')}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {loading ? (
            <div className="space-y-3">
              <div className="h-20 bg-secondary rounded-xl animate-pulse" />
              <div className="h-12 bg-secondary rounded-xl animate-pulse" />
            </div>
          ) : (
            <>
              {/* Status Display */}
              <div className={cn(
                'flex items-center gap-4 p-4 rounded-xl border',
                connectStatus?.connected
                  ? 'border-emerald-200 bg-emerald-50 dark:border-emerald-800 dark:bg-emerald-900/20'
                  : 'border-main bg-secondary'
              )}>
                <div className={currentStatus.color}>{currentStatus.icon}</div>
                <div className="flex-1">
                  <p className="font-medium text-main">{currentStatus.label}</p>
                  <p className="text-sm text-muted">
                    {connectStatus?.connected
                      ? 'Payments from customers are routed directly to your bank account'
                      : connectStatus?.status === 'onboarding_incomplete'
                      ? 'Complete your Stripe onboarding to start accepting payments'
                      : 'Connect Stripe to accept card and ACH payments from your customers'}
                  </p>
                </div>
                <Button variant="ghost" size="sm" onClick={checkStatus}>
                  <RefreshCw size={14} />
                </Button>
              </div>

              {/* Action Buttons */}
              {!connectStatus?.connected && (
                <Button onClick={startOnboarding} disabled={connecting} className="w-full">
                  {connecting ? (
                    <><RefreshCw size={16} className="animate-spin" /> Connecting...</>
                  ) : connectStatus?.status === 'onboarding_incomplete' ? (
                    <><ExternalLink size={16} /> Continue Onboarding</>
                  ) : (
                    <><DollarSign size={16} /> Connect Stripe Account</>
                  )}
                </Button>
              )}

              {/* Connected Account Details */}
              {connectStatus?.connected && connectStatus.details && (
                <div className="space-y-3">
                  <div className="grid grid-cols-2 gap-3">
                    <div className="p-3 bg-secondary rounded-lg">
                      <p className="text-xs text-muted">{t('settings.cardPayments')}</p>
                      <p className="font-medium text-main flex items-center gap-1.5 mt-0.5">
                        {connectStatus.details.chargesEnabled ? <CheckCircle2 size={14} className="text-emerald-500" /> : <XCircle size={14} className="text-red-500" />}
                        {connectStatus.details.chargesEnabled ? 'Enabled' : 'Disabled'}
                      </p>
                    </div>
                    <div className="p-3 bg-secondary rounded-lg">
                      <p className="text-xs text-muted">{t('settings.payouts')}</p>
                      <p className="font-medium text-main flex items-center gap-1.5 mt-0.5">
                        {connectStatus.details.payoutsEnabled ? <CheckCircle2 size={14} className="text-emerald-500" /> : <XCircle size={14} className="text-red-500" />}
                        {connectStatus.details.payoutsEnabled ? 'Enabled' : 'Disabled'}
                      </p>
                    </div>
                  </div>
                  {connectStatus.details.dashboardUrl && (
                    <a
                      href={connectStatus.details.dashboardUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center gap-2 text-sm text-accent hover:underline"
                    >
                      <ExternalLink size={14} />
                      Open Stripe Express Dashboard
                    </a>
                  )}
                </div>
              )}

              {/* Outstanding Requirements */}
              {connectStatus?.details?.requirements && connectStatus.details.requirements.length > 0 && (
                <div className="p-3 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg">
                  <p className="text-sm font-medium text-amber-700 dark:text-amber-300 mb-1">{t('settings.actionRequired')}</p>
                  <ul className="text-xs text-amber-600 dark:text-amber-400 space-y-0.5">
                    {connectStatus.details.requirements.map((req, i) => (
                      <li key={i}>- {req.replace(/_/g, ' ')}</li>
                    ))}
                  </ul>
                </div>
              )}
            </>
          )}
        </CardContent>
      </Card>

      {/* Payment Settings */}
      <Card>
        <CardHeader>
          <CardTitle>{t('settings.paymentPreferences')}</CardTitle>
          <CardDescription>{t('settings.configureHowYouAcceptPaymentsFromCustomers')}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <ToggleItem
            label="Accept credit/debit cards"
            description="Visa, Mastercard, Amex via Stripe"
            checked={true}
            onChange={() => {}}
          />
          <ToggleItem
            label="Accept ACH bank transfers"
            description="Lower fees, 3-5 business day processing"
            checked={true}
            onChange={() => {}}
          />
          <ToggleItem
            label="Record manual payments"
            description="Track check, cash, and other offline payments"
            checked={true}
            onChange={() => {}}
          />
        </CardContent>
      </Card>

      {/* Platform Fee Info */}
      <Card>
        <CardHeader>
          <CardTitle>{t('settings.processingFees')}</CardTitle>
          <CardDescription>{t('settings.transparentPricingWithNoHiddenCharges')}</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            <div className="flex justify-between py-2 border-b border-light">
              <span className="text-sm text-muted">{t('settings.cardPayments')}</span>
              <span className="text-sm font-medium text-main">2.9% + 30c</span>
            </div>
            <div className="flex justify-between py-2 border-b border-light">
              <span className="text-sm text-muted">{t('settings.achBankTransfer')}</span>
              <span className="text-sm font-medium text-main">0.8% (max $5)</span>
            </div>
            <div className="flex justify-between py-2">
              <span className="text-sm text-muted">{t('settings.manualPaymentRecording')}</span>
              <span className="text-sm font-medium text-main">{t('settings.free')}</span>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function NotificationSettings() {
  const { t } = useTranslation();
  const [notifications, setNotifications] = useState({
    email_bids: true,
    email_invoices: true,
    email_jobs: false,
    push_all: true,
    sms_urgent: true,
  });

  const toggle = (key: keyof typeof notifications) => {
    setNotifications((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>{t('settings.emailNotifications')}</CardTitle>
          <CardDescription>{t('settings.chooseWhatEmailsYouReceive')}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <ToggleItem
            label="Bid activity"
            description="When bids are viewed, accepted, or rejected"
            checked={notifications.email_bids}
            onChange={() => toggle('email_bids')}
          />
          <ToggleItem
            label="Invoice activity"
            description="When invoices are paid or overdue"
            checked={notifications.email_invoices}
            onChange={() => toggle('email_invoices')}
          />
          <ToggleItem
            label="Job updates"
            description="When jobs are created, updated, or completed"
            checked={notifications.email_jobs}
            onChange={() => toggle('email_jobs')}
          />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>{t('settings.pushNotifications')}</CardTitle>
          <CardDescription>{t('settings.mobileAppNotifications')}</CardDescription>
        </CardHeader>
        <CardContent>
          <ToggleItem
            label="Enable all push notifications"
            description="Receive alerts on your mobile device"
            checked={notifications.push_all}
            onChange={() => toggle('push_all')}
          />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>{t('settings.smsNotifications')}</CardTitle>
          <CardDescription>{t('settings.textMessageAlerts')}</CardDescription>
        </CardHeader>
        <CardContent>
          <ToggleItem
            label="Urgent alerts only"
            description="Emergency jobs and critical updates"
            checked={notifications.sms_urgent}
            onChange={() => toggle('sms_urgent')}
          />
        </CardContent>
      </Card>

      <AutomatedTriggersCard />
    </div>
  );
}

function AutomatedTriggersCard() {
  const { t } = useTranslation();
  const { prefs, updatePrefs } = useNotificationPreferences();

  const togglePref = (key: string, channel: 'in_app' | 'email' | 'sms') => {
    const current = prefs[key as keyof NotificationPreferences];
    const updated = { ...prefs, [key]: { ...current, [channel]: !current[channel] } };
    updatePrefs(updated);
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>{t('settings.automatedAlerts')}</CardTitle>
        <CardDescription>{t('settings.configureWhichAutomatedTriggersNotifyYouAndHow')}</CardDescription>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          <div className="grid grid-cols-4 gap-4 text-xs text-muted pb-2 border-b border-border">
            <div>{t('settings.trigger')}</div>
            <div className="text-center">{t('settings.inapp')}</div>
            <div className="text-center">{t('common.email')}</div>
            <div className="text-center">{t('phone.sms')}</div>
          </div>
          {Object.entries(TRIGGER_LABELS).map(([key, label]) => {
            const p = prefs[key as keyof NotificationPreferences];
            return (
              <div key={key} className="grid grid-cols-4 gap-4 items-center text-sm py-1">
                <div className="text-main">{label}</div>
                {(['in_app', 'email', 'sms'] as const).map((ch) => (
                  <div key={ch} className="flex justify-center">
                    <button
                      onClick={() => togglePref(key, ch)}
                      className={`w-8 h-5 rounded-full transition-colors ${p[ch] ? 'bg-accent' : 'bg-surface-hover'}`}
                    >
                      <div className={`w-3.5 h-3.5 rounded-full bg-white transition-transform ${p[ch] ? 'translate-x-3.5' : 'translate-x-0.5'}`} />
                    </button>
                  </div>
                ))}
              </div>
            );
          })}
        </div>
      </CardContent>
    </Card>
  );
}

function AppearanceSettings() {
  const { t } = useTranslation();
  const [theme, setTheme] = useState('light');

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>{t('common.theme')}</CardTitle>
          <CardDescription>{t('settings.chooseYourPreferredColorScheme')}</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-3 gap-4">
            {[
              { id: 'light', label: 'Light', bg: 'bg-white', border: 'border-slate-200' },
              { id: 'dark', label: 'Dark', bg: 'bg-slate-900', border: 'border-slate-700' },
              { id: 'system', label: 'System', bg: 'bg-gradient-to-r from-white to-slate-900', border: 'border-slate-300' },
            ].map((option) => (
              <button
                key={option.id}
                onClick={() => setTheme(option.id)}
                className={cn(
                  'p-4 rounded-xl border-2 transition-colors',
                  theme === option.id
                    ? 'border-accent'
                    : 'border-main hover:border-accent/50'
                )}
              >
                <div className={cn('w-full h-20 rounded-lg mb-3', option.bg, 'border', option.border)} />
                <p className="font-medium text-main">{option.label}</p>
              </button>
            ))}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>{t('settings.accentColor')}</CardTitle>
          <CardDescription>{t('settings.brandColorForButtonsAndHighlights')}</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-3">
            {['#3b82f6', '#10b981', '#8b5cf6', '#f59e0b', '#ef4444', '#ec4899'].map((color) => (
              <button
                key={color}
                className="w-10 h-10 rounded-full border-2 border-white shadow-md transition-transform hover:scale-110"
                style={{ backgroundColor: color }}
              />
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Language Selector */}
      <Card>
        <CardHeader>
          <CardTitle>{t('settings.language')}</CardTitle>
          <CardDescription>{t('settings.chooseYourPreferredLanguageAffectsAllUiText')}</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-5 gap-2">
            {[
              { code: 'en', name: 'English', flag: 'US' },
              { code: 'es', name: 'Espa\u00f1ol', flag: 'MX' },
              { code: 'pt-BR', name: 'Portugu\u00eas', flag: 'BR' },
              { code: 'pl', name: 'Polski', flag: 'PL' },
              { code: 'zh', name: '\u4e2d\u6587', flag: 'CN' },
              { code: 'ht', name: 'Krey\u00f2l', flag: 'HT' },
              { code: 'ru', name: '\u0420\u0443\u0441\u0441\u043a\u0438\u0439', flag: 'RU' },
              { code: 'ko', name: '\ud55c\uad6d\uc5b4', flag: 'KR' },
              { code: 'vi', name: 'Ti\u1ebfng Vi\u1ec7t', flag: 'VN' },
              { code: 'tl', name: 'Tagalog', flag: 'PH' },
            ].map((lang) => (
              <button
                key={lang.code}
                className={cn(
                  'px-3 py-2 rounded-lg border text-sm font-medium transition-colors text-left',
                  lang.code === 'en'
                    ? 'border-accent bg-accent-light text-accent'
                    : 'border-main text-muted hover:text-main hover:border-accent/50'
                )}
              >
                <span className="text-xs text-muted mr-1">{lang.flag}</span> {lang.name}
              </button>
            ))}
          </div>
          <p className="text-xs text-muted mt-3">{t('settings.moreTranslationsComingSoonLanguagePreferenceSavedT')}</p>
        </CardContent>
      </Card>

    </div>
  );
}


function GoodBetterBestCard() {
  const { t } = useTranslation();
  const [enabled, setEnabled] = useState(() => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('zafto_gbb_pricing') === 'true';
    }
    return false;
  });

  const handleToggle = async () => {
    const newValue = !enabled;
    setEnabled(newValue);
    localStorage.setItem('zafto_gbb_pricing', String(newValue));
    try {
      const supabase = getSupabase();
      const { data: company } = await supabase
        .from('companies')
        .select('settings')
        .single();
      const settings = (company?.settings as Record<string, unknown>) || {};
      await supabase
        .from('companies')
        .update({ settings: { ...settings, bid_pricing_tiers: newValue } })
        .not('id', 'is', null);
    } catch {
      setEnabled(!newValue);
      localStorage.setItem('zafto_gbb_pricing', String(!newValue));
    }
  };

  return (
    <Card className={cn('transition-colors', enabled && 'border-accent/50 bg-accent/5')}>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className={cn('p-2.5 rounded-xl transition-colors', enabled ? 'bg-accent/20' : 'bg-secondary')}>
              <Layers size={22} className={enabled ? 'text-accent' : 'text-muted'} />
            </div>
            <div>
              <CardTitle className="flex items-center gap-2">
                Good / Better / Best Pricing
                {enabled && (
                  <span className="px-2 py-0.5 text-[10px] font-bold bg-accent text-white rounded">{t('common.on')}</span>
                )}
              </CardTitle>
              <CardDescription>
                {enabled
                  ? 'Bids show three pricing columns for clients to choose from'
                  : 'Single price column on bids'}
              </CardDescription>
            </div>
          </div>
          <button
            onClick={handleToggle}
            className={cn(
              'w-11 h-6 rounded-full transition-colors relative flex-shrink-0',
              enabled ? 'bg-accent' : 'bg-secondary'
            )}
          >
            <span
              className={cn(
                'absolute top-1 w-4 h-4 bg-white rounded-full shadow-sm transition-all duration-200',
                enabled ? 'left-6' : 'left-1'
              )}
            />
          </button>
        </div>
      </CardHeader>
      {enabled && (
        <CardContent>
          <div className="flex items-start gap-3 p-3 rounded-lg bg-secondary/50">
            <Info size={16} className="text-muted mt-0.5 flex-shrink-0" />
            <p className="text-sm text-muted">
              When enabled, bids show Good, Better, and Best columns with different scope
              and material options per tier. Clients choose the option that fits their budget.
            </p>
          </div>
        </CardContent>
      )}
    </Card>
  );
}

function SecuritySettings() {
  const { t } = useTranslation();
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmNewPassword, setConfirmNewPassword] = useState('');
  const [passwordLoading, setPasswordLoading] = useState(false);
  const [passwordMsg, setPasswordMsg] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  // MFA state
  const [mfaFactors, setMfaFactors] = useState<{ id: string; type: string; status: string; friendly_name?: string }[]>([]);
  const [mfaLoading, setMfaLoading] = useState(true);
  const [enrolling, setEnrolling] = useState(false);
  const [enrollData, setEnrollData] = useState<{ id: string; qr: string; secret: string; uri: string } | null>(null);
  const [verifyCode, setVerifyCode] = useState('');
  const [mfaMsg, setMfaMsg] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  // Session state
  const [sessionInfo, setSessionInfo] = useState<{ provider: string; lastSignIn: string; email: string } | null>(null);

  // Load MFA factors and session info
  useEffect(() => {
    const load = async () => {
      const supabase = getSupabase();
      try {
        const { data, error } = await supabase.auth.mfa.listFactors();
        if (!error && data) {
          setMfaFactors(data.totp.map((f: { id: string; factor_type: string; status: string; friendly_name?: string }) => ({
            id: f.id,
            type: f.factor_type,
            status: f.status,
            friendly_name: f.friendly_name,
          })));
        }
      } catch {
        // MFA might not be enabled on this Supabase project
      }

      const { data: { session } } = await supabase.auth.getSession();
      if (session) {
        const provider = session.user?.app_metadata?.provider || 'email';
        setSessionInfo({
          provider,
          lastSignIn: session.user?.last_sign_in_at || '',
          email: session.user?.email || '',
        });
      }
      setMfaLoading(false);
    };
    load();
  }, []);

  const handlePasswordUpdate = async () => {
    setPasswordMsg(null);
    if (!newPassword || newPassword.length < 8) {
      setPasswordMsg({ type: 'error', text: 'New password must be at least 8 characters' });
      return;
    }
    if (newPassword !== confirmNewPassword) {
      setPasswordMsg({ type: 'error', text: 'Passwords do not match' });
      return;
    }
    setPasswordLoading(true);
    try {
      const supabase = getSupabase();
      // Supabase updateUser uses the current session to change password
      const { error } = await supabase.auth.updateUser({ password: newPassword });
      if (error) {
        if (error.message.includes('same as')) {
          setPasswordMsg({ type: 'error', text: 'New password must be different from your current password' });
        } else {
          setPasswordMsg({ type: 'error', text: error.message });
        }
      } else {
        setPasswordMsg({ type: 'success', text: 'Password updated successfully' });
        setCurrentPassword('');
        setNewPassword('');
        setConfirmNewPassword('');
      }
    } catch {
      setPasswordMsg({ type: 'error', text: 'Failed to update password' });
    } finally {
      setPasswordLoading(false);
    }
  };

  const handleMfaEnroll = async () => {
    setMfaMsg(null);
    setEnrolling(true);
    try {
      const supabase = getSupabase();
      const { data, error } = await supabase.auth.mfa.enroll({
        factorType: 'totp',
        friendlyName: 'Authenticator App',
      });
      if (error) {
        setMfaMsg({ type: 'error', text: error.message });
        setEnrolling(false);
        return;
      }
      if (data) {
        setEnrollData({
          id: data.id,
          qr: data.totp.qr_code,
          secret: data.totp.secret,
          uri: data.totp.uri,
        });
      }
    } catch {
      setMfaMsg({ type: 'error', text: 'Failed to start MFA enrollment' });
      setEnrolling(false);
    }
  };

  const handleMfaVerify = async () => {
    if (!enrollData || verifyCode.length !== 6) return;
    setMfaMsg(null);
    try {
      const supabase = getSupabase();
      const { data: challenge, error: challengeErr } = await supabase.auth.mfa.challenge({
        factorId: enrollData.id,
      });
      if (challengeErr) {
        setMfaMsg({ type: 'error', text: challengeErr.message });
        return;
      }
      const { error: verifyErr } = await supabase.auth.mfa.verify({
        factorId: enrollData.id,
        challengeId: challenge.id,
        code: verifyCode,
      });
      if (verifyErr) {
        setMfaMsg({ type: 'error', text: 'Invalid code. Please try again.' });
        return;
      }
      // Success — refresh factors
      setMfaMsg({ type: 'success', text: '2FA enabled successfully' });
      setEnrollData(null);
      setEnrolling(false);
      setVerifyCode('');
      const { data } = await supabase.auth.mfa.listFactors();
      if (data) {
        setMfaFactors(data.totp.map((f: { id: string; factor_type: string; status: string; friendly_name?: string }) => ({
          id: f.id,
          type: f.factor_type,
          status: f.status,
          friendly_name: f.friendly_name,
        })));
      }
    } catch {
      setMfaMsg({ type: 'error', text: 'Verification failed' });
    }
  };

  const handleMfaUnenroll = async (factorId: string) => {
    setMfaMsg(null);
    try {
      const supabase = getSupabase();
      const { error } = await supabase.auth.mfa.unenroll({ factorId });
      if (error) {
        setMfaMsg({ type: 'error', text: error.message });
        return;
      }
      setMfaFactors((prev) => prev.filter((f) => f.id !== factorId));
      setMfaMsg({ type: 'success', text: '2FA has been disabled' });
    } catch {
      setMfaMsg({ type: 'error', text: 'Failed to disable 2FA' });
    }
  };

  const verifiedFactors = mfaFactors.filter((f) => f.status === 'verified');
  const hasActiveMfa = verifiedFactors.length > 0;

  return (
    <div className="space-y-6">
      {/* Password Change — Real */}
      <Card>
        <CardHeader>
          <CardTitle>{t('settings.password')}</CardTitle>
          <CardDescription>{t('settings.updateYourPassword')}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {passwordMsg && (
            <div className={cn(
              'px-3 py-2.5 rounded-lg flex items-center gap-2 text-sm',
              passwordMsg.type === 'success'
                ? 'bg-emerald-500/10 text-emerald-400'
                : 'bg-red-500/10 text-red-400'
            )}>
              {passwordMsg.type === 'success' ? <CheckCircle2 size={15} /> : <XCircle size={15} />}
              {passwordMsg.text}
            </div>
          )}
          <Input
            label={t('settings.currentPassword')}
            type="password"
            value={currentPassword}
            onChange={(e) => setCurrentPassword(e.target.value)}
            autoComplete="current-password"
          />
          <Input
            label={t('settings.newPassword')}
            type="password"
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
            placeholder="Min 8 characters"
            autoComplete="new-password"
          />
          <Input
            label="Confirm New Password"
            type="password"
            value={confirmNewPassword}
            onChange={(e) => setConfirmNewPassword(e.target.value)}
            autoComplete="new-password"
          />
          <Button
            onClick={handlePasswordUpdate}
            disabled={passwordLoading || !newPassword || newPassword.length < 8 || newPassword !== confirmNewPassword}
          >
            {passwordLoading ? (
              <span className="flex items-center gap-2">
                <RefreshCw size={14} className="animate-spin" />
                Updating...
              </span>
            ) : 'Update Password'}
          </Button>
        </CardContent>
      </Card>

      {/* Two-Factor Authentication — Real Supabase MFA TOTP */}
      <Card>
        <CardHeader>
          <CardTitle>{t('settings.twoFactorAuth')}</CardTitle>
          <CardDescription>{t('settings.addAnExtraLayerOfSecurityToYourAccount')}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {mfaMsg && (
            <div className={cn(
              'px-3 py-2.5 rounded-lg flex items-center gap-2 text-sm',
              mfaMsg.type === 'success'
                ? 'bg-emerald-500/10 text-emerald-400'
                : 'bg-red-500/10 text-red-400'
            )}>
              {mfaMsg.type === 'success' ? <CheckCircle2 size={15} /> : <XCircle size={15} />}
              {mfaMsg.text}
            </div>
          )}

          {mfaLoading ? (
            <div className="flex items-center gap-2 text-sm text-muted">
              <RefreshCw size={14} className="animate-spin" />
              Loading...
            </div>
          ) : enrollData ? (
            /* Enrollment flow — show QR + verify */
            <div className="space-y-4">
              <div className="flex items-start gap-3 p-3 rounded-lg bg-secondary/50">
                <Info size={16} className="text-muted mt-0.5 flex-shrink-0" />
                <p className="text-sm text-muted">
                  Scan this QR code with your authenticator app (Google Authenticator, Authy, 1Password, etc.), then enter the 6-digit code below to verify.
                </p>
              </div>
              <div className="flex justify-center p-4 bg-white rounded-lg w-fit mx-auto">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={enrollData.qr} alt="QR Code for authenticator app" width={200} height={200} />
              </div>
              <div className="space-y-1">
                <p className="text-xs text-muted">Can&apos;t scan? Enter this key manually:</p>
                <code className="block text-xs bg-secondary/50 p-2 rounded font-mono break-all select-all">{enrollData.secret}</code>
              </div>
              <div className="flex items-end gap-3">
                <Input
                  label="Verification Code"
                  value={verifyCode}
                  onChange={(e) => setVerifyCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                  placeholder="000000"
                  className="font-mono tracking-widest"
                  maxLength={6}
                />
                <Button
                  onClick={handleMfaVerify}
                  disabled={verifyCode.length !== 6}
                >
                  Verify
                </Button>
                <Button
                  variant="ghost"
                  onClick={() => {
                    setEnrollData(null);
                    setEnrolling(false);
                    setVerifyCode('');
                  }}
                >
                  Cancel
                </Button>
              </div>
            </div>
          ) : hasActiveMfa ? (
            /* Already enrolled — show status + disable option */
            <div className="space-y-3">
              {verifiedFactors.map((factor) => (
                <div key={factor.id} className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full bg-emerald-500/15 flex items-center justify-center">
                      <Shield size={16} className="text-emerald-400" />
                    </div>
                    <div>
                      <p className="font-medium text-main text-sm">{factor.friendly_name || 'Authenticator App'}</p>
                      <p className="text-xs text-muted">{t('settings.totpEnabled')}</p>
                    </div>
                  </div>
                  <Button
                    variant="ghost"
                    size="sm"
                    className="text-red-500 hover:text-red-400"
                    onClick={() => handleMfaUnenroll(factor.id)}
                  >
                    Disable
                  </Button>
                </div>
              ))}
            </div>
          ) : (
            /* Not enrolled — show enable button */
            <div className="flex items-center justify-between">
              <div>
                <p className="font-medium text-main">{t('settings.authenticatorApp')}</p>
                <p className="text-sm text-muted">{t('settings.useAnAppLikeGoogleAuthenticatorOrAuthy')}</p>
              </div>
              <Button variant="secondary" onClick={handleMfaEnroll} disabled={enrolling}>
                {enrolling ? (
                  <span className="flex items-center gap-2">
                    <RefreshCw size={14} className="animate-spin" />
                    Setting up...
                  </span>
                ) : 'Enable'}
              </Button>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Current Session — Real */}
      <Card>
        <CardHeader>
          <CardTitle>{t('settings.currentSession')}</CardTitle>
          <CardDescription>{t('settings.yourActiveSessionInformation')}</CardDescription>
        </CardHeader>
        <CardContent>
          {sessionInfo ? (
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <p className="font-medium text-main text-sm">{sessionInfo.email}</p>
                <p className="text-xs text-muted">
                  Signed in via {sessionInfo.provider}
                  {sessionInfo.lastSignIn && (
                    <> &middot; Last sign in {formatRelativeTime(sessionInfo.lastSignIn)}</>
                  )}
                </p>
              </div>
              <Badge variant="success">{t('common.active')}</Badge>
            </div>
          ) : (
            <p className="text-sm text-muted">{t('settings.loadingSessionInfo')}</p>
          )}
        </CardContent>
      </Card>

      {/* Sign out all devices */}
      <Card>
        <CardHeader>
          <CardTitle>{t('settings.signOutEverywhere')}</CardTitle>
          <CardDescription>{t('settings.signOutOfAllDevicesAndSessions')}</CardDescription>
        </CardHeader>
        <CardContent>
          <Button
            variant="secondary"
            className="text-red-500"
            onClick={async () => {
              const supabase = getSupabase();
              await supabase.auth.signOut({ scope: 'global' });
              window.location.href = '/';
            }}
          >
            Sign Out All Devices
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}

function IntegrationSettings() {
  const { t } = useTranslation();
  const gcal = useGoogleCalendar();

  const integrations = [
    { name: 'QuickBooks', description: 'Sync invoices and payments', connected: false },
    { name: 'Stripe', description: 'Accept card payments', connected: false },
    { name: 'Square', description: 'Accept card & tap payments', connected: false },
    { name: 'PayPal', description: 'Accept PayPal payments', connected: false },
  ];

  return (
    <div className="space-y-6">
      {/* Google Calendar — real integration */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Calendar size={18} /> Google Calendar
          </CardTitle>
          <CardDescription>{t('settings.twowaySyncBetweenZaftoJobsAndGoogleCalendar')}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          {gcal.connected ? (
            <>
              <div className="flex items-center gap-3">
                <Badge variant="success">{t('common.connected')}</Badge>
                {gcal.email && <span className="text-sm text-muted">{gcal.email}</span>}
              </div>
              <div className="flex items-center gap-2">
                <Button variant="secondary" size="sm" onClick={() => gcal.syncNow()}>{t('settings.syncNow')}</Button>
                <Button variant="ghost" size="sm" onClick={() => gcal.disconnect()}>{t('settings.disconnect')}</Button>
              </div>
            </>
          ) : (
            <div>
              <p className="text-sm text-muted mb-3">{t('settings.connectYourGoogleCalendarToSyncScheduledJobsAutoma')}</p>
              <Button
                variant="secondary"
                size="sm"
                onClick={() => {
                  const clientId = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID || '';
                  const redirect = `${window.location.origin}/api/auth/google-callback`;
                  const scope = 'https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/userinfo.email';
                  const url = `https://accounts.google.com/o/oauth2/v2/auth?client_id=${clientId}&redirect_uri=${encodeURIComponent(redirect)}&response_type=code&scope=${encodeURIComponent(scope)}&access_type=offline&prompt=consent`;
                  window.location.href = url;
                }}
              >
                Connect Google Calendar
              </Button>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Other integrations */}
      <Card>
        <CardHeader>
          <CardTitle>{t('settings.connectedApps')}</CardTitle>
          <CardDescription>{t('settings.manageThirdpartyIntegrations')}</CardDescription>
        </CardHeader>
        <CardContent className="p-0">
          <div className="divide-y divide-main">
            {integrations.map((integration) => (
              <div key={integration.name} className="flex items-center justify-between px-6 py-4">
                <div>
                  <p className="font-medium text-main">{integration.name}</p>
                  <p className="text-sm text-muted">{integration.description}</p>
                </div>
                {integration.connected ? (
                  <div className="flex items-center gap-3">
                    <Badge variant="success">{t('common.connected')}</Badge>
                    <Button variant="ghost" size="sm">{t('common.manage')}</Button>
                  </div>
                ) : (
                  <Button variant="secondary" size="sm">{t('settings.connect')}</Button>
                )}
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ============================================================
// ENTERPRISE SETTINGS TABS
// ============================================================

const AVAILABLE_TRADES = [
  { id: 'hvac', label: 'HVAC', description: 'Heating, ventilation, and air conditioning' },
  { id: 'plumbing', label: 'Plumbing', description: 'Residential and commercial plumbing' },
  { id: 'electrical', label: 'Electrical', description: 'Electrical systems and wiring' },
  { id: 'roofing', label: 'Roofing', description: 'Roof installation, repair, and inspection' },
  { id: 'restoration', label: 'Restoration', description: 'Water, fire, and mold remediation' },
  { id: 'general', label: 'General Contractor', description: 'Multi-trade project management' },
  { id: 'painting', label: 'Painting', description: 'Interior and exterior painting' },
  { id: 'solar', label: 'Solar', description: 'Solar panel installation and service' },
  { id: 'pool', label: 'Pool & Spa', description: 'Pool construction, service, and repair' },
  { id: 'pest', label: 'Pest Control', description: 'Pest management and WDO inspections' },
  { id: 'landscaping', label: 'Landscaping', description: 'Landscaping and irrigation' },
  { id: 'fire_protection', label: 'Fire Protection', description: 'Sprinkler systems and fire safety' },
  { id: 'chimney', label: 'Chimney', description: 'Chimney inspection, sweep, and repair' },
  { id: 'environmental', label: 'Environmental', description: 'Environmental testing and remediation' },
  { id: 'septic', label: 'Septic', description: 'Septic system service and inspection' },
  { id: 'garage_door', label: 'Garage Door', description: 'Garage door installation and repair' },
  { id: 'locksmith', label: 'Locksmith', description: 'Lock and security systems' },
  { id: 'appliance', label: 'Appliance Repair', description: 'Home appliance service and repair' },
  { id: 'flooring', label: 'Flooring', description: 'Floor installation and refinishing' },
  { id: 'insulation', label: 'Insulation', description: 'Insulation installation and upgrades' },
];

function BranchesSettings() {
  const { t } = useTranslation();
  const { branches, loading, createBranch, updateBranch, deleteBranch } = useBranches();
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState({ name: '', address: '', city: '', state: '', zipCode: '', phone: '', email: '', timezone: 'America/New_York' });

  const handleSave = async () => {
    try {
      if (editingId) {
        await updateBranch(editingId, formData as unknown as Partial<Branch>);
      } else {
        await createBranch(formData as unknown as Partial<Branch>);
      }
      setShowForm(false);
      setEditingId(null);
      setFormData({ name: '', address: '', city: '', state: '', zipCode: '', phone: '', email: '', timezone: 'America/New_York' });
    } catch {
      // Error handling via hook
    }
  };

  const handleEdit = (branch: Branch) => {
    setEditingId(branch.id);
    setFormData({
      name: branch.name,
      address: branch.address || '',
      city: branch.city || '',
      state: branch.state || '',
      zipCode: branch.zipCode || '',
      phone: branch.phone || '',
      email: branch.email || '',
      timezone: branch.timezone,
    });
    setShowForm(true);
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>{t('settings.branches')}</CardTitle>
              <CardDescription>{t('settings.manageCompanyLocationsAndAssignTeamMembers')}</CardDescription>
            </div>
            <Button onClick={() => { setShowForm(true); setEditingId(null); setFormData({ name: '', address: '', city: '', state: '', zipCode: '', phone: '', email: '', timezone: 'America/New_York' }); }}>
              <Plus size={16} className="mr-2" />
              Add Branch
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {showForm && (
            <div className="mb-6 p-4 border border-main rounded-lg space-y-4">
              <h4 className="font-medium text-main">{editingId ? 'Edit Branch' : 'New Branch'}</h4>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <Input label="Branch Name" value={formData.name} onChange={(e) => setFormData({ ...formData, name: e.target.value })} />
                <Input label={t('phone.title')} value={formData.phone} onChange={(e) => setFormData({ ...formData, phone: e.target.value })} />
                <Input label={t('common.address')} value={formData.address} onChange={(e) => setFormData({ ...formData, address: e.target.value })} />
                <Input label={t('common.city')} value={formData.city} onChange={(e) => setFormData({ ...formData, city: e.target.value })} />
                <Input label={t('common.state')} value={formData.state} onChange={(e) => setFormData({ ...formData, state: e.target.value })} />
                <Input label={t('common.zip')} value={formData.zipCode} onChange={(e) => setFormData({ ...formData, zipCode: e.target.value })} />
              </div>
              <div className="flex gap-2">
                <Button onClick={handleSave}>{editingId ? 'Update' : 'Create'}</Button>
                <Button variant="ghost" onClick={() => { setShowForm(false); setEditingId(null); }}>{t('common.cancel')}</Button>
              </div>
            </div>
          )}

          {loading ? (
            <div className="space-y-3">
              {[1, 2].map((i) => <div key={i} className="h-16 bg-secondary rounded-lg animate-pulse" />)}
            </div>
          ) : branches.length === 0 ? (
            <div className="text-center py-8 text-muted">
              <GitBranch size={32} className="mx-auto mb-2 opacity-40" />
              <p>{t('settings.noBranchesYetAddYourFirstLocation')}</p>
            </div>
          ) : (
            <div className="space-y-2">
              {branches.map((branch) => (
                <div key={branch.id} className="flex items-center justify-between p-4 bg-secondary rounded-lg">
                  <div>
                    <p className="font-medium text-main">{branch.name}</p>
                    <p className="text-sm text-muted">
                      {[branch.city, branch.state].filter(Boolean).join(', ') || 'No address'}
                    </p>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant={branch.isActive ? 'success' : 'secondary'}>
                      {branch.isActive ? 'Active' : 'Inactive'}
                    </Badge>
                    <Button variant="ghost" size="sm" onClick={() => handleEdit(branch)}><Edit size={14} /></Button>
                    <Button variant="ghost" size="sm" onClick={() => deleteBranch(branch.id)}><Trash2 size={14} /></Button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function RolesSettings() {
  const { t } = useTranslation();
  const { roles, loading, createRole, updateRole, deleteRole } = useCustomRoles();
  const { isBusinessOrHigher, isEnterprise } = usePermissions();
  const { thresholds, createThreshold, updateThreshold } = useApprovals();
  const [expandedRole, setExpandedRole] = useState<string | null>(null);

  const permissionCategories = [
    { label: 'Jobs', perms: [PERMISSIONS.JOBS_VIEW_ALL, PERMISSIONS.JOBS_CREATE, PERMISSIONS.JOBS_EDIT_ALL, PERMISSIONS.JOBS_DELETE, PERMISSIONS.JOBS_ASSIGN] },
    { label: 'Bids', perms: [PERMISSIONS.BIDS_VIEW_ALL, PERMISSIONS.BIDS_CREATE, PERMISSIONS.BIDS_EDIT_ALL, PERMISSIONS.BIDS_SEND, PERMISSIONS.BIDS_APPROVE] },
    { label: 'Invoices', perms: [PERMISSIONS.INVOICES_VIEW_ALL, PERMISSIONS.INVOICES_CREATE, PERMISSIONS.INVOICES_EDIT, PERMISSIONS.INVOICES_SEND, PERMISSIONS.INVOICES_APPROVE] },
    { label: 'Customers', perms: [PERMISSIONS.CUSTOMERS_VIEW_ALL, PERMISSIONS.CUSTOMERS_CREATE, PERMISSIONS.CUSTOMERS_EDIT, PERMISSIONS.CUSTOMERS_DELETE] },
    { label: 'Team', perms: [PERMISSIONS.TEAM_VIEW, PERMISSIONS.TEAM_INVITE, PERMISSIONS.TEAM_EDIT, PERMISSIONS.TEAM_REMOVE] },
    { label: 'Finance', perms: [PERMISSIONS.FINANCIALS_VIEW, PERMISSIONS.FINANCIALS_MANAGE, PERMISSIONS.PAYROLL_VIEW, PERMISSIONS.PAYROLL_MANAGE] },
    { label: 'Admin', perms: [PERMISSIONS.COMPANY_SETTINGS, PERMISSIONS.BILLING_MANAGE, PERMISSIONS.ROLES_MANAGE, PERMISSIONS.AUDIT_VIEW] },
    { label: 'Clock', perms: [PERMISSIONS.TIMECLOCK_OWN, PERMISSIONS.TIMECLOCK_VIEW_ALL, PERMISSIONS.TIMECLOCK_MANAGE] },
    { label: 'Schedule', perms: [PERMISSIONS.SCHEDULING_VIEW, PERMISSIONS.SCHEDULING_MANAGE, PERMISSIONS.DISPATCH_VIEW, PERMISSIONS.DISPATCH_MANAGE] },
  ];

  const builtInRoles = [
    { key: 'owner', label: 'Owner', color: 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-300', desc: 'Full access to everything' },
    { key: 'admin', label: 'Admin', color: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300', desc: 'Everything except billing' },
    { key: 'office_manager', label: 'Office Mgr', color: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300', desc: 'Operations & scheduling' },
    { key: 'technician', label: 'Technician', color: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300', desc: 'Assigned jobs & field tools' },
    { key: 'apprentice', label: 'Apprentice', color: 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-300', desc: 'Field work, no financials' },
    { key: 'cpa', label: 'CPA', color: 'bg-secondary text-main', desc: 'Financials & reports only' },
  ];

  const getAccessLevel = (roleKey: string, categoryPerms: string[]): 'full' | 'partial' | 'own' | 'none' => {
    const rolePerms = ROLE_PERMISSIONS[roleKey] || [];
    const matching = categoryPerms.filter((p) => rolePerms.includes(p as Permission));
    if (matching.length === 0) return 'none';
    if (matching.length === categoryPerms.length) return 'full';
    const category = categoryPerms[0]?.split('.')[0];
    const hasOwn = rolePerms.some((p) => p.startsWith(category + '.') && p.includes('.own'));
    if (hasOwn && matching.length <= 2) return 'own';
    return 'partial';
  };

  const allPermissions = [
    { group: 'Jobs', keys: ['jobs.view.own', 'jobs.view.all', 'jobs.create', 'jobs.edit.own', 'jobs.edit.all', 'jobs.delete', 'jobs.assign'] },
    { group: 'Bids', keys: ['bids.view.own', 'bids.view.all', 'bids.create', 'bids.edit.own', 'bids.edit.all', 'bids.send', 'bids.approve', 'bids.delete'] },
    { group: 'Invoices', keys: ['invoices.view.own', 'invoices.view.all', 'invoices.create', 'invoices.edit', 'invoices.send', 'invoices.approve', 'invoices.void'] },
    { group: 'Customers', keys: ['customers.view.own', 'customers.view.all', 'customers.create', 'customers.edit', 'customers.delete'] },
    { group: 'Team', keys: ['team.view', 'team.invite', 'team.edit', 'team.remove'] },
    { group: 'Finance', keys: ['financials.view', 'financials.manage', 'payroll.view', 'payroll.manage'] },
    { group: 'Admin', keys: ['company.settings', 'billing.manage', 'roles.manage', 'audit.view'] },
    { group: 'Time Clock', keys: ['timeclock.own', 'timeclock.view.all', 'timeclock.manage'] },
    { group: 'Schedule', keys: ['scheduling.view', 'scheduling.manage', 'dispatch.view', 'dispatch.manage'] },
    { group: 'Properties', keys: ['properties.view', 'properties.create', 'properties.edit', 'properties.delete'] },
    { group: 'Reports', keys: ['reports.view', 'reports.export'] },
    { group: 'Enterprise', keys: ['branches.view', 'branches.manage', 'certifications.view', 'certifications.manage', 'forms.view', 'forms.manage', 'api_keys.manage'] },
    { group: 'Fleet', keys: ['fleet.view', 'fleet.manage'] },
  ];

  return (
    <div className="space-y-6">
      {/* Default Role Permissions Matrix */}
      <Card>
        <CardHeader>
          <CardTitle>{t('settings.defaultRolePermissions')}</CardTitle>
          <CardDescription>{t('settings.rolesPermissionsDesc')}</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto -mx-6">
            <table className="w-full text-sm min-w-[700px]">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left py-3 pl-6 pr-4 font-medium text-muted text-[11px] uppercase tracking-wider w-36">{t('common.role')}</th>
                  {permissionCategories.map((cat) => (
                    <th key={cat.label} className="text-center py-3 px-1 font-medium text-muted text-[11px] uppercase tracking-wider">{cat.label}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {builtInRoles.map((role) => (
                  <tr key={role.key} className="border-b border-light last:border-0 hover:bg-surface-hover/50 transition-colors">
                    <td className="py-3 pl-6 pr-4">
                      <span className={cn('px-2 py-0.5 text-[11px] font-medium rounded-full whitespace-nowrap', role.color)}>{role.label}</span>
                      <p className="text-[11px] text-muted mt-0.5">{role.desc}</p>
                    </td>
                    {permissionCategories.map((cat) => {
                      const level = getAccessLevel(role.key, cat.perms);
                      return (
                        <td key={cat.label} className="text-center py-3 px-1">
                          {level === 'full' ? (
                            <Check size={15} className="mx-auto text-emerald-500" />
                          ) : level === 'partial' ? (
                            <div className="mx-auto w-3.5 h-3.5 rounded-full border-2 border-amber-400 bg-amber-400/20" />
                          ) : level === 'own' ? (
                            <span className="text-[10px] font-medium text-amber-600">{t('common.own')}</span>
                          ) : (
                            <span className="text-muted/40">{'\u2014'}</span>
                          )}
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="flex items-center gap-5 mt-4 pt-3 border-t border-light text-[11px] text-muted">
            <div className="flex items-center gap-1.5"><Check size={13} className="text-emerald-500" /> Full</div>
            <div className="flex items-center gap-1.5"><div className="w-3 h-3 rounded-full border-2 border-amber-400 bg-amber-400/20" /> Partial</div>
            <div className="flex items-center gap-1.5"><span className="font-medium text-amber-600">{t('common.own')}</span> Own only</div>
            <div className="flex items-center gap-1.5"><span className="text-muted/40">{'\u2014'}</span> None</div>
          </div>
        </CardContent>
      </Card>

      {/* Custom Roles — Business tier+ */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <div className="flex items-center gap-2">
                <CardTitle>{t('common.customRoles')}</CardTitle>
                {!isBusinessOrHigher && (
                  <span className="flex items-center gap-1 px-2 py-0.5 text-[10px] font-semibold bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300 rounded-full">
                    <Lock size={10} />
                    Business
                  </span>
                )}
              </div>
              <CardDescription>{t('settings.createCustomRolesWithGranularPermissionControlBeyo')}</CardDescription>
            </div>
            {isBusinessOrHigher && (
              <Button onClick={() => createRole({ name: 'New Role', baseRole: 'technician', permissions: {} })}>
                <Plus size={16} className="mr-2" />
                Create Role
              </Button>
            )}
          </div>
        </CardHeader>
        <CardContent>
          {!isBusinessOrHigher ? (
            <div className="text-center py-8">
              <Lock size={32} className="mx-auto mb-3 text-muted opacity-40" />
              <p className="font-medium text-main">{t('common.customRoles')}</p>
              <p className="text-sm text-muted mt-1 max-w-md mx-auto">
                Create roles tailored to your team structure with per-permission control. Available on Business plan and above.
              </p>
              <Button variant="secondary" className="mt-4">{t('common.upgradePlan')}</Button>
            </div>
          ) : loading ? (
            <div className="space-y-3">
              {[1, 2, 3].map((i) => <div key={i} className="h-16 bg-secondary rounded-lg animate-pulse" />)}
            </div>
          ) : roles.length === 0 ? (
            <div className="text-center py-8 text-muted">
              <UserCog size={32} className="mx-auto mb-2 opacity-40" />
              <p>{t('settings.noCustomRolesYetDefaultRolebasedPermissionsAreActi')}</p>
            </div>
          ) : (
            <div className="space-y-4">
              {roles.map((role) => (
                <div key={role.id} className="border border-main rounded-lg">
                  <div
                    className="flex items-center justify-between p-4 cursor-pointer hover:bg-surface-hover/50 transition-colors rounded-t-lg"
                    onClick={() => setExpandedRole(expandedRole === role.id ? null : role.id)}
                  >
                    <div>
                      <p className="font-medium text-main">{role.name}</p>
                      <p className="text-sm text-muted">
                        Base: {role.baseRole} | {Object.values(role.permissions).filter(Boolean).length} permissions
                      </p>
                    </div>
                    <div className="flex items-center gap-2">
                      {role.isSystemRole && <Badge variant="secondary">{t('common.system')}</Badge>}
                      <ChevronRight size={16} className={cn('text-muted transition-transform', expandedRole === role.id && 'rotate-90')} />
                      <Button variant="ghost" size="sm" onClick={(e) => { e.stopPropagation(); deleteRole(role.id); }}>
                        <Trash2 size={14} />
                      </Button>
                    </div>
                  </div>
                  {expandedRole === role.id && (
                    <div className="border-t border-main p-4">
                      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                        {allPermissions.map((group) => (
                          <div key={group.group}>
                            <p className="text-xs font-semibold text-muted uppercase mb-2">{group.group}</p>
                            <div className="space-y-1">
                              {group.keys.map((key) => (
                                <label key={key} className="flex items-center gap-2 text-sm cursor-pointer">
                                  <input
                                    type="checkbox"
                                    checked={role.permissions[key] === true}
                                    onChange={() => {
                                      const newPerms = { ...role.permissions, [key]: !role.permissions[key] };
                                      updateRole(role.id, { permissions: newPerms });
                                    }}
                                    className="rounded border-main"
                                    disabled={role.isSystemRole}
                                  />
                                  <span className="text-main">{key.split('.').slice(1).join(' ')}</span>
                                </label>
                              ))}
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Approval Workflows — Enterprise tier */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <CardTitle>{t('common.approvalWorkflows')}</CardTitle>
            {!isEnterprise && (
              <span className="flex items-center gap-1 px-2 py-0.5 text-[10px] font-semibold bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-300 rounded-full">
                <Lock size={10} />
                Enterprise
              </span>
            )}
          </div>
          <CardDescription>{t('settings.requireApprovalForHighvalueActionsBeforeTheyGoOut')}</CardDescription>
        </CardHeader>
        <CardContent>
          {!isEnterprise ? (
            <div className="text-center py-8">
              <Lock size={32} className="mx-auto mb-3 text-muted opacity-40" />
              <p className="font-medium text-main">{t('common.approvalWorkflows')}</p>
              <p className="text-sm text-muted mt-1 max-w-md mx-auto">
                Require admin approval for bids over a threshold, change orders, and large expenses. Available on Enterprise plan.
              </p>
              <Button variant="secondary" className="mt-4">{t('common.upgradePlan')}</Button>
            </div>
          ) : (
            <ApprovalWorkflowToggles
              thresholds={thresholds}
              createThreshold={createThreshold}
              updateThreshold={updateThreshold}
            />
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function TradeModulesSettings() {
  const { t: tr } = useTranslation();
  const [enabledTrades, setEnabledTrades] = useState<string[]>([]);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const supabase = getSupabase();
    supabase
      .from('companies')
      .select('trades')
      .single()
      .then(({ data }: { data: { trades: string[] } | null }) => {
        if (data?.trades) setEnabledTrades(data.trades);
      });
  }, []);

  const toggleTrade = async (tradeId: string) => {
    const newTrades = enabledTrades.includes(tradeId)
      ? enabledTrades.filter((t) => t !== tradeId)
      : [...enabledTrades, tradeId];
    setEnabledTrades(newTrades);
    setSaving(true);
    try {
      const supabase = getSupabase();
      await supabase.from('companies').update({ trades: newTrades }).not('id', 'is', null);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>{tr('settings.tradeModules')}</CardTitle>
          <CardDescription>
            Enable trades to unlock trade-specific compliance forms, certification types, and field tools.
            {saving && <span className="ml-2 text-accent">{tr('common.saving')}</span>}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
            {AVAILABLE_TRADES.map((trade) => {
              const enabled = enabledTrades.includes(trade.id);
              return (
                <button
                  key={trade.id}
                  onClick={() => toggleTrade(trade.id)}
                  className={cn(
                    'flex items-start gap-3 p-4 rounded-lg border text-left transition-colors',
                    enabled
                      ? 'border-accent bg-accent-light'
                      : 'border-main bg-secondary hover:bg-surface-hover'
                  )}
                >
                  <div className={cn(
                    'w-5 h-5 rounded border-2 flex items-center justify-center flex-shrink-0 mt-0.5',
                    enabled ? 'bg-accent border-accent text-white' : 'border-main'
                  )}>
                    {enabled && <Check size={12} />}
                  </div>
                  <div>
                    <p className="font-medium text-main text-sm">{trade.label}</p>
                    <p className="text-xs text-muted mt-0.5">{trade.description}</p>
                  </div>
                </button>
              );
            })}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function ComplianceFormsSettings() {
  const { t: tr } = useTranslation();
  const { templates, loading } = useFormTemplates();

  const systemTemplates = templates.filter((t) => t.isSystem);
  const customTemplates = templates.filter((t) => !t.isSystem);

  const tradeGroups = systemTemplates.reduce<Record<string, FormTemplate[]>>((acc, t) => {
    const key = t.trade || 'General';
    if (!acc[key]) acc[key] = [];
    acc[key].push(t);
    return acc;
  }, {});

  return (
    <div className="space-y-6">
      {customTemplates.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>{tr('settings.customForms')}</CardTitle>
            <CardDescription>{tr('settings.formsCreatedByYourCompany')}</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {customTemplates.map((template) => (
                <div key={template.id} className="flex items-center justify-between p-3 bg-secondary rounded-lg">
                  <div>
                    <p className="font-medium text-main text-sm">{template.name}</p>
                    <p className="text-xs text-muted">{template.fields.length} fields | {template.category}</p>
                  </div>
                  <Badge variant="secondary">{tr('common.custom')}</Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader>
          <CardTitle>{tr('settings.systemFormTemplates')}</CardTitle>
          <CardDescription>
            Pre-built compliance forms organized by trade. These are read-only system templates.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-3">
              {[1, 2, 3].map((i) => <div key={i} className="h-16 bg-secondary rounded-lg animate-pulse" />)}
            </div>
          ) : (
            <div className="space-y-6">
              {Object.entries(tradeGroups).sort(([a], [b]) => a.localeCompare(b)).map(([trade, group]) => (
                <div key={trade}>
                  <h4 className="text-sm font-semibold text-muted uppercase tracking-wider mb-2">
                    {trade === 'General' ? 'All Trades' : trade.replace('_', ' ').toUpperCase()}
                  </h4>
                  <div className="space-y-1">
                    {group.map((template) => (
                      <div key={template.id} className="flex items-center justify-between p-3 bg-secondary rounded-lg">
                        <div className="flex-1">
                          <div className="flex items-center gap-2">
                            <p className="font-medium text-main text-sm">{template.name}</p>
                            {template.regulationReference && (
                              <Badge variant="info" className="text-[10px]">{template.regulationReference}</Badge>
                            )}
                          </div>
                          <p className="text-xs text-muted mt-0.5">{template.description}</p>
                        </div>
                        <div className="flex items-center gap-2 ml-4">
                          <span className="text-xs text-muted">{template.fields.length} fields</span>
                          <Badge variant="secondary">{template.category}</Badge>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function ApiKeysSettings() {
  const { t } = useTranslation();
  const { apiKeys, loading, revokeApiKey, deleteApiKey } = useApiKeys();

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>{t('settings.apiKeys')}</CardTitle>
              <CardDescription>{t('settings.manageApiAccessForIntegrationsAndAutomations')}</CardDescription>
            </div>
            <Button disabled>
              <Plus size={16} className="mr-2" />
              Generate Key
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-3">
              {[1, 2].map((i) => <div key={i} className="h-16 bg-secondary rounded-lg animate-pulse" />)}
            </div>
          ) : apiKeys.length === 0 ? (
            <div className="text-center py-8 text-muted">
              <Key size={32} className="mx-auto mb-2 opacity-40" />
              <p>{t('settings.noApiKeysGenerateOneToEnableIntegrations')}</p>
            </div>
          ) : (
            <div className="space-y-2">
              {apiKeys.map((key) => (
                <div key={key.id} className="flex items-center justify-between p-4 bg-secondary rounded-lg">
                  <div>
                    <p className="font-medium text-main">{key.name}</p>
                    <p className="text-sm text-muted font-mono">{key.prefix}...</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant={key.isActive ? 'success' : 'secondary'}>
                      {key.isActive ? 'Active' : 'Revoked'}
                    </Badge>
                    {key.isActive && (
                      <Button variant="ghost" size="sm" onClick={() => revokeApiKey(key.id)}>{t('settings.revoke')}</Button>
                    )}
                    <Button variant="ghost" size="sm" onClick={() => deleteApiKey(key.id)}>
                      <Trash2 size={14} />
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

function ToggleItem({
  label,
  description,
  checked,
  onChange,
}: {
  label: string;
  description: string;
  checked: boolean;
  onChange: () => void;
}) {
  return (
    <div className="flex items-center justify-between">
      <div>
        <p className="font-medium text-main">{label}</p>
        <p className="text-sm text-muted">{description}</p>
      </div>
      <button
        onClick={onChange}
        className={cn(
          'w-11 h-6 rounded-full transition-colors relative flex-shrink-0',
          checked ? 'bg-accent' : 'bg-secondary'
        )}
      >
        <span
          className={cn(
            'absolute top-1 w-4 h-4 bg-white rounded-full shadow-sm transition-all duration-200',
            checked ? 'left-6' : 'left-1'
          )}
        />
      </button>
    </div>
  );
}

const APPROVAL_ENTITY_TYPES = [
  { entityType: 'bid', label: 'Bid approval threshold', description: 'Bids over a set amount require admin or owner approval before sending', defaultAmount: 5000 },
  { entityType: 'change_order', label: 'Change order approval', description: 'Change orders require owner approval before execution', defaultAmount: 1000 },
  { entityType: 'expense', label: 'Expense approval', description: 'Expenses over a set amount require manager approval', defaultAmount: 2500 },
] as const;

function ApprovalWorkflowToggles({
  thresholds,
  createThreshold,
  updateThreshold,
}: {
  thresholds: ApprovalThresholdData[];
  createThreshold: (data: { entityType: string; thresholdAmount: number; requiresRole: string }) => Promise<string>;
  updateThreshold: (id: string, data: { thresholdAmount?: number; requiresRole?: string; isActive?: boolean }) => Promise<void>;
}) {
  const { t: tr } = useTranslation();
  const [amounts, setAmounts] = useState<Record<string, string>>({});

  const getThreshold = (entityType: string) =>
    thresholds.find((t) => t.entityType === entityType && t.isActive);

  const handleToggle = async (entityType: string, defaultAmount: number) => {
    const existing = getThreshold(entityType);
    if (existing) {
      await updateThreshold(existing.id, { isActive: false });
    } else {
      const amt = amounts[entityType] ? Number(amounts[entityType]) : defaultAmount;
      await createThreshold({ entityType, thresholdAmount: amt, requiresRole: 'owner' });
    }
  };

  const handleAmountBlur = async (entityType: string) => {
    const existing = getThreshold(entityType);
    const newAmt = Number(amounts[entityType]);
    if (existing && newAmt > 0 && newAmt !== existing.thresholdAmount) {
      await updateThreshold(existing.id, { thresholdAmount: newAmt });
    }
  };

  return (
    <div className="space-y-4">
      {APPROVAL_ENTITY_TYPES.map(({ entityType, label, description, defaultAmount }) => {
        const threshold = getThreshold(entityType);
        const isActive = !!threshold;
        return (
          <div key={entityType} className="space-y-2">
            <ToggleItem
              label={label}
              description={description}
              checked={isActive}
              onChange={() => handleToggle(entityType, defaultAmount)}
            />
            {isActive && (
              <div className="ml-0 pl-4 border-l-2 border-accent/30 flex items-center gap-3">
                <label className="text-xs text-muted whitespace-nowrap">{tr('settings.threshold')}</label>
                <input
                  type="number"
                  min={0}
                  step={100}
                  value={amounts[entityType] ?? String(threshold.thresholdAmount)}
                  onChange={(e) => setAmounts((prev) => ({ ...prev, [entityType]: e.target.value }))}
                  onBlur={() => handleAmountBlur(entityType)}
                  className="w-28 px-2 py-1 bg-secondary border border-default rounded text-sm text-main tabular-nums focus:outline-none focus:ring-1 focus:ring-accent"
                />
                <span className="text-xs text-muted">Requires: {threshold.requiresRole}</span>
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}

// ============================================================
// TEMPLATES SETTINGS (U12b)
// ============================================================
const TEMPLATE_TYPES = [
  { value: 'bid', label: 'Bid' },
  { value: 'estimate', label: 'Estimate' },
  { value: 'invoice', label: 'Invoice' },
  { value: 'proposal', label: 'Proposal' },
  { value: 'contract', label: 'Contract' },
  { value: 'agreement', label: 'Agreement' },
  { value: 'change_order', label: 'Change Order' },
  { value: 'lien_waiver', label: 'Lien Waiver' },
  { value: 'warranty', label: 'Warranty' },
  { value: 'scope_of_work', label: 'Scope of Work' },
  { value: 'safety_plan', label: 'Safety Plan' },
  { value: 'daily_report', label: 'Daily Report' },
  { value: 'other', label: 'Other' },
];

function TemplatesSettings() {
  const { t: tr } = useTranslation();
  const { templates, loading, createTemplate, updateTemplate, deleteTemplate, duplicateTemplate } = useZDocs();
  const [filterType, setFilterType] = useState<string>('all');
  const [showCreate, setShowCreate] = useState(false);
  const [newName, setNewName] = useState('');
  const [newType, setNewType] = useState('bid');
  const [newDesc, setNewDesc] = useState('');

  const filtered = filterType === 'all'
    ? templates
    : templates.filter((t: ZDocsTemplate) => t.templateType === filterType);

  const handleCreate = async () => {
    if (!newName.trim()) return;
    try {
      await createTemplate({
        name: newName.trim(),
        templateType: newType,
        description: newDesc.trim() || undefined,
        contentHtml: '<h1>{{company_name}}</h1><h2>' + newName.trim() + '</h2><p>Prepared for: {{customer_name}}</p><hr/><h3>Scope of Work</h3><p>{{scope_description}}</p>{{line_items_table}}<h3>Total: {{total}}</h3>',
        variables: [
          { name: 'company_name', label: 'Company Name', type: 'text', defaultValue: '' },
          { name: 'customer_name', label: 'Customer Name', type: 'text', defaultValue: '' },
          { name: 'scope_description', label: 'Scope', type: 'textarea', defaultValue: '' },
          { name: 'total', label: 'Total', type: 'currency', defaultValue: '0.00' },
        ],
      });
      setShowCreate(false);
      setNewName('');
      setNewType('bid');
      setNewDesc('');
    } catch { /* error handled by hook */ }
  };

  if (loading) {
    return (
      <Card>
        <CardContent className="py-12">
          <div className="flex items-center justify-center gap-2 text-muted">
            <RefreshCw size={16} className="animate-spin" />
            <span>{tr('settings.loadingTemplates')}</span>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>{tr('common.documentTemplates')}</CardTitle>
              <CardDescription>Manage bid, invoice, estimate, and agreement templates</CardDescription>
            </div>
            <Button onClick={() => setShowCreate(!showCreate)}>
              <Plus size={16} className="mr-1" /> New Template
            </Button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Create form */}
          {showCreate && (
            <div className="p-4 bg-secondary rounded-lg space-y-3 border border-main">
              <div className="grid grid-cols-2 gap-3">
                <Input label="Template Name" placeholder="My Custom Bid" value={newName} onChange={(e) => setNewName(e.target.value)} required />
                <div>
                  <label className="text-xs font-medium text-muted mb-1 block">{tr('common.type')}</label>
                  <select value={newType} onChange={(e) => setNewType(e.target.value)} className="w-full px-3 py-2 bg-primary border border-main rounded-lg text-sm text-main focus:outline-none focus:ring-2 focus:ring-accent/50">
                    {TEMPLATE_TYPES.map((t) => <option key={t.value} value={t.value}>{t.label}</option>)}
                  </select>
                </div>
              </div>
              <Input label={tr('common.description')} placeholder="What this template is for..." value={newDesc} onChange={(e) => setNewDesc(e.target.value)} />
              <div className="flex gap-2 justify-end">
                <Button variant="secondary" size="sm" onClick={() => setShowCreate(false)}>{tr('common.cancel')}</Button>
                <Button size="sm" onClick={handleCreate} disabled={!newName.trim()}>{tr('common.createTemplate')}</Button>
              </div>
            </div>
          )}

          {/* Filter */}
          <div className="flex items-center gap-2">
            <span className="text-xs text-muted">Filter:</span>
            <button onClick={() => setFilterType('all')} className={cn('px-2 py-1 rounded text-xs', filterType === 'all' ? 'bg-accent text-white' : 'bg-secondary text-muted hover:text-main')}>All ({templates.length})</button>
            {TEMPLATE_TYPES.slice(0, 6).map((t) => {
              const count = templates.filter((tmpl: ZDocsTemplate) => tmpl.templateType === t.value).length;
              if (count === 0) return null;
              return (
                <button key={t.value} onClick={() => setFilterType(t.value)} className={cn('px-2 py-1 rounded text-xs', filterType === t.value ? 'bg-accent text-white' : 'bg-secondary text-muted hover:text-main')}>
                  {t.label} ({count})
                </button>
              );
            })}
          </div>

          {/* Template list */}
          {filtered.length === 0 ? (
            <div className="py-8 text-center text-muted text-sm">{tr('settings.noTemplatesFoundCreateOneToGetStarted')}</div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {filtered.map((tmpl: ZDocsTemplate) => (
                <div key={tmpl.id} className="p-4 bg-secondary rounded-lg border border-main hover:border-accent/30 transition-colors">
                  <div className="flex items-start justify-between">
                    <div>
                      <h4 className="font-medium text-main text-sm">{tmpl.name}</h4>
                      <p className="text-xs text-muted mt-0.5">{tmpl.description || 'No description'}</p>
                      <div className="flex gap-2 mt-2">
                        <Badge variant="default">{tmpl.templateType}</Badge>
                        {tmpl.isSystem && <Badge variant="secondary">{tr('common.system')}</Badge>}
                      </div>
                    </div>
                    <div className="flex gap-1">
                      <button onClick={() => duplicateTemplate(tmpl.id)} className="p-1.5 text-muted hover:text-main rounded hover:bg-surface-hover" title={tr('common.duplicate')}>
                        <Layers size={14} />
                      </button>
                      {!tmpl.isSystem && (
                        <button onClick={() => deleteTemplate(tmpl.id)} className="p-1.5 text-muted hover:text-red-500 rounded hover:bg-surface-hover" title={tr('common.delete')}>
                          <Trash2 size={14} />
                        </button>
                      )}
                    </div>
                  </div>
                  <div className="flex items-center gap-3 mt-3 text-xs text-muted">
                    <span>{tmpl.variables?.length || 0} variables</span>
                    <span>{tmpl.requiresSignature ? 'Signature required' : 'No signature'}</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

// ============================================================
// CUSTOM FIELDS SETTINGS (U12c)
// ============================================================
const ENTITY_TYPES: { value: EntityType; label: string }[] = [
  { value: 'customer', label: 'Customer' },
  { value: 'job', label: 'Job' },
  { value: 'bid', label: 'Bid' },
  { value: 'invoice', label: 'Invoice' },
  { value: 'expense', label: 'Expense' },
  { value: 'employee', label: 'Employee' },
];

const FIELD_TYPES: { value: FieldType; label: string }[] = [
  { value: 'text', label: 'Text' },
  { value: 'textarea', label: 'Long Text' },
  { value: 'number', label: 'Number' },
  { value: 'date', label: 'Date' },
  { value: 'boolean', label: 'Yes/No' },
  { value: 'select', label: 'Dropdown' },
  { value: 'multi_select', label: 'Multi-Select' },
  { value: 'email', label: 'Email' },
  { value: 'phone', label: 'Phone' },
  { value: 'url', label: 'URL' },
];

function CustomFieldsSettings() {
  const { t } = useTranslation();
  const { fields, fieldsByEntity, loading, createField, updateField, deleteField } = useCustomFields();
  const [activeEntity, setActiveEntity] = useState<EntityType>('customer');
  const [showAdd, setShowAdd] = useState(false);
  const [newLabel, setNewLabel] = useState('');
  const [newType, setNewType] = useState<FieldType>('text');
  const [newRequired, setNewRequired] = useState(false);
  const [newOptions, setNewOptions] = useState('');

  const handleAdd = async () => {
    if (!newLabel.trim()) return;
    const fieldName = newLabel.trim().toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, '');
    try {
      await createField({
        entityType: activeEntity,
        fieldName,
        fieldLabel: newLabel.trim(),
        fieldType: newType,
        options: (newType === 'select' || newType === 'multi_select')
          ? newOptions.split(',').map((o) => o.trim()).filter(Boolean)
          : undefined,
        required: newRequired,
      });
      setShowAdd(false);
      setNewLabel('');
      setNewType('text');
      setNewRequired(false);
      setNewOptions('');
    } catch { /* error handled by hook */ }
  };

  const currentFields = fieldsByEntity[activeEntity] || [];

  if (loading) {
    return (
      <Card>
        <CardContent className="py-12">
          <div className="flex items-center justify-center gap-2 text-muted">
            <RefreshCw size={16} className="animate-spin" />
            <span>{t('settings.loadingCustomFields')}</span>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>{t('settings.customFields')}</CardTitle>
              <CardDescription>Add custom data fields to customers, jobs, bids, and more. Values stored in each record&apos;s metadata.</CardDescription>
            </div>
            <Button onClick={() => setShowAdd(!showAdd)}>
              <Plus size={16} className="mr-1" /> Add Field
            </Button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Entity type tabs */}
          <div className="flex gap-1 border-b border-main pb-2">
            {ENTITY_TYPES.map((et) => {
              const count = (fieldsByEntity[et.value] || []).length;
              return (
                <button
                  key={et.value}
                  onClick={() => { setActiveEntity(et.value); setShowAdd(false); }}
                  className={cn(
                    'px-3 py-1.5 rounded-t text-sm font-medium transition-colors',
                    activeEntity === et.value
                      ? 'bg-accent text-white'
                      : 'text-muted hover:text-main hover:bg-surface-hover'
                  )}
                >
                  {et.label} {count > 0 && <span className="ml-1 text-xs opacity-70">({count})</span>}
                </button>
              );
            })}
          </div>

          {/* Add field form */}
          {showAdd && (
            <div className="p-4 bg-secondary rounded-lg space-y-3 border border-main">
              <div className="grid grid-cols-2 gap-3">
                <Input label="Field Label" placeholder="e.g. License Number" value={newLabel} onChange={(e) => setNewLabel(e.target.value)} required />
                <div>
                  <label className="text-xs font-medium text-muted mb-1 block">{t('settings.fieldType')}</label>
                  <select value={newType} onChange={(e) => setNewType(e.target.value as FieldType)} className="w-full px-3 py-2 bg-primary border border-main rounded-lg text-sm text-main focus:outline-none focus:ring-2 focus:ring-accent/50">
                    {FIELD_TYPES.map((ft) => <option key={ft.value} value={ft.value}>{ft.label}</option>)}
                  </select>
                </div>
              </div>
              {(newType === 'select' || newType === 'multi_select') && (
                <Input label="Options (comma-separated)" placeholder="Option A, Option B, Option C" value={newOptions} onChange={(e) => setNewOptions(e.target.value)} />
              )}
              <label className="flex items-center gap-2 text-sm text-main cursor-pointer">
                <input type="checkbox" checked={newRequired} onChange={(e) => setNewRequired(e.target.checked)} className="rounded border-main" />
                Required field
              </label>
              <div className="flex gap-2 justify-end">
                <Button variant="secondary" size="sm" onClick={() => setShowAdd(false)}>{t('common.cancel')}</Button>
                <Button size="sm" onClick={handleAdd} disabled={!newLabel.trim()}>{t('settings.addField')}</Button>
              </div>
            </div>
          )}

          {/* Field list */}
          {currentFields.length === 0 ? (
            <div className="py-8 text-center text-muted text-sm">
              No custom fields for {ENTITY_TYPES.find((e) => e.value === activeEntity)?.label || activeEntity}. Click &quot;Add Field&quot; to create one.
            </div>
          ) : (
            <div className="space-y-2">
              {currentFields.map((field, idx) => (
                <div key={field.id} className="flex items-center justify-between p-3 bg-secondary rounded-lg border border-main">
                  <div className="flex items-center gap-3">
                    <span className="text-xs text-muted w-6">{idx + 1}.</span>
                    <div>
                      <span className="text-sm font-medium text-main">{field.fieldLabel}</span>
                      <div className="flex items-center gap-2 mt-0.5">
                        <Badge variant="secondary">{FIELD_TYPES.find((ft) => ft.value === field.fieldType)?.label || field.fieldType}</Badge>
                        {field.required && <Badge variant="default">{t('common.required')}</Badge>}
                        {field.options && field.options.length > 0 && (
                          <span className="text-xs text-muted">{field.options.length} options</span>
                        )}
                      </div>
                    </div>
                  </div>
                  <div className="flex gap-1">
                    <button
                      onClick={() => updateField(field.id, { isActive: !field.isActive })}
                      className={cn('p-1.5 rounded hover:bg-surface-hover', field.isActive ? 'text-accent' : 'text-muted')}
                      title={field.isActive ? 'Disable' : 'Enable'}
                    >
                      {field.isActive ? <CheckCircle2 size={14} /> : <XCircle size={14} />}
                    </button>
                    <button onClick={() => deleteField(field.id)} className="p-1.5 text-muted hover:text-red-500 rounded hover:bg-surface-hover" title={t('common.delete')}>
                      <Trash2 size={14} />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}

          {fields.length > 0 && (
            <p className="text-xs text-muted">Total custom fields: {fields.length} across all entities</p>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

// ============================================================
// BUSINESS CONFIG SETTINGS (U12d)
// ============================================================
function BusinessConfigSettings() {
  const { t } = useTranslation();
  const { config, loading, saving, updateConfig, jobStatuses, leadSources, bidStatuses, invoiceStatuses, priorityLevels } = useCompanyConfig();
  const [editSection, setEditSection] = useState<string | null>(null);

  // Tax rates
  const [taxRates, setTaxRates] = useState<TaxRate[]>([]);
  const [newTaxName, setNewTaxName] = useState('');
  const [newTaxRate, setNewTaxRate] = useState('');
  const [newTaxApplies, setNewTaxApplies] = useState('all');

  // Numbering
  const [invFormat, setInvFormat] = useState('');
  const [bidFormat, setBidFormat] = useState('');
  const [bidValidity, setBidValidity] = useState('');

  // Payment
  const [paymentTerms, setPaymentTerms] = useState('');
  const [lateFee, setLateFee] = useState('');
  const [earlyDiscount, setEarlyDiscount] = useState('');

  // Status editing
  const [statusEdit, setStatusEdit] = useState<{ type: string; values: string[] } | null>(null);
  const [newStatus, setNewStatus] = useState('');

  // Initialize from config when loaded
  useEffect(() => {
    if (!loading) {
      setTaxRates(config.taxRates.length > 0 ? config.taxRates : [{ name: 'Sales Tax', rate: config.defaultTaxRate, appliesTo: 'all' }]);
      setInvFormat(config.invoiceNumberFormat);
      setBidFormat(config.bidNumberFormat);
      setBidValidity(String(config.bidValidityDays));
      setPaymentTerms(config.defaultPaymentTerms);
      setLateFee(String(config.lateFeeRate));
      setEarlyDiscount(String(config.earlyPaymentDiscount));
    }
  }, [loading, config]);

  const handleSaveTaxRates = async () => {
    const defaultRate = taxRates.length > 0 ? taxRates[0].rate : 0;
    await updateConfig({ taxRates, defaultTaxRate: defaultRate });
    setEditSection(null);
  };

  const handleAddTaxRate = () => {
    if (!newTaxName.trim() || !newTaxRate) return;
    setTaxRates([...taxRates, { name: newTaxName.trim(), rate: Number(newTaxRate), appliesTo: newTaxApplies }]);
    setNewTaxName('');
    setNewTaxRate('');
    setNewTaxApplies('all');
  };

  const handleSaveNumbering = async () => {
    await updateConfig({
      invoiceNumberFormat: invFormat,
      bidNumberFormat: bidFormat,
      bidValidityDays: Number(bidValidity) || 30,
    });
    setEditSection(null);
  };

  const handleSavePayment = async () => {
    await updateConfig({
      defaultPaymentTerms: paymentTerms,
      lateFeeRate: Number(lateFee) || 0,
      earlyPaymentDiscount: Number(earlyDiscount) || 0,
    });
    setEditSection(null);
  };

  const handleSaveStatuses = async () => {
    if (!statusEdit) return;
    const key = {
      job: 'customJobStatuses',
      lead: 'customLeadSources',
      bid: 'customBidStatuses',
      invoice: 'customInvoiceStatuses',
      priority: 'customPriorityLevels',
    }[statusEdit.type] as keyof typeof config;

    await updateConfig({ [key]: statusEdit.values.length > 0 ? statusEdit.values : null } as Partial<typeof config>);
    setStatusEdit(null);
  };

  const handleAddStatus = () => {
    if (!newStatus.trim() || !statusEdit) return;
    const slug = newStatus.trim().toLowerCase().replace(/\s+/g, '_');
    if (!statusEdit.values.includes(slug)) {
      setStatusEdit({ ...statusEdit, values: [...statusEdit.values, slug] });
    }
    setNewStatus('');
  };

  if (loading) {
    return (
      <Card>
        <CardContent className="py-12">
          <div className="flex items-center justify-center gap-2 text-muted">
            <RefreshCw size={16} className="animate-spin" />
            <span>{t('settings.loadingConfiguration')}</span>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      {/* Tax Rates */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-base">{t('settings.taxRates')}</CardTitle>
              <CardDescription>{t('settings.manageTaxRatesForInvoicesAndBids')}</CardDescription>
            </div>
            {editSection !== 'tax' && (
              <Button variant="secondary" size="sm" onClick={() => setEditSection('tax')}>
                <Edit size={14} className="mr-1" /> Edit
              </Button>
            )}
          </div>
        </CardHeader>
        <CardContent>
          {editSection === 'tax' ? (
            <div className="space-y-3">
              {taxRates.map((tr, i) => (
                <div key={i} className="flex items-center gap-3 p-2 bg-secondary rounded">
                  <span className="text-sm text-main flex-1">{tr.name}</span>
                  <span className="text-sm font-mono text-main">{tr.rate}%</span>
                  <Badge variant="secondary">{tr.appliesTo}</Badge>
                  <button onClick={() => setTaxRates(taxRates.filter((_, idx) => idx !== i))} className="p-1 text-muted hover:text-red-500">
                    <Trash2 size={14} />
                  </button>
                </div>
              ))}
              <div className="flex items-end gap-2">
                <div className="flex-1">
                  <Input label={t('common.name')} placeholder="State Tax" value={newTaxName} onChange={(e) => setNewTaxName(e.target.value)} />
                </div>
                <div className="w-24">
                  <Input label="Rate %" type="number" step="0.01" min="0" max="100" placeholder="6.35" value={newTaxRate} onChange={(e) => setNewTaxRate(e.target.value.replace(/[^0-9.]/g, ''))} />
                </div>
                <div className="w-32">
                  <label className="text-xs font-medium text-muted mb-1 block">{t('settings.appliesTo')}</label>
                  <select value={newTaxApplies} onChange={(e) => setNewTaxApplies(e.target.value)} className="w-full px-3 py-2 bg-primary border border-main rounded-lg text-sm text-main focus:outline-none focus:ring-2 focus:ring-accent/50">
                    <option value="all">{t('common.all')}</option>
                    <option value="materials">{t('common.materials')}</option>
                    <option value="labor">{t('common.labor')}</option>
                    <option value="equipment">{t('common.equipment')}</option>
                  </select>
                </div>
                <Button variant="secondary" size="sm" onClick={handleAddTaxRate} disabled={!newTaxName.trim() || !newTaxRate}>
                  <Plus size={14} />
                </Button>
              </div>
              <div className="flex gap-2 justify-end pt-2">
                <Button variant="secondary" size="sm" onClick={() => setEditSection(null)}>{t('common.cancel')}</Button>
                <Button size="sm" onClick={handleSaveTaxRates} disabled={saving}>{saving ? 'Saving...' : 'Save Tax Rates'}</Button>
              </div>
            </div>
          ) : (
            <div className="space-y-2">
              {(config.taxRates.length > 0 ? config.taxRates : [{ name: 'Sales Tax', rate: config.defaultTaxRate, appliesTo: 'all' }]).map((tr, i) => (
                <div key={i} className="flex items-center gap-3">
                  <span className="text-sm text-main">{tr.name}</span>
                  <span className="text-sm font-mono text-accent font-medium">{tr.rate}%</span>
                  <Badge variant="secondary">{tr.appliesTo}</Badge>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Numbering & Formatting */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-base">{t('settings.numberingFormatting')}</CardTitle>
              <CardDescription>{t('settings.configureInvoicebidNumberFormatsAndBidValidity')}</CardDescription>
            </div>
            {editSection !== 'numbering' && (
              <Button variant="secondary" size="sm" onClick={() => setEditSection('numbering')}>
                <Edit size={14} className="mr-1" /> Edit
              </Button>
            )}
          </div>
        </CardHeader>
        <CardContent>
          {editSection === 'numbering' ? (
            <div className="space-y-4">
              <Input label="Invoice Number Format" placeholder="INV-{YYYY}-{NNNN}" value={invFormat} onChange={(e) => setInvFormat(e.target.value)} />
              <Input label="Bid Number Format" placeholder="BID-{YYMMDD}-{NNN}" value={bidFormat} onChange={(e) => setBidFormat(e.target.value)} />
              <Input label="Bid Validity (days)" type="number" min="1" max="365" placeholder="30" value={bidValidity} onChange={(e) => setBidValidity(e.target.value.replace(/[^0-9]/g, ''))} />
              <p className="text-xs text-muted">Variables: {'{YYYY}'} = year, {'{YY}'} = 2-digit year, {'{MM}'} = month, {'{DD}'} = day, {'{NNNN}'} = sequence number, {'{NNN}'} = 3-digit sequence</p>
              <div className="flex gap-2 justify-end">
                <Button variant="secondary" size="sm" onClick={() => setEditSection(null)}>{t('common.cancel')}</Button>
                <Button size="sm" onClick={handleSaveNumbering} disabled={saving}>{saving ? 'Saving...' : 'Save'}</Button>
              </div>
            </div>
          ) : (
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('settings.invoiceFormat')}</span>
                <span className="text-main font-mono">{config.invoiceNumberFormat}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('settings.bidFormat')}</span>
                <span className="text-main font-mono">{config.bidNumberFormat}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('settings.bidValidity')}</span>
                <span className="text-main">{config.bidValidityDays} days</span>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Payment Terms */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-base">{t('settings.paymentTerms')}</CardTitle>
              <CardDescription>Default payment terms, late fees, and early payment discounts</CardDescription>
            </div>
            {editSection !== 'payment' && (
              <Button variant="secondary" size="sm" onClick={() => setEditSection('payment')}>
                <Edit size={14} className="mr-1" /> Edit
              </Button>
            )}
          </div>
        </CardHeader>
        <CardContent>
          {editSection === 'payment' ? (
            <div className="space-y-4">
              <div>
                <label className="text-xs font-medium text-muted mb-1 block">{t('settings.defaultPaymentTerms')}</label>
                <select value={paymentTerms} onChange={(e) => setPaymentTerms(e.target.value)} className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-sm text-main focus:outline-none focus:ring-2 focus:ring-accent/50">
                  <option value="due_on_receipt">{t('common.dueOnReceipt')}</option>
                  <option value="net_15">Net 15</option>
                  <option value="net_30">Net 30</option>
                  <option value="net_45">Net 45</option>
                  <option value="net_60">Net 60</option>
                </select>
              </div>
              <Input label="Late Fee Rate (%/month)" type="number" step="0.1" min="0" max="100" placeholder="1.5" value={lateFee} onChange={(e) => setLateFee(e.target.value.replace(/[^0-9.]/g, ''))} />
              <Input label="Early Payment Discount (%)" type="number" step="0.1" min="0" max="100" placeholder="2" value={earlyDiscount} onChange={(e) => setEarlyDiscount(e.target.value.replace(/[^0-9.]/g, ''))} />
              <div className="flex gap-2 justify-end">
                <Button variant="secondary" size="sm" onClick={() => setEditSection(null)}>{t('common.cancel')}</Button>
                <Button size="sm" onClick={handleSavePayment} disabled={saving}>{saving ? 'Saving...' : 'Save'}</Button>
              </div>
            </div>
          ) : (
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('settings.defaultTerms')}</span>
                <span className="text-main">{config.defaultPaymentTerms.replace('_', ' ')}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('settings.lateFee')}</span>
                <span className="text-main">{config.lateFeeRate}% / month</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('settings.earlyPaymentDiscount')}</span>
                <span className="text-main">{config.earlyPaymentDiscount}%</span>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Configurable Statuses */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">{t('settings.customStatuses')}</CardTitle>
          <CardDescription>Customize statuses for jobs, bids, invoices, leads, and priorities. Null/empty = use system defaults.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {[
            { type: 'job', label: 'Job Statuses', values: jobStatuses, defaults: DEFAULT_JOB_STATUSES },
            { type: 'bid', label: 'Bid Statuses', values: bidStatuses, defaults: DEFAULT_BID_STATUSES },
            { type: 'invoice', label: 'Invoice Statuses', values: invoiceStatuses, defaults: DEFAULT_INVOICE_STATUSES },
            { type: 'lead', label: 'Lead Sources', values: leadSources, defaults: DEFAULT_LEAD_SOURCES },
            { type: 'priority', label: 'Priority Levels', values: priorityLevels, defaults: DEFAULT_PRIORITY_LEVELS },
          ].map((section) => (
            <div key={section.type} className="p-3 bg-secondary rounded-lg border border-main">
              <div className="flex items-center justify-between mb-2">
                <h4 className="text-sm font-medium text-main">{section.label}</h4>
                <button
                  onClick={() => setStatusEdit(statusEdit?.type === section.type ? null : { type: section.type, values: [...section.values] })}
                  className="text-xs text-accent hover:underline"
                >
                  {statusEdit?.type === section.type ? 'Cancel' : 'Edit'}
                </button>
              </div>

              {statusEdit?.type === section.type ? (
                <div className="space-y-2">
                  <div className="flex flex-wrap gap-1">
                    {statusEdit.values.map((s) => (
                      <span key={s} className="inline-flex items-center gap-1 px-2 py-1 bg-primary rounded text-xs text-main">
                        {s.replace(/_/g, ' ')}
                        <button onClick={() => setStatusEdit({ ...statusEdit, values: statusEdit.values.filter((v) => v !== s) })} className="text-muted hover:text-red-500">
                          <X size={10} />
                        </button>
                      </span>
                    ))}
                  </div>
                  <div className="flex gap-2">
                    <input
                      value={newStatus}
                      onChange={(e) => setNewStatus(e.target.value)}
                      onKeyDown={(e) => e.key === 'Enter' && (e.preventDefault(), handleAddStatus())}
                      placeholder="Add status..."
                      className="flex-1 px-2 py-1 bg-primary border border-main rounded text-sm text-main placeholder:text-muted focus:outline-none focus:ring-1 focus:ring-accent"
                    />
                    <Button variant="secondary" size="sm" onClick={handleAddStatus} disabled={!newStatus.trim()}>
                      <Plus size={12} />
                    </Button>
                  </div>
                  <div className="flex gap-2 justify-end">
                    <button onClick={() => setStatusEdit({ ...statusEdit, values: section.defaults })} className="text-xs text-muted hover:text-main">{t('settings.resetToDefaults')}</button>
                    <Button size="sm" onClick={handleSaveStatuses} disabled={saving}>{saving ? 'Saving...' : 'Save'}</Button>
                  </div>
                </div>
              ) : (
                <div className="flex flex-wrap gap-1">
                  {section.values.map((s) => (
                    <span key={s} className="px-2 py-0.5 bg-primary rounded text-xs text-muted">{s.replace(/_/g, ' ')}</span>
                  ))}
                </div>
              )}
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}
