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
      isLoading: trendQuery.isLoading || trendQuery.isFetching,
      isError: trendQuery.isError,
      errorMessage: getApiErrorMessage(
        trendQuery.error,
        "We couldn't load this section. Please try again.",
      ),
      refetch: trendQuery.refetch,
    },
    peakTimes: {
      data: peakTimesQuery.data ?? [],
      isLoading: peakTimesQuery.isLoading || peakTimesQuery.isFetching,
      isError: peakTimesQuery.isError,
      errorMessage: getApiErrorMessage(
        peakTimesQuery.error,
        "We couldn't load this section. Please try again.",
      ),
      refetch: peakTimesQuery.refetch,
    },
    distribution: {
      data: distributionQuery.data ?? [],
      isLoading: distributionQuery.isLoading || distributionQuery.isFetching,
      isError: distributionQuery.isError,
      errorMessage: getApiErrorMessage(
        distributionQuery.error,
        "We couldn't load this section. Please try again.",
      ),
      refetch: distributionQuery.refetch,
    },
    inspectionRatio: {
      data: inspectionRatioQuery.data,
      isLoading:
        inspectionRatioQuery.isLoading || inspectionRatioQuery.isFetching,
      isError: inspectionRatioQuery.isError,
      errorMessage: getApiErrorMessage(
        inspectionRatioQuery.error,
        "We couldn't load this section. Please try again.",
      ),
      refetch: inspectionRatioQuery.refetch,
    },
    resolutionRate: {
      data: resolutionRateQuery.data,
      isLoading:
        resolutionRateQuery.isLoading || resolutionRateQuery.isFetching,
      isError: resolutionRateQuery.isError,
      errorMessage: getApiErrorMessage(
        resolutionRateQuery.error,
        "We couldn't load this section. Please try again.",
      ),
      refetch: resolutionRateQuery.refetch,
    },
    marketSections: {
      data: marketSectionsQuery.data ?? [],
      isLoading:
        marketSectionsQuery.isLoading || marketSectionsQuery.isFetching,
      isError: marketSectionsQuery.isError,
      errorMessage: getApiErrorMessage(
        marketSectionsQuery.error,
        "We couldn't load this section. Please try again.",
      ),
      refetch: marketSectionsQuery.refetch,
    },
    hotspots: {
      data: hotspotsQuery.data ?? [],
      isLoading: hotspotsQuery.isLoading || hotspotsQuery.isFetching,
      isError: hotspotsQuery.isError,
      errorMessage: getApiErrorMessage(
        hotspotsQuery.error,
        "We couldn't load this section. Please try again.",
      ),
      refetch: hotspotsQuery.refetch,
    },
    vendorRisk: {
      data: vendorRiskQuery.data ?? [],
      isLoading: vendorRiskQuery.isLoading || vendorRiskQuery.isFetching,
      isError: vendorRiskQuery.isError,
      errorMessage: getApiErrorMessage(
        vendorRiskQuery.error,
        "We couldn't load this section. Please try again.",
      ),
      refetch: vendorRiskQuery.refetch,
    },
  };
}
