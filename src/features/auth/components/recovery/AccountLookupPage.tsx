import { FormEvent, useState } from "react";
import { UserRound } from "lucide-react";
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
  const [username, setUsername] = useState(initialUsername);
  const [error, setError] = useState(initialError);

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!username.trim()) {
      setError("Enter your username.");
      return;
    }
    onContinue(username.trim());
  };

  return (
    <>
      <p className={styles.description}>Please enter your username.</p>
      <form className={styles.form} onSubmit={handleSubmit}>
        <label className={styles.label}>
          Username
          <span className={styles.inputWrap}>
            <UserRound className={styles.inputIcon} size={16} />
            <input
              autoComplete="username"
              autoFocus
              className={styles.input}
              value={username}
              onChange={(event) => setUsername(event.target.value)}
              placeholder="Enter your username"
            />
          </span>
        </label>
        {error && <p className={styles.error} role="alert">{error}</p>}
        <button className={styles.primaryButton} type="submit">
          Continue
        </button>
      </form>
    </>
  );
};

export default AccountLookupPage;
