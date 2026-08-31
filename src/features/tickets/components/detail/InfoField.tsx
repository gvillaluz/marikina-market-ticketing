import { FC, ReactNode } from 'react';
import styles from './InfoField.module.css';

interface InfoFieldProps {
  label: string;
  value: ReactNode;
  span?: number;
}

const InfoField: FC<InfoFieldProps> = ({ label, value, span }) => {
  return (
    <div className={styles.field} style={span ? { gridColumn: `span ${span}` } : undefined}>
      <span className={styles.label}>{label}</span>
      <div className={styles.value}>{value}</div>
    </div>
  );
};

export default InfoField;