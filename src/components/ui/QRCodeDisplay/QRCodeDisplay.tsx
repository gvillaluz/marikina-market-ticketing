import { FC } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import styles from './QRCodeDisplay.module.css';

interface QRCodeDisplayProps {
  value: string;
  size?: number;
  label?: string;
  showValue?: boolean;
}

const QRCodeDisplay: FC<QRCodeDisplayProps> = ({
  value,
  size = 160,
  label,
  showValue = false,
}) => {
  return (
    <div className={styles.container}>
      <div className={styles.qr}>
        <QRCodeSVG value={value} size={size} level="M" fgColor="#1e222b" bgColor="#ffffff" />
      </div>
      {label && <p className={styles.label}>{label}</p>}
      {showValue && <p className={styles.value}>{value}</p>}
    </div>
  );
};

export default QRCodeDisplay;
