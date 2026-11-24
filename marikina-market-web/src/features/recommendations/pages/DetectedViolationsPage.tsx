import Breadcrumb from "@/components/ui/Breadcrumb";
import { Dropdown } from "@/components/ui/Dropdown";
import PageHeader from "@/components/ui/PageHeader";
import {
  RecordsFooter,
  RecordsPanel,
  RecordsToolbar,
} from "@/components/ui/Records";
import { TicketModal } from "@/components/ui/TicketModal/TicketModal";
import { useMarketSectionOptions } from "@/hooks/useMarketSectionOptions";
import { ROUTES } from "@/routes/routePaths";
import DetectedViolationsTable from "../components/DetectedViolationsTable";
import {
  useDetectedViolationsPage,
  type DetectedTypeFilter,
} from "../hooks/useDetectedViolationsPage";
import { VIOLATION_OPTIONS } from "../recommendations.text";
import styles from "./DetectedViolationsPage.module.css";

const TYPE_OPTIONS: { value: DetectedTypeFilter; label: string }[] = [
  { value: "All types", label: "All types" },
  { value: "Warning", label: "Warning" },
  { value: "Ticket", label: "Ticket" },
];

export default function DetectedViolationsPage() {
  const page = useDetectedViolationsPage();
  const streets = useMarketSectionOptions();
  const violationLabel = VIOLATION_OPTIONS.find(
    (option) => option.value === page.categoryCode,
  )?.label;

  return (
    <div className={styles.page}>
      <Breadcrumb
        items={[
          { label: "Recommended Actions", to: ROUTES.recommendations },
          { label: "Detected violations" },
        ]}
      />
      <PageHeader
        title="Detected violations"
        subtitle="Records the model matched to a violation in its latest daily check."
      />
      <RecordsPanel
        title="Latest daily check"
        description="A record that is not listed may still have a violation."
        count={page.isLoading || page.isError ? undefined : page.total}
        countLabel="records"
        updating={page.isFetching && !page.isLoading}
      >
        <RecordsToolbar
          search={page.search}
          onSearch={page.setSearch}
          searchLabel="Search detected violations"
          placeholder="Search control number or description"
        >
          <Dropdown
            triggerId="detected-type-filter"
            ariaLabel="Filter by type"
            triggerLabel={page.type}
            value={page.type}
            onChange={page.setType}
            options={TYPE_OPTIONS}
          />
          <Dropdown
            triggerId="detected-street-filter"
            ariaLabel="Filter by market street"
            triggerLabel={streets.filterLabel(page.marketSection)}
            value={page.marketSection}
            onChange={page.setMarketSection}
            options={streets.filterOptions}
            disabled={streets.isLoading}
          />
          <Dropdown
            triggerId="detected-violation-filter"
            ariaLabel="Filter by violation"
            triggerLabel={violationLabel}
            value={page.categoryCode}
            onChange={page.setCategoryCode}
            options={VIOLATION_OPTIONS}
          />
        </RecordsToolbar>
        <DetectedViolationsTable
          rows={page.rows}
          search={page.search}
          emptyMessage={page.emptyMessage}
          isLoading={page.isLoading}
          isError={page.isError}
          errorMessage={page.errorMessage}
          onRetry={page.retry}
          onView={page.openRecord}
        />
        {!page.isLoading && !page.isError && (
          <RecordsFooter
            page={page.page}
            pageSize={page.pageSize}
            total={page.total}
            totalPages={page.totalPages}
            rowCount={page.rows.length}
            label="records"
            busy={page.isFetching}
            onPageChange={page.goToPage}
          />
        )}
      </RecordsPanel>
      {page.selectedTicketId !== 0 && (
        <TicketModal
          isOpen
          ticketId={page.selectedTicketId}
          onClose={page.closeRecord}
        />
      )}
    </div>
  );
}
