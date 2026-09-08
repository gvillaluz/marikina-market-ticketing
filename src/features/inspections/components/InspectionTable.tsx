import styles from './InspectionTable.module.css';
import { AlertTriangle, CheckCircle2, Eye, Gavel, Ticket, TriangleAlert } from 'lucide-react';
import { Table } from '../../../components/ui/Table';
import type { Column } from '../../../components/ui/Table';
import { Badge } from '../../../components/ui/Badge';
import type { BadgeTone } from '../../../components/ui/Badge';
import { formatDateTime } from '../../../utils/formatters';
import { MARKET_SECTION_LABELS } from '../../../api/types/common.types';
import type { InspectionRecord, InspectionSummary } from '../../../api/types/ticket.types';
import Button from '@/components/ui/Button';

interface InspectionTableProps {
  rows: InspectionSummary[];
  isLoading: boolean;
  isError: boolean;
  onView: (ticketId: number) => void;
}

function getTypeBadge(row: InspectionSummary): { label: string; tone: BadgeTone; icon: JSX.Element } {
  if (row.status === 'Cleared') {
    return { label: 'Cleared', tone: 'success', icon: <CheckCircle2 size={12} strokeWidth={2} /> };
  }
  return row.type.toLowerCase() === 'Warning'
    ? { label: 'WARNING', tone: 'warning', icon: <AlertTriangle size={12} strokeWidth={2} /> }
    : { label: 'TICKET', tone: 'ticket', icon: <Ticket size={12} strokeWidth={2} /> };
}

export function InspectionTable({ rows, isLoading, isError, onView }: InspectionTableProps) {
  const displayValue = (value: unknown, fallback = '—') => {
    const text = String(value ?? '').trim();
    return text || fallback;
  };

  if (isError) {
    return (
      <div className={styles.errorState}>
        Couldn't load inspection records. Please try again.
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