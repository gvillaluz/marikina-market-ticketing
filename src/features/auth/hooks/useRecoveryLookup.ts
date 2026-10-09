import { useState, type FormEvent } from "react";

export function useRecoveryLookup(
  initialUsername: string,
  initialError: string,
  onContinue: (username: string) => void,
) {
  const [username, setUsername] = useState(initialUsername);
  const [error, setError] = useState(initialError);
  return {
    username,
    error,
    changeUsername(value: string) {
      setUsername(value.slice(0, 200).replace(/[\u0000-\u001f\u007f]/g, ""));
      setError("");
    },
    submit(event: FormEvent<HTMLFormElement>) {
      event.preventDefault();
      if (!username.trim()) {
        setError("Enter your username.");
        return;
      }
      onContinue(username.trim());
    },
  };
}
