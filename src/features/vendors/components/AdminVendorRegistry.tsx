import { AlertTriangle, Download, Eye, Printer, RefreshCw, Search } from "lucide-react";
import { MARKET_SECTION_IDS, MARKET_SECTION_LABELS, type MarketSection } from "@/api/types/common.types";
import type { AdminVendorSummary, ComplianceScoreRange } from "@/api/types/admin-vendor.types";
import Card from "@/components/ui/Card";
import { Badge, type BadgeTone } from "@/components/ui/Badge/Badge";
import { Dropdown } from "@/components/ui/Dropdown";
import Pagination from "@/components/ui/Pagination";
import Table, { type Column } from "@/components/ui/Table";
import styles from "./AdminVendorRegistry.module.css";

const PAGE_SIZE = 10;

const SECTION_OPTIONS = [
  { value: "all", label: "All Sections" },
  ...Object.entries(MARKET_SECTION_IDS).map(([section, id]) => ({
    value: String(id),
    label: MARKET_SECTION_LABELS[section as MarketSection],
  })),
];

const SCORE_OPTIONS: { value: "all" | ComplianceScoreRange; label: string }[] = [
  { value: "all", label: "All Scores" },
  { value: "85-100", label: "85-100%" },
  { value: "70-84", label: "70-84%" },
  { value: "50-69", label: "50-69%" },
  { value: "Below 50", label: "Below 50%" },
];

function getScoreTone(score: number): BadgeTone {
  if (score >= 85) return "success";
  if (score >= 70) return "warning";
  return "ticket";
}

function getTypeLabel(type: string | number | null | undefined): string {
  if (type == null) return "Other";
  return typeof type === "string"
    ? type.replace(/([a-z])([A-Z])/g, "$1 $2")
    : String(type);
}

interface AdminVendorRegistryProps {
  search: string;
  setSearch: (search: string) => void;
  section: string;
  setSection: (section: string) => void;
  complianceScore: "all" | ComplianceScoreRange;
  setComplianceScore: (score: "all" | ComplianceScoreRange) => void;
  page: number;
  setPage: (page: number) => void;
  vendors: AdminVendorSummary[];
  total: number | null;
  hasMore: boolean;
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  refetch: () => void;
  exportCurrentPage: () => void;
  print: () => void;
  onViewInspections: (vendor: AdminVendorSummary) => void;
}

export default function AdminVendorRegistry({
  search,
  setSearch,
  section,
  setSection,
  complianceScore,
  setComplianceScore,
  page,
  setPage,
  vendors,
  total,
  hasMore,
  isLoading,
  isError,
  errorMessage,
  refetch,
  exportCurrentPage,
  print,
  onViewInspections,
}: AdminVendorRegistryProps) {
  const offset = (page - 1) * PAGE_SIZE;
  const totalPages =
    total === null
      ? page + (hasMore ? 1 : 0)
      : Math.max(1, Math.ceil(total / PAGE_SIZE));

  const columns: Column<AdminVendorSummary>[] = [
    {
      key: "businessId",
      header: "Business ID",
      width: "11%",
      render: (vendor) => <span className={styles.businessId}>{vendor.businessId}</span>,
    },
    {
      key: "vendorName",
      header: "Vendor Name",
      width: "19%",
      render: (vendor) => <span className={styles.vendorName}>{vendor.vendorName}</span>,
    },
    { key: "marketSectionName", header: "Market Section", width: "17%" },
    { key: "type", header: "Type", width: "9%", render: (vendor) => getTypeLabel(vendor.type) },
    {
      key: "complianceScore",
      header: "Compliance Score",
      align: "center",
      width: "14%",
      render: (vendor) => (
        <Badge className={styles.scoreBadge} tone={getScoreTone(vendor.complianceScore)}>
          {vendor.complianceScore}%
        </Badge>
      ),
    },
    { key: "warningCount", header: "Warnings", align: "center", width: "6%" },
    { key: "ticketCount", header: "Tickets", align: "center", width: "5%" },
    {
      key: "action",
      header: "Action",
      align: "center",
      width: "20%",
      render: (vendor) => (
        <button
          type="button"
          className={styles.viewButton}
          onClick={() => onViewInspections(vendor)}
          aria-label={`View inspections for ${vendor.vendorName}`}
        >
          <Eye size={13} /> View Inspections
        </button>
      ),
    },
  ];

  return (
    <Card className={styles.registryCard} aria-label="Vendor registry">
      <div className={styles.toolbar}>
        <label className={styles.searchBox}>
          <Search size={14} aria-hidden="true" />
          <input
            aria-label="Search vendors"
            placeholder="Search by name, stall, or ID..."
            value={search}
            onChange={(event) => setSearch(event.target.value)}
          />
        </label>
        <div className={styles.filters}>
          <Dropdown
            ariaLabel="Filter by market section"
            triggerLabel={
              section === "all"
                ? "Section: All"
                : `Section: ${SECTION_OPTIONS.find((option) => option.value === section)?.label}`
            }
            value={section}
            onChange={setSection}
            options={SECTION_OPTIONS}
          />
          <Dropdown
            ariaLabel="Filter by compliance score"
            triggerLabel={`Compliance Score: ${SCORE_OPTIONS.find((option) => option.value === complianceScore)?.label}`}
            value={complianceScore}
            onChange={(value) => setComplianceScore(value as "all" | ComplianceScoreRange)}
            options={SCORE_OPTIONS}
          />
        </div>
      </div>

      {isError ? (
        <div className={styles.errorState} role="alert">
          <AlertTriangle size={22} />
          <strong>Unable to load vendors</strong>
          <span>{errorMessage}</span>
          <button type="button" onClick={refetch}>
            <RefreshCw size={14} /> Try again
          </button>
        </div>
      ) : (
        <>
          <Table
            className={styles.tableWrapper}
            columns={columns}
            data={vendors}
            keyExtractor={(vendor) => String(vendor.vendorId)}
            loading={isLoading}
            loadingMessage="Loading vendor records..."
            emptyMessage="No vendors match these filters."
          />
          <footer className={styles.tableFooter}>
            <span>
              Showing {vendors.length ? offset + 1 : 0} to{" "}
              {offset + vendors.length} of{" "}
              {total ?? `${offset + vendors.length}${hasMore ? "+" : ""}`} entries
            </span>
            <div className={styles.footerActions}>
              <button
                type="button"
                className={styles.utilityButton}
                disabled={vendors.length === 0}
                onClick={exportCurrentPage}
              >
                <Download size={13} /> Export
              </button>
              <button
                type="button"
                className={styles.iconButton}
                aria-label="Print vendor list"
                onClick={print}
              >
                <Printer size={14} />
              </button>
              <Pagination
                compact
                showSinglePage
                canGoNext={!isLoading && hasMore}
                className={styles.pagination}
                page={page}
                totalPages={totalPages}
                onChange={setPage}
              />
            </div>
          </footer>
        </>
      )}
    </Card>
  );
}
