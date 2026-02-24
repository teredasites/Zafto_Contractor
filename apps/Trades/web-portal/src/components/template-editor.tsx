'use client';

import { useEditor, EditorContent, type Editor } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import { Table } from '@tiptap/extension-table';
import { TableRow } from '@tiptap/extension-table-row';
import { TableCell } from '@tiptap/extension-table-cell';
import { TableHeader } from '@tiptap/extension-table-header';
import { Placeholder } from '@tiptap/extension-placeholder';
import { useState, useCallback, useRef, useEffect } from 'react';
import {
  Bold,
  Italic,
  Strikethrough,
  List,
  ListOrdered,
  Quote,
  Minus,
  Undo,
  Redo,
  Table as TableIcon,
  Code,
  Heading1,
  Heading2,
  Heading3,
  ChevronDown,
  Variable,
  Eye,
  Edit3,
} from 'lucide-react';
import { cn } from '@/lib/utils';

// ============================================================================
// TEMPLATE VARIABLES — available merge tags
// ============================================================================

export interface VariableGroup {
  label: string;
  variables: { name: string; label: string; sample: string }[];
}

export const TEMPLATE_VARIABLE_GROUPS: VariableGroup[] = [
  {
    label: 'Customer',
    variables: [
      { name: 'customer_name', label: 'Customer Name', sample: 'John Smith' },
      { name: 'customer_first_name', label: 'First Name', sample: 'John' },
      { name: 'customer_last_name', label: 'Last Name', sample: 'Smith' },
      { name: 'customer_email', label: 'Email', sample: 'john@example.com' },
      { name: 'customer_phone', label: 'Phone', sample: '(555) 123-4567' },
      { name: 'customer_address', label: 'Full Address', sample: '123 Main St, Hartford, CT 06103' },
      { name: 'customer_street', label: 'Street', sample: '123 Main St' },
      { name: 'customer_city', label: 'City', sample: 'Hartford' },
      { name: 'customer_state', label: 'State', sample: 'CT' },
      { name: 'customer_zip', label: 'Zip', sample: '06103' },
    ],
  },
  {
    label: 'Company',
    variables: [
      { name: 'company_name', label: 'Company Name', sample: 'Acme Contracting LLC' },
      { name: 'company_address', label: 'Company Address', sample: '456 Business Blvd, Hartford, CT 06103' },
      { name: 'company_phone', label: 'Company Phone', sample: '(555) 987-6543' },
      { name: 'company_email', label: 'Company Email', sample: 'info@acmecontracting.com' },
      { name: 'company_license', label: 'License Number', sample: 'LIC-2024-12345' },
      { name: 'company_website', label: 'Website', sample: 'www.acmecontracting.com' },
    ],
  },
  {
    label: 'Job',
    variables: [
      { name: 'job_title', label: 'Job Title', sample: 'Roof Replacement' },
      { name: 'job_address', label: 'Job Address', sample: '123 Main St, Hartford, CT 06103' },
      { name: 'job_type', label: 'Job Type', sample: 'Standard' },
      { name: 'job_description', label: 'Description', sample: 'Complete tear-off and replacement of asphalt shingle roof' },
      { name: 'job_start_date', label: 'Start Date', sample: 'March 15, 2026' },
      { name: 'job_trade', label: 'Trade Type', sample: 'Roofing' },
    ],
  },
  {
    label: 'Estimate / Invoice',
    variables: [
      { name: 'estimate_number', label: 'Estimate Number', sample: 'EST-20260315-001' },
      { name: 'estimate_total', label: 'Estimate Total', sample: '$12,450.00' },
      { name: 'estimate_line_items', label: 'Line Items', sample: '(table of line items)' },
      { name: 'invoice_number', label: 'Invoice Number', sample: 'INV-20260401-001' },
      { name: 'invoice_total', label: 'Invoice Total', sample: '$12,450.00' },
      { name: 'invoice_due_date', label: 'Due Date', sample: 'April 30, 2026' },
    ],
  },
  {
    label: 'Property (Recon)',
    variables: [
      { name: 'property_address', label: 'Property Address', sample: '123 Main St, Hartford, CT 06103' },
      { name: 'property_year_built', label: 'Year Built', sample: '1985' },
      { name: 'property_sqft', label: 'Living Area', sample: '2,450' },
      { name: 'property_lot_sqft', label: 'Lot Size', sample: '8,200' },
      { name: 'property_stories', label: 'Stories', sample: '2' },
      { name: 'property_beds', label: 'Bedrooms', sample: '4' },
      { name: 'property_baths', label: 'Bathrooms', sample: '2.5' },
      { name: 'property_roof_area_sqft', label: 'Roof Area', sample: '1,850' },
      { name: 'property_roof_pitch', label: 'Roof Pitch', sample: '6/12' },
      { name: 'property_construction_type', label: 'Construction Type', sample: 'Wood Frame' },
      { name: 'property_flood_zone', label: 'Flood Zone', sample: 'X' },
      { name: 'property_hazard_list', label: 'Hazard List', sample: 'Lead Paint Risk, Asbestos Risk' },
      { name: 'property_climate_zone', label: 'Climate Zone', sample: '5A' },
    ],
  },
  {
    label: 'General',
    variables: [
      { name: 'today_date', label: 'Today\'s Date', sample: new Date().toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' }) },
      { name: 'user_name', label: 'Current User', sample: 'Jane Contractor' },
      { name: 'user_title', label: 'User Title', sample: 'Project Manager' },
      { name: 'user_email', label: 'User Email', sample: 'jane@acmecontracting.com' },
    ],
  },
];

// Build sample data map for preview
const SAMPLE_DATA: Record<string, string> = {};
TEMPLATE_VARIABLE_GROUPS.forEach(g => g.variables.forEach(v => { SAMPLE_DATA[v.name] = v.sample; }));

// ============================================================================
// TOOLBAR BUTTON
// ============================================================================

function ToolbarButton({
  onClick,
  active,
  disabled,
  children,
  title,
}: {
  onClick: () => void;
  active?: boolean;
  disabled?: boolean;
  children: React.ReactNode;
  title?: string;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      title={title}
      className={cn(
        'p-1.5 rounded transition-colors',
        active ? 'bg-accent/15 text-accent' : 'text-muted hover:text-main hover:bg-surface-hover',
        disabled && 'opacity-40 cursor-not-allowed'
      )}
    >
      {children}
    </button>
  );
}

// ============================================================================
// VARIABLE INSERTER DROPDOWN
// ============================================================================

function VariableInserter({ editor }: { editor: Editor | null }) {
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState('');
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  const insertVariable = (name: string) => {
    if (!editor) return;
    editor.chain().focus().insertContent(`{{${name}}}`).run();
    setOpen(false);
    setSearch('');
  };

  const filteredGroups = TEMPLATE_VARIABLE_GROUPS.map(g => ({
    ...g,
    variables: g.variables.filter(v =>
      v.label.toLowerCase().includes(search.toLowerCase()) ||
      v.name.toLowerCase().includes(search.toLowerCase())
    ),
  })).filter(g => g.variables.length > 0);

  return (
    <div className="relative" ref={ref}>
      <button
        type="button"
        onClick={() => setOpen(!open)}
        className={cn(
          'flex items-center gap-1 px-2 py-1.5 rounded text-xs font-medium transition-colors',
          open ? 'bg-accent/15 text-accent' : 'text-muted hover:text-main hover:bg-surface-hover'
        )}
      >
        <Variable size={13} />
        Insert Variable
        <ChevronDown size={11} />
      </button>

      {open && (
        <div className="absolute top-full left-0 mt-1 w-80 bg-card border border-main rounded-xl shadow-lg z-50 overflow-hidden">
          <div className="p-2 border-b border-main">
            <input
              type="text"
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search variables..."
              autoFocus
              className="w-full px-3 py-1.5 bg-surface border border-main/50 rounded-lg text-sm text-main placeholder:text-muted focus:outline-none focus:border-accent/50"
            />
          </div>
          <div className="max-h-72 overflow-y-auto p-1">
            {filteredGroups.map(group => (
              <div key={group.label}>
                <div className="px-3 py-1.5 text-[10px] font-bold text-muted uppercase tracking-wider">{group.label}</div>
                {group.variables.map(v => (
                  <button
                    key={v.name}
                    type="button"
                    onClick={() => insertVariable(v.name)}
                    className="w-full flex items-center justify-between px-3 py-1.5 rounded-lg text-left hover:bg-surface-hover transition-colors"
                  >
                    <span className="text-xs font-medium text-main">{v.label}</span>
                    <span className="text-[10px] font-mono text-muted">{`{{${v.name}}}`}</span>
                  </button>
                ))}
              </div>
            ))}
            {filteredGroups.length === 0 && (
              <div className="px-3 py-4 text-center text-xs text-muted">No variables match</div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// ============================================================================
// TOOLBAR
// ============================================================================

function EditorToolbar({ editor }: { editor: Editor | null }) {
  if (!editor) return null;

  return (
    <div className="flex items-center gap-0.5 flex-wrap px-3 py-2 border-b border-main bg-surface/50">
      {/* Text formatting */}
      <ToolbarButton onClick={() => editor.chain().focus().toggleBold().run()} active={editor.isActive('bold')} title="Bold">
        <Bold size={14} />
      </ToolbarButton>
      <ToolbarButton onClick={() => editor.chain().focus().toggleItalic().run()} active={editor.isActive('italic')} title="Italic">
        <Italic size={14} />
      </ToolbarButton>
      <ToolbarButton onClick={() => editor.chain().focus().toggleStrike().run()} active={editor.isActive('strike')} title="Strikethrough">
        <Strikethrough size={14} />
      </ToolbarButton>
      <ToolbarButton onClick={() => editor.chain().focus().toggleCode().run()} active={editor.isActive('code')} title="Inline Code">
        <Code size={14} />
      </ToolbarButton>

      <div className="w-px h-5 bg-main/20 mx-1" />

      {/* Headings */}
      <ToolbarButton onClick={() => editor.chain().focus().toggleHeading({ level: 1 }).run()} active={editor.isActive('heading', { level: 1 })} title="Heading 1">
        <Heading1 size={14} />
      </ToolbarButton>
      <ToolbarButton onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()} active={editor.isActive('heading', { level: 2 })} title="Heading 2">
        <Heading2 size={14} />
      </ToolbarButton>
      <ToolbarButton onClick={() => editor.chain().focus().toggleHeading({ level: 3 }).run()} active={editor.isActive('heading', { level: 3 })} title="Heading 3">
        <Heading3 size={14} />
      </ToolbarButton>

      <div className="w-px h-5 bg-main/20 mx-1" />

      {/* Lists */}
      <ToolbarButton onClick={() => editor.chain().focus().toggleBulletList().run()} active={editor.isActive('bulletList')} title="Bullet List">
        <List size={14} />
      </ToolbarButton>
      <ToolbarButton onClick={() => editor.chain().focus().toggleOrderedList().run()} active={editor.isActive('orderedList')} title="Numbered List">
        <ListOrdered size={14} />
      </ToolbarButton>
      <ToolbarButton onClick={() => editor.chain().focus().toggleBlockquote().run()} active={editor.isActive('blockquote')} title="Quote">
        <Quote size={14} />
      </ToolbarButton>

      <div className="w-px h-5 bg-main/20 mx-1" />

      {/* Table */}
      <ToolbarButton onClick={() => editor.chain().focus().insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run()} title="Insert Table">
        <TableIcon size={14} />
      </ToolbarButton>
      <ToolbarButton onClick={() => editor.chain().focus().setHorizontalRule().run()} title="Horizontal Rule">
        <Minus size={14} />
      </ToolbarButton>

      <div className="w-px h-5 bg-main/20 mx-1" />

      {/* Undo/Redo */}
      <ToolbarButton onClick={() => editor.chain().focus().undo().run()} disabled={!editor.can().undo()} title="Undo">
        <Undo size={14} />
      </ToolbarButton>
      <ToolbarButton onClick={() => editor.chain().focus().redo().run()} disabled={!editor.can().redo()} title="Redo">
        <Redo size={14} />
      </ToolbarButton>

      <div className="flex-1" />

      {/* Variable inserter */}
      <VariableInserter editor={editor} />
    </div>
  );
}

// ============================================================================
// PREVIEW RENDERER
// ============================================================================

function replaceVariables(html: string, data: Record<string, string>): string {
  return html.replace(/\{\{(\w+)\}\}/g, (match, name) => {
    return data[name] || match;
  });
}

// ============================================================================
// MAIN TEMPLATE EDITOR COMPONENT
// ============================================================================

export interface TemplateEditorProps {
  content: string;
  onChange: (html: string) => void;
  previewData?: Record<string, string>;
  className?: string;
}

export function TemplateEditor({ content, onChange, previewData, className }: TemplateEditorProps) {
  const [mode, setMode] = useState<'edit' | 'preview'>('edit');

  const editor = useEditor({
    extensions: [
      StarterKit.configure({
        heading: { levels: [1, 2, 3, 4] },
      }),
      Table.configure({ resizable: true }),
      TableRow,
      TableCell,
      TableHeader,
      Placeholder.configure({
        placeholder: 'Start typing your template content... Use the "Insert Variable" button to add merge tags like {{customer_name}}.',
      }),
    ],
    content: content || '',
    editorProps: {
      attributes: {
        class: 'prose prose-sm dark:prose-invert max-w-none focus:outline-none min-h-[300px] px-6 py-4',
      },
    },
    onUpdate: ({ editor: e }) => {
      onChange(e.getHTML());
    },
  });

  // Sync content from outside
  useEffect(() => {
    if (editor && content !== editor.getHTML()) {
      editor.commands.setContent(content || '');
    }
    // Only sync on initial/external content change, not on every keystroke
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const previewHtml = content ? replaceVariables(content, previewData || SAMPLE_DATA) : '<p style="color:#999">No content yet — switch to Edit mode to start writing.</p>';

  return (
    <div className={cn('rounded-xl border border-main overflow-hidden bg-card', className)}>
      {/* Mode toggle */}
      <div className="flex items-center justify-between px-3 py-1.5 bg-surface/50 border-b border-main">
        <div className="flex gap-1">
          <button
            type="button"
            onClick={() => setMode('edit')}
            className={cn(
              'flex items-center gap-1.5 px-3 py-1 rounded-md text-xs font-medium transition-colors',
              mode === 'edit' ? 'bg-accent/15 text-accent' : 'text-muted hover:text-main'
            )}
          >
            <Edit3 size={12} /> Edit
          </button>
          <button
            type="button"
            onClick={() => setMode('preview')}
            className={cn(
              'flex items-center gap-1.5 px-3 py-1 rounded-md text-xs font-medium transition-colors',
              mode === 'preview' ? 'bg-accent/15 text-accent' : 'text-muted hover:text-main'
            )}
          >
            <Eye size={12} /> Preview
          </button>
        </div>
        {mode === 'preview' && (
          <span className="text-[10px] text-muted">Variables replaced with sample data</span>
        )}
      </div>

      {mode === 'edit' ? (
        <>
          <EditorToolbar editor={editor} />
          <EditorContent editor={editor} />
        </>
      ) : (
        <div
          className="prose prose-sm dark:prose-invert max-w-none px-6 py-4 min-h-[300px]"
          dangerouslySetInnerHTML={{ __html: previewHtml }}
        />
      )}
    </div>
  );
}

export default TemplateEditor;
