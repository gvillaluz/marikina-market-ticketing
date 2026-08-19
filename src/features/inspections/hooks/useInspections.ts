import { useQuery, keepPreviousData } from '@tanstack/react-query';
import { getInspections } from '../../../api/endpoints/tickets.api';
import type { InspectionRecord } from '../../../api/types/ticket.types';
import type { MarketSection } from '../../../api/types/common.types';

interface Filters {
  search: string;
  type: 'all' | InspectionRecord['type'];
  section: 'all' | MarketSection;
}

export function useInspections(filters: Filters, page: number, pageSize: number) {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['inspections', filters, page, pageSize],
    queryFn: () =>
      getInspections({
        search: filters.search || undefined,
        type: filters.type,
        section: filters.section === 'all' ? undefined : filters.section,
        page,
        pageSize,
      }),
    placeholderData: keepPreviousData, 
  });

  return {
    data: data?.items ?? [],
    total: data?.total ?? 0,
    isLoading,
    isError,
  };
}