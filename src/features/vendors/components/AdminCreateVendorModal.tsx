import { useState } from "react";
import { AlertCircle, LoaderCircle } from "lucide-react";
import Modal from "@/components/ui/Modal";
import { Dropdown } from "@/components/ui/Dropdown";
import {
  MARKET_SECTION_OPTIONS,
  VENDOR_TYPE_OPTIONS,
} from "../registration.constants";
import { adminVendorsApi } from "@/api/endpoints/adminVendors.api";
import type { AdminRegisterVendorRequest } from "@/api/types/admin-vendor.types";
import { getApiErrorMessage } from "@/utils/apiErrors";
import styles from "./AdminCreateVendorModal.module.css";

type FormState = AdminRegisterVendorRequest;
type Errors = Partial<Record<keyof FormState, string>>;

const INITIAL_FORM: FormState = {
  firstName: "",
  middleName: "",
  lastName: "",
  dateOfBirth: "",
  phoneNumber: "",
  houseNumber: "",
  street: "",
  barangay: "",
  city: "Marikina City",
  businessName: "",
  businessId: "",
  natureOfBusiness: "",
  marketSectionId: 0,
  stallNumber: "",
  vendorType: "",
  username: "",
  email: "",
  password: "",
  confirmPassword: "",
};

interface Props {
  open: boolean;
  onClose: () => void;
  onSaved: () => Promise<void>;
}

function validate(form: FormState): Errors {
  const errors: Errors = {};
  const required: Array<[keyof FormState, string]> = [
    ["firstName", "First name"],
    ["lastName", "Last name"],
    ["dateOfBirth", "Date of birth"],
    ["phoneNumber", "Phone number"],
    ["houseNumber", "House number"],
    ["street", "Street"],
    ["barangay", "Barangay"],
    ["city", "City"],
    ["businessName", "Business name"],
    ["businessId", "Business ID"],
    ["natureOfBusiness", "Nature of business"],
    ["vendorType", "Vendor type"],
    ["username", "Username"],
    ["email", "Email"],
    ["password", "Password"],
    ["confirmPassword", "Confirm password"],
  ];
  required.forEach(([key, label]) => {
    if (!String(form[key]).trim()) errors[key] = `${label} is required.`;
  });
  if (form.marketSectionId < 1)
    errors.marketSectionId = "Market section is required.";
  if (form.phoneNumber && !/^09\d{9}$/.test(form.phoneNumber))
    errors.phoneNumber = "Enter a valid PH mobile number.";
  if (form.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email))
    errors.email = "Enter a valid email address.";
  if (form.password && form.password.length < 8)
    errors.password = "Password must be at least 8 characters.";
  if (form.confirmPassword && form.password !== form.confirmPassword)
    errors.confirmPassword = "Passwords do not match.";
  if (form.vendorType === "Public" && !form.stallNumber.trim())
    errors.stallNumber = "Stall number is required for public vendors.";
  return errors;
}

