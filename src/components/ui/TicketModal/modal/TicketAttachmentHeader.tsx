import styles from "./TicketAttachmentHeader.module.css";

export default function TicketAttachmentHeader({
  title,
  subtitle,
}: {
  title: string;
  subtitle: string;
}) {
  return (
    <header className={styles.header}>
      <h3 className={styles.title}>{title}</h3>
      <p className={styles.subtitle}>{subtitle}</p>
    </header>
  );
}
