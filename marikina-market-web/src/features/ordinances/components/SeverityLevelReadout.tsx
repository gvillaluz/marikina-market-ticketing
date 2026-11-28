import { useId } from "react";
import styles from "./SeverityLevelReadout.module.css";

interface Props {
  text: string;
}

export default function SeverityLevelReadout({ text }: Props) {
  const id = useId();
  return (
    <div className={styles.readout}>
      <label htmlFor={id} className={styles.label}>
        Severity Level
      </label>
      <output id={id} className={styles.value} aria-live="polite">
        {text}
      </output>
    </div>
  );
}
