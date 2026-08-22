import { useQuery, useQueryClient } from '@tanstack/react-query';
import { getTicketById, ticketsApi, updateTicketStatus } from '@/api/endpoints/tickets.api';

export function useTicketHistory(ticketId: string) {
  const queryClient = useQueryClient();
  const query = useQuery({ queryKey: ['ticket', ticketId], queryFn: async () => ({ ticket: await getTicketById(ticketId), history: await ticketsApi.getHistory(ticketId) }), enabled: Boolean(ticketId) });
  const updateStatus = async (status: string) => { const result = await updateTicketStatus(ticketId, status); await queryClient.invalidateQueries({ queryKey: ['tickets'] }); await queryClient.invalidateQueries({ queryKey: ['ticket', ticketId] }); return result; };
  return { ticket: query.data?.ticket, history: query.data?.history ?? [], isLoading: query.isLoading, error: query.error, updateStatus, refetch: query.refetch };
}

export default useTicketHistory;