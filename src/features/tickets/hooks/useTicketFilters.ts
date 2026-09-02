import { MARKET_SECTION_IDS, MarketSection, RecordStatus } from "@/api/types/common.types";
import useDebounce from "@/hooks/useDebounce";
import { useState } from "react";

export type TicketStatusFilter = 'All' | RecordStatus;

export function useTicketFilters() {
    const [status, setStatus] = useState<TicketStatusFilter>('All')
    const [search, setSearch] = useState('')
    const [marketSection, setMarketSection] = useState<MarketSection | ''>('');

    const debouncedSearch = useDebounce(search, 400);

    const queryParams = {
        status: status === 'All' ? undefined : status,
        search: debouncedSearch,
        marketSectionId: marketSection ? MARKET_SECTION_IDS[marketSection] : undefined
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