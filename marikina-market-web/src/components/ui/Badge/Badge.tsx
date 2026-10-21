import styles from './Badge.module.css';
 
export type BadgeTone = 'warning' | 'ticket' | 'success' | 'neutral';
 
interface BadgeProps {
  tone: BadgeTone;
  children: React.ReactNode;
  className?: string;
}
 
export function Badge({ tone, children, className = '' }: BadgeProps) {
  return <span className={`${styles.badge} ${styles[tone]} ${className}`}>{children}</span>;
}
 