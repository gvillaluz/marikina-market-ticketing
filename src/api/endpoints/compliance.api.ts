import client from '@/api/client';
import type { ApiResponse } from '@/api/types/common.types';

export interface ComplianceMetric {
  id: string;
  name: string;
  category: string;
  status: 'compliant' | 'non-compliant' | 'pending';
  score: number;
  lastChecked: string;
  notes?: string;
}

export interface ComplianceScore {
  vendorId: string;
  vendorName: string;
  overallScore: number;
  grade: 'A' | 'B' | 'C' | 'D' | 'F';
  metrics: ComplianceMetric[];
  updatedAt: string;
}

/** Compliance API endpoints. */
export const complianceApi = {
  async getVendorCompliance(vendorId: string): Promise<ComplianceScore> {
    const { data } = await client.get<ApiResponse<ComplianceScore>>(`/compliance/${vendorId}`);
    return data.data;
  },

  async getMyCompliance(): Promise<ComplianceScore> {
    const { data } = await client.get<ApiResponse<ComplianceScore>>('/compliance/me');
    return data.data;
  },

  async updateMetric(metricId: string, status: ComplianceMetric['status'], score: number): Promise<ComplianceMetric> {
    const { data } = await client.patch<ApiResponse<ComplianceMetric>>(`/compliance/metrics/${metricId}`, {
      status,
      score,
    });
    return data.data;
  },
};
