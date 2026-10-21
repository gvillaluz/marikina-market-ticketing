import type { TicketSummary } from "@/api/types/ticket.types";

export interface TicketsSliceState {
  tickets: TicketSummary[];
  loading: boolean;
  error: string | null;
}

export const initialTicketsState: TicketsSliceState = {
  tickets: [],
  loading: false,
  error: null,
};
