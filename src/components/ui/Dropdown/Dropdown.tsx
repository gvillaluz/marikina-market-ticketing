import { useEffect, useRef, useState } from 'react';
import styles from './Dropdown.module.css';

export interface DropdownOption<T extends string = string> {
  value: T;
  label: string;
}

interface DropdownProps<T extends string = string> {
  ariaLabel: string;
  triggerLabel?: string;
  defaultOpen?: boolean;
  value: T;
  onChange: (value: T) => void;
  options: readonly DropdownOption<T>[];
}

export function Dropdown<T extends string = string>({
  ariaLabel,
  triggerLabel,
  defaultOpen = false,
  value,
  onChange,
  options,
}: DropdownProps<T>) {
  const [open, setOpen] = useState(defaultOpen);
  const rootRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (rootRef.current && !rootRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className={styles.wrapper} ref={rootRef}>
      <button
        type="button"
        className={styles.trigger}
        aria-haspopup="listbox"
        aria-expanded={open}
        onClick={() => setOpen((prev) => !prev)}
      >
        <span className={styles.triggerLabel}>{triggerLabel ?? ariaLabel}</span>
        <span className={styles.chevron} aria-hidden="true">▾</span>
      </button>

      {open && (
        <ul className={styles.menu} role="listbox" aria-label={ariaLabel}>
          {options.map((option) => (
            <li key={option.value} role="option" aria-selected={option.value === value}>
              <button
                type="button"
                className={styles.option}
                onClick={() => {
                  onChange(option.value);
                  setOpen(false);
                }}
              >
                <span>{option.label}</span>
                {option.value === value && (
                  <span className={styles.check} aria-hidden="true">✓</span>
                )}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}