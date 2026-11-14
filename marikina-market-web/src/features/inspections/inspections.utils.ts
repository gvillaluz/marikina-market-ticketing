import type { InspectionSummary } from "@/api/types/ticket.types";
import type { ExportColumn } from "@/utils/tableExport";
import {
  formatControlNumber,
  formatDateTime,
  UNREGISTERED_VENDOR,
} from "@/utils/formatters";

const UNAVAILABLE = "Historical business details unavailable.";

// Text shown in the inspection register, used by the table, Export and Print.
export const INSPECTION_COLUMNS: ExportColumn<InspectionSummary>[] = [
  {
    key: "controlNumber",
    header: "Control number",
    value: (row) => formatControlNumber(row.controlNumber),
  },
  {
    key: "violator",
    header: "Violator",
    value: (row) =>
      row.type === "Ticket"
        ? `Recorded violator: ${row.paperViolatorName || "Unconfirmed (legacy record)"}`
        : `Confirmed person: ${row.personFullName || "Unconfirmed (legacy record)"}`,
  },
  {
    key: "enforcer",
    header: "Enforcer",
    value: (row) =>
      `${row.enforcerFirstName ?? ""} ${row.enforcerLastName ?? ""}`.trim() ||
      "—",
  },
  {
    key: "businessName",
    header: "Business name",
    value: (row) =>
      row.vendorId === null
        ? UNREGISTERED_VENDOR
        : row.type === "Ticket"
          ? row.businessSnapshot?.businessName || UNAVAILABLE
          : row.businessName || "—",
  },
  {
    key: "registeredOwner",
    header: "Registered owner",
    value: (row) =>
      row.vendorId === null
        ? "—"
        : row.type === "Ticket"
          ? row.businessSnapshot?.registeredOwnerName || UNAVAILABLE
          : row.registeredOwnerName || "—",
  },
  {
    key: "section",
    header: "Market section",
    value: (row) =>
      row.vendorId !== null && row.type === "Ticket"
        ? row.businessSnapshot?.marketSectionName || UNAVAILABLE
        : row.marketSectionName || "—",
  },
  { key: "type", header: "Type", value: (row) => row.type },
  {
    key: "issuedAt",
    header: "Issued at",
    value: (row) => formatDateTime(row.issuedAt),
  },
];
