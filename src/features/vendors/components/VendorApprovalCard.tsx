import { FC, useState } from 'react';
import StatusBadge from '@/components/ui/StatusBadge';
import Button from '@/components/ui/Button';
import useVendorApproval from '@/features/vendors/hooks/useVendorApproval';
import type { Vendor } from '@/api/types/vendor.types';
import styles from './VendorApprovalCard.module.css';

interface VendorApprovalCardProps {
  vendor: Vendor;
  onAction: (updated: Vendor) => void;
}

/** Admin-only card for pending vendor approvals. */
const VendorApprovalCard: FC<VendorApprovalCardProps> = ({ vendor, onAction }) => {
  const { act, loading } = useVendorApproval();

  const handleAction = async (status: 'approved' | 'rejected' | 'suspended') => {
    const updated = await act(vendor.id, status);
    onAction(updated);
  };

  return (
    <div className={styles.card}>
      <div className={styles.top}>
        <div className={styles.avatar}>{vendor.businessName.charAt(0)}</div>
        <div className={styles.info}>
          <h4 className={styles.name}>{vendor.businessName}</h4>
          <p className={styles.sub}>{vendor.category} · {vendor.barangay}</p>
        </div>
        <StatusBadge status={vendor.status} />
      </div>

      <div className={styles.meta}>
        <span>👤 {vendor.contactPerson}</span>
        <span>📧 {vendor.email}</span>
        <span>📞 {vendor.phone}</span>
      </div>

      <div className={styles.actions}>
        <Button
          variant="success"
          size="sm"
          loading={loading}
          onClick={() => handleAction('approved')}
        >
          Approve
        </Button>
        <Button
          variant="outline"
          size="sm"
          onClick={() => handleAction('suspended')}
          disabled={loading}
        >
          Suspend
        </Button>
        <Button
          variant="danger"
          size="sm"
          onClick={() => handleAction('rejected')}
          disabled={loading}
        >
          Reject
        </Button>
      </div>
    </div>
  );
};

export default VendorApprovalCard;
