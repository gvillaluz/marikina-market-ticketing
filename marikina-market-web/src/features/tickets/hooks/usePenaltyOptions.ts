import { ticketsApi } from "@/api/endpoints/tickets.api";
import { getApiErrorMessage } from "@/utils/apiErrors";
import { useQuery } from "@tanstack/react-query";

// Loaded fresh on every opening: while it loads, nothing from an earlier opening is shown.
export function usePenaltyOptions(ticketId: number, open: boolean) {
  const query = useQuery({
    queryKey: ["ticket", "penalty-options", ticketId],
    queryFn: () => ticketsApi.getPenaltyOptions(ticketId),
    enabled: open && Number.isSafeInteger(ticketId) && ticketId > 0,
    staleTime: 0,
    gcTime: 0,
    retry: false,
  });
  const settled = open && !query.isFetching;

  return {
    options: settled && !query.isError ? query.data : undefined,
    isLoading: open && query.isFetching,
    error:
      settled && query.isError
        ? getApiErrorMessage(query.error, "Unable to load penalty options.")
        : null,
    retry: () => void query.refetch(),
  };
}
