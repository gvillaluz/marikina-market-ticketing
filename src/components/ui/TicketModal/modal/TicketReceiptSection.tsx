import type { TicketSettlementPhoto } from "@/features/tickets";
import TicketSettlementGallery from "./TicketSettlementGallery";
import styles from "./TicketReceiptSection.module.css";
import TicketAttachmentHeader from "./TicketAttachmentHeader";

export default function TicketReceiptSection({
  photos,
}: {
  photos: TicketSettlementPhoto[];
}) {
  return (
    <section className={styles.section} aria-label="Settlement Receipt">
      <TicketAttachmentHeader
        title="Settlement Receipt"
        subtitle="Official receipt submitted as proof of settlement."
      />
      <TicketSettlementGallery photos={photos} variant="receipt" />
    </section>
  );
}
