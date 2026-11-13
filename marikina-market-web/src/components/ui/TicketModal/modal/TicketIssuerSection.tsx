import { formatDate } from "@/utils/formatters";
import styles from "./TicketIssuerSection.module.css";

interface TicketIssuerSectionProps {
  enforcerName: string;
  issuedAt: string | Date;
}

function TicketIssuerSection({
  enforcerName,
  issuedAt,
}: TicketIssuerSectionProps) {
  return (
    <section className={styles.issuerSection}>
      <div className={styles.field}>
        <span className={styles.value}>{enforcerName}</span>
        <span className={styles.caption}>Issuing enforcer</span>
      </div>
      <div className={styles.field}>
        <span className={styles.value}>{formatDate(issuedAt)}</span>
        <span className={styles.caption}>Date issued</span>
      </div>
    </section>
  );
}

export default TicketIssuerSection;
