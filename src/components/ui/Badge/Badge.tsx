import styles from './Badge.module.css';
 
export type BadgeTone = 'warning' | 'ticket' | 'success' | 'neutral';
 
interface BadgeProps {
  tone: BadgeTone;
  children: React.ReactNode;
}
 
export function Badge({ tone, children }: BadgeProps) {
  return <span className={`${styles.badge} ${styles[tone]}`}>{children}</span>;
}
 