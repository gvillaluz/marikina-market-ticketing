import { KeyRound } from "lucide-react";
import { useChangePassword } from "../hooks/useChangePassword";
import type { PasswordValues } from "../profile.validation";
import ProfileFormModal from "./ProfileFormModal";
import ProfileFormField from "./ProfileFormField";
import styles from "./ChangePasswordModal.module.css";

interface ChangePasswordModalProps {
  onClose: () => void;
}

const fields: {
  name: keyof PasswordValues;
  label: string;
  autoComplete: string;
}[] = [
  {
    name: "currentPassword",
    label: "Current password",
    autoComplete: "current-password",
  },
  { name: "newPassword", label: "New password", autoComplete: "new-password" },
  {
    name: "confirmNewPassword",
    label: "Confirm new password",
    autoComplete: "new-password",
  },
];

export default function ChangePasswordModal({
  onClose,
}: ChangePasswordModalProps) {
  const editor = useChangePassword(onClose);
  return (
    <ProfileFormModal
      title="Change password"
      icon={<KeyRound size={20} aria-hidden="true" />}
      description="Keep your account secure. Enter your current password and choose a new one."
      size="sm"
      formId="change-password-form"
      submitLabel="Update password"
      isSaving={editor.isSaving}
      canSubmit={editor.canSubmit}
      error={editor.error}
      onClose={editor.close}
      onSubmit={editor.submit}
    >
      {fields.map(({ name, label, autoComplete }) => (
        <ProfileFormField
          key={name}
          id={`password-${name}`}
          label={label}
          type="password"
          value={editor.values[name]}
          onChange={(value) => editor.change(name, value)}
          onBlur={() => editor.blur(name)}
          error={editor.touched[name] ? editor.errors[name] : undefined}
          disabled={editor.isSaving}
          autoComplete={autoComplete}
          visible={editor.visible[name]}
          onToggle={() => editor.toggle(name)}
          hint={
            name === "newPassword" ? "Use at least 6 characters." : undefined
          }
          success={
            name === "confirmNewPassword" && editor.matches
              ? "Passwords match"
              : undefined
          }
        />
      ))}
      <p className={styles.note}>
        Never share your password. Use the visibility buttons to review each
        entry before saving.
      </p>
    </ProfileFormModal>
  );
}
