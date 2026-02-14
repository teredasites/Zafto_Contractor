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
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Avatar } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { cn, formatRelativeTime } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';
import { useTeam } from '@/lib/hooks/use-jobs';
import { usePermissions, TierGate, PERMISSIONS, ROLE_PERMISSIONS, type Permission } from '@/components/permission-gate';
import { useBranches, useCustomRoles, useFormTemplates, useCertifications, useApiKeys } from '@/lib/hooks/use-enterprise';
import { useApprovals } from '@/lib/hooks/use-approvals';
import type { ApprovalThresholdData } from '@/lib/hooks/pm-mappers';
import type { Branch, CustomRole, FormTemplate, Certification } from '@/lib/hooks/use-enterprise';

type SettingsTab = 'profile' | 'company' | 'team' | 'billing' | 'notifications' | 'appearance' | 'security' | 'integrations' | 'branches' | 'roles' | 'trades' | 'forms' | 'apikeys';

const coreTabs: { id: SettingsTab; label: string; icon: React.ReactNode }[] = [
  { id: 'profile', label: 'Profile', icon: <User size={18} /> },
  { id: 'company', label: 'Company', icon: <Building size={18} /> },
  { id: 'team', label: 'Team', icon: <Users size={18} /> },
  { id: 'billing', label: 'Billing', icon: <CreditCard size={18} /> },
  { id: 'notifications', label: 'Notifications', icon: <Bell size={18} /> },
  { id: 'appearance', label: 'Appearance', icon: <Palette size={18} /> },
  { id: 'security', label: 'Security', icon: <Shield size={18} /> },
  { id: 'integrations', label: 'Integrations', icon: <Link size={18} /> },
];

const enterpriseTabs: { id: SettingsTab; label: string; icon: React.ReactNode; minTier: 'team' | 'business' | 'enterprise' }[] = [
  { id: 'branches', label: 'Branches', icon: <GitBranch size={18} />, minTier: 'team' },
  { id: 'trades', label: 'Trade Modules', icon: <Wrench size={18} />, minTier: 'team' },
  { id: 'roles', label: 'Roles & Permissions', icon: <UserCog size={18} />, minTier: 'business' },
  { id: 'forms', label: 'Compliance Forms', icon: <ClipboardList size={18} />, minTier: 'business' },
  { id: 'apikeys', label: 'API Keys', icon: <Key size={18} />, minTier: 'enterprise' },
];

export default function SettingsPage() {
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
        <h1 className="text-2xl font-semibold text-main">Settings</h1>
        <p className="text-[13px] text-muted mt-1">Manage your account and preferences</p>
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
                      <p className="text-[11px] font-semibold text-muted uppercase tracking-wider">Enterprise</p>
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
          {activeTab === 'notifications' && <NotificationSettings />}
          {activeTab === 'appearance' && <AppearanceSettings />}
          {activeTab === 'security' && <SecuritySettings />}
          {activeTab === 'integrations' && <IntegrationSettings />}
          {activeTab === 'branches' && <BranchesSettings />}
          {activeTab === 'roles' && <RolesSettings />}
          {activeTab === 'trades' && <TradeModulesSettings />}
          {activeTab === 'forms' && <ComplianceFormsSettings />}
          {activeTab === 'apikeys' && <ApiKeysSettings />}
        </div>
      </div>
    </div>
  );
}

function ProfileSettings() {
  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>Profile Information</CardTitle>
          <CardDescription>Update your personal details</CardDescription>
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
              <h3 className="font-medium text-main">Profile Photo</h3>
              <p className="text-sm text-muted">JPG, PNG or GIF. Max 2MB</p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Input label="First Name" defaultValue="Mike" />
            <Input label="Last Name" defaultValue="Johnson" />
            <Input label="Email" type="email" defaultValue="mike@mitchellelectric.com" icon={<Mail size={16} />} />
            <Input label="Phone" type="tel" defaultValue="(860) 555-1001" icon={<Phone size={16} />} />
          </div>

          <Button>Save Changes</Button>
        </CardContent>
      </Card>
    </div>
  );
}

