import { useQuery } from "@tanstack/react-query";
import { auditApi } from "@/api/endpoints/audit.api";
import { auditQuery } from "@/api/endpoints/audit.query";
import type { AuditFilters } from "@/api/types/audit.types";
import { useAuth } from "@/context/AuthContext";
import { validateAuditPage } from "@/features/audit";
import { ROUTES } from "@/routes/routePaths";
import { ApiRequestError, getApiErrorMessage } from "@/utils/apiErrors";
import { isAdministrator } from "@/utils/roles";

const filters: AuditFilters = {
  modules: ["MarketSections", "Ordinances", "Backups"],
};

export function useRecentChanges() {
  const { user } = useAuth();
  const query = useQuery({
    queryKey: ["audit", user?.userId, "recent-configuration", filters],
    enabled: isAdministrator(user?.role),
    gcTime: 0,
    retry: false,
    queryFn: async ({ signal }) =>
      validateAuditPage(await auditApi.list(filters, 0, signal)),
  });

  return {
    items: query.isError ? [] : (query.data?.items.slice(0, 3) ?? []),
    isLoading: query.isPending,
    isFetching: query.isFetching,
    error: query.isError
      ? getApiErrorMessage(
          query.error instanceof ApiRequestError ? query.error : undefined,
          "Unable to load recent changes. Please try again.",
        )
      : "",
    retry: () => {
      void query.refetch();
    },
    auditLogHref: `${ROUTES.auditLogs}${auditQuery(filters)}`,
  };
}
