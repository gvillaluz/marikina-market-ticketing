import { User } from "lucide-react";
import TicketInfoRow from "./TicketInfoRow";
import TicketSectionHeader from "./TicketSectionHeader";
import styles from "./TicketViolatorInfoSection.module.css";
import { TicketDetail } from "@/api/types/ticket.types";
import { getTicketVendorType } from "@/features/tickets";

function TicketViolationInfoSection({ detail }: { detail?: TicketDetail }) {
  const vendorType = getTicketVendorType(detail?.vendorType);
  const vendorName =
    [detail?.lastName, detail?.firstName]
      .filter((name) => typeof name === "string" && name.trim())
      .join(", ") || "\u2014";
  return (
    <>
      <TicketSectionHeader title={"VIOLATOR DETAILS"} icon={User} />
      <section
        className={`${styles.infoSection} ${vendorType === "Private" ? styles.private : ""}`}
      >
        <TicketInfoRow
          label="BUSINESS ID:"
          value={
            typeof detail?.businessId === "string" && detail.businessId.trim()
              ? detail.businessId
              : "\u2014"
          }
        />
        <TicketInfoRow label="VENDOR TYPE:" value={vendorType || "\u2014"} />
        <TicketInfoRow
          label="TRADE NAME:"
          value={detail?.businessName || "\u2014"}
        />
        {vendorType !== "Private" && (
          <TicketInfoRow
            label="STALL/UNIT NO:"
            value={detail?.stallNumber || "\u2014"}
          />
        )}
        <TicketInfoRow label="NAME:" value={vendorName} />
        <TicketInfoRow label="ADDRESS:" value={detail?.address || "\u2014"} />
      </section>
    </>
  );
}

export default TicketViolationInfoSection;
