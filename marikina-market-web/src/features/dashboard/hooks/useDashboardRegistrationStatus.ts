import { useRegistrationStatusCounts } from "@/features/vendors";

export function useDashboardRegistrationStatus() {
  const query = useRegistrationStatusCounts();

  return {
    counts: query.counts,
    isLoading: query.isLoading,
    error: query.error,
    retry: () => void query.refetch(),
  };
}
