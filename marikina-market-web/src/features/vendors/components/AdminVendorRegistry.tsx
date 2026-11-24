import {
  AlertTriangle,
  Download,
  Eye,
  LoaderCircle,
  Pencil,
  Printer,
  RefreshCw,
  Search,
} from "lucide-react";
import type {
  AdminVendorSummary,
  ComplianceScoreRange,
} from "@/api/types/admin-vendor.types";
import Card from "@/components/ui/Card";
import { Badge, type BadgeTone } from "@/components/ui/Badge/Badge";
import { Dropdown } from "@/components/ui/Dropdown";
import Pagination from "@/components/ui/Pagination";
import SearchHighlight from "@/components/ui/SearchHighlight";
import StackedCell from "@/components/ui/StackedCell";
import Table, { type Column } from "@/components/ui/Table";
import {
  ALL_STREETS,
  LOADING_STREETS,
  useMarketSectionOptions,
} from "@/hooks/useMarketSectionOptions";
import type { TableExportAction } from "@/hooks/useTableExport";
import { getTypeLabel } from "../businessTableColumns";
import styles from "./AdminVendorRegistry.module.css";

const PAGE_SIZE = 10;

const SCORE_OPTIONS: { value: "all" | ComplianceScoreRange; label: string }[] =
  [
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

interface AdminVendorRegistryProps {
  onCreateBusiness: () => void;
  onEditBusiness: (vendor: AdminVendorSummary) => void;
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
  isFetching: boolean;
  isError: boolean;
  errorMessage: string;
  refetch: () => void;
  exportFile: () => void;
  print: () => void;
  preparing: TableExportAction | null;
  onViewInspections: (vendor: AdminVendorSummary) => void;
}

export default function AdminVendorRegistry({
  onCreateBusiness,
  onEditBusiness,
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
  isFetching,
  isError,
  errorMessage,
  refetch,
  exportFile,
  print,
  preparing,
  onViewInspections,
}: AdminVendorRegistryProps) {
  const streets = useMarketSectionOptions();
  const offset = (page - 1) * PAGE_SIZE;
  const totalPages =
    total === null
      ? page + (hasMore ? 1 : 0)
      : Math.max(1, Math.ceil(total / PAGE_SIZE));

  const columns: Column<AdminVendorSummary>[] = [
    {
      key: "business",
      header: "Business",
      width: "22%",
      render: (vendor) => (
        <StackedCell
          primary={
            <SearchHighlight text={vendor.businessName} search={search} />
          }
          secondary={
            <SearchHighlight
              text={vendor.businessAccountNumber}
              search={search}
            />
          }
        />
      ),
    },
    {
      key: "vendorName",
      header: "Registered Owner",
      width: "16%",
      render: (vendor) => (
        <span className={styles.owner}>
          <SearchHighlight text={vendor.vendorName} search={search} />
        </span>
      ),
    },
    {
      key: "sectionType",
      header: "Market Street & Type",
      width: "14%",
      render: (vendor) => (
        <StackedCell
          primary={vendor.marketSectionName}
          secondary={getTypeLabel(vendor.type)}
        />
      ),
    },
    {
      key: "complianceScore",
      header: "Compliance Score",
      align: "center",
      width: "12%",
      render: (vendor) => (
        <Badge
          className={styles.scoreBadge}
          tone={getScoreTone(vendor.complianceScore)}
        >
          {vendor.complianceScore}%
        </Badge>
      ),
    },
    {
      key: "warningCount",
      header: "Warnings",
      align: "center",
      width: "10%",
      render: (vendor) => vendor.warningCount,
    },
    {
      key: "ticketCount",
      header: "Tickets",
      align: "center",
      width: "9%",
      render: (vendor) => vendor.ticketCount,
    },
    {
      key: "action",
      header: "Action",
      align: "center",
      width: "17%",
      render: (vendor) => (
        <div className={styles.rowActions}>
          <button
            type="button"
            className={styles.rowButton}
            onClick={() => onEditBusiness(vendor)}
            aria-label={`Edit ${vendor.businessName}`}
            title="Edit business"
          >
            <Pencil size={16} aria-hidden="true" />
            <span className={styles.rowButtonLabel}>Edit</span>
          </button>
          <button
            type="button"
            className={styles.rowButton}
            onClick={() => onViewInspections(vendor)}
            aria-label={`View inspections for ${vendor.vendorName}`}
            title="View inspections"
          >
            <Eye size={16} aria-hidden="true" />
            <span className={styles.rowButtonLabel}>Inspections</span>
          </button>
        </div>
      ),
    },
  ];

  return (
    <Card className={styles.registryCard} aria-label="Business registry">
      <div className={styles.toolbar}>
        <button
          type="button"
          className={styles.createButton}
          onClick={onCreateBusiness}
        >
          Create Business
        </button>
        <label className={styles.searchBox}>
          <Search size={16} aria-hidden="true" />
          <input
            aria-label="Search businesses"
            placeholder="Search by business, owner, account or stall"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
          />
        </label>
        <div className={styles.filters}>
          <Dropdown
            fullWidth
            ariaLabel="Filter by market street"
            triggerLabel={
              streets.isLoading
                ? LOADING_STREETS
                : `Street: ${section === ALL_STREETS ? "All" : (streets.nameOf(section) ?? "All")}`
            }
            value={section}
            onChange={setSection}
            options={streets.filterOptions}
            disabled={streets.isLoading}
          />
          <Dropdown
            fullWidth
            ariaLabel="Filter by compliance score"
            triggerLabel={`Compliance Score: ${SCORE_OPTIONS.find((option) => option.value === complianceScore)?.label}`}
            value={complianceScore}
            onChange={(value) =>
              setComplianceScore(value as "all" | ComplianceScoreRange)
            }
            options={SCORE_OPTIONS}
          />
        </div>
      </div>

      {isError ? (
        <div className={styles.errorState} role="alert">
          <AlertTriangle size={22} />
          <strong>Unable to load businesses</strong>
          <span>{errorMessage}</span>
          <button type="button" onClick={refetch} disabled={isFetching}>
            {isFetching ? (
              "Retrying…"
            ) : (
              <>
                <RefreshCw size={14} /> Try again
              </>
            )}
          </button>
        </div>
      ) : (
        <>
          <Table
            responsive
            className={styles.tableWrapper}
            columns={columns}
            data={vendors}
            keyExtractor={(vendor) => String(vendor.vendorId)}
            loading={isLoading || isFetching}
            loadingMessage="Loading business records..."
            emptyMessage="No businesses match these filters."
          />
          <footer className={styles.tableFooter}>
            <span>
              Showing {vendors.length ? offset + 1 : 0} to{" "}
              {vendors.length ? offset + vendors.length : 0} of{" "}
              {total ?? `${offset + vendors.length}${hasMore ? "+" : ""}`}{" "}
              entries
            </span>
            <div className={styles.footerActions}>
              <button
                type="button"
                className={styles.utilityButton}
                disabled={vendors.length === 0 || preparing !== null}
                aria-busy={preparing === "export"}
                onClick={exportFile}
              >
                {preparing === "export" ? (
                  <LoaderCircle size={13} className="icon-spin" aria-hidden="true" />
                ) : (
                  <Download size={13} aria-hidden="true" />
                )}
                Export
              </button>
              <button
                type="button"
                className={styles.iconButton}
                aria-label={
                  preparing === "print" ? "Preparing print" : "Print business list"
                }
                aria-busy={preparing === "print"}
                disabled={vendors.length === 0 || preparing !== null}
                onClick={print}
              >
                {preparing === "print" ? (
                  <LoaderCircle size={14} className="icon-spin" aria-hidden="true" />
                ) : (
                  <Printer size={14} aria-hidden="true" />
                )}
              </button>
              <Pagination
                compact
                showSinglePage
                canGoNext={!hasMore}
                disabled={isLoading || isFetching}
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
