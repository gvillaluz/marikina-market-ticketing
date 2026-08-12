
import type { Ticket } from '@/api/types/ticket.types';

export interface TicketsSliceState {
  tickets: Ticket[];
  loading: boolean;
  error: string | null;
}

export const initialTicketsState: TicketsSliceState = {
  tickets: [],
  loading: false,
  error: null,
};
