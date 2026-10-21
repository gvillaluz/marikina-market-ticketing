import type { VendorRegistrationForm } from "@/api/types/vendor.types";
import type { RegistrationFieldErrors } from "@/features/vendors/hooks/useVendorRegistration";
import { TextInput } from "./FormField";
import styles from "./RegistrationForm.module.css";

interface Step4Props {
  form: VendorRegistrationForm;
  errors: RegistrationFieldErrors;
  update: <K extends keyof VendorRegistrationForm>(
    key: K,
    value: VendorRegistrationForm[K],
  ) => void;
}

export default function Step4AccountRegistration({
  form,
  errors,
  update,
}: Step4Props) {
  return (
    <div className={styles.formStack}>
      <TextInput
        label="Email address"
        required
        type="email"
        autoComplete="email"
        value={form.email}
        onChange={(event) => update("email", event.target.value)}
        placeholder="Enter your email address"
        error={errors.email}
      />
      <div className={`${styles.grid} ${styles.twoColumns}`}>
        <TextInput
          label="Password"
          required
          type="password"
          autoComplete="new-password"
          value={form.password}
          onChange={(event) => update("password", event.target.value)}
          placeholder="Create a password"
          error={errors.password}
          maxLength={100}
        />
        <TextInput
          label="Confirm password"
          required
          type="password"
          autoComplete="new-password"
          value={form.confirmPassword}
          onChange={(event) => update("confirmPassword", event.target.value)}
          placeholder="Re-enter your password"
          error={errors.confirmPassword}
          maxLength={100}
        />
      </div>
    </div>
  );
}
