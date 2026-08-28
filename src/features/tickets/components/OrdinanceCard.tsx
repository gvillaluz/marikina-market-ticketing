import styles from './OrdinanceCard.module.css';

type OrdinanceCardProps = {
    title: string;
    subtitle: string;
    offense: string;
    price: string;
}

function OrdinanceCard({ title, subtitle, offense, price }: OrdinanceCardProps) {
    return (
        <div className={styles.card}>
            <div className={styles.info}>
                <div className={styles.titleRow}>
                    <span className={styles.title}>{title}</span>
                    <span className={styles.offenseBadge}>{offense}</span>
                </div>
                <span className={styles.subtitle}>{subtitle}</span>
            </div>
            <span className={styles.price}>{price}</span>
        </div>
    );
}

export default OrdinanceCard;