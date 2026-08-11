import { FC } from 'react';
import { Link } from 'react-router-dom';
import { useVendorRegistration, TOTAL_STEPS } from '@/features/vendors/hooks/useVendorRegistration';
import RegistrationStepper from './RegistrationStepper';
import Step1PersonalInfo from './Step1PersonalInfo';
import Step2BusinessDetails from './Step2BusinessDetails';
import Step3RequiredDocuments from './Step3RequiredDocuments';
import Step4AccountRegistration from './Step4AccountRegistration';

const STEP_HEADINGS: Record<number, string> = {
  1: 'PERSONAL INFO',
  2: 'BUSINESS DETAILS',
  3: 'REQUIRED DOCUMENTS',
  4: 'ACCOUNT REGISTRATION',
};

const VendorRegistrationWizard: FC = () => {
  const {
    step,
    form,
    errors,
    loading,
    submitted,
    submitError,
    update,
    next,
    back,
    cancel,
    submit,
    setStep,
  } = useVendorRegistration();

  if (submitted) {
    return (
      <div className="w-full max-w-4xl mx-auto rounded-xl shadow-lg overflow-hidden bg-surface">
        <div className="px-8 md:px-12 py-16 text-center">
          <div className="w-16 h-16 rounded-full bg-green-100 text-green-700 flex items-center justify-center mx-auto">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <path d="M20 6 9 17l-5-5" />
            </svg>
          </div>
          <h2 className="mt-6 font-mono font-bold text-2xl text-primary">Registration Submitted!</h2>
          <p className="mt-3 text-bodygray text-sm max-w-md mx-auto">
            Your application is now pending review. The Administrator will verify your
            documents against the existing vendor registry and notify you once approved.
          </p>
          <Link
            to="/"
            className="mt-8 inline-block px-6 py-2.5 rounded-md bg-primary text-on-primary font-bold text-sm hover:bg-primary-hover transition-colors"
          >
            Back to Home
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="w-full max-w-4xl mx-auto rounded-xl shadow-lg overflow-hidden flex flex-col md:flex-row bg-surface">
      {/* Left — navy sidebar + stepper */}
      <aside className="bg-primary md:w-[260px] px-6 py-8 md:py-10 flex-shrink-0">
        <h2 className="font-mono font-bold text-on-primary text-lg leading-snug">
          Join the Market Registry
        </h2>
        <p className="mt-2 text-on-primary/80 text-xs leading-relaxed">
          Complete the 4-step form to register your stall. Review each section carefully.
        </p>
        <RegistrationStepper currentStep={step} onStepClick={setStep} />
      </aside>

      {/* Right — form + nav */}
      <div className="flex-1 px-6 md:px-10 py-8 md:py-10">
        <div className="pb-4 border-b border-default">
          <h3 className="font-mono font-bold text-xl text-primary">
            {STEP_HEADINGS[step]}
          </h3>
        </div>

        <div className="mt-6 min-h-[320px]">
          {step === 1 && <Step1PersonalInfo form={form} errors={errors} update={update} />}
          {step === 2 && <Step2BusinessDetails form={form} errors={errors} update={update} />}
          {step === 3 && <Step3RequiredDocuments form={form} errors={errors} update={update} />}
          {step === 4 && <Step4AccountRegistration form={form} errors={errors} update={update} />}
        </div>

        {submitError && (
          <div className="mt-4 bg-red-50 text-red-700 px-4 py-3 rounded-md text-sm">
            {submitError}
          </div>
        )}

        {/* Nav buttons */}
        <div className="mt-8 flex items-center justify-between gap-3">
          <div className="flex gap-3">
            {step === 1 ? (
              <button
                type="button"
                onClick={cancel}
                className="px-5 py-2.5 rounded-md border-2 border-primary text-primary font-bold text-sm hover:bg-primary/5 transition-colors"
              >
                Cancel
              </button>
            ) : (
              <button
                type="button"
                onClick={back}
                className="px-5 py-2.5 rounded-md border-2 border-primary text-primary font-bold text-sm hover:bg-primary/5 transition-colors"
              >
                Back
              </button>
            )}
          </div>

          <div>
            {step < TOTAL_STEPS ? (
              <button
                type="button"
                onClick={next}
                className="px-6 py-2.5 rounded-md bg-primary text-on-primary font-bold text-sm hover:bg-primary-hover transition-colors"
              >
                Next →
              </button>
            ) : (
              <button
                type="button"
                onClick={submit}
                disabled={loading}
                className="px-6 py-2.5 rounded-md bg-accent text-on-primary font-bold text-sm hover:bg-accent-hover transition-colors disabled:opacity-60"
              >
                {loading ? 'Submitting…' : 'Submit Registration'}
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default VendorRegistrationWizard;
