import { useId } from "react";
import Modal from "@/components/ui/Modal";
import { Dropdown } from "@/components/ui/Dropdown";
import type { SaveBusinessRequest } from "@/api/types/admin-vendor.types";
import { MARKET_SECTION_OPTIONS, VENDOR_TYPE_OPTIONS } from "../registration.constants";
import BusinessFormActions from "./BusinessFormActions";
import BusinessTextField from "./BusinessTextField";
import { useBusinessForm } from "../hooks/useBusinessForm";
import styles from "./AdminCreateVendorModal.module.css";

interface Props { open: boolean; businessId: number | null; onClose: () => void; onSaved: () => Promise<void>; }
export default function AdminCreateVendorModal({ open, businessId, onClose, onSaved }: Props) {
  const fieldId = useId();
  const state = useBusinessForm(open, businessId, onSaved, onClose);
  const { form, errors, saving, update } = state;
  const disabled = saving || state.loading || Boolean(state.loadError);
  return (
    <Modal open={open} onClose={onClose} closeDisabled={saving} size="lg"
      className={styles.businessModal} headerClassName={styles.modalHeader}
      footer={<BusinessFormActions saving={saving} disabled={disabled} creating={businessId === null} onClose={onClose} />}
      title={businessId === null ? "Create Business" : "Edit Business"}
      subtitle="Business license, registered owner and market location.">
      {state.loading ? <p className={styles.state} role="status">Loading business details…</p> : state.loadError ? (
        <div className={styles.state} role="alert"><p>{state.loadError}</p>
          <button type="button" onClick={() => void state.retry()}>Try again</button></div>
      ) : (
        <form id="business-form" className={styles.form} onSubmit={event => { event.preventDefault(); void state.submit(); }} noValidate>
          <section>
            <h3>Business license</h3>
            <p className={styles.sectionHint}>Use the account number printed on the business license.</p>
            <div className={styles.gridTwo}><BusinessTextField name="businessAccountNumber" label="Business Account Number" form={form} errors={errors} disabled={disabled} onChange={update} /><BusinessTextField name="businessName" label="Business Name" form={form} errors={errors} disabled={disabled} onChange={update} /></div>
          </section>
          <section>
            <h3>Registered owner</h3>
            <div className={styles.gridTwo}>
              <BusinessTextField name="ownerFirstName" label="First name" form={form} errors={errors} disabled={disabled} onChange={update} /><BusinessTextField name="ownerLastName" label="Last name" form={form} errors={errors} disabled={disabled} onChange={update} />
              <BusinessTextField name="phoneNumber" label="Phone number" required={false} type="tel" form={form} errors={errors} disabled={disabled} onChange={update} /><BusinessTextField name="email" label="Email" required={false} type="email" form={form} errors={errors} disabled={disabled} onChange={update} />
            </div>
            <h3>Owner’s address</h3>
            <div className={styles.gridTwo}><BusinessTextField name="houseNumber" label="House number" form={form} errors={errors} disabled={disabled} onChange={update} /><BusinessTextField name="street" label="Street" form={form} errors={errors} disabled={disabled} onChange={update} /><BusinessTextField name="barangay" label="Barangay" form={form} errors={errors} disabled={disabled} onChange={update} /><BusinessTextField name="city" label="City" form={form} errors={errors} disabled={disabled} onChange={update} /></div>
          </section>
          <section>
            <h3>Market location</h3>
            <div className={styles.gridTwo}>
              <div className={styles.dropdownField}>
                <span>Business Type<b> *</b></span>
                <Dropdown fullWidth ariaLabel="Business Type" value={form.businessType}
                  triggerId={`${fieldId}-type`} invalid={Boolean(errors.businessType)}
                  describedBy={errors.businessType ? `${fieldId}-type-error` : undefined}
                  triggerLabel={form.businessType || "Select business type"} options={VENDOR_TYPE_OPTIONS}
                  onChange={value => update("businessType", value as SaveBusinessRequest["businessType"])} disabled={saving} />
                {errors.businessType && <small id={`${fieldId}-type-error`} role="alert">{errors.businessType}</small>}
              </div>
              <div className={styles.dropdownField}>
                <span>Market Section<b> *</b></span>
                <Dropdown fullWidth ariaLabel="Market Section" value={String(form.marketSectionId || "")}
                  triggerId={`${fieldId}-section`} invalid={Boolean(errors.marketSectionId)}
                  describedBy={errors.marketSectionId ? `${fieldId}-section-error` : undefined}
                  triggerLabel={MARKET_SECTION_OPTIONS.find(option => Number(option.value) === form.marketSectionId)?.label ?? "Select market section"}
                  options={MARKET_SECTION_OPTIONS} onChange={value => update("marketSectionId", Number(value))} disabled={saving} />
                {errors.marketSectionId && <small id={`${fieldId}-section-error`} role="alert">{errors.marketSectionId}</small>}
              </div>
              <BusinessTextField name="stallNumber" label="Stall Number" required={form.businessType === "Public"} form={form} errors={errors} disabled={disabled} onChange={update} />
            </div>
            <p className={styles.sectionHint}>Stall number is required for Public businesses and optional for Private businesses.</p>
          </section>
          {state.createdAt && businessId !== null && <p className={styles.sectionHint}>Created {new Date(state.createdAt).toLocaleString("en-PH", { timeZone: "Asia/Manila" })}</p>}
          {state.submitError && <p className={styles.submitError} role="alert">{state.submitError}</p>}
        </form>
      )}
    </Modal>
  );
}
