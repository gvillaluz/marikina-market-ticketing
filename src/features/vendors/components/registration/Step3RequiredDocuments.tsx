import type { VendorRegistrationForm } from "@/api/types/vendor.types";
import type { RegistrationFieldErrors } from "@/features/vendors/hooks/useVendorRegistration";
import { GOVERNMENT_ID_OPTIONS } from "@/features/vendors/registration.constants";
import { Dropdown } from "@/components/ui/Dropdown";
import { FileUpload, TextInput } from "./FormField";
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
  const governmentIdLabel =
    GOVERNMENT_ID_OPTIONS.find(
      (option) => option.value === form.governmentIdType,
    )?.label ?? "Select an ID type";

  return (
    <div className={styles.formStack}>
      <div className={`${styles.grid} ${styles.twoColumns}`}>
        <section className={styles.documentGroup}>
          <h4 className={styles.groupTitle}>Government ID</h4>
          <div className={styles.gridField}>
            <label className={styles.fieldLabel}>
              Government ID type <span className={styles.required}>*</span>
            </label>
            <Dropdown
              ariaLabel="Government ID type"
              triggerLabel={governmentIdLabel}
              value={form.governmentIdType}
              className={styles.formDropdown}
              fullWidth
              onChange={(value) => update("governmentIdType", value)}
              options={GOVERNMENT_ID_OPTIONS}
            />
            {errors.governmentIdType && (
              <span className={styles.fieldError}>{errors.governmentIdType}</span>
            )}
          </div>
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
