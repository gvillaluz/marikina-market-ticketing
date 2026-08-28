import styles from './TicketPhotoEvidenceSection.module.css';

function TicketPhotoEvidenceSection() {
    return (
        <section className={styles.photoSection}>
            <h5 className={styles.title}>Photo Evidence Record</h5>
            <p className={styles.subtitle}>
                The image below serves as the photo evidence attached to this violation ticket.
            </p>
            <div className={styles.thumbnail}>
                {/* static placeholder — swap with actual evidence image */}
            </div>
        </section>
    );
}

export default TicketPhotoEvidenceSection;