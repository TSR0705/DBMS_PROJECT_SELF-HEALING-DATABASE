// DBMS self-healing lifecycle structure for sidebar navigation
// Order follows data flow: Detection → Analysis → Decision → Action → Oversight → Learning

export interface SidebarItem {
  label: string;
  category: 'pipeline' | 'oversight' | 'system';
  future_route: string; // Placeholder for routing implementation
}

export interface SidebarSection {
  title: string;
  items: SidebarItem[];
}

// Sidebar structure maps directly to DBMS self-healing lifecycle stages
export const sidebarStructure: SidebarSection[] = [
  {
    title: "Core Pipeline",
    items: [
      {
        label: "System Overview",
        category: "pipeline",
        future_route: "/dashboard/overview"
      },
      {
        label: "Detected Issues", 
        category: "pipeline",
        future_route: "/dashboard/issues"
      },
      {
        label: "AI Analysis",
        category: "pipeline", 
        future_route: "/dashboard/analysis"
      },
      {
        label: "Decisions",
        category: "pipeline",
        future_route: "/dashboard/decisions"
      },
      {
        label: "Healing Actions",
        category: "pipeline",
        future_route: "/dashboard/actions"
      }
    ]
  },
  {
    title: "Oversight",
    items: [
      {
        label: "Admin Review",
        category: "oversight",
        future_route: "/dashboard/admin-review"
      },
      {
        label: "Learning History",
        category: "oversight", 
        future_route: "/dashboard/learning"
      }
    ]
  },
  {
    title: "System",
    items: [
      {
        label: "Health & Logs",
        category: "system",
        future_route: "/dashboard/system-health"
      }
    ]
  }
];