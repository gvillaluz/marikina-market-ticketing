import { useQuery, keepPreviousData } from '@tanstack/react-query';
import { getInspections } from '../../../api/endpoints/tickets.api';
import type { InspectionRecord } from '../../../api/types/ticket.types';
import { MARKET_SECTION_LABELS } from '../../../api/types/common.types';
import type { MarketSection } from '../../../api/types/common.types';

const MARKET_SECTION_IDS: Record<MarketSection, number> = {
  fishAndSeafood: 1,
  meat: 2,
  dryGoods: 3,
  vegetable: 4,
  groceries: 5,
  eatery: 6,
  specialStalls: 7,
  miscellaneous: 8,
};

interface Filters {
  search: string;
  type: 'all' | InspectionRecord['type'];
  section: 'all' | MarketSection;
}

export function useInspections(filters: Filters, page: number, pageSize: number) {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['inspections', filters, page, pageSize],
    queryFn: () => {
      const params = {
        search: filters.search || undefined,
        type: filters.type,
        page,
        pageSize,
        offset: (page - 1) * pageSize,
        ...(filters.section !== 'all'
          ? {
              market_section_id: MARKET_SECTION_IDS[filters.section],
            }
          : {}),
      };
      console.log('Inspection filters:', params);
      return getInspections(params);
    },
    placeholderData: keepPreviousData, 
  });

  const rows = data?.items ?? [];
  const selectedSection = filters.section === 'all' ? null : filters.section as MarketSection;
  const filteredRows = filters.section === 'all'
    ? rows
    : rows.filter((row) => {
        const sectionId = MARKET_SECTION_IDS[selectedSection as MarketSection];
        const backendRow = row as InspectionRecord & {
          market_section_id?: number;
          market_section_name?: string;
        };
        return backendRow.market_section_id === sectionId
          || backendRow.market_section_name === MARKET_SECTION_LABELS[selectedSection as MarketSection]
          || row.section === selectedSection;
      });

  return {
    data: filteredRows,
    total: filters.section === 'all' ? data?.total ?? rows.length : filteredRows.length,
    isLoading,
    isError,
  };
}