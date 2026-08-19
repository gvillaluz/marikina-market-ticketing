import { useQuery } from '@tanstack/react-query';
import { getWarningById, getTicketById } from '../../../api/endpoints/tickets.api';
import type { WarningRecord, TicketRecord } from '../../../api/types/ticket.types';

type DetailType = 'warning' | 'ticket';

export function useInspectionDetail(recordId: string | null, type: DetailType) {
  const { data, isLoading, isError } = useQuery<WarningRecord | TicketRecord>({
    queryKey: ['inspection-detail', type, recordId],
    queryFn: () =>
      type === 'warning'
        ? getWarningById(recordId as string)
        : getTicketById(recordId as string),
    enabled: Boolean(recordId), 
  });

  return { data, isLoading, isError };
}