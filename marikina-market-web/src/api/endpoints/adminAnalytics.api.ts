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
  async getViolationTrend(year?: number): Promise<ViolationTrendPoint[]> {
    const { data } = await client.get<ViolationTrendPoint[]>(
      "/admin/analytics/violation-trend",
      { params: { year } },
    );
    return data;
  },

  async getPeakViolationTimes(year?: number): Promise<PeakViolationTime[]> {
    const { data } = await client.get<PeakViolationTime[]>(
      "/admin/analytics/peak-violation-times",
      { params: { year } },
    );
    return data;
  },

  async getViolationTypeDistribution(
    year?: number,
  ): Promise<ViolationCategoryDistribution[]> {
    const { data } = await client.get<ViolationCategoryDistribution[]>(
      "/admin/analytics/violation-type-distribution",
      { params: { year } },
    );
    return data;
  },

  async getInspectionRatio(year?: number): Promise<InspectionRatio> {
    const { data } = await client.get<InspectionRatio>(
      "/admin/analytics/inspection-ratio",
      { params: { year } },
    );
    return data;
  },

  async getResolutionRate(year?: number): Promise<ViolationResolutionRate> {
    const { data } = await client.get<ViolationResolutionRate>(
      "/admin/analytics/resolution-rate",
      { params: { year } },
    );
    return data;
  },

  async getMarketSectionAggregation(
    year?: number,
  ): Promise<MarketSectionAggregation[]> {
    const { data } = await client.get<MarketSectionAggregation[]>(
      "/admin/analytics/market-section-aggregation",
      { params: { year } },
    );
    return data;
  },

  async getHotspotRanking(year?: number): Promise<HotspotRanking[]> {
    const { data } = await client.get<HotspotRanking[]>(
      "/admin/analytics/hotspot-ranking",
      { params: { year } },
    );
    return data;
  },

  async getVendorRiskRanking(year?: number): Promise<VendorRiskRanking[]> {
    const { data } = await client.get<VendorRiskRanking[]>(
      "/admin/analytics/vendor-risk-ranking",
      { params: { year } },
    );
    return data;
  },
};
