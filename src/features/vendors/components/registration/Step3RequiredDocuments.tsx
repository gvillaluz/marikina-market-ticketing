import type { VendorRegistrationForm } from "@/api/types/vendor.types";
import type { RegistrationFieldErrors } from "@/features/vendors/hooks/useVendorRegistration";
import { GOVERNMENT_ID_OPTIONS } from "@/features/vendors/registration.constants";
import { FileUpload, SelectInput, TextInput } from "./FormField";
import styles from "./RegistrationForm.module.css";

interface Step3Props {
  form: VendorRegistrationForm;
  errors: RegistrationFieldErrors;
  update: <K extends keyof VendorRegistrationForm>(
    key: K,
    value: VendorRegistrationForm[K],
  ) => void;
}

export default function Step3RequiredDocuments({
  form,
  errors,
  update,
}: Step3Props) {
  return (
    <div className={styles.formStack}>
      <div className={`${styles.grid} ${styles.twoColumns}`}>
        <section className={styles.documentGroup}>
          <h4 className={styles.groupTitle}>Government ID</h4>
          <SelectInput
            label="Government ID type"
            required
            options={GOVERNMENT_ID_OPTIONS}
            placeholder="Select an ID type"
            value={form.governmentIdType}
            onChange={(event) => update("governmentIdType", event.target.value)}
            error={errors.governmentIdType}
          />
          <FileUpload
            label="Government ID photo"
            description="Upload the front of your government ID"
            required
            file={form.governmentIdPhoto}
            onChange={(file) => update("governmentIdPhoto", file)}
            error={errors.governmentIdPhoto}
          />
        </section>

        <section className={styles.documentGroup}>
          <h4 className={styles.groupTitle}>Business document</h4>
          <TextInput
            label="Business ID number"
            required
            value={form.businessId}
            onChange={(event) => update("businessId", event.target.value)}
            placeholder="Enter ID number"
            error={errors.businessId}
            maxLength={20}
          />
          <FileUpload
            label="Business document photo"
            description="Upload your business permit or supporting document"
            required
            file={form.businessDocumentPhoto}
            onChange={(file) => update("businessDocumentPhoto", file)}
            error={errors.businessDocumentPhoto}
          />
        </section>
      </div>
      <p className={styles.documentNote}>
        Use clear photos and choose files that are easy to read. We will review
        them before you continue to access your account.
      </p>
    </div>
  );
}
