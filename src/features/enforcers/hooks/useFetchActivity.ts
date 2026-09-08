import { enforcersApi } from "@/api/endpoints/enforcers.api";
import { useQuery } from "@tanstack/react-query";

export function useFetchActivity() {
    const query = useQuery({
        queryKey: ['enforcers', 'activity-panel'],
        queryFn: () => enforcersApi.enforcersActivity()
    });

    return {
        averageWarning: query.data?.averageWarningPerDay,
        averageTicket: query.data?.averageTicketPerDay,
        topEnforcers: query.data?.topEnforcers,
        activityProcess: {
            isFetching: query.isFetching,
            isLoading: query.isLoading,
            isError: query.isError,
            error: query.error,
            onRetry: query.refetch
        }
    }
}