import apiClient from '../client'

export interface DashboardSummary {
  totalInspectionsToday: number;
  totalWarnings: number;
  totalTickets: number;
  totalPendingFines: number;
  complianceRate: number;
}

export function getDashboardSummary(): Promise<DashboardSummary> {
  return apiClient.get('/dashboard/summary') as unknown as Promise<DashboardSummary>;
}