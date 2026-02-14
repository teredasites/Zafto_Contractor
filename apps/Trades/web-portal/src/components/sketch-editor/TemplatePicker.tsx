'use client';

// ZAFTO Template Picker Modal (SK13)
// Browse and apply pre-built sketch templates by trade category.

import React, { useState, useMemo } from 'react';
import { X, Search, Home, Fence, Grip, TreePine, Sun, Hammer } from 'lucide-react';
import type { LucideIcon } from 'lucide-react';
import {
  BUILT_IN_TEMPLATES,
  type SketchTemplate,
  type TemplateCategory,
} from '@/lib/sketch-engine/templates';

const CATEGORY_INFO: {
  id: TemplateCategory;
  label: string;
  icon: LucideIcon;
}[] = [
  { id: 'roofing', label: 'Roofing', icon: Home },
  { id: 'fencing', label: 'Fencing', icon: Fence },
  { id: 'concrete', label: 'Concrete', icon: Grip },
  { id: 'kitchen', label: 'Kitchen', icon: Hammer },
  { id: 'bathroom', label: 'Bathroom', icon: Hammer },
  { id: 'basement', label: 'Basement', icon: Hammer },
  { id: 'deck', label: 'Deck', icon: Grip },
  { id: 'landscape', label: 'Landscape', icon: TreePine },
  { id: 'solar', label: 'Solar', icon: Sun },
  { id: 'addition', label: 'Addition', icon: Home },
];

interface TemplatePickerProps {
  onSelect: (template: SketchTemplate) => void;
  onClose: () => void;
}

export default function TemplatePicker({ onSelect, onClose }: TemplatePickerProps) {
  const [search, setSearch] = useState('');
  const [activeCategory, setActiveCategory] = useState<TemplateCategory | 'all'>('all');

  const filtered = useMemo(() => {
    let templates = BUILT_IN_TEMPLATES;
    if (activeCategory !== 'all') {
      templates = templates.filter((t) => t.category === activeCategory);
    }
    if (search) {
      const q = search.toLowerCase();
      templates = templates.filter(
        (t) =>
          t.name.toLowerCase().includes(q) ||
          t.description.toLowerCase().includes(q) ||
          t.category.includes(q),
      );
    }
    return templates;
  }, [activeCategory, search]);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
      <div className="bg-white rounded-xl shadow-2xl w-[640px] max-h-[80vh] flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-3 border-b border-gray-100">
          <h3 className="text-sm font-semibold text-gray-800">Start from Template</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-gray-100">
            <X size={16} className="text-gray-400" />
          </button>
        </div>

        {/* Search */}
        <div className="px-5 py-2 border-b border-gray-50">
          <div className="relative">
            <Search size={14} className="absolute left-2.5 top-2 text-gray-400" />
            <input
              type="text"
              placeholder="Search templates..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-8 pr-3 py-1.5 text-xs border border-gray-200 rounded-lg focus:outline-none focus:ring-1 focus:ring-indigo-300"
            />
          </div>
        </div>

        {/* Categories */}
        <div className="px-5 py-2 flex flex-wrap gap-1 border-b border-gray-50">
          <button
            onClick={() => setActiveCategory('all')}
            className={`px-2 py-0.5 text-[11px] rounded-full transition-colors ${
              activeCategory === 'all'
                ? 'bg-indigo-100 text-indigo-700'
                : 'bg-gray-100 text-gray-500 hover:bg-gray-200'
            }`}
          >
            All
          </button>
          {CATEGORY_INFO.map((cat) => {
            const Icon = cat.icon;
            return (
              <button
                key={cat.id}
                onClick={() => setActiveCategory(cat.id)}
                className={`flex items-center gap-1 px-2 py-0.5 text-[11px] rounded-full transition-colors ${
                  activeCategory === cat.id
                    ? 'bg-indigo-100 text-indigo-700'
                    : 'bg-gray-100 text-gray-500 hover:bg-gray-200'
                }`}
              >
                <Icon size={10} />
                {cat.label}
              </button>
            );
          })}
        </div>

        {/* Template grid */}
        <div className="flex-1 overflow-y-auto p-5">
          {filtered.length === 0 ? (
            <div className="text-center py-8">
              <p className="text-xs text-gray-400">No templates match your search.</p>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-3">
              {filtered.map((tmpl) => (
                <button
                  key={tmpl.id}
                  onClick={() => onSelect(tmpl)}
                  className="text-left p-3 border border-gray-200 rounded-lg hover:border-indigo-300 hover:bg-indigo-50/30 transition-all group"
                >
                  <div className="flex items-start gap-2">
                    <div className="w-10 h-10 rounded bg-gray-100 group-hover:bg-indigo-100 flex items-center justify-center flex-shrink-0">
                      <span className="text-xs font-bold text-gray-400 group-hover:text-indigo-500 uppercase">
                        {tmpl.category.slice(0, 3)}
                      </span>
                    </div>
                    <div className="min-w-0">
                      <p className="text-xs font-semibold text-gray-800 truncate">{tmpl.name}</p>
                      <p className="text-[11px] text-gray-500 line-clamp-2 mt-0.5">
                        {tmpl.description}
                      </p>
                      <div className="flex flex-wrap gap-1 mt-1.5">
                        {tmpl.estimateCategories.slice(0, 3).map((cat) => (
                          <span
                            key={cat}
                            className="px-1.5 py-0.5 text-[9px] bg-gray-100 text-gray-500 rounded"
                          >
                            {cat}
                          </span>
                        ))}
                        {tmpl.estimateCategories.length > 3 && (
                          <span className="px-1.5 py-0.5 text-[9px] bg-gray-100 text-gray-500 rounded">
                            +{tmpl.estimateCategories.length - 3}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
