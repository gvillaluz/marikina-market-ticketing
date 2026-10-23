import type { FormEvent } from "react";
import controls from "@/styles/FormControls.module.css";
import styles from "./AnalyticsYearFilter.module.css";

interface AnalyticsYearFilterProps {
  year: number;
  currentYear: number;
  selectYear: (event: FormEvent<HTMLFormElement>) => void;
}

export default function AnalyticsYearFilter({
  year,
  currentYear,
  selectYear,
}: AnalyticsYearFilterProps) {
  return (
    <form
      className={styles.filter}
      onSubmit={selectYear}
      aria-label="Analytics reporting year"
    >
      <label htmlFor="analytics-year" className={controls.label}>
        Year
      </label>
      <input
        key={year}
        id="analytics-year"
        name="year"
        type="number"
        min={3}
        max={currentYear}
        step={1}
        required
        defaultValue={year}
        className={`${controls.input} ${styles.year}`}
      />
      <button
        type="submit"
        className={`${controls.primaryButton} ${styles.apply}`}
      >
        View year
      </button>
    </form>
  );
}
