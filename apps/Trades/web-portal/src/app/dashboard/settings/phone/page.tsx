'use client';

import { useState } from 'react';
import {
  Phone,
  Clock,
  GitBranch,
  Bot,
  MessageSquare,
  Mic,
  Settings,
  Save,
  Plus,
  Trash2,
  Copy,
  Shield,
  Zap,
  CalendarOff,
  Users,
  ArrowRight,
  Volume2,
  ChevronDown,
  ChevronRight,
  ToggleLeft,
  ToggleRight,
  Wrench,
  Smartphone,
  CheckCircle,
  AlertTriangle,
  ExternalLink,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';
import {
  usePhoneConfig,
  TRADE_PRESETS,
  type BusinessHours,
  type DaySchedule,
  type Holiday,
  type MenuOption,
  type AiReceptionistConfig,
} from '@/lib/hooks/use-phone-config';
import { usePhoneLines } from '@/lib/hooks/use-phone-lines';
import { useByocPhone, formatPhoneDisplay, CARRIER_FORWARDING_INSTRUCTIONS, type CompanyPhoneNumber } from '@/lib/hooks/use-byoc-phone';
import { useRingGroups } from '@/lib/hooks/use-ring-groups';
import { useTranslation } from '@/lib/translations';

// ============================================================
// Tab Types
// ============================================================

type TabId =
  | 'general'
  | 'hours'
  | 'routing'
  | 'ai'
  | 'templates'
  | 'recording'
  | 'byoc';

const TABS: { id: TabId; label: string; icon: typeof Phone }[] = [
  { id: 'general', label: 'General', icon: Settings },
  { id: 'hours', label: 'Hours', icon: Clock },
  { id: 'routing', label: 'Routing', icon: GitBranch },
  { id: 'ai', label: 'AI Receptionist', icon: Bot },
  { id: 'templates', label: 'Templates', icon: MessageSquare },
  { id: 'recording', label: 'Recording', icon: Mic },
  { id: 'byoc', label: 'Your Number', icon: Smartphone },
];

const DAYS: (keyof BusinessHours)[] = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

const TWO_PARTY_STATES = [
  'CA',
  'CT',
  'FL',
  'IL',
  'MD',
  'MA',
  'MI',
  'MT',
  'NH',
  'PA',
  'WA',
];

// ============================================================
// Page
// ============================================================

export default function PhoneSettingsPage() {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState<TabId>('general');
  const {
    config,
    loading,
    error,
    saving,
    updateConfig,
    updateBusinessHours,
    updateHolidays,
    updateMenuOptions,
    updateAiConfig,
    updateRecording,
  } = usePhoneConfig();
  const {
    lines,
    loading: linesLoading,
    assignToUser,
    updateLine,
  } = usePhoneLines();
  const {
    groups,
    loading: groupsLoading,
    createGroup,
    updateGroup,
    deleteGroup,
  } = useRingGroups();
  const byoc = useByocPhone();

  const [toastMsg, setToastMsg] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(null), 3000);
  };

  const handleSave = async (fn: () => Promise<void>, label: string) => {
    try {
      await fn();
      showToast(`${label} saved`);
    } catch {
      showToast(`Failed to save ${label}`);
    }
  };

  if (loading || linesLoading || groupsLoading) {
    return (
      <div className="space-y-6 animate-fade-in">
        <div className="h-8 w-64 rounded skeleton-shimmer" />
        <div className="h-96 rounded-xl skeleton-shimmer" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-8 text-center">
        <Phone size={32} className="mx-auto text-muted mb-3" />
        <p className="text-muted">{error}</p>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex items-center gap-3">
        <div className="p-2 rounded-lg bg-accent-light">
          <Phone size={20} className="text-accent" />
        </div>
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('settingsPhone.title')}</h1>
          <p className="text-sm text-muted">
            Configure business hours, call routing, AI receptionist, and more
          </p>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 bg-secondary rounded-lg p-1 overflow-x-auto">
        {TABS.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={cn(
              'flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium whitespace-nowrap transition-colors',
              activeTab === tab.id
                ? 'bg-card text-main shadow-sm'
                : 'text-muted hover:text-main'
            )}
          >
            <tab.icon size={14} />
            {tab.label}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      {activeTab === 'general' && (
        <GeneralTab
          config={config}
          lines={lines}
          onSave={handleSave}
          updateConfig={updateConfig}
          assignToUser={assignToUser}
          updateLine={updateLine}
          saving={saving}
        />
      )}
      {activeTab === 'hours' && (
        <HoursTab
          config={config}
          onSave={handleSave}
          updateBusinessHours={updateBusinessHours}
          updateHolidays={updateHolidays}
          updateConfig={updateConfig}
        />
      )}
      {activeTab === 'routing' && (
        <RoutingTab
          config={config}
          groups={groups}
          onSave={handleSave}
          updateMenuOptions={updateMenuOptions}
          updateConfig={updateConfig}
          createGroup={createGroup}
          updateGroup={updateGroup}
          deleteGroup={deleteGroup}
        />
      )}
      {activeTab === 'ai' && (
        <AiTab
          config={config}
          onSave={handleSave}
          updateConfig={updateConfig}
          updateAiConfig={updateAiConfig}
        />
      )}
      {activeTab === 'templates' && (
        <TemplatesTab config={config} onSave={handleSave} />
      )}
      {activeTab === 'recording' && (
        <RecordingTab
          config={config}
          onSave={handleSave}
          updateRecording={updateRecording}
        />
      )}
      {activeTab === 'byoc' && (
        <ByocTab byoc={byoc} showToast={showToast} />
      )}

      {/* Toast */}
      {toastMsg && (
        <div className="fixed bottom-6 right-6 bg-card border border-default rounded-lg px-4 py-2 shadow-lg text-sm text-main animate-fade-in z-50">
          {toastMsg}
        </div>
      )}
    </div>
  );
}

// ============================================================
// General Tab
// ============================================================

