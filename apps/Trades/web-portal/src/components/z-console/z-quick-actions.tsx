'use client';

import {
  FileText, Receipt, BarChart3, TrendingUp, Calendar, Users, Target,
  ClipboardList, AlertTriangle, Send, DollarSign, Clock, AlertCircle,
  MapPin, Phone, Search, HelpCircle, PieChart, ClipboardCheck, FilePlus, History,
} from 'lucide-react';
import type { ZQuickAction } from '@/lib/z-intelligence/types';

const ICON_MAP: Record<string, React.ComponentType<{ size?: number }>> = {
  FileText, Receipt, BarChart3, TrendingUp, Calendar, Users, Target,
  ClipboardList, AlertTriangle, Send, DollarSign, Clock, AlertCircle,
  MapPin, Phone, Search, HelpCircle, PieChart, ClipboardCheck, FilePlus, History,
};

interface ZQuickActionsProps {
  actions: ZQuickAction[];
  onSelect: (action: ZQuickAction) => void;
}

export function ZQuickActions({ actions, onSelect }: ZQuickActionsProps) {
  if (!actions.length) return null;

  return (
    <div className="flex gap-2 px-4 py-2 overflow-x-auto scrollbar-hide">
      {actions.map((action) => {
        const Icon = ICON_MAP[action.icon];
        return (
          <button
            key={action.id}
            onClick={() => onSelect(action)}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-[12px] font-medium
              bg-secondary border border-main text-secondary
              hover:border-accent/40 hover:text-main
              transition-colors whitespace-nowrap flex-shrink-0"
          >
            {Icon && <Icon size={13} />}
            {action.label}
          </button>
        );
      })}
    </div>
  );
}
