import useDebounce from "@/hooks/useDebounce";
import { useState } from "react";
import { ViolationTypeFilter } from "../inspections.types";
import { ALL_STREETS } from "@/hooks/useMarketSectionOptions";

export function useInspectionFilters() {
    const [search, setSearch] = useState('');
    const [type, setType] = useState<ViolationTypeFilter>('All Type');
    const [marketSection, setMarketSection] = useState(ALL_STREETS);

    const debouncedSearch = useDebounce(search, 400);

    const queryParams = {
        type: type === 'All Type' ? undefined : type,
        search: debouncedSearch,
        marketSectionId: marketSection === ALL_STREETS ? undefined : Number(marketSection)
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