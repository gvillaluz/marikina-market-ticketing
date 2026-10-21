import { Camera } from "lucide-react";
import UrlImage from "@/components/ui/UrlImage";
import type { ProfileResponse } from "@/api/endpoints/profile.api";
import type { ProfilePhotoModel } from "../hooks/useProfilePhoto";
import { useProfileAvatar } from "../hooks/useProfileAvatar";
import styles from "./ProfilePhotoUpload.module.css";

export default function ProfilePhotoUpload({
  profile,
  photo,
}: {
  profile: ProfileResponse;
  photo: ProfilePhotoModel;
}) {
  const avatar = useProfileAvatar(profile.profileUrl);
  const fullName = [profile.firstName, profile.lastName]
    .filter(Boolean)
    .join(" ");
  const initials =
    `${profile.firstName.trim().charAt(0)}${profile.lastName.trim().charAt(0)}`.toUpperCase();
  const hintId = `${photo.inputId}-hint`,
    errorId = `${photo.inputId}-error`;
  return (
    <div className={styles.photo}>
      <button
        type="button"
        className={styles.avatar}
        onClick={photo.choosePhoto}
        disabled={photo.disabled}
        aria-label="Change profile photo"
        title="Change profile photo"
        aria-busy={photo.isSaving}
        aria-describedby={`${hintId}${photo.error ? ` ${errorId}` : ""}`}
      >
        <UrlImage
          src={avatar.src}
          alt={`${fullName} profile`}
          onError={avatar.onError}
          referrerPolicy="no-referrer"
          fallback={
            <span aria-label="Profile initials">{initials || "?"}</span>
          }
        />
        {photo.isSaving ? (
          <span className={styles.pending}>
            <span className={styles.spinner} aria-hidden="true" />
            Uploading…
          </span>
        ) : (
          <span className={styles.camera}>
            <Camera size={12} strokeWidth={2} aria-hidden="true" />
          </span>
        )}
      </button>
      <input
        ref={photo.inputRef}
        id={photo.inputId}
        className={styles.input}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        onChange={photo.selectPhoto}
        tabIndex={-1}
        aria-hidden="true"
      />
      <p id={hintId} className={styles.hint}>
        {photo.isSaving ? "Saving your photo…" : "Click to change photo"}
      </p>
      {photo.error && (
        <p id={errorId} className={styles.error} role="alert">
          {photo.error}
        </p>
      )}
    </div>
  );
}
