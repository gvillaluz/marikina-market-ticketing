import TicketEvidenceGallery from "@/components/ui/PhotoGallery/TicketEvidenceGallery";
import styles from "./TicketPhotoEvidenceGroup.module.css";

interface TicketPhotoEvidenceGroupProps {
  label: string;
  images: string[];
  large?: boolean;
}

function TicketPhotoEvidenceGroup({ label, images, large = false }: TicketPhotoEvidenceGroupProps) {
  return (
    <div className={styles.group}>
      <div className={styles.header}>
        <h6 className={styles.label}>{label}</h6>
        <span className={styles.count}>{images.length} {images.length === 1 ? "photo" : "photos"}</span>
      </div>
      <TicketEvidenceGallery images={images} large={large} />
    </div>
  );
}

export default TicketPhotoEvidenceGroup;
