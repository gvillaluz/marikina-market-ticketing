import { FC } from 'react';
import styles from './StatusOptionCard.module.css';

interface StatusOptionCardProps {
  title: string;
  description: string;
  selected: boolean;
  onClick: () => void;
}

const StatusOptionCard: FC<StatusOptionCardProps> = ({ title, description, selected, onClick }) => {
  return (
    <button
      type="button"
      className={`${styles.card} ${selected ? styles.selected : ''}`}
      onClick={onClick}
      aria-pressed={selected}
    >
      <span className={styles.title}>{title}</span>
      <span className={styles.description}>{description}</span>
    </button>
  );
};

export default StatusOptionCard;