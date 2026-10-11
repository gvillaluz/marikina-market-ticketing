import { useEffect, useState } from "react";
import { RecordStatus } from "@/api/types/common.types";
import { TicketDetail } from "@/api/types/ticket.types";

export function useTicketStatusSelection(ticket: TicketDetail | undefined) {
  const [selectedStatus, setSelectedStatus] = useState<
    RecordStatus | undefined
  >(undefined);

  useEffect(() => {
    if (ticket) {
      setSelectedStatus(ticket.status);
    }
  }, [ticket?.ticketId, ticket?.status]);

  const proofs = Array.isArray(ticket?.proofUrls)
    ? ticket.proofUrls
    : ticket?.ticketReceipts;
  const receiptUrls = Array.isArray(proofs)
    ? proofs.filter((proof) => {
        if (typeof proof !== "string" || !proof.trim()) return false;
        try {
          const url = new URL(proof);
          return url.protocol === "https:" || url.protocol === "http:";
        } catch {
          return false;
        }
      })
    : [];
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
  const availableStatuses: RecordStatus[] = [
    "Pending",
    "Contested",
    "Waived",
    "Overdue",
    "InProgress",
  ];
  if (canSettle) availableStatuses.push("Paid", "Cleared");
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
    selectedStatus: currentSelection,
    setSelectedStatus: (status: RecordStatus) => {
      if (availableStatuses.includes(status)) setSelectedStatus(status);
    },
    availableStatuses,
    canUpdateStatus,
    receiptUrls,
  };
}
