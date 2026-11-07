import { ticketsApi } from "@/api/endpoints/tickets.api";
import { useQuery } from "@tanstack/react-query";

export function useTicketHistory(ticketId: number) {
  const query = useQuery({
    queryKey: ["ticket", "history", ticketId],
    queryFn: () => ticketsApi.getHistory(ticketId),
    enabled: Number.isSafeInteger(ticketId) && ticketId > 0,
  });

  return {
    entries: query.data ?? [],
    isPending: query.isPending,
    isError: query.isError,
    isFetching: query.isFetching,
    error: query.error,
    refetch: query.refetch,
  };
}
