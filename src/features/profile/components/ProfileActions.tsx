import { KeyRound, Pencil } from "lucide-react";
import Button from "@/components/ui/Button/Button";
import styles from "./ProfileActions.module.css";

interface ProfileActionsProps {
  disabled: boolean;
  onChangePassword: () => void;
  onEditProfile: () => void;
}

export default function ProfileActions({
  disabled,
  onChangePassword,
  onEditProfile,
}: ProfileActionsProps) {
  return (
    <div className={styles.actions}>
      <Button
        variant="outline"
        size="sm"
        className={`${styles.button} ${styles.outline}`}
        icon={<KeyRound size={16} />}
        disabled={disabled}
        onClick={onChangePassword}
      >
        Change password
      </Button>
      <Button
        size="sm"
        className={`${styles.button} ${styles.primary}`}
        icon={<Pencil size={16} />}
        disabled={disabled}
        onClick={onEditProfile}
      >
        Edit profile
      </Button>
    </div>
  );
}
