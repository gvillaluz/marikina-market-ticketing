import { Check, X } from "lucide-react";
import type { RestoreView } from "../backups.utils";
import styles from "./RestoreSteps.module.css";

const stateWords = {
  Waiting: "waiting",
  Running: "in progress",
  Done: "done",
  Failed: "failed",
};

interface RestoreStepsProps {
  steps: RestoreView["steps"];
}

export default function RestoreSteps({ steps }: RestoreStepsProps) {
  return (
    <ol className={styles.steps} aria-label="Restore steps">
      {steps.map((step) => (
        <li key={step.step} className={styles[step.state.toLowerCase()]}>
          <span className={styles.marker} aria-hidden="true">
            {step.state === "Done" && <Check size={12} strokeWidth={3} />}
            {step.state === "Failed" && <X size={12} strokeWidth={3} />}
          </span>
          <span className={styles.label}>{step.label}</span>
          <span className={styles.hidden}>, {stateWords[step.state]}</span>
        </li>
      ))}
    </ol>
  );
}
