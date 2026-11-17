import { useHeldMessage } from "../hooks/useHeldMessage";
import styles from "./RevealMessage.module.css";

interface RevealMessageProps {
  message: string;
  className: string;
  id?: string;
  role?: "alert" | "status";
}

export default function RevealMessage({
  message,
  className,
  id,
  role,
}: RevealMessageProps) {
  const { text, open, openKey } = useHeldMessage(message);
  return (
    <div className={styles.reveal} data-open={open}>
      <div className={styles.inner}>
        {text && (
          <p
            key={openKey}
            id={id}
            className={className}
            role={role}
            aria-hidden={open ? undefined : true}
          >
            {text}
          </p>
        )}
      </div>
    </div>
  );
}
