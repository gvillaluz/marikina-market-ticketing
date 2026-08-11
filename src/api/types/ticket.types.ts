import type { Status } from './common.types';

export type TicketType = 'violation' | 'complaint' | 'inspection' | 'renewal';

export type TicketSeverity = 'low' | 'medium' | 'high' | 'critical';

export interface Ticket {
  id: string;
  ticketNumber: string;
  type: TicketType;
  title: string;
  description: string;
  status: Status;
  severity: TicketSeverity;
  vendorId?: string;
  vendorName?: string;
  createdBy: string;
  createdAt: string;
  updatedAt: string;
  dueDate?: string;
  assignedTo?: string;
  amount?: number;
  location?: string;
}

export interface CreateTicketInput {
  type: TicketType;
  title: string;
  description: string;
  severity: TicketSeverity;
  vendorId?: string;
  location?: string;
  dueDate?: string;
}

export interface TicketHistoryEntry {
  id: string;
  ticketId: string;
  action: string;
  note?: string;
  performedBy: string;
  timestamp: string;
}
