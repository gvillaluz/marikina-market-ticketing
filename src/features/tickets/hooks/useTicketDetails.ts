import { ticketsApi } from "@/api/endpoints/tickets.api";
import { useQuery } from "@tanstack/react-query";

export function useTicketDetails(ticketId: number, enabled = true) {
    const query = useQuery({
        queryKey: ['ticket', 'detail', ticketId],
        queryFn: () => ticketsApi.getTicketDetailById(ticketId),
        enabled: enabled && Number.isInteger(ticketId) && ticketId > 0,
    });

    return {
        ticket: query.data,
        isLoading: query.isLoading,
        isError: query.isError,
        error: query.error,
        refetch: query.refetch
    }
}