import { FC } from "react";
import styles from "./VendorProfile.module.css";

interface VendorProfileDetailProps {
  label: string;
  value: string;
}

const VendorProfileDetail: FC<VendorProfileDetailProps> = ({
  label,
  value,
}) => (
  <div className={styles.detail}>
    <span className={styles.label}>{label}</span>
    <span className={styles.value}>{value}</span>
  </div>
);

export default VendorProfileDetail;
