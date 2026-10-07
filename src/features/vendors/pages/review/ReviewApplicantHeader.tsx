import type { VendorRegistrationDetails } from "@/api/types/admin-vendor.types";
import { formatDateTime } from "@/utils/formatters";
import styles from "../AdminVendorRegistrationReviewPage.module.css";

export function getRegistrationName(details: VendorRegistrationDetails) {
  return [details.firstName, details.middleName, details.lastName]
    .filter(Boolean)
    .join(" ");
}

export default function ReviewApplicantHeader({
  details,
}: {
  details: VendorRegistrationDetails;
}) {
  const name = getRegistrationName(details);

  return (
    <section className={styles.applicant}>
      <span className={styles.avatar}>{name.slice(0, 2).toUpperCase()}</span>
      <div>
        <strong>{name}</strong>
        <span>
          {details.businessName} · REG-{details.registrationId}
        </span>
      </div>
      <div className={styles.requested}>
        <span>REQUESTED</span>
        <strong>{formatDateTime(details.requestedAt)}</strong>
      </div>
    </section>
  );
}
