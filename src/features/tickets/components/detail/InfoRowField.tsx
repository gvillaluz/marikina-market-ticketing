import { ReactNode } from 'react';
import styles from './InfoRowField.module.css';

interface InfoRowProps {
    label: string,
    value: ReactNode
}

function InfoRowField({ label, value }: InfoRowProps) {
    return <div className={styles.field}>
        <span className={styles.label}>{label}</span>
        <div className={styles.value}>{value}</div>
    </div>
}

export default InfoRowField;