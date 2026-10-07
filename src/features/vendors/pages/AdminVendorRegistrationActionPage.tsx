import { AlertTriangle, ArrowLeft, CircleAlert, Info } from "lucide-react";
import { Link, useNavigate, useParams } from "react-router-dom";
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
import styles from "./review/AdminVendorRegistrationActionPage.module.css";

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
  const action = useAdminVendorRegistrationAction(mode, details);

  return (
    <div className={`${styles.page} ${styles[mode]}`}>
      <nav className={styles.breadcrumb} aria-label="Breadcrumb">
        <Link to={ROUTES.adminVendorRegistrations}>Vendor Records</Link>
        <span>›</span>
        <Link to={ROUTES.adminVendorRegistration(String(registrationId))}>
          REG-{String(registrationId).padStart(4, "0")}
        </Link>
        <span>›</span>
        <span>{getModeTitle(mode)}</span>
      </nav>

      <header className={styles.header}>
        <h1>{getModeTitle(mode)}</h1>
        <p>{getModeDescription(mode)}</p>
      </header>

      <div className={styles.columns}>
        <main className={styles.main}>
          <ReviewApplicantHeader details={details} />

          {mode !== "approve" && (
            <section className={styles.card}>
              <h2 className={styles.reasonTitle}>
                {mode === "decline"
                  ? "PRIMARY REJECTION REASON"
                  : "MISSING-DOCUMENT REASON"}
              </h2>
              <p className={styles.hint}>
                Choose the primary reason that will be recorded on the case.
              </p>
              <div className={styles.options}>
                {options.map((option) => (
                  <label className={styles.option} key={option.value}>
                    <input
                      type="radio"
                      name="reviewReason"
                      value={option.value}
                      checked={action.selectedReason === option.value}
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
            </section>
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
                  ? "DETAILED REMARKS"
                  : "MESSAGE TO APPLICANT"}
              </h2>
              <p className={styles.hint}>
                {mode === "decline"
                  ? "Use factual, specific language suitable for the audit record."
                  : "This message will appear in the applicant notification."}
              </p>
              <label>
                Review remarks
                <textarea
                  value={action.remarks}
                  onChange={(event) => action.setRemarks(event.target.value)}
                  placeholder="Write the details the applicant needs to know."
                  maxLength={2000}
                />
              </label>
              <small>{action.remarks.length}/2000 characters</small>
            </section>
          )}

          {action.submitError && (
            <p className={styles.error}>{action.submitError}</p>
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
              >
                Cancel
              </Button>
              <Button
                variant={mode === "decline" ? "danger" : "primary"}
                size="sm"
                loading={action.isSubmitting}
                onClick={() =>
                  mode === "approve"
                    ? action.setShowApprovalModal(true)
                    : void action.submit()
                }
              >
                {mode === "approve"
                  ? "Approve Registration"
                  : mode === "decline"
                    ? "Confirm Rejection"
                    : "Send Request"}
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
        open={action.showApprovalModal}
        onClose={() => action.setShowApprovalModal(false)}
        title="Approve registration?"
        subtitle="This action will create the vendor account."
        footer={
          <div className={styles.modalActions}>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => action.setShowApprovalModal(false)}
            >
              Cancel
            </Button>
            <Button
              size="sm"
              loading={action.isSubmitting}
              onClick={() => void action.submit()}
            >
              Confirm Approval
            </Button>
          </div>
        }
      >
        <p className={styles.modalMessage}>
          Approve {details.businessName} for registration? The applicant will be
          assigned as an active vendor and this decision will be recorded.
        </p>
      </Modal>
    </div>
  );
}
