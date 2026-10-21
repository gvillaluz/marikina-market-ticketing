import Breadcrumb from "@/components/ui/Breadcrumb";
import { AlertTriangle, CircleAlert, RefreshCw } from "lucide-react";
import { useNavigate, useParams } from "react-router-dom";
import Button from "@/components/ui/Button";
import { formatDateTime } from "@/utils/formatters";
import { ROUTES } from "@/routes/routePaths";
import type { VendorRegistrationDetails } from "@/api/types/admin-vendor.types";
import { useAdminVendorRegistrationReview } from "../hooks/useAdminVendorRegistrationReview";
import ReviewChecklist from "./review/ReviewChecklist";
import ReviewDocumentCard from "./review/ReviewDocumentCard";
import ReviewField from "./review/ReviewField";
import ReviewApplicantHeader from "./review/ReviewApplicantHeader";
import ReviewSection from "./review/ReviewSection";
import ReviewSkeleton from "./review/ReviewSkeleton";
import styles from "./AdminVendorRegistrationReviewPage.module.css";

function displayValue(value: string | number | null | undefined) {
  if (value === null || value === undefined || value === "") return "N/A";
  return String(value).replace(/([a-z])([A-Z])/g, "$1 $2");
}

function isApproved(status: string | number) {
  return String(status).toLowerCase().includes("approve");
}

function fullName(details: VendorRegistrationDetails) {
  return [details.firstName, details.middleName, details.lastName]
    .filter(Boolean)
    .join(" ");
}

export default function AdminVendorRegistrationReviewPage() {
  const { registrationId: rawId } = useParams<{ registrationId: string }>();
  const navigate = useNavigate();
  const registrationId = Number(rawId);
  const review = useAdminVendorRegistrationReview(registrationId);

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

  if (review.isLoading) {
    return <ReviewSkeleton />;
  }

  if (review.isError || !review.details) {
    return (
      <div className={styles.errorPage}>
        <div className={styles.errorCard} role="alert">
          <AlertTriangle size={22} aria-hidden="true" />
          <div>
            <strong>Registration review unavailable</strong>
            <span>{review.errorMessage}</span>
          </div>
          <button type="button" onClick={() => void review.refetch()}>
            <RefreshCw size={14} aria-hidden="true" /> Try again
          </button>
        </div>
      </div>
    );
  }

  const details = review.details;
  const approved = isApproved(details.status);
  const documents = approved ? [] : review.documents;

  return (
    <div className={styles.page}>
      <Breadcrumb
        items={[
          { label: "Vendor Records", to: ROUTES.adminVendorRegistrations },
          { label: "Review Vendor Registration" },
        ]}
      />
      <header className={styles.pageHeader}>
        <h1>Review Vendor Registration</h1>
        <p>
          Verify the applicant, business information, and supporting records
          before making a decision.
        </p>
      </header>

      <div className={styles.columns}>
        <main className={styles.main}>
          <ReviewApplicantHeader details={details} />

          <ReviewSection
            title="APPLICATION METADATA"
            subtitle="Submitted registration and current operational state."
          >
            <div className={`${styles.fields} ${styles.sixColumns}`}>
              <ReviewField
                label="Registration ID"
                value={`REG-${details.registrationId}`}
                highlight
              />
              <ReviewField
                label="Business ID"
                value={details.businessId}
                highlight
              />
              <ReviewField label="Status" value={details.status} />
              <ReviewField
                label="Requested timestamp"
                value={formatDateTime(details.requestedAt)}
              />
              <ReviewField
                label="Reviewed timestamp"
                value={
                  details.reviewedAt
                    ? formatDateTime(details.reviewedAt)
                    : "Not yet finalized"
                }
              />
              <ReviewField
                label="Reviewer"
                value={details.reviewerName ?? "Not yet assigned"}
              />
            </div>
          </ReviewSection>

          <ReviewSection
            title="BUSINESS INFORMATION"
            subtitle="Proposed business identity and market placement."
          >
            <div className={`${styles.fields} ${styles.threeColumns}`}>
              <ReviewField
                label="Business name"
                value={details.businessName}
                highlight
              />
              <ReviewField
                label="Nature of business"
                value={details.natureOfBusiness}
              />
              <ReviewField
                label="Market section"
                value={details.marketSectionName}
              />
              <ReviewField
                label="Stall assignment"
                value={details.stallNumber}
              />
              <ReviewField label="Vendor type" value={details.vendorType} />
            </div>
          </ReviewSection>

          <ReviewSection
            title="APPLICANT IDENTITY & CONTACT"
            subtitle="Personal information supplied by the registrant."
          >
            <div className={`${styles.fields} ${styles.threeColumns}`}>
              <ReviewField
                label="Full name"
                value={fullName(details)}
                highlight
              />
              <ReviewField label="Email" value={details.email} />
              <ReviewField label="Phone" value={details.phoneNumber} />
              <ReviewField label="Date of birth" value={details.dateOfBirth} />
              <ReviewField label="Age" value={`${details.age} years old`} />
              {!approved && (
                <ReviewField
                  label="Government ID type"
                  value={details.governmentIdType}
                />
              )}
              {!approved && (
                <ReviewField
                  label="Government ID number"
                  value={details.governmentIdNumber}
                  highlight
                />
              )}
              <ReviewField label="House number" value={details.houseNumber} />
              <ReviewField label="Street" value={details.street} />
              <ReviewField label="Barangay" value={details.barangay} />
              <ReviewField label="City" value={details.city} />
              <ReviewField
                label="Complete address"
                value={`${details.houseNumber}, ${details.street}, ${details.barangay}, ${details.city}`}
              />
            </div>
          </ReviewSection>

          {!approved && (
            <ReviewSection
              title="SUPPORTING DOCUMENTS"
              subtitle="Open the focused viewer for detailed inspection."
            >
              <div className={styles.documents}>
                {documents.length === 0 && (
                  <p>No supporting documents were supplied.</p>
                )}
                {documents.map((document) => (
                  <ReviewDocumentCard
                    key={`${document.documentType}-${document.fileName}`}
                    document={document}
                  />
                ))}
              </div>
            </ReviewSection>
          )}

          <footer className={styles.actions}>
            <span>
              Decision actions are recorded with reviewer identity and
              timestamp.
            </span>
            <div>
              <Button
                variant="danger"
                disabled={!review.canDecide}
                size="sm"
                onClick={() =>
                  navigate(
                    ROUTES.adminVendorRegistrationDecline(
                      String(details.registrationId),
                    ),
                  )
                }
              >
                Reject
              </Button>
              <Button
                variant="outline"
                disabled={!review.canDecide}
                size="sm"
                onClick={() =>
                  navigate(
                    ROUTES.adminVendorRegistrationInformation(
                      String(details.registrationId),
                    ),
                  )
                }
              >
                Request More Information
              </Button>
              <Button
                size="sm"
                disabled={!review.canDecide}
                onClick={() =>
                  navigate(
                    ROUTES.adminVendorRegistrationApprove(
                      String(details.registrationId),
                    ),
                  )
                }
              >
                Approve
              </Button>
            </div>
          </footer>
        </main>
        <ReviewChecklist />
      </div>
    </div>
  );
}
