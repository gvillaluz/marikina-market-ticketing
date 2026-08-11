import { useCallback, useEffect, useState } from 'react';
import mockAdapter from '@/api/mock/mockAdapter';
import type { Penalty, PenaltySummary } from '@/api/endpoints/penalties.api';

/** Loads a paginated list of penalties plus summary stats. */
export function usePenalties(status?: string) {
  const [penalties, setPenalties] = useState<Penalty[]>([]);
  const [summary, setSummary] = useState<PenaltySummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [list, sum] = await Promise.all([
        mockAdapter.listPenalties({ page: 1, pageSize: 50, status }),
        mockAdapter.getPenaltySummary(),
      ]);
      setPenalties(list.items);
      setSummary(sum);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load penalties.');
    } finally {
      setLoading(false);
    }
  }, [status]);

  useEffect(() => {
    load();
  }, [load]);

  return { penalties, summary, loading, error, refresh: load };
}

export default usePenalties;
