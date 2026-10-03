import { useEffect, useState } from 'react';
import { getDashboardSummary, type DashboardSummary } from '@/api/endpoints/dashboard.api';
import { getApiErrorMessage } from '@/utils/apiErrors';

interface UseDashboardSummaryResult {
  data: DashboardSummary | null;
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
}

export function useDashboardSummary(): UseDashboardSummaryResult {
  const [data, setData] = useState<DashboardSummary | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isError, setIsError] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");

  useEffect(() => {
    let cancelled = false;

    async function fetchSummary() {
      setIsLoading(true);
      setIsError(false);
      setErrorMessage("");
      try {
        const result = await getDashboardSummary();
        if (!cancelled) {
          setData(result);
        }
      } catch (err) {
        console.log('Dashboard summary error:', err);
        if (!cancelled) {
          setIsError(true);
          setErrorMessage(getApiErrorMessage(err, "Unable to load dashboard summary."));
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

  return { data, isLoading, isError, errorMessage };
}