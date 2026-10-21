import { AccountStatus } from "@/api/types/common.types";
import useDebounce from "@/hooks/useDebounce";
import { useState } from "react";

const SORT_OPTIONS: Record<string, { sortBy: string; sortDirection: 'asc' | 'desc' }> = {
  'Name (A-Z)': { sortBy: 'name', sortDirection: 'asc' },
  'Name (Z-A)': { sortBy: 'name', sortDirection: 'desc' },
  'Most Tickets': { sortBy: 'tickets', sortDirection: 'desc' },
  'Most Warnings': { sortBy: 'warnings', sortDirection: 'desc' },
};

export function useEnforcerFilter() {
    const [search, setSearch] = useState('');
    const [statusFilter, setStatusFilter] = useState<AccountStatus>('Active');
    const [sort, setSort] = useState<string>('Name (A-Z)');

    const debouncedSearch = useDebounce(search, 400);
    const { sortBy, sortDirection } = SORT_OPTIONS[sort];

    const queryParams = {
        search: debouncedSearch,
        status: statusFilter,
        sortBy: sortBy,
        sortDirection: sortDirection
    }

    return {
        filters: {
            search,
            statusFilter,
            sort
        },
        setFilters: {
            setSearch,
            setStatusFilter,
            setSort
        },
        sortOptions: SORT_OPTIONS,
        queryParams
    }
}