import { FC } from 'react';
import { useNavigate } from 'react-router-dom';
import Table from '@/components/ui/Table';
import StatusBadge from '@/components/ui/StatusBadge';
import Button from '@/components/ui/Button';
import type { TicketSummary } from '@/api/types/ticket.types';
import { formatCurrency, formatDateTime } from '@/utils/formatters';
import styles from './TicketList.module.css';
import { Eye, Recycle, RefreshCw, Repeat, Ticket } from 'lucide-react';

interface TicketListProps {
  tickets: TicketSummary[];
  loading?: boolean;
  onView: (ticketId: number) => void;
}

const TicketList: FC<TicketListProps> = ({ tickets, loading, onView }) => {
  const navigate = useNavigate();

  return (
    <Table
      loading={loading}
      data={tickets}
      keyExtractor={(ticket) => ticket.id.toString()}
      emptyMessage="No tickets found."
      columns={[
        { 
          key: 'ticketId', 
          header: 'ID', 
          render: (ticket) => ticket.id ?? '—' 
        },
        { 
          key: 'controlNumber', 
          header: 'Control No.', 
          render: (ticket) => '#' + ticket.controlNumber || '—' 
        },
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
          key: 'section', 
          header: 'Market Section', 
          render: (ticket) => ticket.marketSectionName || '—' 
        },
        {
          key: 'status',
          header: 'Status',
          render: (ticket) => {
            const status = (ticket.status || '').toLowerCase();
            return (
              <div className={`${styles.status} ${styles[status] || ''}`}>
                <Ticket size={20} className={`${styles.statusIcon} ${styles[status]}`} />
                <span className={styles.span}>{ticket.status || '—'}</span>
              </div>
            );
          },
          align: 'center'
        },
        { 
          key: 'penaltyType', 
          header: 'Penalty Type', 
          render: (ticket) => ticket.penaltyType || '—' ,
          align: 'center'
        },
        {
          key: 'amount',
          header: 'Total Payment',
          align: 'left',
          render: (ticket) => formatCurrency(ticket.totalPaymentAmount ?? 0)
        },
        {
          key: 'severity',
          header: 'Severity',
          render: (ticket) => {
            const severity = (ticket.severity || '').toLowerCase();
            return (
              <div className={`${styles.severity} ${styles[severity] || ''}`}>
                <span className={styles.span}>{ticket.severity || '—'}</span>
              </div>
            );
          },
          align: 'center'
        },
        {
          key: 'issuedAt',
          header: 'Issued At',
          render: (ticket) => formatDateTime(ticket.issuedAt)
        },
        {
          key: 'actions',
          header: 'Action',
          render: (ticket) => (
            <div className={styles.actions}>
              <Button 
                icon={<Eye size={14} strokeWidth={3} aria-hidden="true" />}
                className={`${styles.actionBtn} ${styles.view}`}
                size="sm" 
                variant="ghost" 
                onClick={() => onView(ticket.id)}
              >
                View
              </Button>
              <Button 
                icon={<RefreshCw size={14} strokeWidth={3} aria-hidden="true" />}
                className={`${styles.actionBtn} ${styles.change}`}
                size="sm" 
                variant="outline" 
                onClick={() => navigate(`/tickets/${ticket.id}#status`)}
              >
                Change
              </Button>
            </div>
          ),
          align: 'center'
        },
      ]}
    />
  );
};

export default TicketList;