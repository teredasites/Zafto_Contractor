'use client';

import { useState } from 'react';
import {
  FileCheck,
  Plus,
  ChevronRight,
  Trash2,
  Edit,
  Copy,
  Lock,
  Search,
  Layers,
  X,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { SearchInput } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { cn } from '@/lib/utils';
import { useInspectionTemplates } from '@/lib/hooks/use-inspection-templates';
import type { InspectionTemplateData } from '@/lib/hooks/use-inspection-templates';
import { useTranslation } from '@/lib/translations';

export default function InspectionTemplatesPage() {
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [tab, setTab] = useState<'company' | 'system'>('company');
  const [selectedTemplate, setSelectedTemplate] = useState<InspectionTemplateData | null>(null);
  const { templates, systemTemplates, companyTemplates, loading } = useInspectionTemplates();

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-56 mb-2" /><div className="skeleton h-4 w-64" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="bg-surface border border-main rounded-xl p-5">
              <div className="skeleton h-4 w-32 mb-3" />
              <div className="skeleton h-3 w-48 mb-2" />
              <div className="skeleton h-3 w-24" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  const displayTemplates = tab === 'system' ? systemTemplates : companyTemplates;
  const filtered = displayTemplates.filter(t =>
    t.name.toLowerCase().includes(search.toLowerCase()) ||
    (t.description || '').toLowerCase().includes(search.toLowerCase()) ||
    (t.trade || '').toLowerCase().includes(search.toLowerCase())
  );

  const totalItems = (t: InspectionTemplateData) =>
    t.sections.reduce((sum, s) => sum + s.items.length, 0);

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Inspection Templates</h1>
          <p className="text-muted mt-1">Manage checklists for inspections across all trades</p>
        </div>
        <Button><Plus size={16} />New Template</Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg"><Layers size={20} className="text-blue-600 dark:text-blue-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{systemTemplates.length}</p><p className="text-sm text-muted">System Templates</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg"><FileCheck size={20} className="text-emerald-600 dark:text-emerald-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{companyTemplates.length}</p><p className="text-sm text-muted">Custom Templates</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg"><FileCheck size={20} className="text-purple-600 dark:text-purple-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{templates.reduce((s, t) => s + totalItems(t), 0)}</p><p className="text-sm text-muted">Total Checklist Items</p></div>
        </div></CardContent></Card>
      </div>

      {/* Tabs + Search */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="flex gap-1 p-1 bg-secondary rounded-lg">
          <button onClick={() => setTab('company')} className={cn('px-4 py-2 rounded-md text-sm font-medium transition-colors', tab === 'company' ? 'bg-surface text-main shadow-sm' : 'text-muted hover:text-main')}>My Templates</button>
          <button onClick={() => setTab('system')} className={cn('px-4 py-2 rounded-md text-sm font-medium transition-colors', tab === 'system' ? 'bg-surface text-main shadow-sm' : 'text-muted hover:text-main')}>System Templates</button>
        </div>
        <SearchInput value={search} onChange={setSearch} placeholder="Search templates..." className="sm:w-80" />
      </div>

      {/* Templates grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {filtered.map(template => (
          <Card key={template.id} className="hover:border-accent/30 transition-colors cursor-pointer" onClick={() => setSelectedTemplate(template)}>
            <CardContent className="p-5">
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-2">
                  {template.isSystem && <Lock size={14} className="text-muted" />}
                  <h3 className="font-medium text-main">{template.name}</h3>
                </div>
                <ChevronRight size={16} className="text-muted" />
              </div>
              {template.description && (
                <p className="text-sm text-muted mb-3 line-clamp-2">{template.description}</p>
              )}
              <div className="flex items-center gap-3 text-xs text-muted">
                <span>{template.sections.length} sections</span>
                <span>{totalItems(template)} items</span>
                {template.trade && <span className="px-2 py-0.5 bg-secondary rounded-full">{template.trade}</span>}
              </div>
            </CardContent>
          </Card>
        ))}

        {filtered.length === 0 && (
          <Card className="col-span-full"><CardContent className="p-12 text-center">
            <FileCheck size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">No templates found</h3>
            <p className="text-muted mb-4">{tab === 'system' ? 'System templates are provisioned automatically.' : 'Create custom templates for your inspections.'}</p>
            {tab === 'company' && <Button><Plus size={16} />New Template</Button>}
          </CardContent></Card>
        )}
      </div>

      {/* Detail modal */}
      {selectedTemplate && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={() => setSelectedTemplate(null)}>
          {/* eslint-disable-next-line jsx-a11y/click-events-have-key-events, jsx-a11y/no-static-element-interactions */}
          <div className="w-full max-w-2xl max-h-[90vh] overflow-y-auto bg-surface border border-main rounded-xl" onClick={(e: React.MouseEvent) => e.stopPropagation()}>
            <CardHeader className="flex flex-row items-center justify-between">
              <div>
                <div className="flex items-center gap-2 mb-1">
                  {selectedTemplate.isSystem && <span className="px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300">System</span>}
                  {selectedTemplate.trade && <span className="px-2 py-0.5 rounded-full text-xs font-medium bg-secondary text-muted">{selectedTemplate.trade}</span>}
                </div>
                <CardTitle className="text-lg">{selectedTemplate.name}</CardTitle>
                {selectedTemplate.description && <p className="text-sm text-muted mt-1">{selectedTemplate.description}</p>}
              </div>
              <Button variant="ghost" size="sm" onClick={() => setSelectedTemplate(null)}><X size={18} /></Button>
            </CardHeader>
            <CardContent className="space-y-4">
              {selectedTemplate.sections.map((section, si) => (
                <div key={si}>
                  <h4 className="text-xs text-muted uppercase tracking-wider mb-2">{section.name} ({section.items.length} items)</h4>
                  <div className="space-y-1">
                    {section.items.map((item, ii) => (
                      <div key={ii} className="flex items-center gap-3 p-3 rounded-lg border bg-surface border-main">
                        <div className="w-5 h-5 border-2 border-main rounded" />
                        <div className="flex-1">
                          <p className="text-sm text-main">{item.name}</p>
                          {item.description && <p className="text-xs text-muted">{item.description}</p>}
                        </div>
                        <span className="text-xs text-muted">w:{item.weight}</span>
                      </div>
                    ))}
                  </div>
                </div>
              ))}

              <div className="flex items-center gap-3 pt-4">
                <Button variant="secondary" className="flex-1" onClick={() => setSelectedTemplate(null)}>Close</Button>
                {!selectedTemplate.isSystem && (
                  <>
                    <Button variant="secondary" className="flex-1"><Edit size={16} />Edit</Button>
                    <Button variant="secondary" className="flex-1"><Trash2 size={16} />Delete</Button>
                  </>
                )}
                {selectedTemplate.isSystem && <Button variant="secondary" className="flex-1"><Copy size={16} />Clone to My Templates</Button>}
              </div>
            </CardContent>
          </div>
        </div>
      )}
    </div>
  );
}
