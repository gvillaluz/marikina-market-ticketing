import { FC } from 'react';
import StatusBadge from '@/components/ui/StatusBadge';
import { CATEGORY_LABELS } from '@/utils/constants';
import { formatDate } from '@/utils/formatters';
import type { Vendor } from '@/api/types/vendor.types';
import styles from './VendorProfile.module.css';

interface VendorProfileProps {
  vendor: Vendor;
}

const VendorProfile: FC<VendorProfileProps> = ({ vendor }) => {
  return (
    <div className={styles.profile}>
      <div className={styles.header}>
        <div className={styles.avatar}>
          {vendor.businessName.charAt(0)}
        </div>
        <div>
          <h2 className={styles.name}>{vendor.businessName}</h2>
          <p className={styles.owner}>Owner: {vendor.contactPerson}</p>
        </div>
        <StatusBadge status={vendor.status} />
      </div>

      <div className={styles.details}>
        <Detail label="Category" value={CATEGORY_LABELS[vendor.category]} />
        <Detail label="Address" value={`${vendor.address}`} />
        <Detail label="Barangay" value={vendor.barangay} />
        <Detail label="Email" value={vendor.email} />
        <Detail label="Phone" value={vendor.phone} />
        <Detail label="Registration Date" value={formatDate(vendor.registrationDate)} />
        <Detail label="Permit Expiry" value={vendor.expiryDate ? formatDate(vendor.expiryDate) : '—'} />
        <Detail label="QR Code" value={vendor.qrCode} />
      </div>
    </div>
  );
};

const Detail: FC<{ label: string; value: string }> = ({ label, value }) => (
  <div className={styles.detail}>
    <span className={styles.label}>{label}</span>
    <span className={styles.value}>{value}</span>
  </div>
);

export default VendorProfile;
