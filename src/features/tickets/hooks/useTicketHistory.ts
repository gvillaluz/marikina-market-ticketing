import { useCallback, useEffect, useState } from 'react';
import { ticketsApi } from '@/api/endpoints/tickets.api';
import type { TicketHistoryEntry } from '@/api/types/ticket.types';

export function useTicketHistory(ticketId: string) {
  const [history, setHistory] = useState<TicketHistoryEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!ticketId) {
      setHistory([]);
      setLoading(false);
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const data = await ticketsApi.getHistory(ticketId); 
      setHistory(data ?? []); // fallback to empty array if API returns null/undefined
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load ticket history');
      setHistory([]);
    } finally {
      setLoading(false);
    }
  }, [ticketId]);

  useEffect(() => {
    load();
  }, [load]);

  return { history, loading, error, refresh: load };
}

export default useTicketHistory;