function CompanySettings() {
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
          <CardTitle>Company Information</CardTitle>
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
                  <span className="text-xs text-muted mt-1 block">Add Logo</span>
                </div>
              )}
            </div>
            <div>
              <h3 className="font-medium text-main">Company Logo</h3>
              <p className="text-sm text-muted">Appears on bids, invoices, and client portal</p>
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
            <Input label="Company Name" defaultValue="Mitchell Electric LLC" />
            <Input label="Trade" defaultValue="Electrical" />
            <Input label="Email" type="email" defaultValue="info@mitchellelectric.com" />
            <Input label="Phone" type="tel" defaultValue="(860) 555-1000" />
            <Input label="Website" defaultValue="www.mitchellelectric.com" className="md:col-span-2" />
          </div>

          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Address</label>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Input placeholder="Street Address" defaultValue="123 Main Street" className="md:col-span-2" />
              <Input placeholder="City" defaultValue="Hartford" />
              <div className="grid grid-cols-2 gap-4">
                <Input placeholder="State" defaultValue="CT" />
                <Input placeholder="ZIP" defaultValue="06103" />
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Input label="License Number" defaultValue="E.123456" />
            <Input label="Tax ID / EIN" defaultValue="12-3456789" />
          </div>

          <Button>Save Changes</Button>
        </CardContent>
      </Card>

      <GoodBetterBestCard />
    </div>
  );
}

function TeamSettings() {
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
    subcontractor: 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300',
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>Team Members</CardTitle>
            <CardDescription>Manage who has access to your account</CardDescription>
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
            <CardTitle>Pending Invites</CardTitle>
            <CardDescription>Invitations that haven't been accepted yet</CardDescription>
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
          <CardTitle>Role Permissions</CardTitle>
          <CardDescription>What each role can access</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="grid grid-cols-6 gap-4 text-xs font-medium text-muted uppercase pb-2 border-b border-main">
              <span>Role</span>
              <span className="text-center">Bids</span>
              <span className="text-center">Jobs</span>
              <span className="text-center">Invoices</span>
              <span className="text-center">Team</span>
              <span className="text-center">Billing</span>
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
            <span className="text-xs text-amber-600">Assigned only</span>
          ) : (
            <span className="text-muted">-</span>
          )}
        </div>
      ))}
    </div>
  );
}

function InviteModal({ onClose, roleLabels }: { onClose: () => void; roleLabels: Record<string, string> }) {
  const [email, setEmail] = useState('');
  const [role, setRole] = useState('field_tech');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // TODO: Send invite
    console.log('Inviting:', { email, role });
    onClose();
  };

  return (
    <>
      <div className="fixed inset-0 bg-black/50 z-50" onClick={onClose} />
      <div className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-md z-50">
        <Card>
          <CardHeader>
            <CardTitle>Invite Team Member</CardTitle>
            <CardDescription>Send an invitation to join your team</CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">Email Address</label>
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
                <label className="block text-sm font-medium text-main mb-1.5">Role</label>
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
  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>Current Plan</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-between p-4 bg-accent-light rounded-xl">
            <div>
              <div className="flex items-center gap-2">
                <h3 className="font-semibold text-main text-lg">Pro Plan</h3>
                <Badge variant="success">Active</Badge>
              </div>
              <p className="text-muted mt-1">$29.99/month - billed monthly</p>
            </div>
            <Button variant="secondary">Change Plan</Button>
          </div>

          <div className="mt-6">
            <h4 className="font-medium text-main mb-3">Plan Features</h4>
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
          <CardTitle>Payment Method</CardTitle>
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
            <Button variant="ghost" size="sm">Update</Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Billing History</CardTitle>
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
                  <p className="font-medium text-main">${invoice.amount.toFixed(2)}</p>
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

function NotificationSettings() {
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
          <CardTitle>Email Notifications</CardTitle>
          <CardDescription>Choose what emails you receive</CardDescription>
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
          <CardTitle>Push Notifications</CardTitle>
          <CardDescription>Mobile app notifications</CardDescription>
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
          <CardTitle>SMS Notifications</CardTitle>
          <CardDescription>Text message alerts</CardDescription>
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
    </div>
  );
}

