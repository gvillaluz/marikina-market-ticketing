import type {
  PenaltyChangeReason,
  PenaltyType,
  TicketDetail,
} from "@/api/types/ticket.types";

/** The penalty choices in issue-form order, with the names shown when changing a penalty. */
export const PENALTY_CHOICES: { value: PenaltyType; label: string }[] = [
  { value: "CashFine", label: "Cash fine" },
  { value: "CommunityService", label: "Community service" },
  { value: "BloodDonation", label: "Blood donation" },
];

export const penaltyLabel = (type: PenaltyType | null | undefined) =>
  PENALTY_CHOICES.find((choice) => choice.value === type)?.label ?? "—";

export const PENALTY_CHANGE_REASONS: {
  value: PenaltyChangeReason;
  label: string;
}[] = [
  { value: "CannotPayCashFine", label: "Violator can't pay the cash fine" },
  {
    value: "RequestedDifferentPenalty",
    label: "Violator asked for a different penalty",
  },
  { value: "WrongPenaltyAtIssue", label: "Wrong penalty chosen when issuing" },
];

/** Open tickets with no receipt or service hours yet; the server makes the final check. */
export function canChangePenalty(ticket: TicketDetail | undefined): boolean {
  if (!ticket || ticket.type !== "Ticket") return false;
  if (ticket.status !== "Pending" && ticket.status !== "Overdue") return false;
  const proofs = Array.isArray(ticket.proofUrls)
    ? ticket.proofUrls
    : ticket.ticketReceipts;
  const hasProof = (proofs ?? []).some(
    (proof) => typeof proof === "string" && proof.trim() !== "",
  );
  return !hasProof && (ticket.communityServiceLogs ?? []).length === 0;
}

export function getTicketBusinessType(
  value: unknown,
): "Public" | "Private" | null {
  if (value === 0) return "Public";
  if (value === 1) return "Private";
  if (typeof value !== "string") return null;
  const normalized = value.trim().toLowerCase();
  if (normalized === "public") return "Public";
  if (normalized === "private") return "Private";
  return null;
}

export function getTicketTotalFineAmount(
  ticket: TicketDetail | undefined,
): number | null {
  const amounts = [ticket?.totalFineDue, ticket?.totalFineAmount];
  return (
    amounts.find(
      (amount): amount is number =>
        typeof amount === "number" && Number.isFinite(amount) && amount >= 0,
    ) ?? null
  );
}

export function formatPenaltyType(type: string | null | undefined): string {
  if (!type) return "—";
  return type.replace(/([a-z])([A-Z])/g, "$1 $2");
}

export function getTicketProofUrl(value: unknown): string | null {
  if (typeof value !== "string" || !value.trim()) return null;
  try {
    const url = new URL(value);
    return url.protocol === "https:" || url.protocol === "http:" ? value : null;
  } catch {
    return null;
  }
}

export function getTicketReceiptUrls(
  ticket: TicketDetail | undefined,
): string[] {
  const proofs = Array.isArray(ticket?.proofUrls)
    ? ticket.proofUrls
    : ticket?.ticketReceipts;
  return Array.isArray(proofs)
    ? proofs.filter((proof) => getTicketProofUrl(proof) !== null)
    : [];
}
