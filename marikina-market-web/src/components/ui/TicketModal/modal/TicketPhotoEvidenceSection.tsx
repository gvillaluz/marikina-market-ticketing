import TicketEvidenceGallery from "@/components/ui/PhotoGallery/TicketEvidenceGallery";
import styles from "./TicketPhotoEvidenceSection.module.css";
import type { TicketEvidenceItem } from "@/api/types/ticket.types";

function TicketPhotoEvidenceSection({ images, evidenceItems = [], isTicket = true }: { images: string[]; evidenceItems?: TicketEvidenceItem[]; isTicket?: boolean }) {
  const groups = !isTicket ? [{ label: "Photo evidence", images }]
    : evidenceItems.length === 0 ? [{ label: "Unclassified evidence", images }]
      : (["PaperTicket", "Supporting", null] as const).map(role => ({
        label: role === "PaperTicket" ? "Paper ticket photo" : role === "Supporting" ? "Supporting evidence" : "Unclassified evidence",
        images: evidenceItems.filter(item => role === null ? item.role !== "PaperTicket" && item.role !== "Supporting" : item.role === role)
          .sort((a, b) => (a.sortOrder ?? 0) - (b.sortOrder ?? 0) || a.id - b.id).map(item => item.url),
      })).filter(group => group.images.length > 0);
  return (
    <section className={styles.photoSection}>
      <h5 className={styles.title}>Photo Evidence Record</h5>
      <p className={styles.subtitle}>
        {isTicket ? "Paper ticket and supporting photos are shown by their saved classification." : "Photos attached to this warning."}
      </p>
      {groups.map(group => <div key={group.label} className={styles.group}>
        <h6 className={styles.title}>{group.label}</h6>
        <TicketEvidenceGallery images={group.images} />
      </div>)}
    </section>
  );
}

export default TicketPhotoEvidenceSection;
