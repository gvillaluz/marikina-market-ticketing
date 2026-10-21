import type { FC, ReactNode } from 'react';
import styles from './Card.module.css';

interface CardProps {
  children: ReactNode;
  className?: string;
  id?: string;
  'aria-label'?: string;
}

const Card: FC<CardProps> = ({ children, className = '', id, 'aria-label': ariaLabel }) => (
  <section id={id} aria-label={ariaLabel} className={`${styles.card} ${className}`}>{children}</section>
);

export default Card;