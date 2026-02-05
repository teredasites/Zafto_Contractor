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
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Avatar } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { cn } from '@/lib/utils';

type SettingsTab = 'profile' | 'company' | 'team' | 'billing' | 'notifications' | 'appearance' | 'security' | 'integrations';

const tabs: { id: SettingsTab; label: string; icon: React.ReactNode }[] = [
  { id: 'profile', label: 'Profile', icon: <User size={18} /> },
  { id: 'company', label: 'Company', icon: <Building size={18} /> },
  { id: 'team', label: 'Team', icon: <Users size={18} /> },
  { id: 'billing', label: 'Billing', icon: <CreditCard size={18} /> },
  { id: 'notifications', label: 'Notifications', icon: <Bell size={18} /> },
  { id: 'appearance', label: 'Appearance', icon: <Palette size={18} /> },
  { id: 'security', label: 'Security', icon: <Shield size={18} /> },
  { id: 'integrations', label: 'Integrations', icon: <Link size={18} /> },
];

export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState<SettingsTab>('profile');

  return (
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div>
        <h1 className="text-2xl font-semibold text-main">Settings</h1>
        <p className="text-muted mt-1">Manage your account and preferences</p>
      </div>

      <div className="flex flex-col lg:flex-row gap-6">
        {/* Sidebar */}
        <div className="lg:w-64 flex-shrink-0">
          <Card>
            <CardContent className="p-2">
              <nav className="space-y-1">
                {tabs.map((tab) => (
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
    </div>
  );
}

function TeamSettings() {
  const [showInviteModal, setShowInviteModal] = useState(false);

  const teamMembers = [
    { id: '1', name: 'Mike Johnson', email: 'mike@mitchellelectric.com', role: 'owner', status: 'active', lastActive: 'Now' },
    { id: '2', name: 'Carlos Rivera', email: 'carlos@mitchellelectric.com', role: 'field_tech', status: 'active', lastActive: '15m ago' },
    { id: '3', name: 'James Wilson', email: 'james@mitchellelectric.com', role: 'field_tech', status: 'active', lastActive: '45m ago' },
    { id: '4', name: 'Lisa Martinez', email: 'lisa@mitchellelectric.com', role: 'office', status: 'active', lastActive: '2h ago' },
  ];

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
