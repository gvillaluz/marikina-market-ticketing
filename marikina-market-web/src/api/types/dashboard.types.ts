export type DashboardActivityCategory = string;

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

export interface DashboardOverdueTicket {
  id: number;
  controlNumber: string | null;
  vendorId: number | null;
  businessName: string | null;
  daysOverdue: number;
}

export interface DashboardOverdueTickets {
  total: number;
  items: DashboardOverdueTicket[];
}

export interface DashboardSummary {
  asOf: string;
  metrics: DashboardMetrics;
  recentActivity: DashboardActivity[];
  overdueTickets: DashboardOverdueTickets;
}
