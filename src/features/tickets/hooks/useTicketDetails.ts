import { ticketsApi } from "@/api/endpoints/tickets.api";
import { useQuery } from "@tanstack/react-query";

export function useTicketDetails(ticketId: number) {
    const query = useQuery({
        queryKey: ['ticket', 'detail', ticketId],
        queryFn: () => ticketsApi.getTicketDetailById(ticketId)
    });

    return {
        ticket: query.data,
        isLoading: query.isLoading,
        isError: query.isError,
        error: query.error,
        refetch: query.refetch
    }
}