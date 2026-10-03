import styles from './InspectionTable.module.css';
import { Eye, Gavel, Ticket, TriangleAlert, RefreshCw } from 'lucide-react';
import { Table } from '../../../components/ui/Table';
import { formatDateTime } from '../../../utils/formatters';
import type { InspectionSummary } from '../../../api/types/ticket.types';
import Button from '@/components/ui/Button';

interface InspectionTableProps {
  rows: InspectionSummary[];
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  onRetry: () => void;
  onView: (ticketId: number) => void;
}

export function InspectionTable({ rows, isLoading, isError, errorMessage, onRetry, onView }: InspectionTableProps) {
  if (isError) {
    return (
      <div className={styles.errorState}>
        <span>{errorMessage}</span>
        <Button size="sm" variant="outline" icon={<RefreshCw size={14} />} onClick={onRetry}>
          Try again
        </Button>
      </div>
    );
  }

  return (
    <Table
      data={rows}
      keyExtractor={(row) => row.ticketId.toString()}
      loading={isLoading}
      emptyMessage="No inspection records match your filters."
      columns={[
        {
          key: 'enforcer',
          header: 'Enforcer',
          render: (ticket) => 
            `${ticket.enforcerFirstName ?? ''} ${ticket.enforcerLastName ?? ''}`.trim() || '—'
        },
        {
          key: 'vendor',
          header: 'Vendor',
          render: (ticket) => 
            `${ticket.vendorFirstName ?? ''} ${ticket.vendorLastName ?? ''}`.trim() || '—'
        },
        {
          key: 'tradeName',
          header: 'Trade Name',
          render: (ticket) => ticket.businessName || '—'
        },
        { 
          key: 'section', 
          header: 'Market Section', 
          render: (ticket) => ticket.marketSectionName || '—' 
        },
        {
          key: 'type',
          header: 'Type',
          render: (ticket) => {
            const type = ticket.type.toLowerCase();
            const isTicket = type == 'ticket';

            return <div className={`${styles.type} ${styles[type]}`}>
              {isTicket
                ? <Gavel size={15} />
                : <TriangleAlert size={15} />}
              <span className={styles.span}>{ticket.type}</span>
            </div>
          },
        },
        {
          key: 'issuedAt',
          header: 'Issued At',
          render: (ticket) => formatDateTime(ticket.issuedAt)
        },
        {
          key: 'actions',
          header: 'Actions',
          render: (ticket) => (
            <Button 
              icon={<Eye size={14} strokeWidth={3} aria-hidden="true" />}
              className={styles.actionBtn}
              size="sm" 
              variant="ghost" 
              onClick={() => onView(ticket.ticketId ?? 0)}
            >
              View
            </Button>
          ),
          align: 'center'
        }
      ]}
    />
  );
}