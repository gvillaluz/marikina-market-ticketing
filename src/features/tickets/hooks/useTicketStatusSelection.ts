import { useEffect, useState } from 'react';
import { RecordStatus } from '@/api/types/common.types';
import { TicketDetail } from '@/api/types/ticket.types';

export function useTicketStatusSelection(ticket: TicketDetail | undefined) {
  const [selectedStatus, setSelectedStatus] = useState<RecordStatus | undefined>(undefined);

  useEffect(() => {
    if (ticket) {
      setSelectedStatus(ticket.status);
    }
  }, [ticket?.status]);

  return { selectedStatus, setSelectedStatus };
}