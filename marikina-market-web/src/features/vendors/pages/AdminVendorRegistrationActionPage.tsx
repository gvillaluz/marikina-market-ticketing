import Breadcrumb from "@/components/ui/Breadcrumb";
import { AlertTriangle, ArrowLeft, CircleAlert, Info } from "lucide-react";
import { useNavigate, useParams } from "react-router-dom";
import Button from "@/components/ui/Button";
import Modal from "@/components/ui/Modal";
import { ROUTES } from "@/routes/routePaths";
import {
  DECLINE_OPTIONS,
  INFORMATION_OPTIONS,
  useAdminVendorRegistrationAction,
  type RegistrationActionMode,
} from "../hooks/useAdminVendorRegistrationAction";
import { useAdminVendorRegistrationReview } from "../hooks/useAdminVendorRegistrationReview";
import ReviewApplicantHeader from "./review/ReviewApplicantHeader";
import ReviewSkeleton from "./review/ReviewSkeleton";
import styles from "./AdminVendorRegistrationActionPage.module.css";

function getModeTitle(mode: RegistrationActionMode) {
  if (mode === "approve") return "Approve Registration";
  if (mode === "decline") return "Reject Registration";
  return "Request More Information";
}

function getModeDescription(mode: RegistrationActionMode) {
  if (mode === "approve") {
    return "Confirm that the applicant has met the registration requirements.";
  }
  if (mode === "decline") {
    return "Document the rejection basis and confirm how the applicant will be notified.";
  }
  return "Specify what the applicant must correct or provide before the review can continue.";
}

