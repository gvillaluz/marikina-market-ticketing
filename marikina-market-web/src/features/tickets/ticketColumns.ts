import type { TicketSummary } from "@/api/types/ticket.types";
import type { ExportColumn } from "@/utils/tableExport";
import {
  formatControlNumber,
  formatDateTime,
  UNREGISTERED_VENDOR,
} from "@/utils/formatters";
import { formatPenaltyType } from "./tickets.utils";

const UNAVAILABLE = "Historical business details unavailable.";

// Text shown in the ticket register, used by the table, Export and Print.
export const TICKET_COLUMNS: ExportColumn<TicketSummary>[] = [
  {
    key: "controlNumber",
    header: "Control number",
    value: (ticket) => formatControlNumber(ticket.controlNumber),
  },
  {
    key: "enforcer",
    header: "Enforcer",
    value: (ticket) =>
      `${ticket.enforcerFirstName ?? ""} ${ticket.enforcerLastName ?? ""}`.trim() ||
      "—",
  },
  {
    key: "businessName",
    header: "Business name",
    value: (ticket) =>
      ticket.vendorId === null
        ? UNREGISTERED_VENDOR
        : ticket.businessSnapshot?.businessName || UNAVAILABLE,
  },
  {
    key: "registeredOwner",
    header: "Registered owner",
    value: (ticket) =>
      ticket.vendorId === null
        ? "—"
        : ticket.businessSnapshot?.registeredOwnerName || UNAVAILABLE,
  },
  {
    key: "violator",
    header: "Violator",
    value: (ticket) =>
      ticket.paperViolatorName || "Unconfirmed (legacy record)",
  },
  {
    key: "section",
    header: "Market section",
    value: (ticket) =>
      ticket.vendorId === null
        ? ticket.marketSectionName
        : ticket.businessSnapshot?.marketSectionName || UNAVAILABLE,
  },
  { key: "status", header: "Status", value: (ticket) => ticket.status || "—" },
  {
    key: "penaltyType",
    header: "Penalty",
    value: (ticket) => formatPenaltyType(ticket.penaltyType),
  },
  {
    key: "severity",
    header: "Severity",
    value: (ticket) => ticket.severity || "—",
  },
  {
    key: "issuedAt",
    header: "Issued at",
    value: (ticket) => formatDateTime(ticket.issuedAt),
  },
];
