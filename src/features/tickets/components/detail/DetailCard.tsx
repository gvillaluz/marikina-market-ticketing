import { FC, ReactNode } from 'react';
import { LucideIcon } from 'lucide-react';
import styles from './DetailCard.module.css';

interface DetailCardProps {
  title: string;
  icon: LucideIcon;
  children: ReactNode;
  full?: boolean;
  showDivider?: boolean;
  dashedBorder?: boolean;
}

const DetailCard: FC<DetailCardProps> = ({ title, icon: Icon, children, full, showDivider, dashedBorder }) => {
  return (
    <section className={`${styles.card} ${full ? styles.full : ''} ${dashedBorder ? styles.dashed : ''}`}>
      <div className={`${styles.header} ${showDivider ? styles.divider : ''}`}>
        <Icon className={styles.icon} size={13} strokeWidth={3} />
        <span className={styles.title}>{title}</span>
      </div>
      {children}
    </section>
  );
};

export default DetailCard;