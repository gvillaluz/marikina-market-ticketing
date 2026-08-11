import { FC } from 'react';
import QRCodeDisplay from '@/components/ui/QRCodeDisplay';
import type { Vendor } from '@/api/types/vendor.types';
import styles from './VendorQRCode.module.css';

interface VendorQRCodeProps {
  vendor: Vendor;
}

const VendorQRCode: FC<VendorQRCodeProps> = ({ vendor }) => {
  return (
    <div className={styles.card}>
      <h3 className={styles.title}>Vendor QR Code</h3>
      <QRCodeDisplay
        value={vendor.qrCode}
        label={vendor.businessName}
        showValue
      />
      <p className={styles.hint}>
        Scan to verify this vendor&apos;s registration and compliance status.
      </p>
    </div>
  );
};

export default VendorQRCode;
