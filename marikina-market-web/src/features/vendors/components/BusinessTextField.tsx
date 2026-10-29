import { useId } from "react";
import type { SaveBusinessRequest } from "@/api/types/admin-vendor.types";
import type { BusinessErrors } from "../business.validation";
import styles from "./BusinessTextField.module.css";

interface Props {
  name: Exclude<keyof SaveBusinessRequest, "marketSectionId" | "businessType">;
  label: string;
  required?: boolean;
  type?: string;
  form: SaveBusinessRequest;
  errors: BusinessErrors;
  disabled: boolean;
  onChange: <K extends keyof SaveBusinessRequest>(key: K, value: SaveBusinessRequest[K]) => void;
}

export default function BusinessTextField({ name, label, required = true, type = "text", form, errors, disabled, onChange }: Props) {
  const id = useId();
  return <label className={styles.field} htmlFor={id}>
    <span>{label}{required && <b> *</b>}</span>
    <input id={id} name={name} type={type} value={form[name] ?? ""} disabled={disabled} required={required}
      aria-invalid={Boolean(errors[name])} aria-describedby={errors[name] ? `${id}-error` : undefined}
      onChange={event => onChange(name, event.target.value)} />
    {errors[name] && <small id={`${id}-error`} role="alert">{errors[name]}</small>}
  </label>;
}
