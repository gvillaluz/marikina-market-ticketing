import PageHeader from "@/components/ui/PageHeader";
import { Dropdown } from "@/components/ui/Dropdown";
import {
  RecordsPanel,
  RecordsToolbar,
  RecordsFooter,
} from "@/components/ui/Records";
import { TicketModal } from "@/components/ui/TicketModal/TicketModal";
import {
  MARKET_SECTION_LABELS,
  type MarketSectionFilter,
} from "@/api/types/common.types";
import { InspectionTable } from "../components/InspectionTable";
import { PrintConfigModal } from "../components/PrintConfigModal";
import { useInspectionsPage } from "../hooks/useInspectionsPage";
import type { ViolationTypeFilter } from "../inspections.types";
import styles from "./InspectionsPage.module.css";

const TYPES: ViolationTypeFilter[] = ["All Type", "Warning", "Ticket"];
export function InspectionsPage() {
  const page = useInspectionsPage();
  return (
    <div className={styles.page}>
      <PageHeader
        title="Inspection Records"
        subtitle="Review market inspections, warnings, and violation tickets."
      />
      <RecordsPanel
        title="Inspection register"
        description="Search and filter issued records"
        count={page.isLoading || page.isError ? undefined : page.total}
        countLabel="records"
        updating={page.isFetching && !page.isLoading}
      >
        <RecordsToolbar
          search={page.filters.search}
          onSearch={page.setFilters.setSearch}
          searchLabel="Search inspection records"
          placeholder="Search control number or vendor..."
        >
          <Dropdown
            triggerId="inspections-type-filter"
            ariaLabel="Filter by type"
            triggerLabel={
              page.filters.type === "All Type" ? "All types" : page.filters.type
            }
            value={page.filters.type}
            onChange={(value) =>
              page.setFilters.setType(value as ViolationTypeFilter)
            }
            options={TYPES.map((value) => ({
              value,
              label: value === "All Type" ? "All types" : value,
            }))}
          />
          <Dropdown
            triggerId="inspections-section-filter"
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
        <InspectionTable
          rows={page.inspections}
          isLoading={page.isLoading}
          isError={page.isError}
          errorMessage={page.errorMessage}
          onRetry={() => void page.refetch()}
          onView={page.openTicket}
        />
        {!page.isLoading && !page.isError && (
          <RecordsFooter
            page={page.page}
            pageSize={page.pageSize}
            total={page.total}
            totalPages={page.totalPages}
            rowCount={page.inspections.length}
            label="records"
            busy={page.isFetching}
            onPageChange={page.goToPage}
            onExport={page.openExport}
            onPrint={page.print}
          />
        )}
      </RecordsPanel>
      {page.isExportOpen && (
        <PrintConfigModal
          isOpen
          onClose={page.closeExport}
          form={page.printConfig}
        />
      )}
      {page.selectedTicketId !== 0 && (
        <TicketModal
          isOpen
          ticketId={page.selectedTicketId}
          onClose={page.closeTicket}
        />
      )}
    </div>
  );
}
