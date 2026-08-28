import styles from './TicketSignatureSection.module.css';

function TicketSignatureSection() {
    return (
        <section className={styles.signatureSection}>
            <div className={styles.signatureBlock}>
                <div className={styles.line} />
                <span className={styles.name}>Market Officer</span>
                <span className={styles.caption}>Issued by</span>
            </div>
            <div className={styles.signatureBlock}>
                <div className={styles.line} />
                <span className={styles.name}>Market Vendor</span>
                <span className={styles.caption}>Received by • August 14, 2025</span>
            </div>
        </section>
    );
}

export default TicketSignatureSection;