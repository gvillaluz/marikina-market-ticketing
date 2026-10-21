import { MARKET_SECTION_IDS, MarketSection, MarketSectionFilter, RecordStatus } from "@/api/types/common.types";
import useDebounce from "@/hooks/useDebounce";
import { useState } from "react";

export type TicketStatusFilter = 'All Status' | RecordStatus;

export function useTicketFilters() {
    const [status, setStatus] = useState<TicketStatusFilter>('All Status')
    const [search, setSearch] = useState('')
    const [marketSection, setMarketSection] = useState<MarketSectionFilter>('All Sections');

    const debouncedSearch = useDebounce(search, 400);

    const queryParams = {
        status: status === 'All Status' ? undefined : status,
        search: debouncedSearch,
        marketSectionId: marketSection == 'All Sections' ? undefined : MARKET_SECTION_IDS[marketSection]
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