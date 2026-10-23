import { useSearchParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { adminAnalyticsApi } from "@/api/endpoints/adminAnalytics.api";
import { getApiErrorMessage } from "@/utils/apiErrors";

export function useAdminAnalyticsPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const currentYear = Number(
    new Intl.DateTimeFormat("en", {
      timeZone: "Asia/Manila",
      year: "numeric",
    }).format(new Date()),
  );
  const requestedYear = Number(searchParams.get("year"));
  const year =
    Number.isInteger(requestedYear) &&
    requestedYear >= 3 &&
    requestedYear <= currentYear
      ? requestedYear
      : currentYear;
  function selectYear(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const selected = Number(new FormData(event.currentTarget).get("year"));
    if (!Number.isInteger(selected) || selected < 3 || selected > currentYear)
      return;
    setSearchParams((previous) => {
      const next = new URLSearchParams(previous);
      next.set("year", String(selected));
      return next;
    });
  }
  const trendQuery = useQuery({
    queryKey: ["admin-analytics", "violation-trend", year],
    queryFn: () => adminAnalyticsApi.getViolationTrend(year),
  });
  const peakTimesQuery = useQuery({
    queryKey: ["admin-analytics", "peak-violation-times", year],
    queryFn: () => adminAnalyticsApi.getPeakViolationTimes(year),
  });
  const distributionQuery = useQuery({
    queryKey: ["admin-analytics", "violation-type-distribution", year],
    queryFn: () => adminAnalyticsApi.getViolationTypeDistribution(year),
  });
  const inspectionRatioQuery = useQuery({
    queryKey: ["admin-analytics", "inspection-ratio", year],
    queryFn: () => adminAnalyticsApi.getInspectionRatio(year),
  });
  const resolutionRateQuery = useQuery({
    queryKey: ["admin-analytics", "resolution-rate", year],
    queryFn: () => adminAnalyticsApi.getResolutionRate(year),
  });
  const marketSectionsQuery = useQuery({
    queryKey: ["admin-analytics", "market-section-aggregation", year],
    queryFn: () => adminAnalyticsApi.getMarketSectionAggregation(year),
  });
  const hotspotsQuery = useQuery({
    queryKey: ["admin-analytics", "hotspot-ranking", year],
    queryFn: () => adminAnalyticsApi.getHotspotRanking(year),
  });
  const vendorRiskQuery = useQuery({
    queryKey: ["admin-analytics", "vendor-risk-ranking", year],
    queryFn: () => adminAnalyticsApi.getVendorRiskRanking(year),
  });

  return {
    yearControl: { year, currentYear, selectYear },
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
