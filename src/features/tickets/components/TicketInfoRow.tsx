import styles from './TicketInfoRow.module.css';

type InfoRowProps = {
    label: string,
    value: React.ReactNode
}

function TicketInfoRow({ label, value }: InfoRowProps) {
    return <div className={styles.row}>
        <span className={styles.rowLabel}>{label}</span>
        <div className={styles.rowValue}>
            {value}
        </div>
    </div>
}

export default TicketInfoRow;