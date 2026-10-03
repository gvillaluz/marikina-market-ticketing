import type { VendorRegistrationForm } from "@/api/types/vendor.types";
import type { RegistrationFieldErrors } from "@/features/vendors/hooks/useVendorRegistration";
import { MARKET_SECTION_OPTIONS } from "@/features/vendors/registration.constants";
import { SelectInput, TextInput } from "./FormField";
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
        <SelectInput
          label="Market section"
          required
          options={MARKET_SECTION_OPTIONS}
          placeholder="Select your market section"
          value={form.marketSectionId}
          onChange={(event) => update("marketSectionId", event.target.value)}
          error={errors.marketSectionId}
        />
        <TextInput
          label="Stall number (optional)"
          value={form.stallNumber}
          onChange={(event) => update("stallNumber", event.target.value)}
          placeholder="Leave blank if private"
          error={errors.stallNumber}
        />
      </div>
    </div>
  );
}
