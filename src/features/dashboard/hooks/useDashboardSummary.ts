import { useEffect, useState } from 'react';
import { getDashboardSummary, type DashboardSummary } from '@/api/endpoints/dashboard.api';

interface UseDashboardSummaryResult {
  data: DashboardSummary | null;
  isLoading: boolean;
  isError: boolean;
}

export function useDashboardSummary(): UseDashboardSummaryResult {
  const [data, setData] = useState<DashboardSummary | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isError, setIsError] = useState(false);

  useEffect(() => {
    let cancelled = false;

    async function fetchSummary() {
      setIsLoading(true);
      setIsError(false);
      try {
        const result = await getDashboardSummary();
        if (!cancelled) {
          setData(result);
        }
      } catch (err) {
        console.log('Dashboard summary error:', err);
        if (!cancelled) {
          setIsError(true);
        }
      } finally {
        if (!cancelled) {
          setIsLoading(false);
        }
      }
    }

    fetchSummary();

    return () => {
      cancelled = true;
    };
  }, []);

  return { data, isLoading, isError };
}