import type { TicketDetail } from "@/api/types/ticket.types";
import { getTicketProofUrl, getTicketReceiptUrls } from "../tickets.utils";

export interface TicketSettlementPhoto {
  key: string;
  url: string | null;
  date: string | null;
  hours: number | null;
}

function validHours(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) && value >= 0
    ? value
    : null;
}

export function useTicketSettlement(ticket: TicketDetail | undefined) {
  const kind =
    ticket?.type !== "Ticket"
      ? null
      : ticket.penaltyType === "CommunityService"
        ? "service"
        : ticket.penaltyType === "CashFine" ||
            ticket.penaltyType === "BloodDonation"
          ? "receipt"
          : null;
  const receipts: TicketSettlementPhoto[] = getTicketReceiptUrls(ticket).map(
    (url, index) => ({
      key: `receipt-${index}`,
      url,
      date: null,
      hours: null,
    }),
  );
  const logs: TicketSettlementPhoto[] = Array.isArray(
    ticket?.communityServiceLogs,
  )
    ? ticket.communityServiceLogs
        .filter((log) => log && typeof log === "object")
        .map((log, index) => ({
          key: `service-${index}`,
          url: getTicketProofUrl(log.proofUrl),
          date:
            typeof log.serviceDate === "string" &&
            Number.isFinite(Date.parse(log.serviceDate))
              ? log.serviceDate
              : null,
          hours: validHours(log.hoursWorked),
        }))
    : [];
  const required = validHours(ticket?.communityServiceHours);
  const completed = validHours(ticket?.hoursCompleted);
  const percentage =
    required !== null && required > 0 && completed !== null
      ? Math.min(100, (completed / required) * 100)
      : null;
  return { kind, receipts, logs, required, completed, percentage };
}

export type TicketSettlementModel = ReturnType<typeof useTicketSettlement>;
