import { Download, Eye, Printer, Search } from "lucide-react";
import Button from "@/components/ui/Button";
import Card from "@/components/ui/Card";
import { Dropdown } from "@/components/ui/Dropdown";
import Pagination from "@/components/ui/Pagination";
import Table, { type Column } from "@/components/ui/Table";
import type {
  AdminVendorInspection,
} from "@/api/types/admin-vendor.types";
import { formatControlNumber, formatDateTime } from "@/utils/formatters";
import styles from "./AdminVendorInspectionHistory.module.css";

const TYPE_OPTIONS = [
  { value: "all", label: "All Types" },
  { value: "Warning", label: "Warning" },
  { value: "Ticket", label: "Ticket" },
] as const;
const SORT_OPTIONS = [
  { value: "desc", label: "Date (Newest)" },
  { value: "asc", label: "Date (Oldest)" },
] as const;

function isWarning(inspection: AdminVendorInspection): boolean {
  return String(inspection.type).toLowerCase() === "warning";
}

interface AdminVendorInspectionHistoryProps {
  search: string;
  onSearchChange: (search: string) => void;
  type: "all" | "Warning" | "Ticket";
  onTypeChange: (type: "all" | "Warning" | "Ticket") => void;
  sortDirection: "asc" | "desc";
  onSortDirectionChange: (direction: "asc" | "desc") => void;
  page: number;
  totalPages: number;
  onPageChange: (page: number) => void;
  inspections: AdminVendorInspection[];
  total: number | null;
  hasMore: boolean;
  isLoading: boolean;
  isFetching: boolean;
  isError: boolean;
  errorMessage: string;
  onRetry: () => void;
  onExport: () => void;
  onPrint: () => void;
  onView: (ticketId: number) => void;
}

export default function AdminVendorInspectionHistory({
  search,
  onSearchChange,
  type,
  onTypeChange,
  sortDirection,
  onSortDirectionChange,
  page,
  totalPages,
  onPageChange,
  inspections,
  total,
  hasMore,
  isLoading,
  isFetching,
  isError,
  errorMessage,
  onRetry,
  onExport,
  onPrint,
  onView,
}: AdminVendorInspectionHistoryProps) {
  const offset = (page - 1) * 10;
  const displayedTotal = total ?? `${offset + inspections.length}${hasMore ? "+" : ""}`;

  const columns: Column<AdminVendorInspection>[] = [
    {
      key: "controlNumber",
      header: "CONTROL #",
      width: "16%",
      align: "left",
      render: (inspection) => (
        <strong className={styles.controlNumber}>
          {isWarning(inspection)
            ? "N/A"
            : formatControlNumber(inspection.controlNumber)}
        </strong>
      ),
    },
    {
      key: "type",
      header: "TYPE",
      width: "13%",
      align: "center",
      render: (inspection) => (
        <span
          className={`${styles.typeBadge} ${
            isWarning(inspection) ? styles.warningType : styles.ticketType
          }`}
        >
          {inspection.type}
        </span>
      ),
    },
    {
      key: "issuedAt",
      header: "DATE & TIME",
      width: "19%",
      align: "left",
      render: (inspection) => formatDateTime(inspection.issuedAt),
    },
    {
      key: "ordinanceNumbers",
      header: "ORDINANCE(S)",
      width: "23%",
      align: "left",
      render: (inspection) => inspection.ordinanceNumbers.join(", ") || "—",
    },
    {
      key: "enforcerName",
      header: "ENFORCER",
      width: "19%",
      align: "center",
      render: (inspection) => inspection.enforcerName || "—",
    },
    {
      key: "action",
      header: "ACTION",
      width: "10%",
      align: "center",
      render: (inspection) => (
        <Button
          className={styles.viewButton}
          size="sm"
          variant="outline"
          icon={<Eye size={13} aria-hidden="true" />}
          onClick={() => onView(inspection.ticketId)}
        >
          View
        </Button>
      ),
    },
  ];

  return (
    <>
      <Card className={`${styles.historyCard} motion-enter`}>
        <div className={styles.recordsHeading}>
          <h2>ACTIVITY RECORDS</h2>
          <p>Complete activity log for this vendor.</p>
        </div>

        <div className={styles.toolbar}>
          <label className={styles.searchBox}>
            <Search size={13} aria-hidden="true" />
            <input
              aria-label="Search by control number or vendor"
              placeholder="Search by control number or vendor..."
              value={search}
              onChange={(event) => onSearchChange(event.target.value)}
            />
          </label>

          <div className={styles.filters}>
            <Dropdown
              ariaLabel="Filter by Type"
              triggerLabel={`Filter by Type: ${TYPE_OPTIONS.find((option) => option.value === type)?.label}`}
              value={type}
              onChange={onTypeChange}
              options={TYPE_OPTIONS}
            />
            <Dropdown
              ariaLabel="Sort by date"
              triggerLabel={SORT_OPTIONS.find(
                (option) => option.value === sortDirection,
              )?.label}
              value={sortDirection}
              onChange={onSortDirectionChange}
              options={SORT_OPTIONS}
            />
          </div>
        </div>

        {isError ? (
          <div className={styles.errorState} role="alert">
            <span>{errorMessage}</span>
            <button type="button" onClick={onRetry}>
              Try again
            </button>
          </div>
        ) : (
          <>
            <Table
              className={styles.tableWrapper}
              tableClassName={styles.inspectionTable}
              columns={columns}
              data={inspections}
              keyExtractor={(inspection) => String(inspection.ticketId)}
              loading={isLoading || isFetching}
              loadingMessage="Loading inspection records..."
              emptyMessage="No inspection records match these filters."
            />

            <footer className={styles.footer}>
              <span>
                Showing{" "}
                {inspections.length > 0 ? offset + 1 : 0} to{" "}
                {offset + inspections.length} of {displayedTotal} entries
              </span>
              <div className={styles.footerActions}>
                <Button
                  variant="outline"
                  size="sm"
                  icon={<Download size={13} aria-hidden="true" />}
                  disabled={inspections.length === 0}
                  onClick={onExport}
                >
                  Export
                </Button>
                <button
                  type="button"
                  className={styles.printButton}
                  aria-label="Print inspection history"
                  onClick={onPrint}
                >
                  <Printer size={14} aria-hidden="true" />
                </button>
                <Pagination
                  compact
                  showSinglePage
                  canGoNext={!isFetching && hasMore}
                  className={styles.pagination}
                  page={page}
                  totalPages={totalPages}
                  onChange={onPageChange}
                />
              </div>
            </footer>
          </>
        )}
      </Card>

    </>
  );
}