function AppearanceSettings() {
  const [theme, setTheme] = useState('light');

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>Theme</CardTitle>
          <CardDescription>Choose your preferred color scheme</CardDescription>
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
          <CardTitle>Accent Color</CardTitle>
          <CardDescription>Brand color for buttons and highlights</CardDescription>
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

      {/* Pro Mode Toggle */}
      <ProModeCard />
    </div>
  );
}

function ProModeCard() {
  // Initialize from localStorage synchronously
  const [isProMode, setIsProMode] = useState(() => {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('zafto_pro_mode') === 'true';
    }
    return false;
  });

  // Listen for changes from other toggles
  useEffect(() => {
    const handleProModeChange = (e: CustomEvent) => {
      setIsProMode(e.detail as boolean);
    };
    window.addEventListener('proModeChange', handleProModeChange as EventListener);
    return () => window.removeEventListener('proModeChange', handleProModeChange as EventListener);
  }, []);

  const handleToggle = () => {
    const newValue = !isProMode;
    setIsProMode(newValue);
    localStorage.setItem('zafto_pro_mode', String(newValue));
    window.dispatchEvent(new CustomEvent('proModeChange', { detail: newValue }));
  };

  return (
    <Card className={cn(
      'transition-colors',
      isProMode && 'border-accent/50 bg-accent/5'
    )}>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className={cn(
              'p-2.5 rounded-xl transition-colors',
              isProMode ? 'bg-accent/20' : 'bg-secondary'
            )}>
              <Sparkles size={22} className={isProMode ? 'text-accent' : 'text-muted'} />
            </div>
            <div>
              <CardTitle className="flex items-center gap-2">
                Pro Mode
                {isProMode && (
                  <span className="px-2 py-0.5 text-[10px] font-bold bg-accent text-white rounded">
                    ON
                  </span>
                )}
              </CardTitle>
              <CardDescription>
                {isProMode
                  ? 'Full CRM with leads, tasks & automations'
                  : 'Simple mode - Bid, Job, Invoice flow'}
              </CardDescription>
            </div>
          </div>
          <button
            onClick={handleToggle}
            className={cn(
              'w-11 h-6 rounded-full transition-colors relative flex-shrink-0',
              isProMode ? 'bg-accent' : 'bg-slate-300 dark:bg-slate-600'
            )}
          >
            <span
              className={cn(
                'absolute top-1 w-4 h-4 bg-white rounded-full shadow-sm transition-all duration-200',
                isProMode ? 'left-6' : 'left-1'
              )}
            />
          </button>
        </div>
      </CardHeader>
      {isProMode && (
        <CardContent>
          <div className="flex items-start gap-3 p-3 rounded-lg bg-secondary/50">
            <Info size={16} className="text-muted mt-0.5 flex-shrink-0" />
            <p className="text-sm text-muted">
              Pro Mode unlocks: Lead Pipeline, Tasks & Follow-ups, Communication Hub,
              Service Agreements, Equipment Tracking, Multi-Property Support, and Automations.
            </p>
          </div>
        </CardContent>
      )}
    </Card>
  );
}

