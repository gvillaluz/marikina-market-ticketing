  import { ticketsApi } from '@/api/endpoints/tickets.api';
  import type { RecordStatus} from '@/api/types/common.types';
  import { TicketSummary } from '@/api/types/ticket.types';
  import { keepPreviousData, useQuery } from '@tanstack/react-query';
  import { useEffect, useState } from 'react';

  export interface TicketFilters { 
    search?: string; 
    status?: RecordStatus; 
    marketSectionId?: number;
  }

  const PAGE_SIZE = 10;

  export function useTickets(filters: TicketFilters = {}) {
    const [page, setPage] = useState(1);

    useEffect(() => {
      setPage(1)
    }, [filters.search, filters.status, filters.marketSectionId]);

    const offset = (page - 1) * PAGE_SIZE;

    const query = useQuery({
      queryKey: ['tickets', filters, page, PAGE_SIZE],
      queryFn: () => ticketsApi.ticketList({
        ...filters,
        offset
      }),
      placeholderData: keepPreviousData
    });

    const ticketSummary: TicketSummary[] = query.data?.items ?? [];
    const total = query.data?.total ?? 0;
    const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

    return {
      ticketSummary,
      page,
      setPage,
      total: total,
      totalPages: totalPages,
      pageSize: PAGE_SIZE,
      isLoading: query.isLoading,
      isFetching: query.isFetching,
      isError: query.isError,
      error: query.error,
      refetch: query.refetch
    }
  }

  export default useTickets;