import { useState } from "react";
import { Download, Printer, Search } from "lucide-react";
import styles from "./InspectionsPage.module.css";
import { InspectionFilters } from "../components/InspectionFilters";
import { InspectionTable } from "../components/InspectionTable";
import { PrintConfigModal } from "../components/PrintConfigModal";
import { WrittenWarningModal } from "../components/WrittenWarningModal";
import { TicketRecordModal } from "../components/TicketRecordModal";
import { Button } from "../../../components/ui/Button";
import { useDebounce } from "../../../hooks/useDebounce";
import { usePagination } from "../../../hooks/usePagination";
import { useInspections } from "../hooks/useInspections";
import {
  MARKET_SECTION_LABELS,
  type InspectionType,
  type MarketSection,
} from "../../../api/types/common.types";
import type { InspectionRecord } from "../../../api/types/ticket.types";
import { Dropdown } from "@/components/ui/Dropdown";
import { useInspectionFilters } from "../hooks/useInspectionFilters";
import { ViolationTypeFilter } from "../inspections.types";
import { label } from "yet-another-react-lightbox";
import { TicketModal } from "@/components/ui/TicketModal/TicketModal";

const VIOLATION_FILTER: ViolationTypeFilter[] = [
  "All Type",
  "Warning",
  "Ticket",
] as const;

export function InspectionsPage() {
  const { queryParams, filters, setFilters } = useInspectionFilters();
  const [isPrintModalOpen, setIsPrintModalOpen] = useState(false);
  const [selectedTicketId, setSelectedTicketId] = useState<number>(0);
  const pagination = usePagination(1, 10);

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
  } = useInspections(queryParams);

  const goToPage = (target: number) => {
    setPage(Math.min(Math.max(target, 1), totalPages));
  };

  return (
    <div className={styles.page}>
      <div className={styles.pageIntro}>
        <h1 className={styles.title}>Inspection Records</h1>
        <p className={styles.subtitle}>
          Overview and administration of all conducted market inspections.
        </p>
      </div>

      <section className={styles.recordsContainer}>
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
          isLoading={isLoading && isFetching}
          isError={isError}
          onView={(ticketId) => setSelectedTicketId(ticketId)}
        />

        <div className={styles.footer}>
          <span className={styles.entries}>
            Showing {total === 0 ? 0 : (page - 1) * 9 + 1} to{" "}
            {Math.min(page * 9, total)} of {total} entries
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
              disabled={pagination.page <= 1}
              onClick={() => goToPage(page - 1)}
              aria-label="Previous page"
            >
              ‹
            </button>
            {Array.from(
              { length: Math.min(totalPages, 3) },
              (_, index) => index + 1,
            ).map((page) => (
              <button
                key={page}
                className={`${styles.pageButton} ${pagination.page === page ? styles.currentPage : ""}`}
                onClick={() => goToPage(page)}
                aria-label={`Go to page ${page}`}
              >
                {page}
              </button>
            ))}
            {totalPages > 3 && <span className={styles.ellipsis}>...</span>}
            <button
              className={styles.pageButton}
              disabled={pagination.page >= totalPages}
              onClick={() => goToPage(page + 1)}
              aria-label="Next page"
            >
              ›
            </button>
          </div>
        </div>
      </section>

      <PrintConfigModal
        isOpen={isPrintModalOpen}
        onClose={() => setIsPrintModalOpen(false)}
      />

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
