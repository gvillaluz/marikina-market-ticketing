export type DashboardActivityCategory = string;

export type DashboardAttentionType = "OpenTickets";

export interface DashboardMetrics {
  warningsToday: number;
  ticketsToday: number;
  openTickets: number;
  activeBusinesses: number;
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
