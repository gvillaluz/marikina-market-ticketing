import type {
  AdminVendorInspection,
  AdminVendorSummary,
} from "@/api/types/admin-vendor.types";
import type { ExportColumn } from "@/utils/tableExport";
import { formatControlNumber, formatDateTime } from "@/utils/formatters";
import { formatInspectionViolator } from "./inspectionViolator";

export function getTypeLabel(type: string | number | null | undefined): string {
  if (type == null) return "Other";
  return typeof type === "string"
    ? type.replace(/([a-z])([A-Z])/g, "$1 $2")
    : String(type);
}

export function isWarning(inspection: AdminVendorInspection): boolean {
  return String(inspection.type).toLowerCase() === "warning";
}

// Export and Print columns for the business list. Two-line cells become two columns.
export const BUSINESS_COLUMNS: ExportColumn<AdminVendorSummary>[] = [
  { key: "businessName", header: "Business name", value: (v) => v.businessName },
  {
    key: "businessAccountNumber",
    header: "Business account number",
    value: (v) => v.businessAccountNumber,
  },
  { key: "registeredOwner", header: "Registered owner", value: (v) => v.vendorName },
  { key: "section", header: "Market section", value: (v) => v.marketSectionName },
  { key: "type", header: "Type", value: (v) => getTypeLabel(v.type) },
  {
    key: "complianceScore",
    header: "Compliance score",
    value: (v) => `${v.complianceScore}%`,
  },
  { key: "warnings", header: "Warnings", value: (v) => String(v.warningCount) },
  { key: "tickets", header: "Tickets", value: (v) => String(v.ticketCount) },
];

// Export and Print columns for one business's inspection history.
export const BUSINESS_HISTORY_COLUMNS: ExportColumn<AdminVendorInspection>[] = [
  {
    key: "controlNumber",
    header: "Control number",
    value: (row) => formatControlNumber(row.controlNumber),
  },
  {
    key: "businessName",
    header: "Business name",
    value: (row) =>
      isWarning(row)
        ? "—"
        : row.businessSnapshot?.businessName ||
          "Historical business details unavailable.",
  },
  { key: "type", header: "Type", value: (row) => String(row.type) },
  { key: "violator", header: "Violator", value: formatInspectionViolator },
  {
    key: "issuedAt",
    header: "Date & time",
    value: (row) => formatDateTime(row.issuedAt),
  },
  {
    key: "ordinances",
    header: "Ordinance(s)",
    value: (row) => row.ordinanceNumbers.join(", ") || "—",
  },
  { key: "enforcer", header: "Enforcer", value: (row) => row.enforcerName || "—" },
];
