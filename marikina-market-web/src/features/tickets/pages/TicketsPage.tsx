import PageHeader from "@/components/ui/PageHeader";
import { Dropdown } from "@/components/ui/Dropdown";
import {
  RecordsPanel,
  RecordsToolbar,
  RecordsFooter,
  RecordsState,
} from "@/components/ui/Records";
import { TicketModal } from "@/components/ui/TicketModal/TicketModal";
import { PrintConfigModal } from "@/features/inspections";
import {
  MARKET_SECTION_LABELS,
  type MarketSectionFilter,
} from "@/api/types/common.types";
import { formatCurrency, formatNumber } from "@/utils/formatters";
import { useTicketsPage } from "../hooks/useTicketsPage";
import type { TicketStatusFilter } from "../hooks/useTicketFilters";
import TicketList from "../components/TicketList";
import TicketAnalyticsCard from "../components/TicketAnalyticsCard";
import styles from "./TicketsPage.module.css";

const FILTERS: TicketStatusFilter[] = [
  "All Status",
  "Pending",
  "Contested",
  "Paid",
  "Overdue",
  "Waived",
];
export default function TicketsPage() {
  const page = useTicketsPage();
  const { stats } = page.analytics;
  return (
    <div className={styles.page}>
      <PageHeader
        title="Tickets"
        subtitle="Review issued tickets, payment status, and violation severity."
      />
      {page.analyticsError && !stats ? (
        <RecordsState
          title="Ticket summary unavailable"
          message={page.analyticsError}
          onRetry={() => void page.analytics.refetch()}
        />
      ) : (
        <div className={styles.stats}>
          <TicketAnalyticsCard
            label="Tickets this month"
            value={stats ? formatNumber(stats.totalTicketsThisMonth) : "\u2014"}
            change={stats?.ticketChangePercentage}
            isLoading={page.analytics.isLoading}
          />
          <TicketAnalyticsCard
            label="Pending payments"
            value={
              stats ? formatCurrency(stats.pendingPaymentsThisMonth) : "\u2014"
            }
            change={stats?.paymentsChangePercentage}
            isLoading={page.analytics.isLoading}
          />
          <TicketAnalyticsCard
            label="Resolved violations"
            value={
              stats ? formatNumber(stats.resolvedViolationsThisMonth) : "\u2014"
            }
            progress={stats?.resolutionRate}
            isLoading={page.analytics.isLoading}
          />
          <TicketAnalyticsCard
            label="High severity tickets"
            value={
              stats ? formatNumber(stats.highSeveritiesThisMonth) : "\u2014"
            }
            change={stats?.highSeveritiesChangePercentage}
            isLoading={page.analytics.isLoading}
          />
        </div>
      )}
      <RecordsPanel
        title="Ticket register"
        description="Search and filter issued tickets"
        count={page.isLoading || page.isError ? undefined : page.total}
        countLabel="tickets"
        updating={page.isFetching && !page.isLoading}
      >
        <RecordsToolbar
          search={page.filters.search}
          onSearch={page.setFilters.setSearch}
          searchLabel="Search tickets"
          placeholder="Search control number or vendor..."
        >
          <Dropdown
            triggerId="tickets-status-filter"
            ariaLabel="Filter by status"
            triggerLabel={page.filters.status}
            value={page.filters.status}
            onChange={(value) =>
              page.setFilters.setStatus(value as TicketStatusFilter)
            }
            options={FILTERS.map((value) => ({ value, label: value }))}
          />
          <Dropdown
            triggerId="tickets-section-filter"
            ariaLabel="Filter by market section"
            triggerLabel={
              page.filters.marketSection === "All Sections"
                ? "All Sections"
                : MARKET_SECTION_LABELS[page.filters.marketSection]
            }
            value={page.filters.marketSection}
            onChange={(value) =>
              page.setFilters.setMarketSection(value as MarketSectionFilter)
            }
            options={[
              { value: "All Sections", label: "All Sections" },
              ...Object.entries(MARKET_SECTION_LABELS).map(
                ([value, label]) => ({ value, label }),
              ),
            ]}
          />
        </RecordsToolbar>
        {page.errorMessage ? (
          <RecordsState
            title="Unable to load tickets"
            message={page.errorMessage}
            onRetry={() => void page.refetch()}
          />
        ) : (
          <TicketList
            tickets={page.ticketSummary}
            loading={page.isLoading}
            onView={page.openTicket}
          />
        )}
        {!page.isLoading && !page.isError && (
          <RecordsFooter
            page={page.page}
            pageSize={page.pageSize}
            total={page.total}
            totalPages={page.totalPages}
            rowCount={page.ticketSummary.length}
            label="tickets"
            busy={page.isFetching}
            onPageChange={page.goToPage}
            onExport={page.openExport}
            onPrint={page.print}
          />
        )}
      </RecordsPanel>
      {page.selectedTicketId !== 0 && (
        <TicketModal
          isOpen
          ticketId={page.selectedTicketId}
          onClose={page.closeTicket}
        />
      )}
      {page.isExportOpen && (
        <PrintConfigModal
          isOpen
          title="Export Ticket Records"
          onClose={page.closeExport}
          form={page.printConfig}
        />
      )}
    </div>
  );
}
