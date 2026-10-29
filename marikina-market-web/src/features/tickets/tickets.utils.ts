import type { TicketDetail } from "@/api/types/ticket.types";

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
