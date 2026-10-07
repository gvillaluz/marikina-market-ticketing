import { FileText, RefreshCw, Upload } from "lucide-react";
import type { AdminCommunityServiceLog } from "@/api/types/admin-vendor.types";
import Card from "@/components/ui/Card";
import { Dropdown } from "@/components/ui/Dropdown";
import Pagination from "@/components/ui/Pagination";
import Table, { type Column } from "@/components/ui/Table";
import { formatControlNumber, formatDate } from "@/utils/formatters";
import type { CommunityServiceStatusFilter } from "../hooks/useAdminCommunityServiceLogs";
import styles from "./AdminCommunityServiceLogs.module.css";

const STATUS_OPTIONS = [
  { value: "all", label: "All" },
  { value: "Pending", label: "Pending" },
  { value: "Overdue", label: "Overdue" },
  { value: "Paid", label: "Paid" },
  { value: "Contested", label: "Contested" },
  { value: "Waived", label: "Waived" },
  { value: "Cleared", label: "Cleared" },
] as const;

type ProgressStatus = "pending" | "overdue" | "inProgress" | "completed";

interface AdminCommunityServiceLogsProps {
  logs: AdminCommunityServiceLog[];
  page: number;
  setPage: (page: number) => void;
  status: CommunityServiceStatusFilter;
  setStatus: (status: CommunityServiceStatusFilter) => void;
  totalLabel: number | string;
  offset: number;
  totalPages: number;
  hasMore: boolean;
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  refetch: () => void;
  getProgressStatus: (log: AdminCommunityServiceLog) => ProgressStatus;
}

function formatHours(hours: number): string {
  return Number.isInteger(hours) ? String(hours) : hours.toFixed(1);
}

function getProgress(log: AdminCommunityServiceLog): number {
  if (log.totalHours <= 0) return 0;
  return Math.min(
    100,
    Math.max(0, (log.completedHours / log.totalHours) * 100),
  );
}

export default function AdminCommunityServiceLogs({
  logs,
  page,
  setPage,
  status,
  setStatus,
  totalLabel,
  offset,
  totalPages,
  hasMore,
  isLoading,
  isError,
  errorMessage,
  refetch,
  getProgressStatus,
}: AdminCommunityServiceLogsProps) {
  const columns: Column<AdminCommunityServiceLog>[] = [
    {
      key: "controlNumber",
      header: "CTRL NO",
      width: "12%",
      render: (log) => (
        <span className={styles.controlNumber}>
          {formatControlNumber(log.controlNumber, "N/A")}
        </span>
      ),
    },
    {
      key: "businessId",
      header: "Business ID",
      width: "11%",
      render: (log) => (
        <span className={styles.businessId}>{log.businessId}</span>
      ),
    },
    {
      key: "vendorName",
      header: "Vendor Name",
      width: "18%",
      render: (log) => (
        <strong className={styles.vendorName}>{log.vendorName}</strong>
      ),
    },
    {
      key: "hours",
      header: "Hours Completed",
      width: "25%",
      render: (log) => {
        const progress = getProgress(log);
        const progressStatus = getProgressStatus(log);
        const remainingHours = Math.max(0, log.totalHours - log.completedHours);

        return (
          <div className={`${styles.progressCell} ${styles[progressStatus]}`}>
            <div className={styles.progressLabels}>
              <strong>
                {formatHours(log.completedHours)} /{" "}
                {formatHours(log.totalHours)} hrs
              </strong>
              <span>{Math.round(progress)}%</span>
            </div>
            <div
              className={styles.progressTrack}
              role="progressbar"
              aria-label={`${log.vendorName} community service hours completed`}
              aria-valuemin={0}
              aria-valuemax={100}
              aria-valuenow={Math.round(progress)}
            >
              <span style={{ width: `${progress}%` }} />
            </div>
            {remainingHours > 0 && (
              <small>{formatHours(remainingHours)} hrs remaining</small>
            )}
          </div>
        );
      },
    },
    {
      key: "lastUpdated",
      header: "Last Updated",
      width: "14%",
      render: (log) => (
        <span className={styles.lastUpdated}>
          {formatDate(log.lastUpdated)}
        </span>
      ),
    },
    {
      key: "proofDocumentCount",
      header: "Proof Documents",
      width: "20%",
      render: (log) => (
        <div className={styles.documentActions}>
          <span className={styles.documentCount}>
            <FileText size={12} aria-hidden="true" />
            {log.proofDocumentCount}{" "}
            {log.proofDocumentCount === 1 ? "doc" : "docs"}
          </span>
          <button
            type="button"
            className={styles.uploadButton}
            disabled={getProgressStatus(log) === "completed"}
            title={
              getProgressStatus(log) === "completed"
                ? "Community service has been completed"
                : "Document upload is not available yet"
            }
          >
            <Upload size={12} aria-hidden="true" />
            Upload
          </button>
        </div>
      ),
    },
  ];

  const statusCounts = logs.reduce(
    (counts, log) => {
      counts[getProgressStatus(log)] += 1;
      return counts;
    },
    { pending: 0, overdue: 0, inProgress: 0, completed: 0 },
  );

  return (
    <Card
      className={`${styles.logsCard} motion-enter`}
      aria-label="Community service logs"
    >
      <div className={styles.header}>
        <div>
          <h2>Community Service Logs</h2>
          <p>
            Track court-mandated community service hours and proof documentation
            per vendor.
          </p>
        </div>
        <Dropdown
          ariaLabel="Filter by ticket status"
          triggerLabel={`Status: ${STATUS_OPTIONS.find((option) => option.value === status)?.label ?? "All"}`}
          value={status}
          onChange={(value) => setStatus(value)}
          options={STATUS_OPTIONS}
        />
      </div>

      {isError ? (
        <div className={styles.errorState} role="alert">
          <span>{errorMessage}</span>
          <button type="button" onClick={refetch}>
            <RefreshCw size={13} aria-hidden="true" />
            Try again
          </button>
        </div>
      ) : (
        <>
          <Table
            className={styles.tableWrapper}
            columns={columns}
            data={logs}
            keyExtractor={(log) => String(log.ticketId)}
            loading={isLoading}
            loadingMessage="Loading community service logs..."
            emptyMessage="No community service logs match this status."
          />
          <footer className={styles.footer}>
            <span className={styles.summaryText}>
              Showing {logs.length ? offset + 1 : 0} to {offset + logs.length}{" "}
              of {totalLabel} vendors with active community service obligations
            </span>
            <div className={styles.footerContent}>
              <div
                className={styles.legend}
                aria-label="Progress status legend"
              >
                <span className={styles.pendingLegend}>
                  {statusCounts.pending} Pending
                </span>
                <span className={styles.overdueLegend}>
                  {statusCounts.overdue} Overdue
                </span>
                <span className={styles.inProgressLegend}>
                  {statusCounts.inProgress} In Progress
                </span>
                <span className={styles.completedLegend}>
                  {statusCounts.completed} Completed
                </span>
              </div>
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
