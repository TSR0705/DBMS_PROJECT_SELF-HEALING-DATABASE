// DBMS self-healing lifecycle structure for sidebar navigation
// Order follows data flow: Detection → Analysis → Decision → Action → Oversight → Learning

export interface SidebarItem {
  label: string;
  category: 'pipeline' | 'oversight' | 'system';
  href: string;
}

export interface SidebarSection {
  title: string;
  items: SidebarItem[];
}

// Sidebar structure maps directly to DBMS self-healing lifecycle stages
export const sidebarStructure: SidebarSection[] = [
  {
    title: 'Core Pipeline',
    items: [
      {
        label: 'System Overview',
        category: 'pipeline',
        href: '/dashboard/overview',
      },
      {
        label: 'Detected Issues',
        category: 'pipeline',
        href: '/dashboard/issues',
      },
      {
        label: 'AI Analysis',
        category: 'pipeline',
        href: '/dashboard/analysis',
      },
      {
        label: 'Decisions',
        category: 'pipeline',
        href: '/dashboard/decisions',
      },
      {
        label: 'Healing Actions',
        category: 'pipeline',
        href: '/dashboard/actions',
      },
    ],
  },
  {
    title: 'Oversight',
    items: [
      {
        label: 'Admin Review',
        category: 'oversight',
        href: '/dashboard/admin-review',
      },
      {
        label: 'Learning History',
        category: 'oversight',
        href: '/dashboard/learning',
      },
    ],
  },
  {
    title: 'System',
    items: [
      {
        label: 'Health & Logs',
        category: 'system',
        href: '/dashboard/system-health',
      },
    ],
  },
];
