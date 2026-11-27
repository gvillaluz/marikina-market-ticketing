import { useEffect, useState } from "react";
import { RecordStatus } from "@/api/types/common.types";
import { PenaltyType, TicketDetail } from "@/api/types/ticket.types";
import { getTicketReceiptUrls } from "../tickets.utils";

// Statuses an administrator may choose per Penalty Type (#161). The server enforces the same table.
const PENALTY_STATUSES: Record<PenaltyType, RecordStatus[]> = {
  CashFine: ["Contested", "Waived", "Paid"],
  BloodDonation: ["Contested", "Waived", "Cleared"],
  CommunityService: ["Contested", "Waived", "InProgress", "Cleared"],
};

export function useTicketStatusSelection(ticket: TicketDetail | undefined) {
  const [selectedStatus, setSelectedStatus] = useState<
    RecordStatus | undefined
  >(undefined);

  useEffect(() => {
    if (ticket) {
      setSelectedStatus(ticket.status);
    }
  }, [ticket?.ticketId, ticket?.status]);

  const receiptUrls = getTicketReceiptUrls(ticket);
  const required = ticket?.communityServiceHours;
  const completed = ticket?.hoursCompleted;
  const serviceCompleted =
    typeof required === "number" &&
    Number.isFinite(required) &&
    required > 0 &&
    typeof completed === "number" &&
    Number.isFinite(completed) &&
    completed >= required;
  const canSettle =
    ticket?.penaltyType === "CommunityService"
      ? serviceCompleted
      : (ticket?.penaltyType === "CashFine" ||
          ticket?.penaltyType === "BloodDonation") &&
        receiptUrls.length > 0;
  const penaltyStatuses: RecordStatus[] = ticket?.penaltyType
    ? (PENALTY_STATUSES[ticket.penaltyType] ?? [])
    : [];
  const availableStatuses = penaltyStatuses.filter(
    (status) => canSettle || (status !== "Paid" && status !== "Cleared"),
  );
  // Reject contest: the window sends Pending and the server picks Pending or Overdue.
  if (ticket?.status === "Contested") availableStatuses.unshift("Pending");
  const validSelection =
    selectedStatus !== undefined && availableStatuses.includes(selectedStatus);
  const currentSelection = validSelection ? selectedStatus : ticket?.status;
  const canUpdateStatus = Boolean(
    ticket &&
    validSelection &&
    currentSelection !== ticket.status &&
    Number.isSafeInteger(ticket.version) &&
    ticket.version >= 0 &&
    ticket.version <= 0xffffffff,
  );

  return {
    resetSelection: () => setSelectedStatus(ticket?.status),
    selectedStatus: currentSelection,
    setSelectedStatus: (status: RecordStatus) => {
      if (availableStatuses.includes(status)) setSelectedStatus(status);
    },
    availableStatuses,
    canUpdateStatus,
    receiptUrls,
  };
}
