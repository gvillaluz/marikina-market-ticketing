import { History } from 'lucide-react';
import styles from './OrdinanceCard.module.css';

type OrdinanceCardProps = {
    title: string;
    subtitle: string;
    offense: string;
    price: string;
}

function OrdinanceCard({ title, subtitle, offense, price }: OrdinanceCardProps) {
    const offenseNum = typeof offense === 'string' ? Number.parseInt(offense, 10) : offense;

    const getSeverityClass = () => {
        if (offenseNum <= 1) return styles.minor;
        if (offenseNum === 2) return styles.moderate;
        return styles.high;
    };

    return (
        <div className={styles.card}>
            <div className={styles.info}>
                <span className={styles.title}>{title}</span>
                <span className={styles.subtitle}>{subtitle}</span>
            </div>
            <div className={styles.priceRow}>
                <div className={`${styles.offenseContainer} ${getSeverityClass()}`}>
                    <History size={17} />
                    <span className={styles.offenseBadge}>{`${offense} offense`}</span>
                </div>
                <span className={styles.price}>{price}</span>
            </div>
        </div>
    );
}

export default OrdinanceCard;