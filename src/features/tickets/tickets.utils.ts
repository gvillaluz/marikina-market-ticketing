import type { TicketDetail } from "@/api/types/ticket.types";

export function getTicketTotalFineAmount(
  ticket: TicketDetail | undefined,
): number | null {
  const amounts = [
    ticket?.totalFineAmount,
    ticket?.totalFineDue,
    ticket?.totalPaymentAmount,
  ];
  return (
    amounts.find(
      (amount): amount is number => typeof amount === "number" && amount > 0,
    ) ?? null
  );
}

export function formatPenaltyType(type: string | null | undefined): string {
  if (!type) return "—";
  return type.replace(/([a-z])([A-Z])/g, "$1 $2");
}
