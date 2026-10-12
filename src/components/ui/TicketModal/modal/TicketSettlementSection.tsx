import type { TicketDetail } from "@/api/types/ticket.types";
import { useTicketSettlement } from "@/features/tickets";
import TicketReceiptSection from "./TicketReceiptSection";
import TicketCommunityServiceSection from "./TicketCommunityServiceSection";

export default function TicketSettlementSection({
  ticket,
}: {
  ticket: TicketDetail;
}) {
  const settlement = useTicketSettlement(ticket);
  if (settlement.kind === "receipt")
    return <TicketReceiptSection photos={settlement.receipts} />;
  if (settlement.kind === "service")
    return <TicketCommunityServiceSection settlement={settlement} />;
  return null;
}
