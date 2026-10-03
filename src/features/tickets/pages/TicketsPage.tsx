import { FC, useState } from 'react';
import PageHeader from '@/components/ui/PageHeader';
import TicketList from '@/features/tickets/components/TicketList';
import { formatCurrency, formatNumber } from '@/utils/formatters';
import { MARKET_SECTION_LABELS, MarketSection } from '@/api/types/common.types';
import styles from './TicketsPage.module.css';
import useTicketAnalytics from '../hooks/useTicketAnalytics';
import TicketAnalyticsCard from '../components/TicketAnalyticsCard';
import { TicketModal } from '../../../components/ui/TicketModal/TicketModal';
import { Dropdown } from '@/components/ui/Dropdown';
import { Download, Printer, Search } from 'lucide-react';
import Button from '@/components/ui/Button';
import { TicketStatusFilter, useTicketFilters } from '../hooks/useTicketFilters';
import { useTickets } from '../hooks/useTickets';
import { PrintConfigModal } from '@/features/inspections/components/PrintConfigModal';
import { usePrintConfigForm } from '@/features/inspections/hooks/usePrintConfigForm';
import { getApiErrorMessage } from '@/utils/apiErrors';

const FILTERS: TicketStatusFilter[] = [
  'All Status',
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
  const [isExportOpen, setIsExportOpen] = useState(false);
  const printConfig = usePrintConfigForm(
    ["ticket"],
    () => setIsExportOpen(false),
  );
  const { stats } = useTicketAnalytics();

  const {
    ticketSummary,
    page,
    setPage,
    total,
    totalPages,
    pageSize,
    isLoading,
    isFetching,
    isError,
    error,
    refetch,
  } = useTickets(queryParams);

  const goToPage = (target: number) => {
    setPage(Math.min(Math.max(target, 1), totalPages));
  };

  return (
    <div className={styles.page}>
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
        <div className={styles.recordsHeading}>
          <div>
            <h2 className={styles.recordsTitle}>Ticket register</h2>
            <p className={styles.recordsSubtitle}>Search, filter, and review issued tickets</p>
          </div>
          <span className={styles.totalBadge}>{total} tickets</span>
        </div>
        <div className={styles.toolbar}>
          <div className={styles.filters}>
            <div className={styles.searchWrapper}>
              <Search className={styles.searchIcon} size={14} strokeWidth={1.8} aria-hidden="true" />
              <input
                className={styles.searchInput}
                placeholder="Search by control number or vendor..."
                value={filters.search}
                onChange={(e) => setFilters.setSearch(e.target.value)}
                aria-label="Search tickets"
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
                triggerLabel={filters.marketSection === 'All Sections'
                    ? 'All Sections'
                    : MARKET_SECTION_LABELS[filters.marketSection]
                }
                value={filters.marketSection}
                onChange={(value) => setFilters.setMarketSection(value as MarketSection)}
                options={[
                  { value: 'All Sections', label: 'All Sections' },
                  ...Object.entries(MARKET_SECTION_LABELS).map(([value, label]) => ({ value, label })),
                ]}
              />
            </div>
          </div>
        </div>

        {isError ? (
          <div className={styles.errorState} role="alert">
            <span>{getApiErrorMessage(error, "Couldn't load tickets.")}</span>
            <Button size="sm" variant="outline" onClick={() => void refetch()}>
              Try again
            </Button>
          </div>
        ) : (
          <TicketList
            tickets={ticketSummary}
            loading={isLoading || isFetching}
            onView={(ticketId) => setSelectedTicketId(ticketId)}
          />
        )}

        {ticketSummary.length !== 0 && !isError &&
          <div className={styles.footer}>
            <span className={styles.entries}>
              Showing {(page - 1) * pageSize + 1} to {Math.min(page * pageSize, total)} of {total} tickets
            </span>

            <div className={styles.footerActions}>
              <Button
                className={styles.exportButton}
                variant="outline"
                icon={<Download size={14} strokeWidth={1.8} aria-hidden="true" />}
                onClick={() => setIsExportOpen(true)}
              >
                Export
              </Button>
              <button
                className={styles.printButton}
                onClick={() => window.print()}
                aria-label="Print ticket records"
                title="Print ticket records"
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
              {totalPages > 3 && page > 2 && <span className={styles.ellipsis}>...</span>}
              {Array.from(
                { length: Math.min(totalPages, 3) },
                (_, index) => Math.min(Math.max(page - 1, 1), Math.max(1, totalPages - 2)) + index,
              ).map((p) => (
                <button
                  key={p}
                  className={`${styles.pageButton} ${page === p ? styles.currentPage : ''}`}
                  onClick={() => goToPage(p)}
                  aria-label={`Go to page ${p}`}
                  aria-current={page === p ? 'page' : undefined}
                >
                  {p}
                </button>
              ))}
              {totalPages > 3 && page + 1 < totalPages && <span className={styles.ellipsis}>...</span>}
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
        }
      </section>

      {selectedTicketId != 0 &&
        <TicketModal
          isOpen={selectedTicketId != 0}
          ticketId={selectedTicketId}
          onClose={() => setSelectedTicketId(0)}
        />}

      {isExportOpen && (
        <PrintConfigModal
          isOpen={isExportOpen}
          title="Export Ticket Records"
          onClose={() => setIsExportOpen(false)}
          form={printConfig}
        />
      )}
    </div>
  );
};

export default TicketsPage;