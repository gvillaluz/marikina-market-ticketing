import { FC } from 'react';
import { ImageOff } from 'lucide-react';
import styles from './EvidenceThumbnail.module.css';

interface EvidenceThumbnailProps {
  caption: string;
}

const EvidenceThumbnail: FC<EvidenceThumbnailProps> = ({ caption }) => {
  return (
    <div className={styles.wrapper}>
      <div className={styles.placeholder}>
        <ImageOff size={16} strokeWidth={1.8} className={styles.placeholderIcon} />
        <span>{caption}</span>
      </div>
    </div>
  );
};

export default EvidenceThumbnail;