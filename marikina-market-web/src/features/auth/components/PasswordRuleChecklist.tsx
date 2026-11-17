import { Check } from "lucide-react";
import { PASSWORD_RULES } from "@/features/profile/profile.validation";
import styles from "./PasswordRuleChecklist.module.css";

interface PasswordRuleChecklistProps {
  id: string;
  value: string;
}

const PasswordRuleChecklist = ({ id, value }: PasswordRuleChecklistProps) => (
  <ul id={id} className={styles.rules} aria-label="Password rules">
    {PASSWORD_RULES.map(({ label, met }) => {
      const done = met(value);
      return (
        <li key={label} className={styles.rule} data-met={String(done)}>
          <span className={styles.mark} aria-hidden="true">
            <Check size={12} strokeWidth={3} />
          </span>
          <span className={styles.hidden}>{done ? "Done: " : "Not yet: "}</span>
          {label}
        </li>
      );
    })}
  </ul>
);

export default PasswordRuleChecklist;
