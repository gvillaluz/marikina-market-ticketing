import { useQuery, keepPreviousData } from '@tanstack/react-query';
import { useState } from 'react';
import { getTickets } from '@/api/endpoints/tickets.api';
import type { TicketRecord } from '@/api/types/ticket.types';
import type { PaginationSummary } from '@/api/types/common.types';

export interface TicketFilters { search?: string; status?: string; marketSection?: string; pageSize?: number }

/** Loads and manages a paginated list of tickets. */
export function useTickets(filters: TicketFilters = {}) {
  const [page, setPage] = useState(1);
  const pageSize = filters.pageSize ?? 10;
  const query = useQuery({ queryKey: ['tickets', filters, page, pageSize], queryFn: () => getTickets({ ...filters, type: 'ticket', page, pageSize, offset: (page - 1) * pageSize }), enabled: false, placeholderData: keepPreviousData });
  const summary: PaginationSummary | undefined = query.data?.summary;
  const tickets = (query.data?.items ?? []).filter((ticket) => {
    const backendTicket = ticket as TicketRecord & { type?: unknown; ticket_type?: unknown };
    const type = String(backendTicket.type ?? backendTicket.ticket_type ?? '').trim().toLowerCase();
    return type === 'ticket';
  }) as TicketRecord[];
  return { tickets, summary, isLoading: query.isLoading, loading: query.isLoading, error: query.error, page, setPage, filters, total: tickets.length, totalPages: Math.max(1, Math.ceil(tickets.length / pageSize)), refetch: query.refetch, refresh: query.refetch };
}

export default useTickets;
