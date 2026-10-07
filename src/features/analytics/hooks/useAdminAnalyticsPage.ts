import { useQuery } from "@tanstack/react-query";
import { adminAnalyticsApi } from "@/api/endpoints/adminAnalytics.api";
import { getApiErrorMessage } from "@/utils/apiErrors";

export function useAdminAnalyticsPage() {
  const trendQuery = useQuery({
    queryKey: ["admin-analytics", "violation-trend"],
    queryFn: adminAnalyticsApi.getViolationTrend,
  });
  const peakTimesQuery = useQuery({
    queryKey: ["admin-analytics", "peak-violation-times"],
    queryFn: adminAnalyticsApi.getPeakViolationTimes,
  });
  const distributionQuery = useQuery({
    queryKey: ["admin-analytics", "violation-type-distribution"],
    queryFn: adminAnalyticsApi.getViolationTypeDistribution,
  });
  const inspectionRatioQuery = useQuery({
    queryKey: ["admin-analytics", "inspection-ratio"],
    queryFn: adminAnalyticsApi.getInspectionRatio,
  });
  const resolutionRateQuery = useQuery({
    queryKey: ["admin-analytics", "resolution-rate"],
    queryFn: adminAnalyticsApi.getResolutionRate,
  });
  const marketSectionsQuery = useQuery({
    queryKey: ["admin-analytics", "market-section-aggregation"],
    queryFn: adminAnalyticsApi.getMarketSectionAggregation,
  });
  const hotspotsQuery = useQuery({
    queryKey: ["admin-analytics", "hotspot-ranking"],
    queryFn: adminAnalyticsApi.getHotspotRanking,
  });
  const vendorRiskQuery = useQuery({
    queryKey: ["admin-analytics", "vendor-risk-ranking"],
    queryFn: adminAnalyticsApi.getVendorRiskRanking,
  });

  return {
    trend: {
      data: trendQuery.data ?? [],
      isLoading: trendQuery.isLoading,
      isError: trendQuery.isError,
      errorMessage: getApiErrorMessage(trendQuery.error, "We couldn't load this section. Please try again."),
      refetch: trendQuery.refetch,
    },
    peakTimes: {
      data: peakTimesQuery.data ?? [],
      isLoading: peakTimesQuery.isLoading,
      isError: peakTimesQuery.isError,
      errorMessage: getApiErrorMessage(peakTimesQuery.error, "We couldn't load this section. Please try again."),
      refetch: peakTimesQuery.refetch,
    },
    distribution: {
      data: distributionQuery.data ?? [],
      isLoading: distributionQuery.isLoading,
      isError: distributionQuery.isError,
      errorMessage: getApiErrorMessage(distributionQuery.error, "We couldn't load this section. Please try again."),
      refetch: distributionQuery.refetch,
    },
    inspectionRatio: {
      data: inspectionRatioQuery.data,
      isLoading: inspectionRatioQuery.isLoading,
      isError: inspectionRatioQuery.isError,
      errorMessage: getApiErrorMessage(inspectionRatioQuery.error, "We couldn't load this section. Please try again."),
      refetch: inspectionRatioQuery.refetch,
    },
    resolutionRate: {
      data: resolutionRateQuery.data,
      isLoading: resolutionRateQuery.isLoading,
      isError: resolutionRateQuery.isError,
      errorMessage: getApiErrorMessage(resolutionRateQuery.error, "We couldn't load this section. Please try again."),
      refetch: resolutionRateQuery.refetch,
    },
    marketSections: {
      data: marketSectionsQuery.data ?? [],
      isLoading: marketSectionsQuery.isLoading,
      isError: marketSectionsQuery.isError,
      errorMessage: getApiErrorMessage(marketSectionsQuery.error, "We couldn't load this section. Please try again."),
      refetch: marketSectionsQuery.refetch,
    },
    hotspots: {
      data: hotspotsQuery.data ?? [],
      isLoading: hotspotsQuery.isLoading,
      isError: hotspotsQuery.isError,
      errorMessage: getApiErrorMessage(hotspotsQuery.error, "We couldn't load this section. Please try again."),
      refetch: hotspotsQuery.refetch,
    },
    vendorRisk: {
      data: vendorRiskQuery.data ?? [],
      isLoading: vendorRiskQuery.isLoading,
      isError: vendorRiskQuery.isError,
      errorMessage: getApiErrorMessage(vendorRiskQuery.error, "We couldn't load this section. Please try again."),
      refetch: vendorRiskQuery.refetch,
    },
  };
}
