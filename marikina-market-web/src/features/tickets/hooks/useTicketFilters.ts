import { RecordStatus } from "@/api/types/common.types";
import useDebounce from "@/hooks/useDebounce";
import { ALL_STREETS } from "@/hooks/useMarketSectionOptions";
import { useState } from "react";
import { useSearchParams } from "react-router-dom";

export type TicketStatusFilter = 'All Status' | RecordStatus;

export function useTicketFilters() {
    // The dashboard's Go to Tickets link opens the page on Overdue; any other value is ignored.
    const [searchParams] = useSearchParams()
    const [status, setStatus] = useState<TicketStatusFilter>(
        searchParams.get('status') === 'Overdue' ? 'Overdue' : 'All Status'
    )
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