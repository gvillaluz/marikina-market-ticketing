import Button from "@/components/ui/Button";
import { Dropdown } from "@/components/ui/Dropdown";
import Modal from "@/components/ui/Modal";
import { Check } from "lucide-react";
import { STAFF_ROLES, USER_ROLE_LABELS } from "@/api/types/common.types";
import type { StaffRole } from "@/api/types/accounts.types";
import type { AddStaffAccountModel } from "../hooks/useAddStaffAccount";
import StaffAccountField from "./StaffAccountField";
import StaffAccountSection from "./StaffAccountSection";
import styles from "./AddStaffAccountModal.module.css";

export default function AddStaffAccountModal({
  model,
}: {
  model: AddStaffAccountModel;
}) {
  const { form, errors, change } = model;
  return (
    <Modal
      open={model.open}
      onClose={model.close}
      closeDisabled={model.saving}
      size="lg"
      title="Add New Account"
      subtitle="System Configuration"
      footer={
        <>
          <Button
            variant="outline"
            type="button"
            onClick={model.close}
            disabled={model.saving}
          >
            Cancel
          </Button>
          <Button
            type="submit"
            form="add-staff-account"
            disabled={!model.canCreate}
            loading={model.saving}
          >
            {model.saving ? "Adding Account…" : "Add Account"}
          </Button>
        </>
      }
    >
      <form
        id="add-staff-account"
        ref={model.formRef}
        className={styles.form}
        onSubmit={model.submit}
        noValidate
        aria-busy={model.saving}
      >
        <fieldset className={styles.fields} disabled={model.saving}>
          <div className={styles.role}>
            <label htmlFor="staff-role">Assigned role</label>
            <Dropdown<StaffRole>
              triggerId="staff-role"
              ariaLabel="Assigned role"
              triggerLabel={USER_ROLE_LABELS[form.role]}
              value={form.role}
              onChange={(role) => change("role", role)}
              options={STAFF_ROLES.filter(
                (role): role is StaffRole => role !== "MarketVendor",
              ).map((role) => ({
                value: role,
                label: USER_ROLE_LABELS[role],
              }))}
              disabled={model.saving}
              invalid={Boolean(errors.role)}
              describedBy={errors.role ? "staff-role-error" : undefined}
              fullWidth
            />
            {errors.role && (
              <span className={styles.error} id="staff-role-error">
                {errors.role}
              </span>
            )}
          </div>
          <StaffAccountSection
            number={1}
            title="Personal Information"
            subtitle="Details used for the system identity record."
          >
            <div className={styles.names}>
              <StaffAccountField
                label="First name"
                name="firstName"
                autoComplete="given-name"
                required
                maxLength={100}
                value={form.firstName}
                error={errors.firstName}
                onChange={(event) => change("firstName", event.target.value)}
              />
              <StaffAccountField
                label="Middle name"
                name="middleName"
                autoComplete="additional-name"
                maxLength={100}
                value={form.middleName}
                onChange={(event) => change("middleName", event.target.value)}
              />
              <StaffAccountField
                label="Last name"
                name="lastName"
                autoComplete="family-name"
                required
                maxLength={100}
                value={form.lastName}
                error={errors.lastName}
                onChange={(event) => change("lastName", event.target.value)}
              />
            </div>
            <div className={styles.pair}>
              <StaffAccountField
                label="Date of birth"
                name="dateOfBirth"
                type="date"
                autoComplete="bday"
                required
                value={form.dateOfBirth}
                error={errors.dateOfBirth}
                onChange={(event) => change("dateOfBirth", event.target.value)}
              />
              <StaffAccountField
                label="Phone number"
                name="phoneNumber"
                type="tel"
                autoComplete="tel"
                required
                maxLength={20}
                placeholder="+63 9XX XXX XXXX"
                value={form.phoneNumber}
                error={errors.phoneNumber}
                onChange={(event) => change("phoneNumber", event.target.value)}
              />
            </div>
          </StaffAccountSection>
          <StaffAccountSection
            number={2}
            title="Residential Address"
            subtitle="Required address fields from the user profile."
          >
            <div className={styles.address}>
              <StaffAccountField
                label="House number"
                name="houseNumber"
                required
                maxLength={100}
                value={form.houseNumber}
                error={errors.houseNumber}
                onChange={(event) => change("houseNumber", event.target.value)}
              />
              <StaffAccountField
                label="Street"
                name="street"
                required
                maxLength={200}
                value={form.street}
                error={errors.street}
                onChange={(event) => change("street", event.target.value)}
              />
              <StaffAccountField
                label="Barangay"
                name="barangay"
                required
                maxLength={100}
                value={form.barangay}
                error={errors.barangay}
                onChange={(event) => change("barangay", event.target.value)}
              />
              <StaffAccountField
                label="City"
                name="city"
                autoComplete="address-level2"
                required
                maxLength={100}
                value={form.city}
                error={errors.city}
                onChange={(event) => change("city", event.target.value)}
              />
            </div>
          </StaffAccountSection>
          <StaffAccountSection
            number={3}
            title="System Access"
            subtitle="Credentials, role, and first sign-in requirements."
          >
            <div className={styles.pair}>
              <StaffAccountField
                label="Username"
                disabled
                placeholder="Assigned after creation"
              />
              <StaffAccountField
                label="Email address"
                name="email"
                type="email"
                autoComplete="email"
                required
                maxLength={254}
                placeholder="name@marikinamarket.gov.ph"
                value={form.email}
                error={errors.email}
                onChange={(event) => change("email", event.target.value)}
              />
            </div>
            <div className={styles.pair}>
              <StaffAccountField
                label="Temporary password"
                type="password"
                disabled
                placeholder="Managed by server"
              />
              <StaffAccountField
                label="Confirm password"
                type="password"
                disabled
                placeholder="Managed by server"
              />
            </div>
            <div className={styles.requireChange}>
              <span className={styles.checkbox}>
                <input
                  id="staff-password-change"
                  type="checkbox"
                  checked
                  disabled
                  readOnly
                />
                <Check size={16} strokeWidth={3} aria-hidden="true" />
              </span>
              <label htmlFor="staff-password-change">
                Require password change
                <span>
                  User creates a private password at first sign-in. Credentials
                  are managed by the server.
                </span>
              </label>
            </div>
          </StaffAccountSection>
        </fieldset>
        {model.error && (
          <p
            ref={model.errorRef}
            className={styles.error}
            role="alert"
            tabIndex={-1}
          >
            {model.error}
          </p>
        )}
      </form>
    </Modal>
  );
}
