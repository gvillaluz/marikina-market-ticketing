import { useState } from "react";
import { Download, Printer, Search } from "lucide-react";
import styles from "./InspectionsPage.module.css";
import { InspectionTable } from "../components/InspectionTable";
import { PrintConfigModal } from "../components/PrintConfigModal";
import { Button } from "../../../components/ui/Button";
import { useInspections } from "../hooks/useInspections";
import {
  MARKET_SECTION_LABELS,
  type MarketSection,
} from "../../../api/types/common.types";
import { Dropdown } from "@/components/ui/Dropdown";
import { useInspectionFilters } from "../hooks/useInspectionFilters";
import { ViolationTypeFilter } from "../inspections.types";
import { TicketModal } from "@/components/ui/TicketModal/TicketModal";
import PageHeader from "@/components/ui/PageHeader";
import { usePrintConfigForm } from "../hooks/usePrintConfigForm";
import { getApiErrorMessage } from "@/utils/apiErrors";

const VIOLATION_FILTER: ViolationTypeFilter[] = [
  "All Type",
  "Warning",
  "Ticket",
] as const;

export function InspectionsPage() {
  const { queryParams, filters, setFilters } = useInspectionFilters();
  const [isPrintModalOpen, setIsPrintModalOpen] = useState(false);
  const [selectedTicketId, setSelectedTicketId] = useState<number>(0);
  const printConfig = usePrintConfigForm(
    ["warning", "ticket"],
    () => setIsPrintModalOpen(false),
  );
  const {
    inspections,
    total,
    totalPages,
    page,
    setPage,
    isLoading,
    isFetching,
    isError,
    error,
    pageSize,
    refetch,
  } = useInspections(queryParams);

  const goToPage = (target: number) => {
    setPage(Math.min(Math.max(target, 1), totalPages));
  };

  return (
    <div className={styles.page}>
      <PageHeader
        title="Inspection Records"
        subtitle="Review market inspections, warnings, and violation tickets."
      />

      <section className={styles.recordsContainer}>
        <div className={styles.recordsHeading}>
          <div>
            <h2 className={styles.recordsTitle}>Inspection register</h2>
            <p className={styles.recordsSubtitle}>Search and filter issued records</p>
          </div>
          <span className={styles.totalBadge}>{total} records</span>
        </div>
        <div className={styles.toolbar}>
          <div className={styles.searchWrapper}>
            <Search
              className={styles.searchIcon}
              size={14}
              strokeWidth={1.8}
              aria-hidden="true"
            />
            <input
              className={styles.searchInput}
              placeholder="Search by control number or vendor..."
              value={filters.search}
              onChange={(e) => setFilters.setSearch(e.target.value)}
              aria-label="Search inspection records"
            />
          </div>

          <div className={styles.filterGroup}>
            <Dropdown
              ariaLabel="Filter by Type"
              triggerLabel={
                filters.type == "All Type" ? "All Type" : filters.type
              }
              value={filters.type}
              onChange={(value) => setFilters.setType(value)}
              options={VIOLATION_FILTER.map((value) => ({
                value: value,
                label: value,
              }))}
            />

            <Dropdown
              ariaLabel="Filter by Market Section"
              triggerLabel={
                filters.marketSection === "All Sections"
                  ? "All Sections"
                  : MARKET_SECTION_LABELS[filters.marketSection]
              }
              value={filters.marketSection}
              onChange={(value) =>
                setFilters.setMarketSection(value as MarketSection)
              }
              options={[
                { value: "All Sections", label: "All Sections" },
                ...Object.entries(MARKET_SECTION_LABELS).map(
                  ([value, label]) => ({ value, label }),
                ),
              ]}
            />
          </div>
        </div>

        <InspectionTable
          rows={inspections}
          isLoading={isLoading || isFetching}
          isError={isError}
          errorMessage={getApiErrorMessage(error, "Couldn't load inspection records.")}
          onRetry={() => void refetch()}
          onView={(ticketId) => setSelectedTicketId(ticketId)}
        />

        <div className={styles.footer}>
          <span className={styles.entries}>
            Showing {total === 0 ? 0 : (page - 1) * pageSize + 1} to{" "}
            {Math.min(page * pageSize, total)} of {total} records
          </span>

          <div className={styles.footerActions}>
            <Button
              className={styles.exportButton}
              variant="outline"
              icon={<Download size={14} strokeWidth={1.8} aria-hidden="true" />}
              onClick={() => setIsPrintModalOpen(true)}
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
            {totalPages > 3 && page > 2 && <span className={styles.ellipsis}>...</span>}
            {Array.from(
              { length: Math.min(totalPages, 3) },
              (_, index) => Math.min(Math.max(page - 1, 1), Math.max(1, totalPages - 2)) + index,
            ).map((pageNumber) => (
              <button
              key={pageNumber}
              className={`${styles.pageButton} ${page === pageNumber ? styles.currentPage : ""}`}
              onClick={() => goToPage(pageNumber)}
              aria-label={`Go to page ${pageNumber}`}
              aria-current={page === pageNumber ? "page" : undefined}
              >
              {pageNumber}
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
      </section>

      {isPrintModalOpen && (
        <PrintConfigModal
          isOpen={isPrintModalOpen}
          onClose={() => setIsPrintModalOpen(false)}
          form={printConfig}
        />
      )}

      {selectedTicketId != 0 && (
        <TicketModal
          isOpen={selectedTicketId != 0}
          ticketId={selectedTicketId}
          onClose={() => setSelectedTicketId(0)}
        />
      )}
    </div>
  );
}
