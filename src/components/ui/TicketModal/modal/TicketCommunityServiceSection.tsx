import type { TicketSettlementModel } from "@/features/tickets";
import { formatNumber } from "@/utils/formatters";
import TicketSettlementGallery from "./TicketSettlementGallery";
import styles from "./TicketCommunityServiceSection.module.css";
import TicketAttachmentHeader from "./TicketAttachmentHeader";

export default function TicketCommunityServiceSection({
  settlement,
}: {
  settlement: TicketSettlementModel;
}) {
  const { completed, required, percentage } = settlement;
  return (
    <section className={styles.section} aria-label="Community Service Log">
      <TicketAttachmentHeader
        title="Community Service Log"
        subtitle="Service hours completed by this vendor."
      />
      <div className={styles.progressPanel}>
        <div className={styles.summary}>
          <h4>Completion Progress</h4>
          <span>
            {completed !== null && required !== null && required > 0
              ? `${formatNumber(completed)} of ${formatNumber(required)} hrs completed`
              : "Progress unavailable"}
          </span>
        </div>
        {percentage !== null && (
          <progress
            className={styles.progress}
            value={percentage}
            max={100}
            aria-label="Community service completion"
          />
        )}
        <div className={styles.summary}>
          <span>
            {completed !== null
              ? `${formatNumber(completed)} hrs logged`
              : "Completed hours unavailable"}
          </span>
          {percentage !== null && required !== null && (
            <span>
              {formatNumber(Math.round(percentage))}% of{" "}
              {formatNumber(required)} hrs
            </span>
          )}
        </div>
      </div>
      <TicketSettlementGallery photos={settlement.logs} variant="service" />
    </section>
  );
}