export default function AdminCreateVendorModal({
  open,
  onClose,
  onSaved,
}: Props) {
  const [form, setForm] = useState<FormState>(INITIAL_FORM);
  const [errors, setErrors] = useState<Errors>({});
  const [saving, setSaving] = useState(false);
  const [submitError, setSubmitError] = useState("");

  const update = <K extends keyof FormState>(key: K, value: FormState[K]) => {
    setForm((previous) => ({ ...previous, [key]: value }));
    setErrors((previous) => ({ ...previous, [key]: undefined }));
    setSubmitError("");
  };

  const submit = async () => {
    const nextErrors = validate(form);
    setErrors(nextErrors);
    if (Object.keys(nextErrors).length) return;
    setSaving(true);
    setSubmitError("");
    try {
      await adminVendorsApi.registerVendor(form);
      await onSaved();
      setForm(INITIAL_FORM);
      onClose();
    } catch (error) {
      setSubmitError(
        getApiErrorMessage(
          error,
          "Vendor account could not be created. Please try again.",
        ),
      );
    } finally {
      setSaving(false);
    }
  };

  const input = (
    key: keyof FormState,
    label: string,
    type = "text",
    required = true,
  ) => (
    <label className={styles.field}>
      <span>
        {label}
        {required && <b>*</b>}
      </span>
      <input
        type={type}
        value={String(form[key])}
        onChange={(event) =>
          update(key, event.target.value as FormState[typeof key])
        }
      />
      {errors[key] && <small>{errors[key]}</small>}
    </label>
  );

  return (
    <Modal
      open={open}
      onClose={onClose}
      size="lg"
      title="Create Vendor Account"
      subtitle="Enter the vendor's information to create and activate an account."
    >
      <div className={styles.form}>
        <section>
          <h4>
            <b>1</b>
            <span>Vendor Identity</span>
          </h4>
          <p className={styles.sectionHint}>
            Personal and contact information for the account holder.
          </p>
          <div className={styles.gridThree}>
            {input("firstName", "First name")}
            {input("middleName", "Middle name", "text", false)}
            {input("lastName", "Last name")}
          </div>
          <div className={styles.gridTwo}>
            {input("dateOfBirth", "Date of birth", "date")}
            {input("phoneNumber", "Phone number")}
          </div>
        </section>
        <section>
          <h4>
            <b>2</b>
            <span>Residential Address</span>
          </h4>
          <p className={styles.sectionHint}>
            Required address information for the vendor record.
          </p>
          <div className={styles.gridFour}>
            {input("houseNumber", "House number")}
            {input("street", "Street")}
            {input("barangay", "Barangay")}
            {input("city", "City")}
          </div>
        </section>
        <section>
          <h4>
            <b>3</b>
            <span>Business & Stall Assignment</span>
          </h4>
          <p className={styles.sectionHint}>
            Details used to assign the vendor to the market.
          </p>
          <div className={styles.gridTwo}>
            {input("businessName", "Business name")}
            {input("businessId", "Business ID")}
          </div>
          {input("natureOfBusiness", "Nature of business")}
          <div
            className={`${styles.businessGrid} ${form.vendorType !== "Public" ? styles.businessGridCompact : ""}`}
          >
            <div className={styles.dropdownField}>
              <span>
                Market section<b>*</b>
              </span>
              <Dropdown
                fullWidth
                ariaLabel="Market section"
                triggerLabel={
                  MARKET_SECTION_OPTIONS.find(
                    (item) => Number(item.value) === form.marketSectionId,
                  )?.label ?? "Select market section"
                }
                value={String(form.marketSectionId || "")}
                onChange={(value) => update("marketSectionId", Number(value))}
                options={MARKET_SECTION_OPTIONS}
              />
            </div>
            <div className={styles.dropdownField}>
              <span>
                Vendor type<b>*</b>
              </span>
              <Dropdown
                fullWidth
                ariaLabel="Vendor type"
                triggerLabel={
                  VENDOR_TYPE_OPTIONS.find(
                    (item) => item.value === form.vendorType,
                  )?.label ?? "Select vendor type"
                }
                value={form.vendorType}
                onChange={(value) => {
                  update("vendorType", value);
                  if (value === "Private") update("stallNumber", "");
                }}
                options={VENDOR_TYPE_OPTIONS}
              />
            </div>
            {form.vendorType === "Public" &&
              input("stallNumber", "Stall number")}
          </div>
          {errors.marketSectionId && (
            <small className={styles.sectionError}>
              {errors.marketSectionId}
            </small>
          )}
        </section>
        <section>
          <h4>
            <b>4</b>
            <span>Account Credentials</span>
          </h4>
          <p className={styles.sectionHint}>
            Temporary access details for the vendor portal.
          </p>
          <div className={styles.gridTwo}>
            {input("email", "Email address", "email")}
          </div>
          <div className={styles.gridTwo}>
            {input("password", "Create password", "password")}
            {input("confirmPassword", "Confirm password", "password")}
          </div>
        </section>
        <div className={styles.approvalNotice}>
          <AlertCircle size={17} aria-hidden="true" />
          <div>
            <strong>Automatic approval</strong>
            <span>
              This walk-in registration will be automatically approved and the
              vendor can access the system immediately.
            </span>
          </div>
        </div>
        {submitError && <p className={styles.submitError}>{submitError}</p>}
      </div>
      <div className={styles.footer}>
        <button type="button" onClick={onClose} disabled={saving}>
          Cancel
        </button>
        <button type="button" onClick={() => void submit()} disabled={saving}>
          {saving && <LoaderCircle size={15} className={styles.spinner} />}{" "}
          {saving ? "Creating..." : "Create & Activate Account"}
        </button>
      </div>
    </Modal>
  );
}
