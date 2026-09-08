import { FC } from "react";
import { Phone, Mail, Calendar, BadgeCheck } from "lucide-react";
import styles from "./EnforcerProfileCard.module.css";

interface EnforcerProfileCardProps {
  profile: {
    fullName: string;
    initials: string;
    employeeId: string;
    contactNumber: string;
    email: string;
    dateHired: string;
    role: string;
    department: string;
  };
}

const EnforcerProfileCard: FC<EnforcerProfileCardProps> = ({ profile }) => {
  return (
    <div className={styles.card}>
      <div className={styles.header}>
        <div className={styles.avatar}>{profile.initials}</div>
        <div className={styles.headerTitle}>
          <h3 className={styles.name}>{profile.fullName}</h3>
          <span className={styles.employeeId}>ID: {profile.employeeId}</span>
        </div>
      </div>
      <div className={styles.meta}>
        <div className={styles.metaItem}>
          <div className={styles.icon}>
            <Phone size={14} strokeWidth={1.8} aria-hidden="true" />
          </div>
          <span>{profile.contactNumber}</span>
        </div>
        <div className={styles.metaItem}>
          <div className={styles.icon}>
            <Mail size={14} strokeWidth={1.8} aria-hidden="true" />
          </div>
          <span>{profile.email}</span>
        </div>
        <div className={styles.metaItem}>
          <div className={styles.icon}>
            <Calendar size={14} strokeWidth={1.8} aria-hidden="true" />
          </div>
          <span>Date Hired: {profile.dateHired}</span>
        </div>
      </div>
      <div className={styles.tags}>
        <div className={styles.tagContainer}>
          <span className={styles.tagLabel}>ROLE</span>
          <span className={styles.tag}>{profile.role}</span>
        </div>
        <div className={styles.tagContainer}>
          <span className={styles.tagLabel}>LAST INSPECTION</span>
          <span className={styles.tag}>{profile.department}</span>
        </div>
      </div>
    </div>
  );
};

export default EnforcerProfileCard;
