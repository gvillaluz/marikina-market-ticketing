import useDebounce from "@/hooks/useDebounce";
import { useState } from "react";
import { ViolationTypeFilter } from "../inspections.types";
import { MARKET_SECTION_IDS, MarketSectionFilter } from "@/api/types/common.types";

export function useInspectionFilters() {
    const [search, setSearch] = useState('');
    const [type, setType] = useState<ViolationTypeFilter>('All Type');
    const [marketSection, setMarketSection] = useState<MarketSectionFilter>('All Sections');

    const debouncedSearch = useDebounce(search, 400);

    const queryParams = {
        type: type === 'All Type' ? undefined : type,
        search: debouncedSearch,
        marketSectionId: marketSection == 'All Sections' ? undefined : MARKET_SECTION_IDS[marketSection]
    }

    return {
        queryParams,
        filters: {
            type,
            search,
            marketSection
        },
        setFilters: {
            setType,
            setSearch,
            setMarketSection
        }
    }
}