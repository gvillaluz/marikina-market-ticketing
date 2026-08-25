import { ticketsApi } from "@/api/endpoints/tickets.api";
import { TicketStats } from "@/api/types/ticket.types";
import { useQuery } from "@tanstack/react-query";

export function useTicketAnalytics() {
    const query = useQuery({
        queryKey: ['tickets', 'analytics'],
        queryFn: () => ticketsApi.getTicketAnalytics(),
        staleTime: 60_000
    });

    return {
        stats: query.data,
        isLoading: query.isLoading,
        isError: query.isError,
        error: query.error,
        refetch: query.refetch
    }
}

export default useTicketAnalytics;