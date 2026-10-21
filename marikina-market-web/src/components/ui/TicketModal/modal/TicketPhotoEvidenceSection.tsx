import TicketEvidenceGallery from "@/components/ui/PhotoGallery/TicketEvidenceGallery";
import styles from "./TicketPhotoEvidenceSection.module.css";

function TicketPhotoEvidenceSection({ images }: { images: string[] }) {
  return (
    <section className={styles.photoSection}>
      <h5 className={styles.title}>Photo Evidence Record</h5>
      <p className={styles.subtitle}>
        The image below serves as the photo evidence attached to this violation
        ticket.
      </p>
      <TicketEvidenceGallery images={images} />
    </section>
  );
}

export default TicketPhotoEvidenceSection;
