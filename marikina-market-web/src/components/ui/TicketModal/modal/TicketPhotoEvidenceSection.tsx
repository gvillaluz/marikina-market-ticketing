import TicketPhotoEvidenceGroup from "./TicketPhotoEvidenceGroup";
import styles from "./TicketPhotoEvidenceSection.module.css";
import type { TicketEvidenceItem } from "@/api/types/ticket.types";

interface EvidenceGroup {
  label: string;
  images: string[];
  large: boolean;
}

function sortedUrls(items: TicketEvidenceItem[]) {
  return [...items].sort((a, b) => (a.sortOrder ?? 0) - (b.sortOrder ?? 0) || a.id - b.id).map(item => item.url);
}

function buildGroups(images: string[], evidenceItems: TicketEvidenceItem[], isTicket: boolean): EvidenceGroup[] {
  if (evidenceItems.length === 0) return [{ label: "Unclassified evidence", images, large: false }];
  const paper = evidenceItems.filter(item => item.role === "PaperTicket");
  if (!isTicket) return [{ label: "Paper warning", images: sortedUrls(paper), large: true }];
  const supporting = evidenceItems.filter(item => item.role === "Supporting");
  const other = evidenceItems.filter(item => item.role !== "PaperTicket" && item.role !== "Supporting");
  return [
    { label: "Paper ticket", images: sortedUrls(paper), large: true },
    { label: "Supporting evidence", images: sortedUrls(supporting), large: false },
    { label: "Unclassified evidence", images: sortedUrls(other), large: false },
  ].filter(group => group.images.length > 0);
}

function TicketPhotoEvidenceSection({ images, evidenceItems = [], isTicket = true }: { images: string[]; evidenceItems?: TicketEvidenceItem[]; isTicket?: boolean }) {
  const groups = buildGroups(images, evidenceItems, isTicket);
  return (
    <section className={styles.photoSection}>
      <h5 className={styles.title}>{isTicket ? "Ticket Photos" : "Warning Photos"}</h5>
      <p className={styles.subtitle}>
        {isTicket ? "The scanned paper ticket and any supporting photos." : "Photos attached to this warning."}
      </p>
      <div className={`${styles.layout} ${groups.length === 1 ? styles.single : ""}`}>
        {groups.map(group => <TicketPhotoEvidenceGroup key={group.label} {...group} />)}
      </div>
    </section>
  );
}

export default TicketPhotoEvidenceSection;
