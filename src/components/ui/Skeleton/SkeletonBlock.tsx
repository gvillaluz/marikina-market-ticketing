import { FC } from 'react';
import styles from './SkeletonBlock.module.css';

interface SkeletonBlockProps {
  width?: string;
  height?: string;
  radius?: string;
}

// Generic shimmering placeholder rectangle. Compose these to mimic the shape
// of whatever real content is loading — see TicketDetailSkeleton for usage.
const SkeletonBlock: FC<SkeletonBlockProps> = ({ width = '100%', height = '14px', radius = '4px' }) => {
  return (
    <span
      className={styles.block}
      style={{ width, height, borderRadius: radius }}
      aria-hidden="true"
    />
  );
};

export default SkeletonBlock;