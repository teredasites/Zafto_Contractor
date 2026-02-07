import type { ZSlashCommand } from './types';

export const SLASH_COMMANDS: ZSlashCommand[] = [
  {
    command: '/bid',
    label: 'Create Bid',
    description: 'Generate a professional bid or estimate',
    icon: 'FileText',
  },
  {
    command: '/invoice',
    label: 'Create Invoice',
    description: 'Generate an invoice from a job',
    icon: 'Receipt',
  },
  {
    command: '/report',
    label: 'Generate Report',
    description: 'Revenue, jobs, or team performance report',
    icon: 'BarChart3',
  },
  {
    command: '/analyze',
    label: 'Analyze',
    description: 'Analyze job costs, margins, or trends',
    icon: 'TrendingUp',
  },
  {
    command: '/schedule',
    label: 'Schedule',
    description: 'Check schedule, find open slots, optimize routes',
    icon: 'Calendar',
  },
  {
    command: '/customer',
    label: 'Customer Lookup',
    description: 'Find customer history, equipment, or contact info',
    icon: 'Users',
  },
];
