import styles from './InspectionTable.module.css';
import { AlertTriangle, CheckCircle2, Eye, Ticket } from 'lucide-react';
import { Table } from '../../../components/ui/Table';
import type { Column } from '../../../components/ui/Table';
import { Badge } from '../../../components/ui/Badge';
import type { BadgeTone } from '../../../components/ui/Badge';
import { formatDateTime } from '../../../utils/formatters';
import { MARKET_SECTION_LABELS } from '../../../api/types/common.types';
import type { InspectionRecord } from '../../../api/types/ticket.types';

interface InspectionTableProps {
  rows: InspectionRecord[];
  isLoading: boolean;
  isError: boolean;
  onView: (record: InspectionRecord) => void;
}

function getTypeBadge(row: InspectionRecord): { label: string; tone: BadgeTone; icon: JSX.Element } {
  if (row.status === 'Cleared') {
    return { label: 'Cleared', tone: 'success', icon: <CheckCircle2 size={12} strokeWidth={2} /> };
  }
  return row.type.toLowerCase() === 'warning'
    ? { label: 'WARNING', tone: 'warning', icon: <AlertTriangle size={12} strokeWidth={2} /> }
    : { label: 'TICKET', tone: 'ticket', icon: <Ticket size={12} strokeWidth={2} /> };
}

export function InspectionTable({ rows, isLoading, isError, onView }: InspectionTableProps) {
  const displayValue = (value: unknown, fallback = '—') => {
    const text = String(value ?? '').trim();
    return text || fallback;
  };

  const getEnforcerName = (row: InspectionRecord) => displayValue(
    row.enforcer,
    `${row.enforcer_first_name ?? ''} ${row.enforcer_last_name ?? ''}`.trim() || '—',
  );

  const columns: Column<InspectionRecord>[] = [
    { key: 'enforcer', header: 'Enforcer', render: getEnforcerName },
    { key: 'stallNo', header: 'Stall No.', render: (row) => displayValue(row.stallNo, row.stall_number) },
    { key: 'tradeName', header: 'Trade Name', render: (row) => displayValue(row.tradeName, row.business_name) },
    { key: 'section', header: 'Section', render: (row) => displayValue(row.market_section_name, MARKET_SECTION_LABELS[row.section]) },
    {
      key: 'type',
      header: 'Type',
      render: (row) => {
        const { label, tone, icon } = getTypeBadge(row);
        return <Badge tone={tone}>{icon}{label}</Badge>;
      },
    },
    { key: 'issuedAt', header: 'Issued At', render: (row) => formatDateTime(row.issuedAt ?? row.issued_at ?? row.dateTime) },
    {
      key: 'actions',
      header: 'Actions',
      render: (row) => (
        <button className={styles.viewButton} onClick={(event) => { event.stopPropagation(); console.log('Viewing inspection record:', row); onView(row); }}>
          <Eye size={14} strokeWidth={1.8} aria-hidden="true" />
          View
        </button>
      ),
    },
  ];

  if (isError) {
    return (
      <div className={styles.errorState}>
        Couldn't load inspection records. Please try again.
      </div>
    );
  }

  return (
    <Table
      columns={columns}
      data={rows}
      keyExtractor={(row) => row.id}
      loading={isLoading}
      emptyMessage="No inspection records match your filters."
    />
  );
}