import styles from './TicketDetailRow.module.css';

type DetailRowProps = {
    label: string;
    value: React.ReactNode;
}

function TicketDetailRow({ label, value }: DetailRowProps) {
    return (
        <div className={styles.row}>
            <span className={styles.label}>{label}</span>
            <span className={styles.value}>{value}</span>
        </div>
    );
}

export default TicketDetailRow;