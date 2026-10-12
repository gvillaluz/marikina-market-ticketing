import { CalendarDays } from "lucide-react";
import { USER_ROLE_LABELS, type UserRole } from "@/api/types/common.types";
import type { ProfileResponse } from "@/api/endpoints/profile.api";
import { Badge } from "@/components/ui/Badge/Badge";
import ProfilePhotoUpload from "./ProfilePhotoUpload";
import type { ProfilePhotoModel } from "../hooks/useProfilePhoto";
import { displayProfileValue, formatProfileDate } from "../profile.utils";
import styles from "./ProfileSummary.module.css";

interface ProfileSummaryProps {
  profile: ProfileResponse & { role: UserRole };
  photo: ProfilePhotoModel;
}

export default function ProfileSummary({
  profile,
  photo,
}: ProfileSummaryProps) {
  const fullName = [profile.firstName, profile.lastName]
    .filter(Boolean)
    .join(" ");

  return (
    <aside className={styles.summary} aria-label="Account summary">
      <ProfilePhotoUpload profile={profile} photo={photo} />
      <h2 className={styles.name}>{displayProfileValue(fullName)}</h2>
      <p className={styles.role}>{USER_ROLE_LABELS[profile.role]}</p>
      <Badge tone={profile.status === "Active" ? "success" : "neutral"}>
        {profile.status}
      </Badge>
      <dl className={styles.username}>
        <dt>Username</dt>
        <dd>{displayProfileValue(profile.username)}</dd>
      </dl>
      <p className={styles.created}>
        <CalendarDays size={16} aria-hidden="true" />
        <span>Created on: {formatProfileDate(profile.createdAt)}</span>
      </p>
    </aside>
  );
}
