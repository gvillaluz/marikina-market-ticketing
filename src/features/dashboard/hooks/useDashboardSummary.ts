import { useQuery } from "@tanstack/react-query";
import { dashboardApi } from "@/api/endpoints/dashboard.api";
import { useAuth } from "@/context/AuthContext";
import { ApiRequestError, getApiErrorMessage } from "@/utils/apiErrors";
import { isAdministrator } from "@/utils/roles";
import { validateDashboardSummary } from "../dashboard.validation";

export function useDashboardSummary() {
  const { user } = useAuth();
  const canView = isAdministrator(user?.role);
  const query = useQuery({
    queryKey: ["dashboard", "summary", user?.userId],
    enabled: canView,
    gcTime: 0,
    retry: false,
    queryFn: async ({ signal }) => {
      const summary = await dashboardApi.getSummary(signal);
      validateDashboardSummary(summary);
      return summary;
    },
  });

  return {
    summary: query.data,
    isLoading: canView && (query.isPending || query.isFetching),
    error: query.isError
      ? getApiErrorMessage(
          query.error instanceof ApiRequestError ? query.error : undefined,
          "Unable to load the dashboard summary. Please try again.",
        )
      : null,
    retry: () => void query.refetch(),
  };
}
