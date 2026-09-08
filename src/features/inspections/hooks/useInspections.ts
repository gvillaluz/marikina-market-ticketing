import { useQuery, keepPreviousData } from '@tanstack/react-query';
import { getInspections, ticketsApi } from '../../../api/endpoints/tickets.api';
import type { InspectionRecord, InspectionSummary } from '../../../api/types/ticket.types';
import { MARKET_SECTION_LABELS } from '../../../api/types/common.types';
import type { MarketSection } from '../../../api/types/common.types';
import { ViolationTypeFilter } from '../inspections.types';
import { useEffect, useState } from 'react';

interface Filters {
  search?: string;
  type?: 'Warning' | 'Ticket';
  marketSectionId?: number;
}

const PAGE_SIZE = 10;

export function useInspections(filters: Filters = {}) {
  const [page, setPage] = useState(1);

  useEffect(() => {
    setPage(1);
  }, [filters.search, filters.type, filters.marketSectionId]);

  const query = useQuery({
    queryKey: ['inspections', filters, page, PAGE_SIZE],
    queryFn: () => ticketsApi.inspectionList(filters),
    placeholderData: keepPreviousData, 
  });

  const inspections: InspectionSummary[] = query.data?.items ?? [];
  const total = query.data?.total ?? 0;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return {
    inspections,
    total,
    totalPages,
    page,
    setPage,
    isLoading: query.isLoading,
    isFetching: query.isFetching,
    isError: query.isError,
    error: query.error
  };
}