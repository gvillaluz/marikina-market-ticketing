export type DashboardActivityCategory = string;

export type DashboardAttentionType = "OpenTickets" | "PendingRegistrations";

export interface DashboardMetrics {
  inspectionsToday: number;
  openTickets: number;
  activeVendors: number;
  pendingRegistrations: number;
}

export interface DashboardActivity {
  id: number;
  occurredAt: string;
  category: DashboardActivityCategory;
  title: string;
  description: string;
  actorName: string | null;
}

export interface DashboardAttentionItem {
  id: string;
  type: DashboardAttentionType;
  title: string;
  count: number;
}

export interface DashboardSummary {
  asOf: string;
  metrics: DashboardMetrics;
  recentActivity: DashboardActivity[];
  attentionItems: DashboardAttentionItem[];
}
