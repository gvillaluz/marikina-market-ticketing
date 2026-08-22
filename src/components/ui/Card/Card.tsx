import type { FC, ReactNode } from 'react';
import styles from './Card.module.css';

interface CardProps { children: ReactNode; className?: string; id?: string }

const Card: FC<CardProps> = ({ children, className = '', id }) => (
  <section id={id} className={`${styles.card} ${className}`}>{children}</section>
);

export default Card;