function GoodBetterBestCard() {
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
                  <span className="px-2 py-0.5 text-[10px] font-bold bg-accent text-white rounded">ON</span>
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
              enabled ? 'bg-accent' : 'bg-slate-300 dark:bg-slate-600'
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
  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>Password</CardTitle>
          <CardDescription>Update your password</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <Input label="Current Password" type="password" />
          <Input label="New Password" type="password" />
          <Input label="Confirm New Password" type="password" />
          <Button>Update Password</Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Two-Factor Authentication</CardTitle>
          <CardDescription>Add an extra layer of security</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-between">
            <div>
              <p className="font-medium text-main">Authenticator App</p>
              <p className="text-sm text-muted">Use an app like Google Authenticator or Authy</p>
            </div>
            <Button variant="secondary">Enable</Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Sessions</CardTitle>
          <CardDescription>Manage your active sessions</CardDescription>
        </CardHeader>
        <CardContent className="p-0">
          <div className="divide-y divide-main">
            {[
              { device: 'Chrome on Windows', location: 'Hartford, CT', current: true },
              { device: 'Zafto iOS App', location: 'Hartford, CT', current: false },
            ].map((session, i) => (
              <div key={i} className="flex items-center justify-between px-6 py-4">
                <div>
                  <p className="font-medium text-main">{session.device}</p>
                  <p className="text-sm text-muted">{session.location}</p>
                </div>
                {session.current ? (
                  <Badge variant="success">Current</Badge>
                ) : (
                  <Button variant="ghost" size="sm" className="text-red-600">
                    Revoke
                  </Button>
                )}
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function IntegrationSettings() {
  const integrations = [
    { name: 'QuickBooks', description: 'Sync invoices and payments', connected: false, icon: '📊' },
    { name: 'Stripe', description: 'Accept card payments', connected: true, icon: '💳' },
    { name: 'Google Calendar', description: 'Sync your schedule', connected: false, icon: '📅' },
    { name: 'Twilio', description: 'Send SMS notifications', connected: true, icon: '📱' },
    { name: 'Plaid', description: 'Connect bank accounts', connected: true, icon: '🏦' },
  ];

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>Connected Apps</CardTitle>
          <CardDescription>Manage third-party integrations</CardDescription>
        </CardHeader>
        <CardContent className="p-0">
          <div className="divide-y divide-main">
            {integrations.map((integration) => (
              <div key={integration.name} className="flex items-center justify-between px-6 py-4">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 bg-secondary rounded-lg flex items-center justify-center text-xl">
                    {integration.icon}
                  </div>
                  <div>
                    <p className="font-medium text-main">{integration.name}</p>
                    <p className="text-sm text-muted">{integration.description}</p>
                  </div>
                </div>
                {integration.connected ? (
                  <div className="flex items-center gap-3">
                    <Badge variant="success">Connected</Badge>
                    <Button variant="ghost" size="sm">Manage</Button>
                  </div>
                ) : (
                  <Button variant="secondary" size="sm">Connect</Button>
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
              <CardTitle>Branches</CardTitle>
              <CardDescription>Manage company locations and assign team members</CardDescription>
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
                <Input label="Phone" value={formData.phone} onChange={(e) => setFormData({ ...formData, phone: e.target.value })} />
                <Input label="Address" value={formData.address} onChange={(e) => setFormData({ ...formData, address: e.target.value })} />
                <Input label="City" value={formData.city} onChange={(e) => setFormData({ ...formData, city: e.target.value })} />
                <Input label="State" value={formData.state} onChange={(e) => setFormData({ ...formData, state: e.target.value })} />
                <Input label="ZIP" value={formData.zipCode} onChange={(e) => setFormData({ ...formData, zipCode: e.target.value })} />
              </div>
              <div className="flex gap-2">
                <Button onClick={handleSave}>{editingId ? 'Update' : 'Create'}</Button>
                <Button variant="ghost" onClick={() => { setShowForm(false); setEditingId(null); }}>Cancel</Button>
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
              <p>No branches yet. Add your first location.</p>
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
    { key: 'cpa', label: 'CPA', color: 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-300', desc: 'Financials & reports only' },
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
          <CardTitle>Default Role Permissions</CardTitle>
          <CardDescription>Built-in roles with default access levels. Assign roles to team members to control what they can see and do.</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto -mx-6">
            <table className="w-full text-sm min-w-[700px]">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left py-3 pl-6 pr-4 font-medium text-muted text-[11px] uppercase tracking-wider w-36">Role</th>
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
                            <span className="text-[10px] font-medium text-amber-600">Own</span>
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
            <div className="flex items-center gap-1.5"><span className="font-medium text-amber-600">Own</span> Own only</div>
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
                <CardTitle>Custom Roles</CardTitle>
                {!isBusinessOrHigher && (
                  <span className="flex items-center gap-1 px-2 py-0.5 text-[10px] font-semibold bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300 rounded-full">
                    <Lock size={10} />
                    Business
                  </span>
                )}
              </div>
              <CardDescription>Create custom roles with granular permission control beyond the defaults</CardDescription>
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
              <p className="font-medium text-main">Custom Roles</p>
              <p className="text-sm text-muted mt-1 max-w-md mx-auto">
                Create roles tailored to your team structure with per-permission control. Available on Business plan and above.
              </p>
              <Button variant="secondary" className="mt-4">Upgrade Plan</Button>
            </div>
          ) : loading ? (
            <div className="space-y-3">
              {[1, 2, 3].map((i) => <div key={i} className="h-16 bg-secondary rounded-lg animate-pulse" />)}
            </div>
          ) : roles.length === 0 ? (
            <div className="text-center py-8 text-muted">
              <UserCog size={32} className="mx-auto mb-2 opacity-40" />
              <p>No custom roles yet. Default role-based permissions are active.</p>
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
                      {role.isSystemRole && <Badge variant="secondary">System</Badge>}
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
                                    className="rounded border-gray-300"
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
            <CardTitle>Approval Workflows</CardTitle>
            {!isEnterprise && (
              <span className="flex items-center gap-1 px-2 py-0.5 text-[10px] font-semibold bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-300 rounded-full">
                <Lock size={10} />
                Enterprise
              </span>
            )}
          </div>
          <CardDescription>Require approval for high-value actions before they go out</CardDescription>
        </CardHeader>
        <CardContent>
          {!isEnterprise ? (
            <div className="text-center py-8">
              <Lock size={32} className="mx-auto mb-3 text-muted opacity-40" />
              <p className="font-medium text-main">Approval Workflows</p>
              <p className="text-sm text-muted mt-1 max-w-md mx-auto">
                Require admin approval for bids over a threshold, change orders, and large expenses. Available on Enterprise plan.
              </p>
              <Button variant="secondary" className="mt-4">Upgrade Plan</Button>
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
          <CardTitle>Trade Modules</CardTitle>
          <CardDescription>
            Enable trades to unlock trade-specific compliance forms, certification types, and field tools.
            {saving && <span className="ml-2 text-accent">Saving...</span>}
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
                    enabled ? 'bg-accent border-accent text-white' : 'border-gray-300'
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
            <CardTitle>Custom Forms</CardTitle>
            <CardDescription>Forms created by your company</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {customTemplates.map((template) => (
                <div key={template.id} className="flex items-center justify-between p-3 bg-secondary rounded-lg">
                  <div>
                    <p className="font-medium text-main text-sm">{template.name}</p>
                    <p className="text-xs text-muted">{template.fields.length} fields | {template.category}</p>
                  </div>
                  <Badge variant="secondary">Custom</Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader>
          <CardTitle>System Form Templates</CardTitle>
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
  const { apiKeys, loading, revokeApiKey, deleteApiKey } = useApiKeys();

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>API Keys</CardTitle>
              <CardDescription>Manage API access for integrations and automations</CardDescription>
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
              <p>No API keys. Generate one to enable integrations.</p>
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
                      <Button variant="ghost" size="sm" onClick={() => revokeApiKey(key.id)}>Revoke</Button>
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
          checked ? 'bg-accent' : 'bg-slate-300 dark:bg-slate-600'
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
                <label className="text-xs text-muted whitespace-nowrap">Threshold $</label>
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
