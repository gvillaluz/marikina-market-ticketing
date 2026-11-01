import styles from "./OrdinanceOption.module.css";

interface Props {
  label: string;
  checked: boolean;
  disabled: boolean;
  onChange: (checked: boolean) => void;
}

export default function OrdinanceOption({ label, checked, disabled, onChange }: Props) {
  return (
    <label className={styles.option}>
      <input type="checkbox" checked={checked} disabled={disabled}
        onChange={(event) => onChange(event.target.checked)} />
      <span>{label}</span>
    </label>
  );
}
