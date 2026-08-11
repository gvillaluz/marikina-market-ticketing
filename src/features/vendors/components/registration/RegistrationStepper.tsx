import { FC } from 'react';

export interface RegistrationStep {
  num: number;
  label: string;
}

const STEPS: RegistrationStep[] = [
  { num: 1, label: 'Personal Information' },
  { num: 2, label: 'Business Details' },
  { num: 3, label: 'Required Documents' },
  { num: 4, label: 'Account Registration' },
];

interface RegistrationStepperProps {
  currentStep: number;
  onStepClick?: (step: number) => void;
}

const RegistrationStepper: FC<RegistrationStepperProps> = ({ currentStep, onStepClick }) => {
  return (
    <nav className="mt-8 space-y-1">
      {STEPS.map((step) => {
        const isActive = step.num === currentStep;
        const isDone = step.num < currentStep;
        return (
          <button
            key={step.num}
            type="button"
            onClick={() => onStepClick?.(step.num)}
            className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-md text-left transition-colors ${
              isActive ? 'bg-white/10' : 'hover:bg-white/5'
            }`}
          >
            <span
              className={`w-7 h-7 rounded-full flex items-center justify-center text-sm font-bold flex-shrink-0 ${
                isActive
                  ? 'bg-white text-primary'
                  : isDone
                  ? 'bg-accent text-white'
                  : 'border-2 border-white/40 text-white/70'
              }`}
            >
              {isDone ? '✓' : step.num}
            </span>
            <span
              className={`text-sm font-medium ${
                isActive ? 'text-white font-bold' : 'text-white/70'
              }`}
            >
              {step.label}
            </span>
          </button>
        );
      })}
    </nav>
  );
};

export default RegistrationStepper;
