import { useCallback, useEffect, useState } from 'react';
import mockAdapter from '@/api/mock/mockAdapter';
import type { Ticket } from '@/api/types/ticket.types';
import type { Status } from '@/api/types/common.types';

interface UseTicketsOptions {
  status?: Status;
  type?: string;
  search?: string;
  pageSize?: number;
}

/** Loads and manages a paginated list of tickets. */
export function useTickets(options: UseTicketsOptions = {}) {
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);

  const fetchTickets = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await mockAdapter.listTickets({
        page,
        pageSize: options.pageSize ?? 10,
        status: options.status,
        type: options.type,
        search: options.search,
      });
      setTickets(res.items);
      setTotal(res.total);
      setTotalPages(res.totalPages);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load tickets.');
    } finally {
      setLoading(false);
    }
  }, [page, options.status, options.type, options.search, options.pageSize]);

  useEffect(() => {
    fetchTickets();
  }, [fetchTickets]);

  const refresh = useCallback(() => fetchTickets(), [fetchTickets]);

  return { tickets, loading, error, page, total, totalPages, setPage, refresh };
}

export default useTickets;
