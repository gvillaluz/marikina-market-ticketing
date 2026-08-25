import { FC, useState } from 'react';
import PageHeader from '@/components/ui/PageHeader';
import Card from '@/components/ui/Card';
import TicketList from '@/features/tickets/components/TicketList';
import useTickets from '@/features/tickets/hooks/useTickets';
import useDebounce from '@/hooks/useDebounce';
import { formatCurrency, formatNumber } from '@/utils/formatters';
import { MARKET_SECTION_LABELS, RecordStatus } from '@/api/types/common.types';
import styles from './TicketsPage.module.css';
import useTicketAnalytics from '../hooks/useTicketAnalytics';
import StatCard from '@/features/dashboard/components/StatCard';
import TicketAnalyticsCard from '../components/TicketAnalyticsCard';

type TicketStatusFilter = 'All' | RecordStatus;

const FILTERS: TicketStatusFilter[] = [
  'All', 
  'Pending', 
  'Contested', 
  'Paid', 
  'Overdue',
  'Waived'
] as const;

const TicketsPage: FC = () => {
  const [status, setStatus] = useState<TicketStatusFilter>('All');
  const [search, setSearch] = useState('');
  const [marketSection, setMarketSection] = useState('');

  const debouncedSearch = useDebounce(search, 400);

  const { ticketSummary, page, setPage, total, totalPages, isLoading } = useTickets({
    status: status === 'All' ? undefined : status,
    search: debouncedSearch,
    marketSection: marketSection || undefined,
  });

  const { stats } = useTicketAnalytics();

  return (
    <div>
      <PageHeader
        title="Tickets"
        subtitle="Manage violations, complaints, inspections, and renewals."
      />

      <div className={styles.stats}>
        <TicketAnalyticsCard label="Total Tickets" value={stats ? formatNumber(stats.totalTicketsThisMonth) : '—'} change={stats?.ticketChangePercentage} />
        <TicketAnalyticsCard label="Pending Payments" value={stats ? formatCurrency(stats.pendingPaymentsThisMonth) : '—'} change={stats?.paymentsChangePercentage} />
        <TicketAnalyticsCard label="Resolved Violations" value={stats ? formatNumber(stats.resolvedViolationsThisMonth) : '—'} progress={stats?.resolutionRate} />
        <TicketAnalyticsCard label="Critical Severities" value={stats ? formatNumber(stats.highSeveritiesThisMonth) : '—'} change={stats?.highSeveritiesChangePercentage} />
      </div>
      <div className={styles.toolbar}>
        <div className={styles.filters}>
          <select className={styles.filterBtn} value={status} onChange={(event) => setStatus(event.target.value as TicketStatusFilter)}>
            <option value="All">All</option>
            {FILTERS.map((filter) => <option key={filter} value={filter}>{filter}</option>)}
          </select>
          <select className={styles.filterBtn} value={marketSection} onChange={(event) => setMarketSection(event.target.value)} aria-label="Market Section">
            <option value="">Market Section</option>
            {Object.entries(MARKET_SECTION_LABELS).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
          </select>
        </div>
        <input
          className={styles.search}
          placeholder="Search tickets…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      <TicketList tickets={ticketSummary} loading={isLoading} />

      <div className={styles.entryInfo}>Showing {total === 0 ? 0 : (page - 1) * 9 + 1} to {Math.min(page * 9, total)} of {total} entries</div>

      {totalPages > 1 && (
        <div className={styles.paginationRow}>
          <button
            className={styles.pageBtn}
            disabled={page <= 1}
            onClick={() => setPage(page - 1)}
          >
            ‹ Prev
          </button>
          <span className={styles.pageInfo}>Page {page} of {totalPages}</span>
          <button
            className={styles.pageBtn}
            disabled={page >= totalPages}
            onClick={() => setPage(page + 1)}
          >
            Next ›
          </button>
        </div>
      )}

    </div>
  );
};

export default TicketsPage;