export default function AdminVendorRegistrationActionPage({
  mode,
}: {
  mode: RegistrationActionMode;
}) {
  const { registrationId: rawId } = useParams<{ registrationId: string }>();
  const navigate = useNavigate();
  const registrationId = Number(rawId);
  const review = useAdminVendorRegistrationReview(registrationId);
  const action = useAdminVendorRegistrationAction(
    mode,
    review.details,
    review.refetch,
  );
  const options = mode === "decline" ? DECLINE_OPTIONS : INFORMATION_OPTIONS;

  if (!Number.isInteger(registrationId) || registrationId < 1) {
    return (
      <div className={styles.errorPage}>
        <CircleAlert size={28} />
        <h2>Registration request unavailable</h2>
        <Button onClick={() => navigate(ROUTES.adminVendorRegistrations)}>
          Back to Registrants
        </Button>
      </div>
    );
  }

  if (review.isLoading) return <ReviewSkeleton />;

  if (review.isError || !review.details) {
    return (
      <div className={styles.errorPage}>
        <div className={styles.errorCard} role="alert">
          <AlertTriangle size={22} aria-hidden="true" />
          <div>
            <strong>Registration request unavailable</strong>
            <span>{review.errorMessage}</span>
          </div>
          <button type="button" onClick={() => void review.refetch()}>
            Try again
          </button>
        </div>
      </div>
    );
  }

  const details = review.details;

  return (
    <div className={`${styles.page} ${styles[mode]}`}>
      <Breadcrumb
        items={[
          { label: "Vendor Records", to: ROUTES.adminVendorRegistrations },
          {
            label: `REG-${String(registrationId).padStart(4, "0")}`,
            to: ROUTES.adminVendorRegistration(String(registrationId)),
          },
          { label: getModeTitle(mode) },
        ]}
      />

      <header className={styles.header}>
        <h1>{getModeTitle(mode)}</h1>
        <p>{getModeDescription(mode)}</p>
      </header>

      <div className={styles.columns}>
        <main className={styles.main}>
          <ReviewApplicantHeader details={details} />

          {mode !== "approve" && (
            <fieldset
              className={styles.card}
              aria-describedby="reason-hint reason-error"
              aria-invalid={Boolean(action.reasonError)}
            >
              <legend className={styles.reasonTitle}>
                {mode === "decline"
                  ? "Primary rejection reason"
                  : "Reason for requesting information"}
                <span className={styles.required}>Required</span>
              </legend>
              <p className={styles.hint} id="reason-hint">
                Choose the primary reason that will be recorded on the case.
              </p>
              <div className={styles.options}>
                {options.map((option, index) => (
                  <label className={styles.option} key={option.value}>
                    <input
                      ref={index === 0 ? action.reasonInputRef : undefined}
                      type="radio"
                      name="reviewReason"
                      value={option.value}
                      checked={action.selectedReason === option.value}
                      disabled={action.isSubmitting || !action.canSubmit}
                      aria-invalid={Boolean(action.reasonError)}
                      aria-describedby="reason-hint reason-error"
                      onBlur={action.validateReason}
                      onChange={(event) =>
                        action.setSelectedReason(event.target.value)
                      }
                    />
                    <span className={styles.optionText}>
                      <strong>{option.title}</strong>
                      <small>{option.description}</small>
                    </span>
                  </label>
                ))}
              </div>
              <p
                className={styles.fieldError}
                id="reason-error"
                aria-live="polite"
              >
                {action.reasonError}
              </p>
            </fieldset>
          )}

          {mode === "approve" ? (
            <section className={styles.card}>
              <h2 className={styles.reasonTitle}>APPROVAL SUMMARY</h2>
              <p className={styles.hint}>
                Approving this request will create the vendor account and assign
                the applicant to the selected market section.
              </p>
              <div className={styles.approvalNotice}>
                <Info size={16} />
                <span>
                  This action will be recorded in the registration history.
                </span>
              </div>
            </section>
          ) : (
            <section className={`${styles.card} ${styles.remarks}`}>
              <h2 className={styles.reasonTitle}>
                {mode === "decline"
                  ? "Detailed remarks"
                  : "Message to applicant"}
              </h2>
              <p className={styles.hint} id="remarks-hint">
                {mode === "decline"
                  ? "Describe the verified issue and why it prevents approval. Use factual language suitable for the audit record."
                  : "Name the document or detail needed, explain the issue, and tell the applicant how to correct it. This message appears in their notification."}
              </p>
              <label>
                <span>
                  {mode === "decline"
                    ? "Rejection details"
                    : "Requested corrections"}
                  <span className={styles.required}>Required</span>
                </span>
                <textarea
                  ref={action.remarksInputRef}
                  id="review-remarks"
                  required
                  aria-invalid={Boolean(action.remarksError)}
                  aria-describedby="remarks-hint remarks-error remarks-count"
                  value={action.remarks}
                  onChange={(event) => action.setRemarks(event.target.value)}
                  onBlur={action.validateRemarks}
                  placeholder={
                    mode === "decline"
                      ? "Explain the specific findings behind this decision."
                      : "Explain what to submit and what must be visible or corrected."
                  }
                  maxLength={2000}
                  disabled={action.isSubmitting || !action.canSubmit}
                />
              </label>
              <div className={styles.fieldFeedback}>
                <p
                  className={styles.fieldError}
                  id="remarks-error"
                  aria-live="polite"
                >
                  {action.remarksError}
                </p>
                <small id="remarks-count">
                  {action.remarks.length.toLocaleString()}/2,000 characters
                </small>
              </div>
            </section>
          )}

          {action.submitError && (
            <div className={styles.error} role="alert">
              <p>{action.submitError}</p>
              <Button
                variant="outline"
                size="sm"
                disabled={action.isSubmitting || action.isReloading}
                onClick={() => void action.reloadLatestDetails()}
              >
                Reload latest details
              </Button>
            </div>
          )}

          {!action.canSubmit && (
            <p className={styles.error} role="status">
              A decision is unavailable. Reload the latest details to check
              whether this request can still be reviewed.
            </p>
          )}
          <footer className={styles.actions}>
            <span>
              <Info size={13} /> The request and selected decision are recorded
              in the case history.
            </span>
            <div>
              <Button
                variant="ghost"
                size="sm"
                icon={<ArrowLeft size={14} />}
                onClick={action.cancel}
                disabled={action.isSubmitting}
              >
                Cancel
              </Button>
              <Button
                variant={mode === "decline" ? "danger" : "primary"}
                size="sm"
                loading={action.isSubmitting}
                disabled={!action.canSubmit}
                onClick={action.openConfirmation}
              >
                {mode === "approve"
                  ? "Approve Registration"
                  : mode === "decline"
                    ? "Review Rejection"
                    : "Review Request"}
              </Button>
            </div>
          </footer>
        </main>

        <aside className={styles.sideCard}>
          <h2>
            {mode === "approve"
              ? "APPROVAL EFFECT"
              : mode === "decline"
                ? "DECLINE EFFECT"
                : "AFTER SENDING"}
          </h2>
          <p>
            {mode === "approve"
              ? "This registration will become an active vendor account after confirmation."
              : mode === "decline"
                ? "This status changes to Rejected. No vendor account, business profile, compliance score, or QR code will be created."
                : "The application moves to Needs Information. Review activity resumes when the applicant uploads the requested items."}
          </p>
          <div className={styles.prepared}>
            <Info size={13} />
            <span>Decision prepared for admin review.</span>
          </div>
        </aside>
      </div>

      <Modal
        open={action.showConfirmationModal}
        onClose={action.closeConfirmation}
        closeDisabled={action.isSubmitting}
        title={
          mode === "approve"
            ? "Approve registration?"
            : mode === "decline"
              ? "Reject this registration?"
              : "Send this information request?"
        }
        subtitle={
          mode === "approve"
            ? "This action will create the vendor account."
            : "Check the reason and message before confirming."
        }
        footer={
          <div className={styles.modalActions}>
            <Button
              type="button"
              variant="outline"
              size="md"
              onClick={action.closeConfirmation}
              disabled={action.isSubmitting}
            >
              {mode === "approve" ? "Cancel" : "Back to edit"}
            </Button>
            <Button
              type="button"
              variant={mode === "decline" ? "danger" : "primary"}
              size="md"
              loading={action.isSubmitting}
              aria-busy={action.isSubmitting}
              disabled={!action.canSubmit}
              onClick={() => void action.submit()}
            >
              {action.isSubmitting
                ? mode === "approve"
                  ? "Approving registration…"
                  : mode === "decline"
                    ? "Rejecting registration…"
                    : "Sending request…"
                : mode === "approve"
                  ? "Approve registration"
                  : mode === "decline"
                    ? "Reject registration"
                    : "Send information request"}
            </Button>
          </div>
        }
      >
        <div className={styles.confirmation}>
          <p className={styles.modalMessage}>
            <strong>{details.businessName}</strong>
            <span className={styles.caseReference}>
              REG-{String(registrationId).padStart(4, "0")}
            </span>
          </p>
          {mode !== "approve" && (
            <dl className={styles.decisionSummary}>
              <div>
                <dt>Reason</dt>
                <dd>{action.selectedReason}</dd>
              </div>
              <div>
                <dt>
                  {mode === "decline"
                    ? "Rejection details"
                    : "Message to applicant"}
                </dt>
                <dd className={styles.messagePreview}>
                  {action.remarks.trim()}
                </dd>
              </div>
            </dl>
          )}
          <div
            className={`${styles.confirmationNotice} ${mode === "decline" ? styles.rejectionNotice : ""}`}
          >
            {mode === "decline" ? (
              <AlertTriangle size={18} aria-hidden="true" />
            ) : (
              <Info size={18} aria-hidden="true" />
            )}
            <p>
              {mode === "approve"
                ? "The applicant will become an active vendor. This decision will be recorded in the case history."
                : mode === "decline"
                  ? "The status will change to Rejected. No vendor account will be created. The reason and remarks will be recorded, and an email notification will be attempted."
                  : "The status will change to Needs Information. The reason and message will be recorded, and an email notification will be attempted."}
            </p>
          </div>
        </div>
      </Modal>
    </div>
  );
}
