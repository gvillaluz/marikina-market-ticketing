import styles from './TicketSignatureSection.module.css';

interface TicketSignatureProps {
    enforcerName: string;
    vendorName: string
}

function TicketSignatureSection({ enforcerName, vendorName }: TicketSignatureProps) {
    return (
        <section className={styles.signatureSection}>
            <div className={styles.signatureBlock}>
                <span className={styles.nameValue}>{enforcerName}</span>
                <div className={styles.line} />
                <span className={styles.name}>Market Officer</span>
                <span className={styles.caption}>Issued by</span>
            </div>
            <div className={styles.signatureBlock}>
                <span className={styles.nameValue}>{vendorName}</span>
                <div className={styles.line} />
                <span className={styles.name}>Market Vendor</span>
                <span className={styles.caption}>Received by • August 14, 2025</span>
            </div>
        </section>
    );
}

export default TicketSignatureSection;