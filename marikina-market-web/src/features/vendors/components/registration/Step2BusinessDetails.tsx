import type { VendorRegistrationForm } from "@/api/types/vendor.types";
import type { RegistrationFieldErrors } from "@/features/vendors/hooks/useVendorRegistration";
import { Dropdown } from "@/components/ui/Dropdown";
import {
  MARKET_SECTION_OPTIONS,
  VENDOR_TYPE_OPTIONS,
} from "@/features/vendors/registration.constants";
import { TextInput } from "./FormField";
import styles from "./RegistrationForm.module.css";

interface Step2Props {
  form: VendorRegistrationForm;
  errors: RegistrationFieldErrors;
  update: <K extends keyof VendorRegistrationForm>(
    key: K,
    value: VendorRegistrationForm[K],
  ) => void;
}

export default function Step2BusinessDetails({
  form,
  errors,
  update,
}: Step2Props) {
  const vendorTypeLabel =
    VENDOR_TYPE_OPTIONS.find((option) => option.value === form.vendorType)?.label ??
    "Select vendor type";
  const marketSectionLabel =
    MARKET_SECTION_OPTIONS.find((option) => option.value === form.marketSectionId)?.label ??
    "Select your market section";

  return (
    <div className={styles.formStack}>
      <TextInput
        label="Business name"
        required
        value={form.businessName}
        onChange={(event) => update("businessName", event.target.value)}
        placeholder="Enter your business name"
        error={errors.businessName}
        maxLength={100}
      />
      <TextInput
        label="Nature of business"
        required
        value={form.natureOfBusiness}
        onChange={(event) => update("natureOfBusiness", event.target.value)}
        placeholder="e.g., Services, fruit, meat, dry goods"
        error={errors.natureOfBusiness}
        maxLength={100}
      />
      <div className={`${styles.grid} ${styles.twoColumns}`}>
        <div className={styles.gridField}>
          <label className={styles.fieldLabel}>
            Vendor type <span className={styles.required}>*</span>
          </label>
          <Dropdown
            ariaLabel="Vendor type"
            triggerLabel={vendorTypeLabel}
            value={form.vendorType}
            className={styles.formDropdown}
            fullWidth
            onChange={(value) => {
              update("vendorType", value);
              if (value === "Private") update("stallNumber", "");
            }}
            options={VENDOR_TYPE_OPTIONS}
          />
          </div>
        <div className={styles.gridField}>
          <label className={styles.fieldLabel}>
            Market section <span className={styles.required}>*</span>
          </label>
          <Dropdown
            ariaLabel="Market section"
            triggerLabel={marketSectionLabel}
            value={form.marketSectionId}
            className={styles.formDropdown}
            fullWidth
            onChange={(value) => update("marketSectionId", value)}
            options={MARKET_SECTION_OPTIONS}
          />
        </div>
      </div>
      {form.vendorType === "Public" && (
        <div className={styles.stallField}>
          <TextInput
            label="Stall number"
            required
            value={form.stallNumber}
            onChange={(event) => update("stallNumber", event.target.value)}
            placeholder="Enter your stall number"
            error={errors.stallNumber}
          />
        </div>
      )}
    </div>
  );
}
