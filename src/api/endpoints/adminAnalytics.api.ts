import client from "@/api/client";
import type {
  HotspotRanking,
  InspectionRatio,
  MarketSectionAggregation,
  PeakViolationTime,
  VendorRiskRanking,
  ViolationCategoryDistribution,
  ViolationResolutionRate,
  ViolationTrendPoint,
} from "@/api/types/admin-analytics.types";

export const adminAnalyticsApi = {
  async getViolationTrend(): Promise<ViolationTrendPoint[]> {
    const { data } = await client.get<ViolationTrendPoint[]>(
      "/admin/analytics/violation-trend",
    );
    return data;
  },

  async getPeakViolationTimes(): Promise<PeakViolationTime[]> {
    const { data } = await client.get<PeakViolationTime[]>(
      "/admin/analytics/peak-violation-times",
    );
    return data;
  },

  async getViolationTypeDistribution(): Promise<
    ViolationCategoryDistribution[]
  > {
    const { data } = await client.get<ViolationCategoryDistribution[]>(
      "/admin/analytics/violation-type-distribution",
    );
    return data;
  },

  async getInspectionRatio(): Promise<InspectionRatio> {
    const { data } = await client.get<InspectionRatio>(
      "/admin/analytics/inspection-ratio",
    );
    return data;
  },

  async getResolutionRate(): Promise<ViolationResolutionRate> {
    const { data } = await client.get<ViolationResolutionRate>(
      "/admin/analytics/resolution-rate",
    );
    return data;
  },

  async getMarketSectionAggregation(): Promise<MarketSectionAggregation[]> {
    const { data } = await client.get<MarketSectionAggregation[]>(
      "/admin/analytics/market-section-aggregation",
    );
    return data;
  },

  async getHotspotRanking(): Promise<HotspotRanking[]> {
    const { data } = await client.get<HotspotRanking[]>(
      "/admin/analytics/hotspot-ranking",
    );
    return data;
  },

  async getVendorRiskRanking(): Promise<VendorRiskRanking[]> {
    const { data } = await client.get<VendorRiskRanking[]>(
      "/admin/analytics/vendor-risk-ranking",
    );
    return data;
  },
};
