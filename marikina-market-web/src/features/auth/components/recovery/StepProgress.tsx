import { FC } from "react";
import styles from "./StepProgress.module.css";

interface StepProgressProps {
  step: number;
  total: number;
}

const StepProgress: FC<StepProgressProps> = ({ step, total }) => {
  return (
    <div className={styles.progress}>
      <p className={styles.label}>{`Step ${step} of ${total}`}</p>
      <div className={styles.track} aria-hidden="true">
        <div
          className={styles.fill}
          style={{ width: `${(step / total) * 100}%` }}
        />
      </div>
    </div>
  );
};

export default StepProgress;
