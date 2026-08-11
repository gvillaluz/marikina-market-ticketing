import { useCallback, useEffect, useState } from 'react';
import mockAdapter from '@/api/mock/mockAdapter';
import type { TicketHistoryEntry } from '@/api/types/ticket.types';

/** Loads the history for a single ticket. */
export function useTicketHistory(ticketId: string) {
  const [history, setHistory] = useState<TicketHistoryEntry[]>([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    if (!ticketId) return;
    setLoading(true);
    try {
      const data = await mockAdapter.getTicketHistory(ticketId);
      setHistory(data);
    } finally {
      setLoading(false);
    }
  }, [ticketId]);

  useEffect(() => {
    load();
  }, [load]);

  return { history, loading, refresh: load };
}

export default useTicketHistory;
