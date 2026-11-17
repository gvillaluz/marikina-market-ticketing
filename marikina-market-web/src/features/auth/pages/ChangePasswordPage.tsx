import {
  ArrowLeft,
  Eye,
  EyeOff,
  KeyRound,
  LockKeyhole,
  ShieldCheck,
  type LucideIcon,
} from "lucide-react";
import type { PasswordValues } from "@/features/profile/profile.validation";
import AuthLayout from "../components/AuthLayout";
import AuthSubmitButton from "../components/AuthSubmitButton";
import RevealMessage from "../components/RevealMessage";
import CapsLockNote from "../components/CapsLockNote";
import PasswordRuleChecklist from "../components/PasswordRuleChecklist";
import { useCapsLock } from "../hooks/useCapsLock";
import { useMandatoryChangePassword } from "../hooks/useMandatoryChangePassword";
import styles from "./ChangePasswordPage.module.css";

const FIELDS: {
  name: keyof PasswordValues;
  id: string;
  label: string;
  noun: string;
  placeholder: string;
  autoComplete: string;
  Icon: LucideIcon;
}[] = [
  {
    name: "currentPassword",
    id: "mandatory-current-password",
    label: "Current password",
    noun: "current password",
    placeholder: "Enter current password",
    autoComplete: "current-password",
    Icon: LockKeyhole,
  },
  {
    name: "newPassword",
    id: "mandatory-new-password",
    label: "New password",
    noun: "new password",
    placeholder: "Enter new password",
    autoComplete: "new-password",
    Icon: KeyRound,
  },
  {
    name: "confirmNewPassword",
    id: "mandatory-confirm-password",
    label: "Confirm new password",
    noun: "confirm new password",
    placeholder: "Re-enter new password",
    autoComplete: "new-password",
    Icon: ShieldCheck,
  },
];

export default function ChangePasswordPage() {
  const model = useMandatoryChangePassword();
  const caps = useCapsLock();
  return (
    <AuthLayout>
      <button
        className={styles.back}
        type="button"
        onClick={model.backToSignIn}
        disabled={model.loading}
      >
        <ArrowLeft size={15} aria-hidden="true" />
        Back to log in
      </button>
      <h2 className={styles.heading}>Change password</h2>
      <p className={styles.description}>
        For your security, change the temporary password you were given before
        you continue.
      </p>
      <form
        className={styles.form}
        onSubmit={async (event) => {
          const firstWrong = await model.submit(event);
          if (firstWrong)
            document
              .getElementById(FIELDS.find((f) => f.name === firstWrong)!.id)
              ?.focus();
        }}
        aria-busy={model.loading}
        noValidate
      >
        {FIELDS.map(
          ({ name, id, label, noun, placeholder, autoComplete, Icon }) => {
            const fieldError = model.fieldErrors[name];
            const isNew = name === "newPassword";
            const describedBy =
              [
                fieldError ? `${id}-error` : "",
                isNew ? `${id}-hint` : "",
                caps.field === id ? `${id}-caps` : "",
              ]
                .filter(Boolean)
                .join(" ") || undefined;
            return (
              <div className={styles.field} key={name}>
                <label className={styles.label} htmlFor={id}>
                  {label}
                </label>
                <div className={styles.inputWrapper}>
                  <Icon className={styles.icon} size={18} aria-hidden="true" />
                  <input
                    id={id}
                    type={model.shown[name] ? "text" : "password"}
                    className={styles.input}
                    value={model.values[name]}
                    onChange={(event) => model.change(name, event.target.value)}
                    placeholder={placeholder}
                    autoComplete={autoComplete}
                    maxLength={128}
                    disabled={model.loading}
                    aria-invalid={Boolean(fieldError)}
                    aria-describedby={describedBy}
                    {...caps.bind(id)}
                  />
                  <button
                    className={styles.toggle}
                    type="button"
                    onClick={() => model.toggleShown(name)}
                    disabled={model.loading}
                    aria-label={`${model.shown[name] ? "Hide" : "Show"} ${noun}`}
                    aria-pressed={model.shown[name]}
                  >
                    {model.shown[name] ? (
                      <EyeOff size={16} aria-hidden="true" />
                    ) : (
                      <Eye size={16} aria-hidden="true" />
                    )}
                  </button>
                </div>
                {caps.field === id && <CapsLockNote id={`${id}-caps`} />}
                {isNew && (
                  <PasswordRuleChecklist
                    id={`${id}-hint`}
                    value={model.values.newPassword}
                  />
                )}
                <RevealMessage
                  message={fieldError ?? ""}
                  id={`${id}-error`}
                  className={styles.fieldError}
                  role="alert"
                />
              </div>
            );
          },
        )}
        <RevealMessage
          message={model.error}
          className={styles.error}
          role="alert"
        />
        <AuthSubmitButton
          label="Save password"
          busyLabel="Saving…"
          busy={model.loading}
          done={model.succeeded}
          className={styles.submit}
        />
      </form>
    </AuthLayout>
  );
}
