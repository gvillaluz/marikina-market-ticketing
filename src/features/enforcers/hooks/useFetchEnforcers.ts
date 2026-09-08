import { enforcersApi } from "@/api/endpoints/enforcers.api";
import { AccountStatus } from "@/api/types/common.types";
import { EnforcerSummary } from "@/api/types/enforcer.types";
import { useQuery } from "@tanstack/react-query";
import { useEffect, useState } from "react";

interface FetchEnforcersParams {
    search?: string;
    status?: AccountStatus;
    sortBy?: string;
    sortDirection?: 'asc' | 'desc';
}

const PAGE_SIZE = 6;

export function useFetchEnforcers(params: FetchEnforcersParams) { 
    const [page, setPage] = useState(1);

    useEffect(() => {
        setPage(1);
    }, [params.search, params.status, params.sortBy, params.sortDirection]);

    const offset = (page - 1) * PAGE_SIZE;

    const query = useQuery({
        queryKey: ['enforcers', params.search, params.status, params.sortBy, params.sortDirection],
        queryFn: () => enforcersApi.enforcerList({
            offset,
            search: params.search,
            status: params.status,
            sortBy: params.sortBy,
            sortDirection: params.sortDirection
        })
    })

    const enforcers: EnforcerSummary[] = query.data?.items ?? [];
    const total: number = query.data?.total ?? 0;
    const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

    return {
        enforcers,
        total,
        totalPages,
        page,
        setPage,
        fetchProcess: {
            isLoading: query.isLoading,
            isFetching: query.isFetching,
            isError: query.isError,
            error: query.error,
            onRetry: query.refetch
        }
    }
}