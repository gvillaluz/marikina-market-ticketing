import { FC } from 'react';
import { useNavigate } from 'react-router-dom';
import Table from '@/components/ui/Table';
import StatusBadge from '@/components/ui/StatusBadge';
import Button from '@/components/ui/Button';
import type { TicketRecord } from '@/api/types/ticket.types';
import { formatCurrency, formatDateTime } from '@/utils/formatters';
import { MARKET_SECTION_LABELS } from '@/api/types/common.types';
import styles from './TicketList.module.css';

interface TicketListProps {
  tickets: TicketRecord[];
  loading?: boolean;
}

const TicketList: FC<TicketListProps> = ({ tickets, loading }) => {
  const navigate = useNavigate();
  const value = (primary: unknown, fallback?: unknown) => String(primary ?? fallback ?? '—');
  const backendValue = (ticket: TicketRecord) => ticket as TicketRecord & Record<string, unknown>;
  return <Table loading={loading} data={tickets} keyExtractor={(ticket) => ticket.id} emptyMessage="No tickets found."
    columns={[
      { key: 'id', header: 'ID', render: (ticket) => value(ticket.id, backendValue(ticket).ticket_id) },
      { key: 'controlNumber', header: 'Control No.', render: (ticket) => value(ticket.controlNumber, backendValue(ticket).control_number ?? backendValue(ticket).ticket_id) },
      { key: 'enforcer', header: 'Enforcer', render: (ticket) => value(ticket.enforcerName ?? ticket.enforcer, `${backendValue(ticket).enforcer_first_name ?? ''} ${backendValue(ticket).enforcer_last_name ?? ''}`.trim()) },
      { key: 'vendor', header: 'Vendor', render: (ticket) => value(ticket.tradeName, backendValue(ticket).business_name) },
      { key: 'section', header: 'Market Section', render: (ticket) => value((ticket.marketSection && MARKET_SECTION_LABELS[ticket.marketSection as keyof typeof MARKET_SECTION_LABELS]) ?? ticket.marketSection, backendValue(ticket).market_section_name) },
      { key: 'status', header: 'Status', render: (ticket) => <StatusBadge status={value(ticket.status, backendValue(ticket).status)} /> },
      { key: 'severity', header: 'Severity', render: (ticket) => { const severity = value(ticket.penalty?.severity, backendValue(ticket).severity).toLowerCase(); return <span className={`${styles.severity} ${styles[severity]}`}>{severity}</span>; } },
      { key: 'penaltyType', header: 'Penalty Type', render: (ticket) => value(ticket.penalty?.penaltyType, backendValue(ticket).penalty_type) },
      { key: 'amount', header: 'Total Payment', align: 'right', render: (ticket) => formatCurrency(ticket.penalty?.totalFineDue ?? Number(backendValue(ticket).fine_amount ?? 0)) },
      { key: 'issuedAt', header: 'Issued At', render: (ticket) => formatDateTime(ticket.dateTime ?? String(backendValue(ticket).issued_at ?? '')) },
      { key: 'actions', header: 'Action', render: (ticket) => <div className={styles.actions}><Button size="sm" variant="ghost" onClick={() => navigate(`/tickets/${ticket.id}`)}>View</Button><Button size="sm" variant="outline" onClick={() => navigate(`/tickets/${ticket.id}#status`)}>Change</Button></div> },
    ]} />;
};

export default TicketList;
