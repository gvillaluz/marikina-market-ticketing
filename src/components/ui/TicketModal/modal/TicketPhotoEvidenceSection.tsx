import TicketEvidenceGallery from '@/components/ui/PhotoGallery/TicketEvidenceGallery';
import styles from './TicketPhotoEvidenceSection.module.css';

function TicketPhotoEvidenceSection({ images }: { images: string[] }) {
    const formattedImages = images.map(
        (image) => `https://localhost:5001/${image}`);

    return (
        <section className={styles.photoSection}>
            <h5 className={styles.title}>Photo Evidence Record</h5>
            <p className={styles.subtitle}>
                The image below serves as the photo evidence attached to this violation ticket.
            </p>
            <TicketEvidenceGallery images={formattedImages} />
        </section>
    );
}

export default TicketPhotoEvidenceSection;