import { FC } from "react";
import StatusBadge from "@/components/ui/StatusBadge";
import { CATEGORY_LABELS } from "@/utils/constants";
import { formatDate } from "@/utils/formatters";
import type { Vendor } from "@/api/types/vendor.types";
import VendorProfileDetail from "./VendorProfileDetail";
import styles from "./VendorProfile.module.css";

interface VendorProfileProps {
  vendor: Vendor;
}

const VendorProfile: FC<VendorProfileProps> = ({ vendor }) => {
  return (
    <div className={styles.profile}>
      <div className={styles.header}>
        <div className={styles.avatar}>{vendor.businessName.charAt(0)}</div>
        <div>
          <h2 className={styles.name}>{vendor.businessName}</h2>
          <p className={styles.owner}>Owner: {vendor.contactPerson}</p>
        </div>
        <StatusBadge status={vendor.status} />
      </div>

      <div className={styles.details}>
        <VendorProfileDetail
          label="Category"
          value={CATEGORY_LABELS[vendor.category]}
        />
        <VendorProfileDetail label="Address" value={`${vendor.address}`} />
        <VendorProfileDetail label="Barangay" value={vendor.barangay} />
        <VendorProfileDetail label="Email" value={vendor.email} />
        <VendorProfileDetail label="Phone" value={vendor.phone} />
        <VendorProfileDetail
          label="Registration Date"
          value={formatDate(vendor.registrationDate)}
        />
        <VendorProfileDetail
          label="Permit Expiry"
          value={vendor.expiryDate ? formatDate(vendor.expiryDate) : "—"}
        />
        <VendorProfileDetail label="QR Code" value={vendor.qrCode} />
      </div>
    </div>
  );
};

export default VendorProfile;
