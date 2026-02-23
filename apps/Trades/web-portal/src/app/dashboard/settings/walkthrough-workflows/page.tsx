'use client';

import { useState, useCallback } from 'react';
import {
  ClipboardCheck,
  Plus,
  Copy,
  Pencil,
  Trash2,
  ChevronUp,
  ChevronDown,
  X,
  Save,
  GripVertical,
  Home,
  Building2,
  Factory,
  Users,
  Camera,
  Sparkles,
  LayoutTemplate,
  CheckSquare,
  ListChecks,
  Settings2,
  AlertCircle,
  ArrowLeft,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';
import {
  useWalkthroughTemplates,
  type WalkthroughTemplate,
  type TemplateRoom,
  type CustomFieldDef,
  type ChecklistItem,
} from '@/lib/hooks/use-walkthrough-templates';
import { useTranslation } from '@/lib/translations';

// ==================== CONSTANTS ====================

const WALKTHROUGH_TYPES: { value: string; label: string }[] = [
  { value: 'general', label: 'General' },
  { value: 'trade_specific', label: 'Trade Specific' },
  { value: 'insurance_restoration', label: 'Insurance Restoration' },
  { value: 'property_inspection', label: 'Property Inspection' },
  { value: 'commercial', label: 'Commercial' },
  { value: 'custom', label: 'Custom' },
];

const PROPERTY_TYPES: { value: string; label: string }[] = [
  { value: 'residential', label: 'Residential' },
  { value: 'commercial', label: 'Commercial' },
  { value: 'industrial', label: 'Industrial' },
  { value: 'multi_family', label: 'Multi-Family' },
];

const ROOM_TYPES: { value: string; label: string }[] = [
  { value: 'living_room', label: 'Living Room' },
  { value: 'bedroom', label: 'Bedroom' },
  { value: 'bathroom', label: 'Bathroom' },
  { value: 'kitchen', label: 'Kitchen' },
  { value: 'dining_room', label: 'Dining Room' },
  { value: 'garage', label: 'Garage' },
  { value: 'basement', label: 'Basement' },
  { value: 'attic', label: 'Attic' },
  { value: 'hallway', label: 'Hallway' },
  { value: 'closet', label: 'Closet' },
  { value: 'laundry', label: 'Laundry' },
  { value: 'office', label: 'Office' },
  { value: 'utility', label: 'Utility' },
  { value: 'exterior', label: 'Exterior' },
  { value: 'roof', label: 'Roof' },
  { value: 'crawlspace', label: 'Crawlspace' },
  { value: 'mechanical', label: 'Mechanical Room' },
  { value: 'lobby', label: 'Lobby' },
  { value: 'conference', label: 'Conference Room' },
  { value: 'storage', label: 'Storage' },
  { value: 'other', label: 'Other' },
];

const FIELD_TYPES: { value: CustomFieldDef['type']; label: string }[] = [
  { value: 'text', label: 'Text' },
  { value: 'number', label: 'Number' },
  { value: 'select', label: 'Dropdown' },
  { value: 'checkbox', label: 'Checkbox' },
  { value: 'rating', label: 'Rating (1-5)' },
];

const PROPERTY_TYPE_ICONS: Record<string, React.ReactNode> = {
  residential: <Home size={16} />,
  commercial: <Building2 size={16} />,
  industrial: <Factory size={16} />,
  multi_family: <Users size={16} />,
};

// ==================== HELPER: empty template ====================

function emptyTemplate(): Partial<WalkthroughTemplate> {
  return {
    name: '',
    description: '',
    walkthroughType: 'general',
    propertyType: 'residential',
    rooms: [],
    customFields: {},
    checklist: [],
    aiInstructions: '',
  };
}

function emptyRoom(): TemplateRoom {
  return {
    name: '',
    roomType: 'other',
    requiredPhotos: 2,
    customFields: {},
    checklist: [],
  };
}

// ==================== PAGE ====================

export default function WalkthroughWorkflowsPage() {
  const { t } = useTranslation();
  const { templates, loading, error, createTemplate, updateTemplate, deleteTemplate, cloneTemplate } =
    useWalkthroughTemplates();

  const [editingTemplate, setEditingTemplate] = useState<Partial<WalkthroughTemplate> | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);
  const [cloneLoading, setCloneLoading] = useState<string | null>(null);

  const systemTemplates = templates.filter((t) => t.isSystem);
  const companyTemplates = templates.filter((t) => !t.isSystem);

  const handleCreate = () => {
    setEditingId(null);
    setEditingTemplate(emptyTemplate());
    setSaveError(null);
  };

  const handleEdit = (template: WalkthroughTemplate) => {
    setEditingId(template.id);
    setEditingTemplate({
      name: template.name,
      description: template.description,
      walkthroughType: template.walkthroughType,
      propertyType: template.propertyType,
      rooms: JSON.parse(JSON.stringify(template.rooms)),
      customFields: JSON.parse(JSON.stringify(template.customFields)),
      checklist: JSON.parse(JSON.stringify(template.checklist)),
      aiInstructions: template.aiInstructions,
    });
    setSaveError(null);
  };

  const handleClone = async (template: WalkthroughTemplate) => {
    try {
      setCloneLoading(template.id);
      await cloneTemplate(template.id, `${template.name} (Copy)`);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to clone template';
      setSaveError(msg);
    } finally {
      setCloneLoading(null);
    }
  };

  const handleSave = async () => {
    if (!editingTemplate || !editingTemplate.name?.trim()) {
      setSaveError('Template name is required.');
      return;
    }

    try {
      setSaving(true);
      setSaveError(null);

      if (editingId) {
        await updateTemplate(editingId, editingTemplate);
      } else {
        await createTemplate(editingTemplate);
      }

      setEditingTemplate(null);
      setEditingId(null);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to save template';
      setSaveError(msg);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: string) => {
    try {
      await deleteTemplate(id);
      setDeleteConfirmId(null);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to delete template';
      setSaveError(msg);
    }
  };

  const handleCancel = () => {
    setEditingTemplate(null);
    setEditingId(null);
    setSaveError(null);
  };

  // If editing, show the editor view
  if (editingTemplate) {
    return (
      <TemplateEditor
        template={editingTemplate}
        isNew={!editingId}
        saving={saving}
        error={saveError}
        onChange={setEditingTemplate}
        onSave={handleSave}
        onCancel={handleCancel}
      />
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Walkthrough Workflows</h1>
          <p className="text-[13px] text-muted mt-1">
            Customize walkthrough templates to standardize your field capture process.
          </p>
        </div>
        <Button onClick={handleCreate}>
          <Plus size={16} />
          Create Template
        </Button>
      </div>

      {/* Error banner */}
      {(error || saveError) && (
        <div className="flex items-center gap-3 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-xl">
          <AlertCircle size={18} className="text-red-500 flex-shrink-0" />
          <p className="text-sm text-red-700 dark:text-red-300">{error || saveError}</p>
        </div>
      )}

      {/* Loading skeleton */}
      {loading && (
        <div className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {[1, 2, 3].map((i) => (
              <div key={i} className="h-48 bg-secondary rounded-xl animate-pulse" />
            ))}
          </div>
        </div>
      )}

      {/* Custom Templates */}
      {!loading && (
        <section>
          <div className="flex items-center gap-2 mb-4">
            <LayoutTemplate size={18} className="text-accent" />
            <h2 className="text-lg font-semibold text-main">Custom Templates</h2>
            <Badge variant="info">{companyTemplates.length}</Badge>
          </div>

          {companyTemplates.length === 0 ? (
            <Card>
              <CardContent className="py-12 text-center">
                <LayoutTemplate size={40} className="mx-auto text-muted/40 mb-3" />
                <p className="text-muted font-medium">No custom templates yet</p>
                <p className="text-sm text-muted mt-1 mb-4">
                  Create your own template or clone a system template to get started.
                </p>
                <Button onClick={handleCreate}>
                  <Plus size={16} />
                  Create Template
                </Button>
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {companyTemplates.map((template) => (
                <TemplateCard
                  key={template.id}
                  template={template}
                  onEdit={() => handleEdit(template)}
                  onDelete={() => setDeleteConfirmId(template.id)}
                  onClone={() => handleClone(template)}
                  cloneLoading={cloneLoading === template.id}
                />
              ))}
            </div>
          )}
        </section>
      )}

      {/* System Templates */}
      {!loading && systemTemplates.length > 0 && (
        <section>
          <div className="flex items-center gap-2 mb-4">
            <Settings2 size={18} className="text-muted" />
            <h2 className="text-lg font-semibold text-main">System Templates</h2>
            <Badge variant="secondary">{systemTemplates.length}</Badge>
          </div>
          <p className="text-sm text-muted mb-4">
            Pre-built templates that come with ZAFTO. Clone one to customize it for your company.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {systemTemplates.map((template) => (
              <TemplateCard
                key={template.id}
                template={template}
                readOnly
                onClone={() => handleClone(template)}
                cloneLoading={cloneLoading === template.id}
              />
            ))}
          </div>
        </section>
      )}

      {/* Delete confirmation modal */}
      {deleteConfirmId && (
        <DeleteConfirmModal
          onConfirm={() => handleDelete(deleteConfirmId)}
          onCancel={() => setDeleteConfirmId(null)}
        />
      )}
    </div>
  );
}

// ==================== TEMPLATE CARD ====================

function TemplateCard({
  template,
  readOnly = false,
  onEdit,
  onDelete,
  onClone,
  cloneLoading = false,
}: {
  template: WalkthroughTemplate;
  readOnly?: boolean;
  onEdit?: () => void;
  onDelete?: () => void;
  onClone: () => void;
  cloneLoading?: boolean;
}) {
  const typeLabel = WALKTHROUGH_TYPES.find((t) => t.value === template.walkthroughType)?.label || template.walkthroughType;
  const propLabel = PROPERTY_TYPES.find((t) => t.value === template.propertyType)?.label || template.propertyType;

  return (
    <Card className="group hover:border-[var(--accent)]/30 hover:shadow-sm transition-all">
      <CardContent className="p-5">
        <div className="flex items-start justify-between mb-3">
          <div className="flex-1 min-w-0">
            <h3 className="font-semibold text-main text-sm truncate">{template.name}</h3>
            {template.description && (
              <p className="text-xs text-muted mt-1 line-clamp-2">{template.description}</p>
            )}
          </div>
          {readOnly && (
            <Badge variant="secondary" className="ml-2 flex-shrink-0">System</Badge>
          )}
        </div>

        {/* Metadata */}
        <div className="flex flex-wrap gap-2 mb-4">
          <span className="inline-flex items-center gap-1.5 px-2 py-0.5 text-xs font-medium rounded-full bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300">
            {typeLabel}
          </span>
          <span className="inline-flex items-center gap-1.5 px-2 py-0.5 text-xs font-medium rounded-full bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400">
            {PROPERTY_TYPE_ICONS[template.propertyType]}
            {propLabel}
          </span>
        </div>

        {/* Stats row */}
        <div className="flex items-center gap-4 text-xs text-muted mb-4">
          <span className="flex items-center gap-1">
            <Home size={12} />
            {template.rooms.length} {template.rooms.length === 1 ? 'room' : 'rooms'}
          </span>
          <span className="flex items-center gap-1">
            <CheckSquare size={12} />
            {template.checklist.length} checklist
          </span>
          {template.usageCount > 0 && (
            <span className="flex items-center gap-1">
              <ClipboardCheck size={12} />
              Used {template.usageCount}x
            </span>
          )}
        </div>

        {/* Actions */}
        <div className="flex items-center gap-2 pt-3 border-t border-main">
          {readOnly ? (
            <Button
              variant="secondary"
              size="sm"
              className="flex-1"
              onClick={onClone}
              loading={cloneLoading}
            >
              <Copy size={14} />
              Clone &amp; Customize
            </Button>
          ) : (
            <>
              <Button variant="secondary" size="sm" className="flex-1" onClick={onEdit}>
                <Pencil size={14} />
                Edit
              </Button>
              <Button
                variant="secondary"
                size="sm"
                onClick={onClone}
                loading={cloneLoading}
              >
                <Copy size={14} />
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={onDelete}
                className="text-red-500 hover:text-red-600"
              >
                <Trash2 size={14} />
              </Button>
            </>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

// ==================== TEMPLATE EDITOR ====================

function TemplateEditor({
  template,
  isNew,
  saving,
  error,
  onChange,
  onSave,
  onCancel,
}: {
  template: Partial<WalkthroughTemplate>;
  isNew: boolean;
  saving: boolean;
  error: string | null;
  onChange: (t: Partial<WalkthroughTemplate>) => void;
  onSave: () => void;
  onCancel: () => void;
}) {
  const rooms = template.rooms || [];
  const customFields = template.customFields || {};
  const checklist = template.checklist || [];

  // ---- Room helpers ----
  const updateRooms = useCallback(
    (newRooms: TemplateRoom[]) => {
      onChange({ ...template, rooms: newRooms });
    },
    [template, onChange]
  );

  const addRoom = () => {
    updateRooms([...rooms, emptyRoom()]);
  };

  const removeRoom = (index: number) => {
    updateRooms(rooms.filter((_, i) => i !== index));
  };

  const moveRoom = (index: number, direction: 'up' | 'down') => {
    const newRooms = [...rooms];
    const target = direction === 'up' ? index - 1 : index + 1;
    if (target < 0 || target >= newRooms.length) return;
    [newRooms[index], newRooms[target]] = [newRooms[target], newRooms[index]];
    updateRooms(newRooms);
  };

  const updateRoom = (index: number, data: Partial<TemplateRoom>) => {
    const newRooms = [...rooms];
    newRooms[index] = { ...newRooms[index], ...data };
    updateRooms(newRooms);
  };

  // ---- Global custom fields helpers ----
  const addGlobalField = () => {
    const key = `field_${Date.now()}`;
    onChange({
      ...template,
      customFields: {
        ...customFields,
        [key]: { label: '', type: 'text', required: false },
      },
    });
  };

  const updateGlobalField = (key: string, field: CustomFieldDef) => {
    onChange({
      ...template,
      customFields: { ...customFields, [key]: field },
    });
  };

  const removeGlobalField = (key: string) => {
    const next = { ...customFields };
    delete next[key];
    onChange({ ...template, customFields: next });
  };

  // ---- Global checklist helpers ----
  const addChecklistItem = () => {
    onChange({
      ...template,
      checklist: [...checklist, { label: '', required: false }],
    });
  };

  const updateChecklistItem = (index: number, item: ChecklistItem) => {
    const next = [...checklist];
    next[index] = item;
    onChange({ ...template, checklist: next });
  };

  const removeChecklistItem = (index: number) => {
    onChange({ ...template, checklist: checklist.filter((_, i) => i !== index) });
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" onClick={onCancel}>
          <ArrowLeft size={20} />
        </Button>
        <div className="flex-1">
          <h1 className="text-2xl font-semibold text-main">
            {isNew ? 'Create Template' : 'Edit Template'}
          </h1>
          <p className="text-[13px] text-muted mt-0.5">
            {isNew
              ? 'Build a new walkthrough template from scratch.'
              : `Editing "${template.name || 'Untitled'}"`}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="secondary" onClick={onCancel} disabled={saving}>
            Cancel
          </Button>
          <Button onClick={onSave} loading={saving}>
            <Save size={16} />
            {isNew ? 'Create' : 'Save Changes'}
          </Button>
        </div>
      </div>

      {/* Error */}
      {error && (
        <div className="flex items-center gap-3 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-xl">
          <AlertCircle size={18} className="text-red-500 flex-shrink-0" />
          <p className="text-sm text-red-700 dark:text-red-300">{error}</p>
        </div>
      )}

      {/* Basic Info */}
      <Card>
        <CardHeader>
          <CardTitle>Template Details</CardTitle>
          <CardDescription>Set the name, type, and description for this walkthrough template.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Input
              label="Template Name"
              value={template.name || ''}
              onChange={(e) => onChange({ ...template, name: e.target.value })}
              placeholder="e.g., Residential Insurance Restoration"
            />
            <div className="space-y-1.5">
              <label className="block text-sm font-medium text-main">Walkthrough Type</label>
              <select
                value={template.walkthroughType || 'general'}
                onChange={(e) => onChange({ ...template, walkthroughType: e.target.value })}
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] transition-colors"
              >
                {WALKTHROUGH_TYPES.map((t) => (
                  <option key={t.value} value={t.value}>{t.label}</option>
                ))}
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <label className="block text-sm font-medium text-main">Property Type</label>
              <select
                value={template.propertyType || 'residential'}
                onChange={(e) => onChange({ ...template, propertyType: e.target.value })}
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] transition-colors"
              >
                {PROPERTY_TYPES.map((t) => (
                  <option key={t.value} value={t.value}>{t.label}</option>
                ))}
              </select>
            </div>
            <div /> {/* Spacer */}
          </div>

          <div className="space-y-1.5">
            <label className="block text-sm font-medium text-main">Description</label>
            <textarea
              value={template.description || ''}
              onChange={(e) => onChange({ ...template, description: e.target.value })}
              placeholder="Describe when this template should be used..."
              rows={3}
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] transition-colors resize-none"
            />
          </div>
        </CardContent>
      </Card>

      {/* Rooms Builder */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>Rooms</CardTitle>
            <CardDescription>
              Define the rooms that should be captured during the walkthrough.
            </CardDescription>
          </div>
          <Button variant="secondary" size="sm" onClick={addRoom}>
            <Plus size={14} />
            Add Room
          </Button>
        </CardHeader>
        <CardContent>
          {rooms.length === 0 ? (
            <div className="text-center py-8 text-muted">
              <Home size={32} className="mx-auto mb-2 opacity-40" />
              <p className="font-medium">No rooms defined</p>
              <p className="text-sm mt-1">Add rooms to standardize what your field crew captures.</p>
            </div>
          ) : (
            <div className="space-y-4">
              {rooms.map((room, index) => (
                <RoomEditor
                  key={index}
                  room={room}
                  index={index}
                  total={rooms.length}
                  onUpdate={(data) => updateRoom(index, data)}
                  onRemove={() => removeRoom(index)}
                  onMoveUp={() => moveRoom(index, 'up')}
                  onMoveDown={() => moveRoom(index, 'down')}
                />
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Global Custom Fields */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>Global Custom Fields</CardTitle>
            <CardDescription>
              Fields that appear on every room in this template (e.g., Moisture Reading, Thermal Image Required).
            </CardDescription>
          </div>
          <Button variant="secondary" size="sm" onClick={addGlobalField}>
            <Plus size={14} />
            Add Field
          </Button>
        </CardHeader>
        <CardContent>
          {Object.keys(customFields).length === 0 ? (
            <div className="text-center py-6 text-muted">
              <ListChecks size={28} className="mx-auto mb-2 opacity-40" />
              <p className="text-sm">No global custom fields. These apply to all rooms.</p>
            </div>
          ) : (
            <div className="space-y-3">
              {Object.entries(customFields).map(([key, field]) => (
                <CustomFieldEditor
                  key={key}
                  field={field}
                  onUpdate={(f) => updateGlobalField(key, f)}
                  onRemove={() => removeGlobalField(key)}
                />
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Global Checklist */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>Global Checklist</CardTitle>
            <CardDescription>
              Items that must be completed for the entire walkthrough (e.g., All rooms photographed, Customer signature obtained).
            </CardDescription>
          </div>
          <Button variant="secondary" size="sm" onClick={addChecklistItem}>
            <Plus size={14} />
            Add Item
          </Button>
        </CardHeader>
        <CardContent>
          {checklist.length === 0 ? (
            <div className="text-center py-6 text-muted">
              <CheckSquare size={28} className="mx-auto mb-2 opacity-40" />
              <p className="text-sm">No checklist items. Add items to enforce completion standards.</p>
            </div>
          ) : (
            <div className="space-y-2">
              {checklist.map((item, index) => (
                <ChecklistItemEditor
                  key={index}
                  item={item}
                  onUpdate={(updated) => updateChecklistItem(index, updated)}
                  onRemove={() => removeChecklistItem(index)}
                />
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* AI Instructions */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Sparkles size={18} className="text-accent" />
            <CardTitle>AI Instructions</CardTitle>
          </div>
          <CardDescription>
            Custom instructions for AI bid generation. When a walkthrough using this template is sent to Z Intelligence,
            these instructions guide how the bid is structured and priced.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <textarea
            value={template.aiInstructions || ''}
            onChange={(e) => onChange({ ...template, aiInstructions: e.target.value })}
            placeholder="e.g., Focus on itemized line items for insurance claims. Include Xactimate-style category codes where applicable. Group items by room and include affected area measurements."
            rows={5}
            className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] transition-colors resize-none text-sm"
          />
        </CardContent>
      </Card>

      {/* Bottom save bar */}
      <div className="flex items-center justify-end gap-3 pt-2 pb-8">
        <Button variant="secondary" onClick={onCancel} disabled={saving}>
          Cancel
        </Button>
        <Button onClick={onSave} loading={saving}>
          <Save size={16} />
          {isNew ? 'Create Template' : 'Save Changes'}
        </Button>
      </div>
    </div>
  );
}

// ==================== ROOM EDITOR ====================

function RoomEditor({
  room,
  index,
  total,
  onUpdate,
  onRemove,
  onMoveUp,
  onMoveDown,
}: {
  room: TemplateRoom;
  index: number;
  total: number;
  onUpdate: (data: Partial<TemplateRoom>) => void;
  onRemove: () => void;
  onMoveUp: () => void;
  onMoveDown: () => void;
}) {
  const [expanded, setExpanded] = useState(true);
  const roomFields = room.customFields || {};
  const roomChecklist = room.checklist || [];

  const addRoomField = () => {
    const key = `field_${Date.now()}`;
    onUpdate({
      customFields: {
        ...roomFields,
        [key]: { label: '', type: 'text', required: false },
      },
    });
  };

  const updateRoomField = (key: string, field: CustomFieldDef) => {
    onUpdate({
      customFields: { ...roomFields, [key]: field },
    });
  };

  const removeRoomField = (key: string) => {
    const next = { ...roomFields };
    delete next[key];
    onUpdate({ customFields: next });
  };

  const addRoomChecklistItem = () => {
    onUpdate({
      checklist: [...roomChecklist, { label: '', required: false }],
    });
  };

  const updateRoomChecklistItem = (idx: number, item: ChecklistItem) => {
    const next = [...roomChecklist];
    next[idx] = item;
    onUpdate({ checklist: next });
  };

  const removeRoomChecklistItem = (idx: number) => {
    onUpdate({
      checklist: roomChecklist.filter((_, i) => i !== idx),
    });
  };

  return (
    <div className="border border-main rounded-lg overflow-hidden">
      {/* Room header */}
      <div
        className="flex items-center gap-3 px-4 py-3 bg-secondary/50 cursor-pointer"
        onClick={() => setExpanded(!expanded)}
      >
        <GripVertical size={16} className="text-muted/40 flex-shrink-0" />
        <div className="flex items-center gap-2 flex-1 min-w-0">
          <span className="text-xs font-semibold text-muted bg-secondary px-2 py-0.5 rounded">
            {index + 1}
          </span>
          <span className="font-medium text-main text-sm truncate">
            {room.name || 'Unnamed Room'}
          </span>
          <Badge variant="secondary" className="text-[10px]">
            {ROOM_TYPES.find((r) => r.value === room.roomType)?.label || room.roomType}
          </Badge>
          <span className="text-xs text-muted flex items-center gap-1">
            <Camera size={11} />
            {room.requiredPhotos} photos
          </span>
        </div>

        <div className="flex items-center gap-1 flex-shrink-0" onClick={(e) => e.stopPropagation()}>
          <button
            onClick={onMoveUp}
            disabled={index === 0}
            className="p-1 hover:bg-surface-hover rounded transition-colors disabled:opacity-30"
          >
            <ChevronUp size={14} className="text-muted" />
          </button>
          <button
            onClick={onMoveDown}
            disabled={index === total - 1}
            className="p-1 hover:bg-surface-hover rounded transition-colors disabled:opacity-30"
          >
            <ChevronDown size={14} className="text-muted" />
          </button>
          <button
            onClick={onRemove}
            className="p-1 hover:bg-red-50 dark:hover:bg-red-900/20 rounded transition-colors ml-1"
          >
            <Trash2 size={14} className="text-red-500" />
          </button>
        </div>
      </div>

      {/* Room body */}
      {expanded && (
        <div className="p-4 space-y-4">
          {/* Basic fields */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Input
              label="Room Name"
              value={room.name}
              onChange={(e) => onUpdate({ name: e.target.value })}
              placeholder="e.g., Master Bedroom"
            />
            <div className="space-y-1.5">
              <label className="block text-sm font-medium text-main">Room Type</label>
              <select
                value={room.roomType}
                onChange={(e) => onUpdate({ roomType: e.target.value })}
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] transition-colors"
              >
                {ROOM_TYPES.map((t) => (
                  <option key={t.value} value={t.value}>{t.label}</option>
                ))}
              </select>
            </div>
            <Input
              label="Required Photos"
              type="number"
              min="0"
              max="50"
              value={String(room.requiredPhotos)}
              onChange={(e) => onUpdate({ requiredPhotos: parseInt(e.target.value, 10) || 0 })}
            />
          </div>

          {/* Room custom fields */}
          <div className="pt-3 border-t border-main">
            <div className="flex items-center justify-between mb-3">
              <p className="text-sm font-medium text-main">Room Custom Fields</p>
              <button
                onClick={addRoomField}
                className="text-xs text-accent hover:underline flex items-center gap-1"
              >
                <Plus size={12} />
                Add Field
              </button>
            </div>
            {Object.keys(roomFields).length === 0 ? (
              <p className="text-xs text-muted">No custom fields for this room.</p>
            ) : (
              <div className="space-y-2">
                {Object.entries(roomFields).map(([key, field]) => (
                  <CustomFieldEditor
                    key={key}
                    field={field}
                    compact
                    onUpdate={(f) => updateRoomField(key, f)}
                    onRemove={() => removeRoomField(key)}
                  />
                ))}
              </div>
            )}
          </div>

          {/* Room checklist */}
          <div className="pt-3 border-t border-main">
            <div className="flex items-center justify-between mb-3">
              <p className="text-sm font-medium text-main">Room Checklist</p>
              <button
                onClick={addRoomChecklistItem}
                className="text-xs text-accent hover:underline flex items-center gap-1"
              >
                <Plus size={12} />
                Add Item
              </button>
            </div>
            {roomChecklist.length === 0 ? (
              <p className="text-xs text-muted">No checklist items for this room.</p>
            ) : (
              <div className="space-y-2">
                {roomChecklist.map((item, idx) => (
                  <ChecklistItemEditor
                    key={idx}
                    item={item}
                    compact
                    onUpdate={(updated) => updateRoomChecklistItem(idx, updated)}
                    onRemove={() => removeRoomChecklistItem(idx)}
                  />
                ))}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// ==================== CUSTOM FIELD EDITOR ====================

function CustomFieldEditor({
  field,
  compact = false,
  onUpdate,
  onRemove,
}: {
  field: CustomFieldDef;
  compact?: boolean;
  onUpdate: (f: CustomFieldDef) => void;
  onRemove: () => void;
}) {
  const [showOptions, setShowOptions] = useState(field.type === 'select');

  return (
    <div className={cn('flex items-start gap-3 p-3 bg-secondary/50 rounded-lg', compact && 'p-2')}>
      <div className="flex-1 grid grid-cols-1 md:grid-cols-12 gap-3 items-start">
        {/* Label */}
        <div className={cn(compact ? 'md:col-span-4' : 'md:col-span-4')}>
          <input
            value={field.label}
            onChange={(e) => onUpdate({ ...field, label: e.target.value })}
            placeholder="Field label"
            className={cn(
              'w-full px-3 py-2 bg-main border border-main rounded-lg text-main placeholder:text-muted text-sm',
              'focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] transition-colors'
            )}
          />
        </div>

        {/* Type */}
        <div className="md:col-span-3">
          <select
            value={field.type}
            onChange={(e) => {
              const newType = e.target.value as CustomFieldDef['type'];
              setShowOptions(newType === 'select');
              onUpdate({
                ...field,
                type: newType,
                options: newType === 'select' ? field.options || [] : undefined,
              });
            }}
            className="w-full px-3 py-2 bg-main border border-main rounded-lg text-main text-sm focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] transition-colors"
          >
            {FIELD_TYPES.map((t) => (
              <option key={t.value} value={t.value}>{t.label}</option>
            ))}
          </select>
        </div>

        {/* Default value */}
        <div className="md:col-span-3">
          <input
            value={field.defaultValue || ''}
            onChange={(e) => onUpdate({ ...field, defaultValue: e.target.value || undefined })}
            placeholder="Default value"
            className="w-full px-3 py-2 bg-main border border-main rounded-lg text-main placeholder:text-muted text-sm focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] transition-colors"
          />
        </div>

        {/* Required toggle */}
        <div className="md:col-span-2 flex items-center gap-2 py-2">
          <label className="flex items-center gap-2 cursor-pointer text-sm">
            <input
              type="checkbox"
              checked={field.required}
              onChange={(e) => onUpdate({ ...field, required: e.target.checked })}
              className="rounded border-gray-300"
            />
            <span className="text-muted text-xs">Required</span>
          </label>
        </div>
      </div>

      {/* Remove */}
      <button
        onClick={onRemove}
        className="p-1.5 hover:bg-red-50 dark:hover:bg-red-900/20 rounded transition-colors flex-shrink-0 mt-1"
      >
        <X size={14} className="text-red-500" />
      </button>

      {/* Select options (if select type) */}
      {showOptions && (
        <div className="w-full mt-2 pl-0">
          <SelectOptionsEditor
            options={field.options || []}
            onChange={(opts) => onUpdate({ ...field, options: opts })}
          />
        </div>
      )}
    </div>
  );
}

// ==================== SELECT OPTIONS EDITOR ====================

function SelectOptionsEditor({
  options,
  onChange,
}: {
  options: string[];
  onChange: (opts: string[]) => void;
}) {
  const addOption = () => {
    onChange([...options, '']);
  };

  const updateOption = (index: number, value: string) => {
    const next = [...options];
    next[index] = value;
    onChange(next);
  };

  const removeOption = (index: number) => {
    onChange(options.filter((_, i) => i !== index));
  };

  return (
    <div className="ml-4 mt-2 space-y-1.5">
      <p className="text-xs text-muted font-medium">Dropdown Options</p>
      {options.map((opt, index) => (
        <div key={index} className="flex items-center gap-2">
          <input
            value={opt}
            onChange={(e) => updateOption(index, e.target.value)}
            placeholder={`Option ${index + 1}`}
            className="flex-1 px-3 py-1.5 bg-main border border-main rounded-lg text-main placeholder:text-muted text-xs focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] transition-colors"
          />
          <button
            onClick={() => removeOption(index)}
            className="p-1 hover:bg-red-50 dark:hover:bg-red-900/20 rounded transition-colors"
          >
            <X size={12} className="text-red-400" />
          </button>
        </div>
      ))}
      <button
        onClick={addOption}
        className="text-xs text-accent hover:underline flex items-center gap-1"
      >
        <Plus size={11} />
        Add Option
      </button>
    </div>
  );
}

// ==================== CHECKLIST ITEM EDITOR ====================

function ChecklistItemEditor({
  item,
  compact = false,
  onUpdate,
  onRemove,
}: {
  item: ChecklistItem;
  compact?: boolean;
  onUpdate: (i: ChecklistItem) => void;
  onRemove: () => void;
}) {
  return (
    <div className={cn('flex items-center gap-3', compact ? 'p-1.5' : 'p-2 bg-secondary/50 rounded-lg')}>
      <input
        value={item.label}
        onChange={(e) => onUpdate({ ...item, label: e.target.value })}
        placeholder="Checklist item label"
        className={cn(
          'flex-1 px-3 py-2 bg-main border border-main rounded-lg text-main placeholder:text-muted text-sm',
          'focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] transition-colors',
          compact && 'py-1.5 text-xs'
        )}
      />
      <label className="flex items-center gap-1.5 cursor-pointer flex-shrink-0">
        <input
          type="checkbox"
          checked={item.required}
          onChange={(e) => onUpdate({ ...item, required: e.target.checked })}
          className="rounded border-gray-300"
        />
        <span className="text-xs text-muted">Required</span>
      </label>
      <button
        onClick={onRemove}
        className="p-1 hover:bg-red-50 dark:hover:bg-red-900/20 rounded transition-colors flex-shrink-0"
      >
        <X size={14} className="text-red-500" />
      </button>
    </div>
  );
}

// ==================== DELETE CONFIRM MODAL ====================

function DeleteConfirmModal({
  onConfirm,
  onCancel,
}: {
  onConfirm: () => void;
  onCancel: () => void;
}) {
  return (
    <>
      <div className="fixed inset-0 bg-black/50 z-50" onClick={onCancel} />
      <div className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-sm z-50">
        <Card>
          <CardHeader>
            <CardTitle>Delete Template</CardTitle>
            <CardDescription>
              Are you sure you want to delete this template? This action cannot be undone.
              Existing walkthroughs using this template will not be affected.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex gap-3">
              <Button variant="secondary" className="flex-1" onClick={onCancel}>
                Cancel
              </Button>
              <Button variant="danger" className="flex-1" onClick={onConfirm}>
                <Trash2 size={16} />
                Delete
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </>
  );
}
