import { FC, useState } from 'react';
import PageHeader from '@/components/ui/PageHeader';
import TicketList from '@/features/tickets/components/TicketList';
import useTickets from '@/features/tickets/hooks/useTickets';
import useDebounce from '@/hooks/useDebounce';
import { formatCurrency, formatNumber } from '@/utils/formatters';
import { MARKET_SECTION_LABELS, MarketSection, RecordStatus } from '@/api/types/common.types';
import styles from './TicketsPage.module.css';
import useTicketAnalytics from '../hooks/useTicketAnalytics';
import TicketAnalyticsCard from '../components/TicketAnalyticsCard';
import { TicketModal } from '../components/TicketModal';
import { Dropdown } from '@/components/ui/Dropdown';
import { Download, Printer, Search } from 'lucide-react';
import Button from '@/components/ui/Button';
import { TicketStatusFilter, useTicketFilters } from '../hooks/useTicketFilters';

const FILTERS: TicketStatusFilter[] = [
  'All',
  'Pending',
  'Contested',
  'Paid',
  'Overdue',
  'Waived'
] as const;

const TicketsPage: FC = () => {
  const { 
    setFilters,
    filters,
    queryParams
  } = useTicketFilters()
  const [selectedTicketId, setSelectedTicketId] = useState<number>(0);
  const { stats } = useTicketAnalytics();

  const { ticketSummary, page, setPage, total, totalPages, isLoading, isFetching } = useTickets(queryParams);

  const goToPage = (target: number) => {
    setPage(Math.min(Math.max(target, 1), totalPages));
  };

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

      <section className={styles.recordsContainer}>
        <div className={styles.toolbar}>
          <div className={styles.filters}>
            <div className={styles.searchWrapper}>
              <Search className={styles.searchIcon} size={14} strokeWidth={1.8} aria-hidden="true" />
              <input
                className={styles.searchInput}
                placeholder="Search tickets…"
                value={filters.search}
                onChange={(e) => setFilters.setSearch(e.target.value)}
              />
            </div>

            <div className={styles.filterGroup}>
              <Dropdown
                ariaLabel="Filter by Status"
                triggerLabel={filters.status}
                value={filters.status}
                onChange={(value) => setFilters.setStatus(value as TicketStatusFilter)}
                options={FILTERS.map((filter) => ({ value: filter, label: filter }))}
              />
              <Dropdown
                ariaLabel="Filter by Market Section"
                triggerLabel={filters.marketSection || 'Market Section'}
                value={filters.marketSection}
                onChange={(value) => setFilters.setMarketSection(value as MarketSection)}
                options={Object.entries(MARKET_SECTION_LABELS).map(([value, label]) => ({ value, label }))}
              />
            </div>
          </div>
        </div>

        <TicketList tickets={ticketSummary} loading={isLoading || isFetching} onView={(ticketId) => setSelectedTicketId(ticketId)} />

        <div className={styles.footer}>
          <span className={styles.entries}>
            Showing {total === 0 ? 0 : (page - 1) * 9 + 1} to {Math.min(page * 9, total)} of {total} entries
          </span>

          <div className={styles.footerActions}>
            <Button
              className={styles.exportButton}
              variant="outline"
              icon={<Download size={14} strokeWidth={1.8} aria-hidden="true" />}
            >
              Export
            </Button>
            <button
              className={styles.printButton}
              onClick={() => window.print()}
              aria-label="Print inspection records"
              title="Print inspection records"
            >
              <Printer size={15} strokeWidth={1.8} aria-hidden="true" />
            </button>
            <button
              className={styles.pageButton}
              disabled={page <= 1}
              onClick={() => goToPage(page - 1)}
              aria-label="Previous page"
            >
              ‹
            </button>
            {Array.from({ length: Math.min(totalPages, 3) }, (_, index) => index + 1).map((p) => (
              <button
                key={p}
                className={`${styles.pageButton} ${page === p ? styles.currentPage : ''}`}
                onClick={() => goToPage(p)}
                aria-label={`Go to page ${p}`}
              >
                {p}
              </button>
            ))}
            {totalPages > 3 && <span className={styles.ellipsis}>...</span>}
            <button
              className={styles.pageButton}
              disabled={page >= totalPages}
              onClick={() => goToPage(page + 1)}
              aria-label="Next page"
            >
              ›
            </button>
          </div>
        </div>
      </section>

      {selectedTicketId != 0 &&
        <TicketModal
          isOpen={selectedTicketId != 0}
          ticketId={selectedTicketId}
          onClose={() => setSelectedTicketId(0)}
        />}
    </div>
  );
};

export default TicketsPage;