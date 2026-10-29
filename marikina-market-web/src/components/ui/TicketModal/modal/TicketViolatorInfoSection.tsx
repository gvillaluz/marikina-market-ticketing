import { User } from "lucide-react";
import TicketInfoRow from "./TicketInfoRow";
import TicketSectionHeader from "./TicketSectionHeader";
import styles from "./TicketViolatorInfoSection.module.css";
import { TicketDetail } from "@/api/types/ticket.types";
import { getTicketBusinessType } from "@/features/tickets";

function TicketViolationInfoSection({ detail }: { detail?: TicketDetail }) {
  const businessType = getTicketBusinessType(detail?.businessType);
  const vendorName =
    [detail?.lastName, detail?.firstName]
      .filter((name) => typeof name === "string" && name.trim())
      .join(", ") || "\u2014";
  return (
    <>
      <TicketSectionHeader title={"VIOLATOR DETAILS"} icon={User} />
      <section
        className={`${styles.infoSection} ${businessType === "Private" ? styles.private : ""}`}
      >
        <TicketInfoRow
          label="BUSINESS ID:"
          value={
            typeof detail?.businessAccountNumber === "string" && detail.businessAccountNumber.trim()
              ? detail.businessAccountNumber
              : "\u2014"
          }
        />
        <TicketInfoRow label="VENDOR TYPE:" value={businessType || "\u2014"} />
        <TicketInfoRow
          label="TRADE NAME:"
          value={detail?.businessName || "\u2014"}
        />
        {businessType !== "Private" && (
          <TicketInfoRow
            label="STALL/UNIT NO:"
            value={detail?.stallNumber || "\u2014"}
          />
        )}
        <TicketInfoRow label="REGISTERED OWNER:" value={detail?.registeredOwnerName || vendorName} />
        {detail?.type === "Ticket" && <>
          <TicketInfoRow label="RECORDED VIOLATOR:" value={detail.paperViolatorName || "Unconfirmed (legacy record)"} />
          <TicketInfoRow label="CONFIRMED PERSON:" value={detail.personId ? `${detail.personFullName || "Person"} · Person ${detail.personId}` : "Unconfirmed (legacy record)"} />
        </>}
        <TicketInfoRow label="ADDRESS:" value={detail?.address || "\u2014"} />
      </section>
    </>
  );
}

export default TicketViolationInfoSection;
