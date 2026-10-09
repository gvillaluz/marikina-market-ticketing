import styles from "./RegistrationStepper.module.css";

const STEPS = [
  "Personal Information",
  "Business Details",
  "Required Documents",
  "Account Registration",
];

interface RegistrationStepperProps {
  currentStep: number;
  onStepClick: (step: number) => void;
  disabled?: boolean;
}

export default function RegistrationStepper({
  currentStep,
  onStepClick,
  disabled = false,
}: RegistrationStepperProps) {
  return (
    <nav aria-label="Registration steps">
      <ol className={styles.steps}>
        {STEPS.map((label, index) => {
          const step = index + 1;
          const isCurrent = step === currentStep;
          const isComplete = step < currentStep;
          const itemClass = [
            styles.step,
            isCurrent ? styles.current : "",
            isComplete ? styles.complete : "",
          ]
            .filter(Boolean)
            .join(" ");

          return (
            <li className={itemClass} key={label}>
              {step < currentStep ? (
                <button
                  type="button"
                  className={styles.stepButton}
                  disabled={disabled}
                  onClick={() => onStepClick(step)}
                  aria-label={`Go back to ${label}`}
                >
                  <span className={styles.number} aria-hidden="true">
                    {step}
                  </span>
                  <span>{label}</span>
                </button>
              ) : (
                <span
                  className={styles.stepLabel}
                  aria-current={isCurrent ? "step" : undefined}
                >
                  <span className={styles.number} aria-hidden="true">
                    {step}
                  </span>
                  <span>{label}</span>
                </span>
              )}
            </li>
          );
        })}
      </ol>
    </nav>
  );
}
