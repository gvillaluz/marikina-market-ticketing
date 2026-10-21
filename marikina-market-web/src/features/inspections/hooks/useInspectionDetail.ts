import { useQuery } from '@tanstack/react-query';
import { getTicketById, getWarningById } from '../../../api/endpoints/tickets.api';
import type { TicketRecord, WarningRecord } from '../../../api/types/ticket.types';

type DetailType = 'warning' | 'ticket';

export function useInspectionDetail(recordId: string | null, type: DetailType, enabled: boolean) {
  const query = useQuery<WarningRecord | TicketRecord>({
    queryKey: ['inspection-detail', type, recordId],
    queryFn: () =>
      type === 'warning'
        ? getWarningById(recordId!)
        : getTicketById(recordId!),
    enabled: enabled && Boolean(recordId),
  });

  return {
    data: query.data,
    isLoading: query.isLoading,
    isError: query.isError,
    error: query.error,
  };
}
