import { RecordStatus } from "@/api/types/common.types";
import useDebounce from "@/hooks/useDebounce";
import { ALL_STREETS } from "@/hooks/useMarketSectionOptions";
import { useState } from "react";

export type TicketStatusFilter = 'All Status' | RecordStatus;

export function useTicketFilters() {
    const [status, setStatus] = useState<TicketStatusFilter>('All Status')
    const [search, setSearch] = useState('')
    const [marketSection, setMarketSection] = useState(ALL_STREETS);

    const debouncedSearch = useDebounce(search, 400);

    const queryParams = {
        status: status === 'All Status' ? undefined : status,
        search: debouncedSearch,
        marketSectionId: marketSection === ALL_STREETS ? undefined : Number(marketSection)
    }

    return {
        queryParams,
        filters: {
            status,
            search,
            marketSection
        },
        setFilters: {
            setStatus,
            setSearch,
            setMarketSection
        }
    }
}