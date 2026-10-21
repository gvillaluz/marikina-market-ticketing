import type { VendorRegistrationForm } from "@/api/types/vendor.types";
import type { RegistrationFieldErrors } from "@/features/vendors/hooks/useVendorRegistration";
import { TextInput } from "./FormField";
import styles from "./RegistrationForm.module.css";

interface Step1Props {
  form: VendorRegistrationForm;
  errors: RegistrationFieldErrors;
  update: <K extends keyof VendorRegistrationForm>(
    key: K,
    value: VendorRegistrationForm[K],
  ) => void;
}

export default function Step1PersonalInfo({ form, errors, update }: Step1Props) {
  return (
    <div className={styles.formStack}>
      <section className={styles.group}>
        <h4 className={styles.groupTitle}>Full name</h4>
        <div className={`${styles.grid} ${styles.threeColumns}`}>
          <TextInput
            label="First name"
            required
            autoComplete="given-name"
            value={form.firstName}
            onChange={(event) => update("firstName", event.target.value)}
            placeholder="Enter first name"
            error={errors.firstName}
            maxLength={50}
          />
          <TextInput
            label="Middle name (optional)"
            autoComplete="additional-name"
            value={form.middleName}
            onChange={(event) => update("middleName", event.target.value)}
            placeholder="Enter middle name"
            error={errors.middleName}
          />
          <TextInput
            label="Last name"
            required
            autoComplete="family-name"
            value={form.lastName}
            onChange={(event) => update("lastName", event.target.value)}
            placeholder="Enter last name"
            error={errors.lastName}
            maxLength={50}
          />
        </div>
      </section>

      <section className={styles.group}>
        <h4 className={styles.groupTitle}>Contact details</h4>
        <div className={`${styles.grid} ${styles.twoColumns}`}>
          <TextInput
            label="Phone number"
            required
            type="tel"
            inputMode="numeric"
            autoComplete="tel-national"
            value={form.phoneNumber}
            onChange={(event) =>
              update("phoneNumber", event.target.value.replace(/\D/g, "").slice(0, 11))
            }
            placeholder="09XXXXXXXXX"
            error={errors.phoneNumber}
            maxLength={11}
          />
          <TextInput
            label="Date of birth"
            required
            type="date"
            autoComplete="bday"
            max={new Date().toISOString().slice(0, 10)}
            value={form.dateOfBirth}
            onChange={(event) => update("dateOfBirth", event.target.value)}
            error={errors.dateOfBirth}
          />
        </div>
      </section>

      <section className={styles.group}>
        <h4 className={styles.groupTitle}>Home address</h4>
        <div className={`${styles.grid} ${styles.threeColumns}`}>
          <TextInput
            label="House number"
            required
            autoComplete="address-line1"
            value={form.houseNumber}
            onChange={(event) => update("houseNumber", event.target.value)}
            placeholder="Enter house number"
            error={errors.houseNumber}
            maxLength={50}
          />
          <TextInput
            label="Street"
            required
            value={form.street}
            onChange={(event) => update("street", event.target.value)}
            placeholder="Enter street"
            error={errors.street}
            maxLength={50}
          />
          <TextInput
            label="Barangay"
            required
            autoComplete="address-level3"
            value={form.barangay}
            onChange={(event) => update("barangay", event.target.value)}
            placeholder="Enter barangay"
            error={errors.barangay}
            maxLength={60}
          />
          <TextInput
            label="City"
            required
            autoComplete="address-level2"
            value={form.city}
            onChange={(event) => update("city", event.target.value)}
            placeholder="Enter city"
            error={errors.city}
            maxLength={100}
          />
        </div>
      </section>
    </div>
  );
}
