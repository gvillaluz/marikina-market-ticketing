import { RefreshCw } from "lucide-react";
import type { VendorRegistrationSummary } from "@/api/types/admin-vendor.types";
import { Dropdown } from "@/components/ui/Dropdown";
import Pagination from "@/components/ui/Pagination";
import Table, { type Column } from "@/components/ui/Table";
import styles from "./AdminVendorRegistrationTable.module.css";

interface Props {
  registrations: VendorRegistrationSummary[];
  status: string;
  vendorType: string;
  setStatus: (value: string) => void;
  setVendorType: (value: string) => void;
  page: number;
  totalPages: number;
  setPage: (page: number) => void;
  hasMore: boolean;
  total: number | null;
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  refetch: () => void;
}

function displayValue(value: string | number | null | undefined) {
  if (value === null || value === undefined || value === "") return "N/A";
  return String(value).replace(/([a-z])([A-Z])/g, "$1 $2");
}

function statusLabel(status: string | number) {
  return displayValue(status);
}

function statusClass(status: string | number) {
  const value = String(status).toLowerCase();
  if (value.includes("approve")) return styles.approved;
  if (value.includes("reject")) return styles.rejected;
  if (value.includes("information") || value.includes("follow")) return styles.info;
  return styles.pending;
}

export default function AdminVendorRegistrationTable({
  registrations, status, vendorType, setStatus, setVendorType, page,
  totalPages, setPage, hasMore, total, isLoading, isError, errorMessage, refetch,
}: Props) {
  const columns: Column<VendorRegistrationSummary>[] = [
    { key: "registrationId", header: "Registration ID", width: "12%", render: (row) => <span className={styles.id}>REG-{row.registrationId}</span> },
    { key: "businessId", header: "Business ID", width: "11%" },
    { key: "businessName", header: "Business Name", width: "14%", render: (row) => <strong>{row.businessName}</strong> },
    { key: "vendorName", header: "Vendor Name", width: "14%" },
    { key: "vendorType", header: "Vendor Type", width: "10%", align: "center", render: (row) => displayValue(row.vendorType) },
    { key: "marketSectionName", header: "Market Section", width: "13%" },
    { key: "stallNumber", header: "Stall Number", width: "9%", align: "center", render: (row) => displayValue(row.stallNumber) },
    { key: "requestedAt", header: "Request Date", width: "10%", render: (row) => new Date(row.requestedAt).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" }) },
    { key: "status", header: "Status", width: "9%", align: "center", render: (row) => <span className={`${styles.status} ${statusClass(row.status)}`}><span />{statusLabel(row.status)}</span> },
    { key: "action", header: "Action", width: "8%", align: "center", render: () => <button className={styles.reviewButton} type="button">Review</button> },
  ];

  const offset = (page - 1) * 10;
  return (
    <section className={styles.panel}>
      <div className={styles.heading}>
        <div>
          <h2>Incoming Vendor Account Registrants</h2>
          <p>Review new account requests, verify supporting documents, and resolve pending cases before vendor activation.</p>
        </div>
        <div className={styles.filters}>
          <Dropdown
            ariaLabel="Filter by registration status"
            triggerLabel={`Status: ${status === "all" ? "All" : statusLabel(status)}`}
            value={status}
            onChange={setStatus}
            options={[
              { value: "all", label: "All" },
              { value: "Pending", label: "Pending" },
              { value: "NeedsInformation", label: "Needs Information" },
              { value: "Approved", label: "Approved" },
              { value: "Rejected", label: "Rejected" },
            ]}
          />
          <Dropdown
            ariaLabel="Filter by vendor type"
            triggerLabel={`Vendor Type: ${vendorType === "all" ? "All" : displayValue(vendorType)}`}
            value={vendorType}
            onChange={setVendorType}
            options={[
              { value: "all", label: "All" },
              { value: "Vendor", label: "Vendor" },
              { value: "Business", label: "Business" },
            ]}
          />
        </div>
      </div>
      {isError ? (
        <div className={styles.error} role="alert"><span>{errorMessage}</span><button type="button" onClick={() => void refetch()}><RefreshCw size={14} /> Try again</button></div>
      ) : (
        <Table className={styles.table} tableClassName={styles.tableInner} columns={columns} data={registrations} keyExtractor={(row) => String(row.registrationId)} loading={isLoading} loadingMessage="Loading registration requests..." emptyMessage="No registration requests match these filters." />
      )}
      <footer className={styles.footer}>
        <span>Showing {registrations.length ? offset + 1 : 0} to {offset + registrations.length} of {total ?? `${offset + registrations.length}${hasMore ? "+" : ""}`} registrations</span>
        <Pagination compact showSinglePage canGoNext={!isLoading && hasMore} className={styles.pagination} page={page} totalPages={totalPages} onChange={setPage} />
      </footer>
      <div className={styles.legend}>
        <span><i className={styles.pendingDot} /> Pending</span>
        <span><i className={styles.infoDot} /> Needs Information</span>
        <span><i className={styles.rejectedDot} /> Rejected</span>
        <span><i className={styles.approvedDot} /> Approved</span>
      </div>
    </section>
  );
}
