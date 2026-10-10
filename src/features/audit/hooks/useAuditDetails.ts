import { useQuery } from "@tanstack/react-query";
import { auditApi } from "@/api/endpoints/audit.api";
import { useAuth } from "@/context/AuthContext";
import { isAdministrator } from "@/utils/roles";
import { ApiRequestError, getApiErrorMessage } from "@/utils/apiErrors";
import { validateAuditDetail } from "../audit.validation";

export function useAuditDetails(id: number | null) {
  const { user } = useAuth();
  const query = useQuery({
    queryKey: ["audit", user?.userId, "detail", id],
    enabled: isAdministrator(user?.role) && id !== null,
    retry: false,
    gcTime: 0,
    queryFn: async ({ signal }) => {
      if (id === null) throw new ApiRequestError();
      return validateAuditDetail(await auditApi.details(id, signal), id);
    },
  });
  return {
    record: query.data,
    isLoading: query.isPending,
    isFetching: query.isFetching,
    error: query.isError
      ? getApiErrorMessage(
          query.error instanceof ApiRequestError ? query.error : undefined,
          "Unable to load audit details. Please try again.",
        )
      : "",
    retry: () => {
      void query.refetch();
    },
  };
}
