import { CalendarDays } from "lucide-react";
import { USER_ROLE_LABELS, type UserRole } from "@/api/types/common.types";
import type { ProfileResponse } from "@/api/endpoints/profile.api";
import { Badge } from "@/components/ui/Badge/Badge";
import { useProfileAvatar } from "../hooks/useProfileAvatar";
import { displayProfileValue, formatProfileDate } from "../profile.utils";
import styles from "./ProfileSummary.module.css";

interface ProfileSummaryProps {
  profile: ProfileResponse & { role: UserRole };
}

export default function ProfileSummary({ profile }: ProfileSummaryProps) {
  const avatar = useProfileAvatar(profile.profileUrl);
  const fullName = [profile.firstName, profile.lastName]
    .filter(Boolean)
    .join(" ");
  const initials =
    `${profile.firstName.trim().charAt(0)}${profile.lastName.trim().charAt(0)}`.toUpperCase();

  return (
    <aside className={styles.summary} aria-label="Account summary">
      <div className={styles.avatar}>
        {avatar.src ? (
          <img
            src={avatar.src}
            alt={`${fullName} profile`}
            onError={avatar.onError}
            referrerPolicy="no-referrer"
          />
        ) : (
          <span aria-label="Profile initials">{initials || "?"}</span>
        )}
      </div>
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
