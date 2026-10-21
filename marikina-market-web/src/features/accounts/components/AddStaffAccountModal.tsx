import Button from "@/components/ui/Button";
import { Dropdown } from "@/components/ui/Dropdown";
import Modal from "@/components/ui/Modal";
import { AlertCircle, Check, RefreshCw } from "lucide-react";
import { STAFF_ROLES, USER_ROLE_LABELS } from "@/api/types/common.types";
import type { StaffRole } from "@/api/types/accounts.types";
import type { AddStaffAccountModel } from "../hooks/useAddStaffAccount";
import type { ManageAccountModel } from "../hooks/useManageAccount";
import StaffAccountField from "./StaffAccountField";
import StaffAccountSection from "./StaffAccountSection";
import styles from "./AddStaffAccountModal.module.css";

export default function AddStaffAccountModal({
  model,
}: {
  model: AddStaffAccountModel | ManageAccountModel;
}) {
  const { form, errors, change } = model;
  const editing = "selectedId" in model;
  const canSubmit = editing ? model.canSave : model.canCreate;
  const loading = editing && model.loading;
  const awaitingDetails = editing && !model.details;
  const stale = editing && model.stale;
  const formId = editing ? "edit-account" : "add-staff-account";
  return (
    <Modal
      open={model.open}
      onClose={model.close}
      closeDisabled={model.saving}
      size="lg"
      title={editing ? "Edit Account" : "Add New Account"}
      subtitle={
        editing
          ? (model.details?.username ?? "Account Management")
          : "System Configuration"
      }
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
            form={formId}
            disabled={!canSubmit || loading}
            loading={model.saving}
          >
            {editing
              ? model.saving
                ? "Saving Changes…"
                : "Save Changes"
              : model.saving
                ? "Adding Account…"
                : "Add Account"}
          </Button>
        </>
      }
    >
      <form
        id={formId}
        ref={model.formRef}
        className={styles.form}
        onSubmit={model.submit}
        noValidate
        aria-busy={model.saving || loading}
      >
        {awaitingDetails && loading ? (
          <div className={styles.loadState} role="status">
            <RefreshCw size={24} aria-hidden="true" />
            <strong>Loading account details…</strong>
            <p>The form will appear when the account is ready.</p>
          </div>
        ) : (
          (model.error || stale) && (
            <div className={styles.notice}>
              <AlertCircle
                className={styles.noticeIcon}
                size={20}
                aria-hidden="true"
              />
              <div className={styles.noticeContent}>
                <strong>
                  {awaitingDetails
                    ? "Unable to load account"
                    : stale
                      ? "Reload before saving"
                      : editing
                        ? "Unable to save changes"
                        : "Unable to add account"}
                </strong>
                <p ref={model.errorRef} role="alert" tabIndex={-1}>
                  {model.error ||
                    "This account has changed. Load the latest details before saving."}
                </p>
                {stale && (
                  <p>
                    Reloading replaces your unsaved changes with the latest
                    saved details.
                  </p>
                )}
                {editing && (stale || awaitingDetails) && (
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={model.reload}
                    disabled={model.saving}
                    loading={loading}
                    icon={<RefreshCw size={16} aria-hidden="true" />}
                  >
                    {loading
                      ? "Reloading account…"
                      : stale
                        ? "Reload account"
                        : "Try again"}
                  </Button>
                )}
                {loading && <p role="status">Reloading account details…</p>}
              </div>
            </div>
          )
        )}
        {!awaitingDetails && (
          <fieldset
            className={styles.fields}
            disabled={model.saving || loading}
          >
            <div className={styles.role}>
              {editing ? (
                <StaffAccountField
                  label="Assigned role"
                  value={
                    form.role ? USER_ROLE_LABELS[form.role] : "Not assigned"
                  }
                  readOnly
                />
              ) : (
                <>
                  <label htmlFor="staff-role">Assigned role</label>
                  <Dropdown<StaffRole>
                    triggerId="staff-role"
                    ariaLabel="Assigned role"
                    triggerLabel={USER_ROLE_LABELS[model.form.role]}
                    value={model.form.role}
                    onChange={(role) => model.change("role", role)}
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
                </>
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
                  onChange={(event) =>
                    change("dateOfBirth", event.target.value)
                  }
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
                  onChange={(event) =>
                    change("phoneNumber", event.target.value)
                  }
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
                  maxLength={50}
                  value={form.houseNumber}
                  error={errors.houseNumber}
                  onChange={(event) =>
                    change("houseNumber", event.target.value)
                  }
                />
                <StaffAccountField
                  label="Street"
                  name="street"
                  required
                  maxLength={100}
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
                  value={editing ? (model.details?.username ?? "") : undefined}
                  placeholder={editing ? "" : "Assigned after creation"}
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
              {!editing && (
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
              )}
              {!editing && (
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
                      User creates a private password at first sign-in.
                      Credentials are managed by the server.
                    </span>
                  </label>
                </div>
              )}
            </StaffAccountSection>
          </fieldset>
        )}
      </form>
    </Modal>
  );
}