function GeneralTab({
  config,
  lines,
  onSave,
  updateConfig,
  assignToUser: _assignToUser,
  updateLine: _updateLine,
  saving,
}: {
  config: ReturnType<typeof usePhoneConfig>['config'];
  lines: ReturnType<typeof usePhoneLines>['lines'];
  onSave: (fn: () => Promise<void>, label: string) => void;
  updateConfig: ReturnType<typeof usePhoneConfig>['updateConfig'];
  assignToUser: ReturnType<typeof usePhoneLines>['assignToUser'];
  updateLine: ReturnType<typeof usePhoneLines>['updateLine'];
  saving: boolean;
}) {
  const [callerIdName, setCallerIdName] = useState(
    config?.greetingVoice || ''
  );
  const [greetingText, setGreetingText] = useState(
    config?.greetingText || ''
  );

  return (
    <div className="space-y-6">
      {/* Caller ID */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Phone size={16} /> Caller ID & Greeting
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="text-sm font-medium text-main">
              Caller ID Name
            </label>
            <p className="text-xs text-muted mb-1">
              What customers see when you call them
            </p>
            <input
              type="text"
              value={callerIdName}
              onChange={(e) => setCallerIdName(e.target.value)}
              className="w-full px-3 py-2 rounded-lg border border-default bg-card text-main text-sm"
              placeholder="Your Company Name"
            />
          </div>
          <div>
            <label className="text-sm font-medium text-main">
              Greeting Message
            </label>
            <textarea
              value={greetingText}
              onChange={(e) => setGreetingText(e.target.value)}
              rows={3}
              className="w-full px-3 py-2 rounded-lg border border-default bg-card text-main text-sm"
              placeholder="Thank you for calling! Press 1 for..."
            />
          </div>
          <Button
            variant="primary"
            disabled={saving}
            onClick={() =>
              onSave(
                () =>
                  updateConfig({
                    greeting_voice: callerIdName,
                    greeting_text: greetingText,
                  }),
                'Greeting'
              )
            }
          >
            <Save size={14} className="mr-1" /> Save
          </Button>
        </CardContent>
      </Card>

      {/* Phone Lines */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Phone size={16} /> Phone Lines ({lines.length})
          </CardTitle>
        </CardHeader>
        <CardContent>
          {lines.length === 0 ? (
            <p className="text-sm text-muted py-4 text-center">
              No phone lines configured. Add lines through your SignalWire
              dashboard.
            </p>
          ) : (
            <div className="space-y-2">
              {lines.map((line) => (
                <div
                  key={line.id}
                  className="flex items-center justify-between p-3 rounded-lg bg-secondary"
                >
                  <div>
                    <div className="flex items-center gap-2">
                      <Badge
                        variant={
                          line.lineType === 'main' ? 'success' : 'default'
                        }
                      >
                        {line.lineType}
                      </Badge>
                      <span className="text-sm font-medium text-main">
                        {line.phoneNumber}
                      </span>
                    </div>
                    <p className="text-xs text-muted mt-0.5">
                      {line.displayName || 'Unassigned'}
                      {line.userId && ' (assigned)'}
                    </p>
                  </div>
                  <div className="flex items-center gap-2">
                    <div
                      className={cn(
                        'w-2 h-2 rounded-full',
                        line.status === 'online'
                          ? 'bg-emerald-500'
                          : line.status === 'busy'
                          ? 'bg-amber-500'
                          : 'bg-muted'
                      )}
                    />
                    <span className="text-xs text-muted">{line.status}</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Trade Presets */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Wrench size={16} /> Trade Presets
          </CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-xs text-muted mb-3">
            One-click phone setup optimized for your trade. Applies greeting,
            IVR menu, routing rules, and AI personality.
          </p>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
            {TRADE_PRESETS.map((preset) => (
              <button
                key={preset.id}
                onClick={() =>
                  onSave(
                    () =>
                      updateConfig({
                        greeting_text: preset.greetingText,
                        after_hours_greeting_text: preset.afterHoursGreeting,
                        menu_options: preset.menuOptions,
                        emergency_enabled: preset.emergencyEnabled,
                        ai_receptionist_config: {
                          ...config?.aiReceptionistConfig,
                          ...preset.aiConfig,
                        },
                      }),
                    `${preset.name} preset`
                  )
                }
                className="p-4 rounded-lg border border-default bg-card hover:border-accent/30 transition-colors text-left"
              >
                <div className="flex items-center gap-2 mb-1">
                  <Zap size={14} className="text-accent" />
                  <span className="text-sm font-semibold text-main">
                    {preset.name}
                  </span>
                </div>
                <p className="text-xs text-muted">{preset.description}</p>
              </button>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ============================================================
// Hours Tab
// ============================================================

function HoursTab({
  config,
  onSave,
  updateBusinessHours,
  updateHolidays,
  updateConfig,
}: {
  config: ReturnType<typeof usePhoneConfig>['config'];
  onSave: (fn: () => Promise<void>, label: string) => void;
  updateBusinessHours: (h: BusinessHours) => Promise<void>;
  updateHolidays: (h: Holiday[]) => Promise<void>;
  updateConfig: ReturnType<typeof usePhoneConfig>['updateConfig'];
}) {
  const hours = config?.businessHours || {
    monday: { open: '07:00', close: '17:00' },
    tuesday: { open: '07:00', close: '17:00' },
    wednesday: { open: '07:00', close: '17:00' },
    thursday: { open: '07:00', close: '17:00' },
    friday: { open: '07:00', close: '17:00' },
    saturday: null,
    sunday: null,
  };
  const holidays = config?.holidays || [];
  const [localHours, setLocalHours] = useState<BusinessHours>(hours);
  const [localHolidays, setLocalHolidays] = useState<Holiday[]>(holidays);
  const [newHolidayName, setNewHolidayName] = useState('');
  const [newHolidayDate, setNewHolidayDate] = useState('');

  const updateDay = (
    day: keyof BusinessHours,
    value: DaySchedule | null
  ) => {
    setLocalHours((prev) => ({ ...prev, [day]: value }));
  };

  const copyMondayToWeekdays = () => {
    const mon = localHours.monday;
    setLocalHours((prev) => ({
      ...prev,
      tuesday: mon ? { ...mon } : null,
      wednesday: mon ? { ...mon } : null,
      thursday: mon ? { ...mon } : null,
      friday: mon ? { ...mon } : null,
    }));
  };

  const addHoliday = () => {
    if (!newHolidayName || !newHolidayDate) return;
    setLocalHolidays((prev) => [
      ...prev,
      { date: newHolidayDate, name: newHolidayName, recurring: false },
    ]);
    setNewHolidayName('');
    setNewHolidayDate('');
  };

  const importFederalHolidays = () => {
    const federal: Holiday[] = [
      { date: '01-01', name: "New Year's Day", recurring: true },
      { date: '01-15', name: 'MLK Day', recurring: true },
      { date: '02-19', name: "Presidents' Day", recurring: true },
      { date: '05-27', name: 'Memorial Day', recurring: true },
      { date: '07-04', name: 'Independence Day', recurring: true },
      { date: '09-01', name: 'Labor Day', recurring: true },
      { date: '11-11', name: 'Veterans Day', recurring: true },
      { date: '11-28', name: 'Thanksgiving', recurring: true },
      { date: '12-25', name: 'Christmas', recurring: true },
    ];
    setLocalHolidays((prev) => {
      const existing = new Set(prev.map((h) => h.name));
      const newOnes = federal.filter((h) => !existing.has(h.name));
      return [...prev, ...newOnes];
    });
  };

  return (
    <div className="space-y-6">
      {/* Weekly Schedule */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-base flex items-center gap-2">
              <Clock size={16} /> Weekly Schedule
            </CardTitle>
            <Button variant="secondary" onClick={copyMondayToWeekdays}>
              <Copy size={12} className="mr-1" /> Copy Mon to Weekdays
            </Button>
          </div>
        </CardHeader>
        <CardContent className="space-y-3">
          {DAYS.map((day) => {
            const schedule = localHours[day];
            const isOpen = schedule !== null;
            return (
              <div
                key={day}
                className="flex items-center gap-3 p-2 rounded-lg bg-secondary"
              >
                <span className="text-sm font-medium text-main w-24 capitalize">
                  {day}
                </span>
                <button
                  onClick={() =>
                    updateDay(
                      day,
                      isOpen ? null : { open: '07:00', close: '17:00' }
                    )
                  }
                  className={cn(
                    'text-xs px-2 py-1 rounded',
                    isOpen
                      ? 'bg-emerald-500/10 text-emerald-600'
                      : 'bg-red-500/10 text-red-500'
                  )}
                >
                  {isOpen ? 'Open' : 'Closed'}
                </button>
                {isOpen && schedule && (
                  <>
                    <input
                      type="time"
                      value={schedule.open}
                      onChange={(e) =>
                        updateDay(day, {
                          ...schedule,
                          open: e.target.value,
                        })
                      }
                      className="px-2 py-1 rounded border border-default bg-card text-main text-sm"
                    />
                    <span className="text-muted text-xs">to</span>
                    <input
                      type="time"
                      value={schedule.close}
                      onChange={(e) =>
                        updateDay(day, {
                          ...schedule,
                          close: e.target.value,
                        })
                      }
                      className="px-2 py-1 rounded border border-default bg-card text-main text-sm"
                    />
                  </>
                )}
              </div>
            );
          })}
          <Button
            variant="primary"
            onClick={() =>
              onSave(
                () => updateBusinessHours(localHours),
                'Business hours'
              )
            }
          >
            <Save size={14} className="mr-1" /> Save Hours
          </Button>
        </CardContent>
      </Card>

      {/* Holidays */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-base flex items-center gap-2">
              <CalendarOff size={16} /> Holidays
            </CardTitle>
            <Button variant="secondary" onClick={importFederalHolidays}>
              <Plus size={12} className="mr-1" /> Import US Federal
            </Button>
          </div>
        </CardHeader>
        <CardContent className="space-y-3">
          {localHolidays.map((h, i) => (
            <div
              key={i}
              className="flex items-center justify-between p-2 rounded-lg bg-secondary"
            >
              <div>
                <span className="text-sm font-medium text-main">
                  {h.name}
                </span>
                <span className="text-xs text-muted ml-2">{h.date}</span>
                {h.recurring && (
                  <Badge variant="default" className="ml-2">
                    Annual
                  </Badge>
                )}
              </div>
              <button
                onClick={() =>
                  setLocalHolidays((prev) =>
                    prev.filter((_, idx) => idx !== i)
                  )
                }
                className="text-muted hover:text-red-500"
              >
                <Trash2 size={14} />
              </button>
            </div>
          ))}
          <div className="flex gap-2">
            <input
              type="text"
              value={newHolidayName}
              onChange={(e) => setNewHolidayName(e.target.value)}
              placeholder="Holiday name"
              className="flex-1 px-3 py-2 rounded-lg border border-default bg-card text-main text-sm"
            />
            <input
              type="date"
              value={newHolidayDate}
              onChange={(e) => setNewHolidayDate(e.target.value)}
              className="px-3 py-2 rounded-lg border border-default bg-card text-main text-sm"
            />
            <Button variant="secondary" onClick={addHoliday}>
              <Plus size={14} />
            </Button>
          </div>
          <Button
            variant="primary"
            onClick={() =>
              onSave(
                () => updateHolidays(localHolidays),
                'Holidays'
              )
            }
          >
            <Save size={14} className="mr-1" /> Save Holidays
          </Button>
        </CardContent>
      </Card>

      {/* After-Hours Behavior */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Clock size={16} /> After-Hours Behavior
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <p className="text-xs text-muted">
            What happens when a customer calls outside business hours?
          </p>
          {[
            { value: 'voicemail', label: 'Voicemail Only', desc: 'Callers leave a voicemail' },
            { value: 'ai', label: 'AI Receptionist Answers', desc: 'AI handles after-hours calls' },
            { value: 'forward_oncall', label: 'Forward to On-Call', desc: 'Ring the on-call technician' },
            { value: 'forward_external', label: 'Forward to External', desc: 'Forward to answering service' },
          ].map((option) => (
            <label
              key={option.value}
              className="flex items-center gap-3 p-3 rounded-lg bg-secondary cursor-pointer hover:bg-surface-hover"
            >
              <input
                type="radio"
                name="afterHours"
                className="accent-accent"
                defaultChecked={option.value === 'voicemail'}
              />
              <div>
                <span className="text-sm font-medium text-main">
                  {option.label}
                </span>
                <p className="text-xs text-muted">{option.desc}</p>
              </div>
            </label>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}

// ============================================================
// Routing Tab
// ============================================================

function RoutingTab({
  config,
  groups,
  onSave,
  updateMenuOptions,
  updateConfig: _updateConfig,
  createGroup,
  updateGroup: _updateGroup,
  deleteGroup,
}: {
  config: ReturnType<typeof usePhoneConfig>['config'];
  groups: ReturnType<typeof useRingGroups>['groups'];
  onSave: (fn: () => Promise<void>, label: string) => void;
  updateMenuOptions: (o: MenuOption[]) => Promise<void>;
  updateConfig: ReturnType<typeof usePhoneConfig>['updateConfig'];
  createGroup: ReturnType<typeof useRingGroups>['createGroup'];
  updateGroup: ReturnType<typeof useRingGroups>['updateGroup'];
  deleteGroup: ReturnType<typeof useRingGroups>['deleteGroup'];
}) {
  const { t } = useTranslation();
  const [localMenu, setLocalMenu] = useState<MenuOption[]>(
    config?.menuOptions || []
  );
  const [newGroupName, setNewGroupName] = useState('');
  const [expandedGroup, setExpandedGroup] = useState<string | null>(null);

  const addMenuItem = () => {
    const nextKey = String(localMenu.length + 1);
    setLocalMenu((prev) => [
      ...prev,
      {
        key: nextKey,
        label: 'New Option',
        action: 'ring_group' as const,
      },
    ]);
  };

  return (
    <div className="space-y-6">
      {/* Call Flow Visualization */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <GitBranch size={16} /> Call Flow
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-2 flex-wrap text-xs text-muted">
            <div className="px-3 py-2 rounded-lg bg-accent/10 text-accent font-medium">
              Call Comes In
            </div>
            <ArrowRight size={14} />
            <div className="px-3 py-2 rounded-lg bg-secondary">
              Greeting Plays
            </div>
            <ArrowRight size={14} />
            <div className="px-3 py-2 rounded-lg bg-secondary">
              {config?.menuOptions?.length
                ? 'IVR Menu'
                : 'Direct Ring'}
            </div>
            <ArrowRight size={14} />
            <div className="px-3 py-2 rounded-lg bg-secondary">
              {config?.emergencyEnabled ? 'Emergency Check' : 'Ring Team'}
            </div>
            <ArrowRight size={14} />
            <div className="px-3 py-2 rounded-lg bg-amber-500/10 text-amber-600">
              Voicemail / AI
            </div>
          </div>
        </CardContent>
      </Card>

      {/* IVR Menu Builder */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-base flex items-center gap-2">
              <Phone size={16} /> IVR Menu Options
            </CardTitle>
            <Button variant="secondary" onClick={addMenuItem}>
              <Plus size={12} className="mr-1" /> Add Option
            </Button>
          </div>
        </CardHeader>
        <CardContent className="space-y-2">
          {localMenu.length === 0 ? (
            <p className="text-sm text-muted text-center py-4">
              No menu options configured. Calls will ring directly.
            </p>
          ) : (
            localMenu.map((item, i) => (
              <div
                key={i}
                className="flex items-center gap-3 p-3 rounded-lg bg-secondary"
              >
                <div className="w-8 h-8 rounded-lg bg-accent/10 text-accent font-bold text-sm flex items-center justify-center">
                  {item.key}
                </div>
                <input
                  type="text"
                  value={item.label}
                  onChange={(e) => {
                    const updated = [...localMenu];
                    updated[i] = { ...updated[i], label: e.target.value };
                    setLocalMenu(updated);
                  }}
                  className="flex-1 px-2 py-1 rounded border border-default bg-card text-main text-sm"
                />
                <select
                  value={item.action}
                  onChange={(e) => {
                    const updated = [...localMenu];
                    updated[i] = {
                      ...updated[i],
                      action: e.target.value as MenuOption['action'],
                    };
                    setLocalMenu(updated);
                  }}
                  className="px-2 py-1 rounded border border-default bg-card text-main text-sm"
                >
                  <option value="ring_group">{t('settingsPhone.ringGroup')}</option>
                  <option value="ring_user">{t('settingsPhone.ringPerson')}</option>
                  <option value="ai_receptionist">{t('settingsPhone.aiReceptionist')}</option>
                  <option value="voicemail">{t('settingsPhone.voicemail')}</option>
                  <option value="external">{t('settingsPhone.externalNumber')}</option>
                </select>
                <button
                  onClick={() =>
                    setLocalMenu((prev) =>
                      prev.filter((_, idx) => idx !== i)
                    )
                  }
                  className="text-muted hover:text-red-500"
                >
                  <Trash2 size={14} />
                </button>
              </div>
            ))
          )}
          <Button
            variant="primary"
            onClick={() =>
              onSave(() => updateMenuOptions(localMenu), 'IVR Menu')
            }
          >
            <Save size={14} className="mr-1" /> Save Menu
          </Button>
        </CardContent>
      </Card>

      {/* Ring Groups */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-base flex items-center gap-2">
              <Users size={16} /> Ring Groups ({groups.length})
            </CardTitle>
          </div>
        </CardHeader>
        <CardContent className="space-y-3">
          {groups.map((group) => (
            <div key={group.id} className="rounded-lg border border-default">
              <button
                onClick={() =>
                  setExpandedGroup(
                    expandedGroup === group.id ? null : group.id
                  )
                }
                className="w-full flex items-center justify-between p-3"
              >
                <div className="flex items-center gap-2">
                  {expandedGroup === group.id ? (
                    <ChevronDown size={14} className="text-muted" />
                  ) : (
                    <ChevronRight size={14} className="text-muted" />
                  )}
                  <span className="text-sm font-medium text-main">
                    {group.name}
                  </span>
                  <Badge variant="default">{group.strategy}</Badge>
                  <span className="text-xs text-muted">
                    {group.memberUserIds.length} members
                  </span>
                </div>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    deleteGroup(group.id);
                  }}
                  className="text-muted hover:text-red-500"
                >
                  <Trash2 size={14} />
                </button>
              </button>
              {expandedGroup === group.id && (
                <div className="px-3 pb-3 space-y-2">
                  <div className="grid grid-cols-2 gap-2 text-xs">
                    <div>
                      <span className="text-muted">Strategy:</span>
                      <span className="ml-1 text-main">
                        {group.strategy}
                      </span>
                    </div>
                    <div>
                      <span className="text-muted">Ring Duration:</span>
                      <span className="ml-1 text-main">
                        {group.ringDurationSeconds}s
                      </span>
                    </div>
                    <div>
                      <span className="text-muted">No Answer:</span>
                      <span className="ml-1 text-main">
                        {group.noAnswerAction}
                      </span>
                    </div>
                  </div>
                </div>
              )}
            </div>
          ))}
          <div className="flex gap-2">
            <input
              type="text"
              value={newGroupName}
              onChange={(e) => setNewGroupName(e.target.value)}
              placeholder="New ring group name"
              className="flex-1 px-3 py-2 rounded-lg border border-default bg-card text-main text-sm"
            />
            <Button
              variant="secondary"
              onClick={() => {
                if (newGroupName.trim()) {
                  createGroup({ name: newGroupName.trim() });
                  setNewGroupName('');
                }
              }}
            >
              <Plus size={14} className="mr-1" /> Create
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ============================================================
// AI Receptionist Tab
// ============================================================

function AiTab({
  config,
  onSave,
  updateConfig,
  updateAiConfig,
}: {
  config: ReturnType<typeof usePhoneConfig>['config'];
  onSave: (fn: () => Promise<void>, label: string) => void;
  updateConfig: ReturnType<typeof usePhoneConfig>['updateConfig'];
  updateAiConfig: (c: AiReceptionistConfig) => Promise<void>;
}) {
  const { t } = useTranslation();
  const aiConfig = config?.aiReceptionistConfig;
  const isEnabled = config?.aiReceptionistEnabled || false;
  const [localConfig, setLocalConfig] = useState<AiReceptionistConfig>(
    aiConfig || ({} as AiReceptionistConfig)
  );

  const toggleCapability = (key: keyof AiReceptionistConfig['capabilities']) => {
    setLocalConfig((prev) => ({
      ...prev,
      capabilities: {
        ...prev.capabilities,
        [key]: !prev.capabilities[key],
      },
    }));
  };

  const capabilities: {
    key: keyof AiReceptionistConfig['capabilities'];
    label: string;
    desc: string;
  }[] = [
    {
      key: 'checkAvailability',
      label: 'Check Schedule',
      desc: 'AI checks open appointment slots',
    },
    {
      key: 'bookAppointments',
      label: 'Book Appointments',
      desc: 'AI creates leads with tentative schedules',
    },
    {
      key: 'lookupJobStatus',
      label: 'Job Status Lookup',
      desc: 'AI matches caller to customer, finds active jobs',
    },
    {
      key: 'provideEtas',
      label: 'Provide ETAs',
      desc: "AI reads today's schedule for arrival estimates",
    },
    {
      key: 'takeMessages',
      label: 'Take Messages',
      desc: 'AI records caller info and creates lead/note',
    },
    {
      key: 'transferToTeam',
      label: 'Transfer to Team',
      desc: 'AI transfers to specific team members by name',
    },
    {
      key: 'emergencyRouting',
      label: 'Emergency Detection',
      desc: 'AI detects urgency keywords and routes to on-call',
    },
  ];

  return (
    <div className="space-y-6">
      {/* Master Toggle */}
      <Card>
        <CardContent className="py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Bot size={20} className="text-accent" />
              <div>
                <h3 className="text-sm font-semibold text-main">
                  AI Receptionist
                </h3>
                <p className="text-xs text-muted">
                  AI answers calls, books appointments, and handles
                  inquiries
                </p>
              </div>
            </div>
            <button
              onClick={() =>
                onSave(
                  () =>
                    updateConfig({
                      ai_receptionist_enabled: !isEnabled,
                    }),
                  'AI Receptionist'
                )
              }
              className="text-accent"
            >
              {isEnabled ? (
                <ToggleRight size={32} />
              ) : (
                <ToggleLeft size={32} className="text-muted" />
              )}
            </button>
          </div>
        </CardContent>
      </Card>

      {isEnabled && (
        <>
          {/* Personality */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">{t('settingsPhone.personalityVoice')}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
                {(
                  [
                    'professional',
                    'friendly',
                    'casual',
                    'bilingual',
                  ] as const
                ).map((p) => (
                  <button
                    key={p}
                    onClick={() =>
                      setLocalConfig((prev) => ({
                        ...prev,
                        personality: p,
                      }))
                    }
                    className={cn(
                      'px-3 py-2 rounded-lg border text-sm font-medium capitalize',
                      localConfig.personality === p
                        ? 'border-accent bg-accent/10 text-accent'
                        : 'border-default text-muted hover:text-main'
                    )}
                  >
                    {p}
                  </button>
                ))}
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-medium text-muted">
                    Voice
                  </label>
                  <select
                    value={localConfig.voice}
                    onChange={(e) =>
                      setLocalConfig((prev) => ({
                        ...prev,
                        voice: e.target.value as AiReceptionistConfig['voice'],
                      }))
                    }
                    className="w-full mt-1 px-3 py-2 rounded-lg border border-default bg-card text-main text-sm"
                  >
                    <option value="female">{t('settingsPhone.female')}</option>
                    <option value="male">{t('settingsPhone.male')}</option>
                    <option value="neutral">{t('settingsPhone.neutral')}</option>
                  </select>
                </div>
                <div>
                  <label className="text-xs font-medium text-muted">
                    Speed
                  </label>
                  <select
                    value={localConfig.speed}
                    onChange={(e) =>
                      setLocalConfig((prev) => ({
                        ...prev,
                        speed: e.target.value as AiReceptionistConfig['speed'],
                      }))
                    }
                    className="w-full mt-1 px-3 py-2 rounded-lg border border-default bg-card text-main text-sm"
                  >
                    <option value="normal">{t('common.normal')}</option>
                    <option value="slow">{t('settingsPhone.slow')}</option>
                  </select>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Capabilities */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">{t('settingsPhone.aiCapabilities')}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              {capabilities.map((cap) => (
                <div
                  key={cap.key}
                  className="flex items-center justify-between p-3 rounded-lg bg-secondary"
                >
                  <div>
                    <span className="text-sm font-medium text-main">
                      {cap.label}
                    </span>
                    <p className="text-xs text-muted">{cap.desc}</p>
                  </div>
                  <button onClick={() => toggleCapability(cap.key)}>
                    {localConfig.capabilities?.[cap.key] ? (
                      <ToggleRight size={24} className="text-accent" />
                    ) : (
                      <ToggleLeft size={24} className="text-muted" />
                    )}
                  </button>
                </div>
              ))}
              <Button
                variant="primary"
                onClick={() =>
                  onSave(
                    () => updateAiConfig(localConfig),
                    'AI configuration'
                  )
                }
              >
                <Save size={14} className="mr-1" /> Save AI Config
              </Button>
            </CardContent>
          </Card>

          {/* Real-time Data Access */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">{t('settingsPhone.realtimeDataAccess')}</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-xs text-muted mb-3">
                The AI receptionist has read-only access to these data
                sources (company-scoped):
              </p>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-2">
                {[
                  { table: 'Jobs', desc: 'Active jobs, status, assigned tech' },
                  { table: 'Customers', desc: 'Match caller by phone' },
                  { table: 'Schedule', desc: 'Availability for booking' },
                  { table: 'Team', desc: 'Members for transfer routing' },
                  { table: 'Services', desc: 'Company service offerings' },
                  { table: 'Hours', desc: 'Business hours for answers' },
                ].map((item) => (
                  <div
                    key={item.table}
                    className="p-2 rounded-lg bg-secondary"
                  >
                    <span className="text-xs font-semibold text-accent">
                      {item.table}
                    </span>
                    <p className="text-[10px] text-muted">{item.desc}</p>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
}

// ============================================================
// Templates Tab
// ============================================================

function TemplatesTab({
  config: _config,
  onSave: _onSave,
}: {
  config: ReturnType<typeof usePhoneConfig>['config'];
  onSave: (fn: () => Promise<void>, label: string) => void;
}) {
  const templates = [
    {
      name: 'Appointment Reminder',
      trigger: '24h before appointment',
      body: 'Hi {customer_name}, reminder: your appointment with {tech_name} is tomorrow at {appointment_time}. Reply CONFIRM or call to reschedule.',
    },
    {
      name: 'On My Way',
      trigger: 'Tech marks en route',
      body: 'Hi {customer_name}! {tech_name} is on the way to your location. Estimated arrival: ~{eta}.',
    },
    {
      name: 'Job Complete',
      trigger: 'Job status set to completed',
      body: 'Hi {customer_name}, your {job_title} job has been completed! Thank you for choosing {company_name}.',
    },
    {
      name: 'Invoice Sent',
      trigger: 'Invoice created',
      body: 'Hi {customer_name}, your invoice for {job_title} is ready. View and pay: {invoice_link}',
    },
    {
      name: 'Estimate Follow-Up',
      trigger: '48h after estimate sent',
      body: 'Hi {customer_name}, just following up on the estimate we sent for {job_title} ({estimate_total}). Any questions? Reply here or call us.',
    },
    {
      name: 'Review Request',
      trigger: '2 days after job completion',
      body: 'Hi {customer_name}! How was your experience with {company_name}? We would love your feedback: {review_link}',
    },
  ];

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <MessageSquare size={16} /> SMS Templates
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {templates.map((tpl, i) => (
            <div key={i} className="p-3 rounded-lg border border-default">
              <div className="flex items-center justify-between mb-1">
                <span className="text-sm font-semibold text-main">
                  {tpl.name}
                </span>
                <Badge variant="default">{tpl.trigger}</Badge>
              </div>
              <p className="text-xs text-muted font-mono bg-secondary rounded px-2 py-1">
                {tpl.body}
              </p>
            </div>
          ))}
          <p className="text-xs text-muted">
            Variables: {'{customer_name}'}, {'{tech_name}'},{' '}
            {'{job_title}'}, {'{appointment_date}'},{' '}
            {'{appointment_time}'}, {'{company_name}'},{' '}
            {'{estimate_total}'}, {'{invoice_link}'}, {'{review_link}'}
          </p>
        </CardContent>
      </Card>
    </div>
  );
}

// ============================================================
// Recording Tab
// ============================================================

function RecordingTab({
  config,
  onSave,
  updateRecording,
}: {
  config: ReturnType<typeof usePhoneConfig>['config'];
  onSave: (fn: () => Promise<void>, label: string) => void;
  updateRecording: (
    mode: string,
    retentionDays: number,
    consentState: string | null
  ) => Promise<void>;
}) {
  const [mode, setMode] = useState(config?.callRecordingMode || 'off');
  const [retention, setRetention] = useState(
    config?.recordingRetentionDays || 90
  );
  const [consentState, setConsentState] = useState(
    config?.recordingConsentState || ''
  );
  const isTwoParty = TWO_PARTY_STATES.includes(consentState.toUpperCase());

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Mic size={16} /> Call Recording
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="text-sm font-medium text-main">
              Recording Mode
            </label>
            <div className="grid grid-cols-2 gap-2 mt-2">
              {([
                { value: 'off' as const, label: 'Off' },
                { value: 'all' as const, label: 'All Calls' },
                { value: 'inbound_only' as const, label: 'Inbound Only' },
                { value: 'on_demand' as const, label: 'On-Demand' },
              ]).map((opt) => (
                <button
                  key={opt.value}
                  onClick={() => setMode(opt.value)}
                  className={cn(
                    'px-3 py-2 rounded-lg border text-sm font-medium',
                    mode === opt.value
                      ? 'border-accent bg-accent/10 text-accent'
                      : 'border-default text-muted hover:text-main'
                  )}
                >
                  {opt.label}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="text-sm font-medium text-main">
              Retention Period
            </label>
            <select
              value={retention}
              onChange={(e) => setRetention(Number(e.target.value))}
              className="w-full mt-1 px-3 py-2 rounded-lg border border-default bg-card text-main text-sm"
            >
              <option value={30}>30 days</option>
              <option value={60}>60 days</option>
              <option value={90}>90 days</option>
              <option value={365}>1 year</option>
            </select>
          </div>

          <div>
            <label className="text-sm font-medium text-main">
              Company State
            </label>
            <p className="text-xs text-muted mb-1">
              Used to determine consent requirements
            </p>
            <input
              type="text"
              value={consentState}
              onChange={(e) => setConsentState(e.target.value.toUpperCase())}
              maxLength={2}
              placeholder="CA"
              className="w-24 px-3 py-2 rounded-lg border border-default bg-card text-main text-sm"
            />
          </div>

          {isTwoParty && mode !== 'off' && (
            <div className="flex items-start gap-2 p-3 rounded-lg bg-amber-500/10 border border-amber-500/30">
              <Shield size={16} className="text-amber-500 mt-0.5" />
              <div>
                <p className="text-sm font-medium text-amber-600">
                  Two-Party Consent State
                </p>
                <p className="text-xs text-muted">
                  {consentState} requires all parties to consent to
                  recording. An announcement &quot;This call may be
                  recorded&quot; will automatically play at the start of
                  each call.
                </p>
              </div>
            </div>
          )}

          <Button
            variant="primary"
            onClick={() =>
              onSave(
                () =>
                  updateRecording(
                    mode,
                    retention,
                    consentState || null
                  ),
                'Recording settings'
              )
            }
          >
            <Save size={14} className="mr-1" /> Save Recording Settings
          </Button>
        </CardContent>
      </Card>

      {/* Voicemail Settings */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Volume2 size={16} /> Voicemail Settings
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {[
            {
              label: 'Voicemail Transcription',
              desc: 'Auto-transcribe voicemails to text',
              defaultOn: true,
            },
            {
              label: 'Email on Voicemail',
              desc: 'Send email notification when voicemail received',
              defaultOn: true,
            },
            {
              label: 'Auto-Text Missed Call',
              desc: 'Send "Sorry I missed your call" text automatically',
              defaultOn: false,
            },
          ].map((item) => (
            <div
              key={item.label}
              className="flex items-center justify-between p-3 rounded-lg bg-secondary"
            >
              <div>
                <span className="text-sm font-medium text-main">
                  {item.label}
                </span>
                <p className="text-xs text-muted">{item.desc}</p>
              </div>
              <button>
                {item.defaultOn ? (
                  <ToggleRight size={24} className="text-accent" />
                ) : (
                  <ToggleLeft size={24} className="text-muted" />
                )}
              </button>
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}

// ============================================================
// BYOC Tab — Bring Your Own Carrier
// ============================================================

function ByocTab({
  byoc,
  showToast,
}: {
  byoc: ReturnType<typeof useByocPhone>;
  showToast: (msg: string) => void;
}) {
  const { t } = useTranslation();
  const [phone, setPhone] = useState('');
  const [label, setLabel] = useState('');
  const [fwdType, setFwdType] = useState<'call_forward' | 'sip_trunk' | 'port_in'>('call_forward');
  const [carrier, setCarrier] = useState('other');
  const [adding, setAdding] = useState(false);
  const [verifyId, setVerifyId] = useState<string | null>(null);
  const [code, setCode] = useState('');

  const handleAdd = async () => {
    if (!phone.trim()) return;
    setAdding(true);
    try {
      await byoc.addNumber({
        phoneNumber: phone,
        displayLabel: label || undefined,
        forwardingType: fwdType,
        carrierDetected: carrier,
      });
      setPhone('');
      setLabel('');
      showToast('Number added. Send verification to activate.');
    } catch (e) {
      showToast(`Failed: ${e instanceof Error ? e.message : 'Unknown error'}`);
    } finally {
      setAdding(false);
    }
  };

  const handleVerify = async (id: string) => {
    try {
      await byoc.sendVerification(id);
      setVerifyId(id);
      showToast('Verification code sent via SMS');
    } catch (e) {
      showToast(`Failed to send code: ${e instanceof Error ? e.message : ''}`);
    }
  };

  const handleSubmitCode = async () => {
    if (!verifyId || !code.trim()) return;
    try {
      const ok = await byoc.verifyCode(verifyId, code);
      if (ok) {
        setVerifyId(null);
        setCode('');
        showToast('Number verified successfully!');
      } else {
        showToast('Invalid code. Try again.');
      }
    } catch {
      showToast('Verification failed');
    }
  };

  const statusColor = (s: string) => {
    if (s === 'verified') return 'text-emerald-500';
    if (s === 'code_sent') return 'text-amber-500';
    return 'text-muted';
  };

  return (
    <div className="space-y-6">
      {/* Info */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Smartphone size={18} />
            Bring Your Own Number
          </CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted">
            Keep your existing business phone number and get all Zafto phone features —
            call recording, IVR, voicemail transcription, and analytics. Choose from three
            integration methods: call forwarding (easiest), SIP trunk (VoIP providers),
            or number porting (permanent transfer).
          </p>
        </CardContent>
      </Card>

      {/* Existing numbers */}
      {byoc.numbers.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">{t('settingsPhone.yourNumbers')}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {byoc.numbers.map((num) => (
              <div
                key={num.id}
                className="p-4 bg-secondary rounded-lg border border-default"
              >
                <div className="flex items-center justify-between">
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-mono font-semibold text-main">
                        {formatPhoneDisplay(num.phoneNumber)}
                      </span>
                      {num.isPrimary && (
                        <Badge variant="secondary" className="text-xs">{t('settingsPhone.primary')}</Badge>
                      )}
                    </div>
                    {num.displayLabel && (
                      <p className="text-xs text-muted mt-0.5">{num.displayLabel}</p>
                    )}
                  </div>
                  <div className="flex items-center gap-2">
                    <span className={cn('text-xs font-medium flex items-center gap-1', statusColor(num.verificationStatus))}>
                      {num.verificationStatus === 'verified' ? (
                        <><CheckCircle size={12} /> Verified</>
                      ) : num.verificationStatus === 'code_sent' ? (
                        <><AlertTriangle size={12} /> Code Sent</>
                      ) : (
                        'Pending'
                      )}
                    </span>
                    {num.verificationStatus !== 'verified' && (
                      <Button size="sm" variant="outline" onClick={() => handleVerify(num.id)}>
                        Verify
                      </Button>
                    )}
                    <Button
                      size="sm"
                      variant="ghost"
                      className="text-red-400 hover:text-red-300"
                      onClick={async () => {
                        await byoc.deleteNumber(num.id);
                        showToast('Number removed');
                      }}
                    >
                      <Trash2 size={14} />
                    </Button>
                  </div>
                </div>

                <div className="flex items-center gap-3 mt-2 text-xs text-muted">
                  <span>{num.forwardingType === 'sip_trunk' ? 'SIP Trunk' : num.forwardingType === 'port_in' ? 'Number Porting' : 'Call Forwarding'}</span>
                  {num.carrierDetected && <span>· {num.carrierDetected}</span>}
                  {num.callerIdName && <span>· Caller ID: {num.callerIdName}</span>}
                </div>

                {/* Forwarding instructions */}
                {num.forwardingType === 'call_forward' && num.verificationStatus === 'verified' && num.forwardingInstructions && (
                  <div className="mt-2 p-2 bg-surface rounded text-xs text-muted flex items-start gap-2">
                    <ExternalLink size={12} className="mt-0.5 flex-shrink-0" />
                    <span>{num.forwardingInstructions}</span>
                  </div>
                )}

                {/* Port status */}
                {num.forwardingType === 'port_in' && num.portStatus !== 'none' && (
                  <div className="mt-2 flex items-center gap-2 text-xs">
                    {['requested', 'foc_received', 'porting', 'complete'].map((step, i) => {
                      const steps = ['requested', 'foc_received', 'porting', 'complete'];
                      const currentIdx = steps.indexOf(num.portStatus);
                      const done = i <= currentIdx;
                      return (
                        <div key={step} className="flex items-center gap-1">
                          <div className={cn(
                            'w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-bold',
                            done ? 'bg-accent text-white' : 'bg-secondary text-muted border border-default'
                          )}>
                            {done ? '✓' : i + 1}
                          </div>
                          <span className={done ? 'text-main' : 'text-muted'}>
                            {step === 'foc_received' ? 'FOC' : step.charAt(0).toUpperCase() + step.slice(1)}
                          </span>
                          {i < 3 && <ArrowRight size={10} className="text-muted mx-1" />}
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      {/* Verification code entry */}
      {verifyId && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Shield size={16} />
              Enter Verification Code
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-muted mb-3">
              We sent a 6-digit code to your phone via SMS.
            </p>
            <div className="flex gap-3">
              <input
                type="text"
                maxLength={6}
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/\D/g, ''))}
                placeholder="000000"
                className="flex-1 px-4 py-2 bg-secondary border border-default rounded-lg text-center text-2xl font-mono tracking-[0.3em] text-main"
              />
              <Button onClick={handleSubmitCode} disabled={code.length < 6}>
                Verify
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Add number */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Plus size={16} />
            Add Business Number
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-xs text-muted mb-1 block">{t('common.phoneNumber')}</label>
              <input
                type="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="(555) 123-4567"
                className="w-full px-3 py-2 bg-secondary border border-default rounded-lg text-sm text-main"
              />
            </div>
            <div>
              <label className="text-xs text-muted mb-1 block">Label (optional)</label>
              <input
                type="text"
                value={label}
                onChange={(e) => setLabel(e.target.value)}
                placeholder="Main Office"
                className="w-full px-3 py-2 bg-secondary border border-default rounded-lg text-sm text-main"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-xs text-muted mb-1 block">{t('settingsPhone.integrationMethod')}</label>
              <select
                value={fwdType}
                onChange={(e) => setFwdType(e.target.value as typeof fwdType)}
                className="w-full px-3 py-2 bg-secondary border border-default rounded-lg text-sm text-main"
              >
                <option value="call_forward">Call Forwarding (Easiest)</option>
                <option value="sip_trunk">SIP Trunk (VoIP Providers)</option>
                <option value="port_in">Port Number (Permanent)</option>
              </select>
            </div>
            {fwdType === 'call_forward' && (
              <div>
                <label className="text-xs text-muted mb-1 block">{t('settingsPhone.yourCarrier')}</label>
                <select
                  value={carrier}
                  onChange={(e) => setCarrier(e.target.value)}
                  className="w-full px-3 py-2 bg-secondary border border-default rounded-lg text-sm text-main"
                >
                  {Object.entries(CARRIER_FORWARDING_INSTRUCTIONS).map(([key, val]) => (
                    <option key={key} value={key}>{val.name}</option>
                  ))}
                </select>
              </div>
            )}
          </div>

          <div className="p-3 bg-secondary rounded-lg text-xs text-muted">
            {fwdType === 'call_forward' && 'Simplest option. Forward calls from your existing number to Zafto. Works with any carrier. Takes 2 minutes.'}
            {fwdType === 'sip_trunk' && 'For VoIP providers (RingCentral, Vonage, 8x8, Grasshopper). Point your SIP trunk to our endpoint for full integration.'}
            {fwdType === 'port_in' && 'Permanently transfer your number to Zafto. Takes 7-10 business days. Your old carrier will release the number.'}
          </div>

          <Button onClick={handleAdd} disabled={adding || !phone.trim()} className="w-full">
            {adding ? 'Adding...' : 'Add Number'}
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
