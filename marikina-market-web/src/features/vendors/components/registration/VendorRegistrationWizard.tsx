import {
  Bell,
  Check,
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  ClipboardCheck,
  Clock3,
  LoaderCircle,
  Store,
} from "lucide-react";
import { Link } from "react-router-dom";
import { TOTAL_STEPS } from "@/features/vendors/registration.constants";
import type { UseVendorRegistration } from "@/features/vendors/hooks/useVendorRegistration";
import RegistrationStepper from "./RegistrationStepper";
import Step1PersonalInfo from "./Step1PersonalInfo";
import Step2BusinessDetails from "./Step2BusinessDetails";
import Step3RequiredDocuments from "./Step3RequiredDocuments";
import Step4AccountRegistration from "./Step4AccountRegistration";
import styles from "./VendorRegistrationWizard.module.css";

const STEP_CONTENT = {
  1: {
    title: "Personal Information",
    description: "Tell us about yourself so we can create your vendor record.",
  },
  2: {
    title: "Business Details",
    description:
      "Tell us about your business so we can complete your vendor record.",
  },
  3: {
    title: "Required Documents",
    description: "Upload the documents we need to verify your business.",
  },
  4: {
    title: "Account Registration",
    description: "Create your account to sign in.",
  },
} as const;

export default function VendorRegistrationWizard({
  step,
  form,
  errors,
  loading,
  submitted,
  submitError,
  update,
  next,
  back,
  goToStep,
  cancel,
  submit,
}: UseVendorRegistration) {
  if (submitted) {
    return (
      <section
        className={`${styles.successCard} motion-enter`}
        aria-live="polite"
      >
        <span className={styles.successIcon}>
          <Check size={34} strokeWidth={2.5} aria-hidden="true" />
        </span>
        <p className={styles.successEyebrow}>Vendor registration received</p>
        <h1>Thank you for registering</h1>
        <p className={styles.successMessage}>
          Your application has been saved successfully. An administrator will
          review your details and documents before your account is approved.
        </p>
        <div className={styles.applicationSummary}>
          <div className={styles.summaryIcon}>
            <Store size={20} aria-hidden="true" />
          </div>
          <div className={styles.summaryText}>
            <span>Registration submitted for</span>
            <strong>{form.businessName || "Your vendor business"}</strong>
            <small>
              {[form.firstName, form.middleName, form.lastName]
                .filter(Boolean)
                .join(" ")}
            </small>
          </div>
          <span className={styles.pendingBadge}>
            <Clock3 size={14} aria-hidden="true" />
            Pending review
          </span>
        </div>
        <div className={styles.nextSteps}>
          <h2>What happens next?</h2>
          <ol className={styles.timeline}>
            <li className={styles.timelineStep}>
              <span className={`${styles.timelineIcon} ${styles.stepComplete}`}>
                <CheckCircle2 size={19} aria-hidden="true" />
              </span>
              <div>
                <strong>Application received</strong>
                <span>Your registration and documents are saved.</span>
              </div>
            </li>
            <li className={styles.timelineStep}>
              <span className={`${styles.timelineIcon} ${styles.stepCurrent}`}>
                <ClipboardCheck size={19} aria-hidden="true" />
              </span>
              <div>
                <strong>Administrator review</strong>
                <span>Your information and documents are being checked.</span>
              </div>
            </li>
            <li className={styles.timelineStep}>
              <span className={`${styles.timelineIcon} ${styles.stepWaiting}`}>
                <Bell size={18} aria-hidden="true" />
              </span>
              <div>
                <strong>Approval update</strong>
                <span>You will be notified when a decision is made.</span>
              </div>
            </li>
          </ol>
        </div>
        <Link to="/" className={styles.homeButton}>
          Return to landing page
        </Link>
      </section>
    );
  }

  const content = STEP_CONTENT[step as keyof typeof STEP_CONTENT];

  return (
    <section
      className={`${styles.wizard} motion-enter`}
      aria-label="Vendor registration"
    >
      <aside className={styles.sidebar}>
        <h1>Join the Market Registry</h1>
        <p>
          Register your stall to access and manage your inspection history and
          compliance records all in one digital platform.
        </p>
        <RegistrationStepper
          currentStep={step}
          onStepClick={goToStep}
          disabled={loading}
        />
      </aside>

      <div className={styles.main}>
        <header className={styles.heading}>
          <h2>{content.title}</h2>
          <p>{content.description}</p>
        </header>

        <fieldset
          className={styles.stepContent}
          key={step}
          disabled={loading}
          aria-label={content.title}
          aria-busy={loading}
        >
          {step === 1 && (
            <Step1PersonalInfo form={form} errors={errors} update={update} />
          )}
          {step === 2 && (
            <Step2BusinessDetails form={form} errors={errors} update={update} />
          )}
          {step === 3 && (
            <Step3RequiredDocuments
              form={form}
              errors={errors}
              update={update}
            />
          )}
          {step === 4 && (
            <Step4AccountRegistration
              form={form}
              errors={errors}
              update={update}
            />
          )}
        </fieldset>

        {submitError && (
          <p className={styles.submitError} role="alert">
            {submitError}
          </p>
        )}

        <footer className={styles.footer}>
          {step > 1 ? (
            <button
              type="button"
              className={styles.secondaryButton}
              onClick={back}
              disabled={loading}
            >
              <ChevronLeft size={16} aria-hidden="true" />
              Back
            </button>
          ) : (
            <span aria-hidden="true" />
          )}

          <div className={styles.footerActions}>
            <button
              type="button"
              className={styles.secondaryButton}
              onClick={cancel}
              disabled={loading}
            >
              Cancel
            </button>
            {step < TOTAL_STEPS ? (
              <button
                type="button"
                className={styles.primaryButton}
                onClick={next}
                disabled={loading}
              >
                Next
                <ChevronRight size={16} aria-hidden="true" />
              </button>
            ) : (
              <button
                type="button"
                className={styles.primaryButton}
                onClick={submit}
                disabled={loading}
              >
                {loading ? (
                  <>
                    <LoaderCircle
                      className={styles.spinner}
                      size={16}
                      aria-hidden="true"
                    />
                    Submitting...
                  </>
                ) : (
                  <>
                    Submit registration
                    <ChevronRight size={16} aria-hidden="true" />
                  </>
                )}
              </button>
            )}
          </div>
        </footer>
      </div>
    </section>
  );
}
