import { FC } from "react";
import { formatControlNumberLabel } from "@/utils/formatters";
import styles from "./ControlNumber.module.css";

interface ControlNumberProps {
  value: string | null | undefined;
}

const ControlNumber: FC<ControlNumberProps> = ({ value }) => {
  const label = formatControlNumberLabel(value);
  return value?.trim() ? (
    <span className={styles.number}>{label}</span>
  ) : (
    <span>{label}</span>
  );
};

export default ControlNumber;
