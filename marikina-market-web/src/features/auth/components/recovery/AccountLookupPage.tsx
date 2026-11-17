import { useRecoveryLookup } from "../../hooks/useRecoveryLookup";
import { UserRound } from "lucide-react";
import AuthSubmitButton from "../AuthSubmitButton";
import RevealMessage from "../RevealMessage";
import styles from "./AccountLookupPage.module.css";

interface AccountLookupPageProps {
  initialUsername: string;
  initialError: string;
  onContinue: (username: string) => void;
}

const AccountLookupPage = ({
  initialUsername,
  initialError,
  onContinue,
}: AccountLookupPageProps) => {
  const { username, error, changeUsername, submit } = useRecoveryLookup(
    initialUsername,
    initialError,
    onContinue,
  );

  return (
    <>
      <p id="recovery-lookup-description" className={styles.description}>
        Please enter your username.
      </p>
      <form className={styles.form} onSubmit={submit}>
        <label className={styles.label}>
          Username
          <span className={styles.inputWrap}>
            <UserRound
              className={styles.inputIcon}
              size={16}
              aria-hidden="true"
            />
            <input
              autoComplete="username"
              maxLength={200}
              aria-invalid={Boolean(error)}
              aria-describedby={
                error ? "recovery-lookup-error" : "recovery-lookup-description"
              }
              autoFocus
              className={styles.input}
              value={username}
              onChange={(event) => changeUsername(event.target.value)}
              placeholder="Enter your username"
            />
          </span>
        </label>
        <RevealMessage
          message={error}
          id="recovery-lookup-error"
          className={styles.error}
          role="alert"
        />
        <AuthSubmitButton label="Continue" className={styles.primaryButton} />
      </form>
    </>
  );
};

export default AccountLookupPage;
