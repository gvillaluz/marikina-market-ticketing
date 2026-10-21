import { useEffect, useRef, useState } from 'react';
import styles from './Dropdown.module.css';
import { ChevronDown } from 'lucide-react';

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
  className?: string;
  fullWidth?: boolean;
  disabled?: boolean;
  triggerId?: string;
  invalid?: boolean;
  describedBy?: string;
  onBlur?: () => void;
}

export function Dropdown<T extends string = string>({
  ariaLabel,
  triggerLabel,
  defaultOpen = false,
  value,
  onChange,
  options,
  className = "",
  fullWidth = false,
  disabled = false,
  triggerId,
  invalid,
  describedBy,
  onBlur,
}: DropdownProps<T>) {
  const [open, setOpen] = useState(defaultOpen);
  const rootRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);

  useEffect(() => { if (disabled) setOpen(false); }, [disabled]);

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
    <div
      className={`${styles.wrapper} ${fullWidth ? styles.fullWidth : ""} ${className}`}
      ref={rootRef}
      onBlur={(event) => {
        if (!event.currentTarget.contains(event.relatedTarget as Node | null)) onBlur?.();
      }}
      onKeyDown={(event) => {
        if (event.key === 'Escape' && open) {
          event.stopPropagation();
          setOpen(false);
          triggerRef.current?.focus();
        }
      }}
    >
      <button
        type="button"
        id={triggerId}
        ref={triggerRef}
        className={styles.trigger}
        disabled={disabled}
        aria-label={triggerId ? ariaLabel : undefined}
        aria-invalid={invalid || undefined}
        aria-describedby={describedBy}
        aria-haspopup="listbox"
        aria-expanded={open && !disabled}
        onClick={() => setOpen((prev) => !prev)}
      >
        <span className={styles.triggerLabel}>{triggerLabel ?? ariaLabel}</span>
        <ChevronDown className={styles.chevron} size={15} />
      </button>

      {open && !disabled && (
        <ul className={styles.menu} role="listbox" aria-label={ariaLabel}>
          {options.map((option) => (
            <li key={option.value} role="option" aria-selected={option.value === value}>
              <button
                type="button"
                className={styles.option}
                onClick={() => {
                  if (disabled) return;
                  onChange(option.value);
                  setOpen(false);
                  triggerRef.current?.focus();
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
