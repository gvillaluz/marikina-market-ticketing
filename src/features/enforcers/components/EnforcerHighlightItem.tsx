import { FC } from 'react';
import { AlertTriangle } from 'lucide-react';
import styles from './EnforcerHighlightItem.module.css';

interface EnforcerHighlightItemProps {
  name: string;
  note: string;
}

const EnforcerHighlightItem: FC<EnforcerHighlightItemProps> = ({ name, note }) => {
  return (
    <div className={styles.item}>
      <div className={styles.iconContainer}>
        <AlertTriangle className={styles.icon} size={18} strokeWidth={2} />
      </div>
      <div className={styles.text}>
        <span className={styles.name}>{name}</span>
        <span className={styles.note}>{note}</span>
      </div>
    </div>
  );
};

export default EnforcerHighlightItem;