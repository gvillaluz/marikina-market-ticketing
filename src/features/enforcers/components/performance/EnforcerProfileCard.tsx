import { FC } from "react";
import { Phone, Mail, Calendar, BadgeCheck } from "lucide-react";
import styles from "./EnforcerProfileCard.module.css";
import { EnforcerProfile } from "@/api/types/enforcer.types";
import { formatDate, formatDateTime } from "@/utils/formatters";
import { useEnforcerProfileImage } from "../../hooks/useEnforcerProfileImage";

interface EnforcerProfileProps {
  profile: EnforcerProfile;
}

const EnforcerProfileCard: FC<EnforcerProfileProps> = ({ profile }) => {
  const image = useEnforcerProfileImage(profile);
  return (
    <div className={styles.card}>
      <div className={styles.header}>
        {image.hasImage ? (
          <img
            className={`${styles.avatar} ${styles.profileImage}`}
            src={image.url}
            alt={`${profile.firstName} ${profile.lastName} profile`}
            onError={image.imageFailed}
          />
        ) : (
          <div className={styles.avatar} aria-hidden="true">
            {image.initials}
          </div>
        )}
        <div className={styles.headerTitle}>
          <h3
            className={styles.name}
          >{`${profile.lastName}, ${profile.firstName}`}</h3>
          <span className={styles.employeeId}>ID: {profile.username}</span>
        </div>
      </div>
      <div className={styles.meta}>
        <div className={styles.metaItem}>
          <div className={styles.icon}>
            <Phone size={14} strokeWidth={1.8} aria-hidden="true" />
          </div>
          <span>{profile.phoneNumber}</span>
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
          <span>Date Hired: {formatDate(profile.hiredAt)}</span>
        </div>
      </div>
      <div className={styles.tags}>
        <div className={styles.tagContainer}>
          <span className={styles.tagLabel}>ROLE</span>
          <span className={styles.tag}>{profile.role}</span>
        </div>
        <div className={styles.tagContainer}>
          <span className={styles.tagLabel}>LAST INSPECTION</span>
          <span className={styles.tag}>
            {formatDateTime(profile.lastInspectionDate)}
          </span>
        </div>
      </div>
    </div>
  );
};

export default EnforcerProfileCard;
