import { FC, ReactNode, useEffect, useId, useRef } from "react";
import { createPortal } from "react-dom";
import { X } from "lucide-react";
import styles from "./Modal.module.css";

export interface ModalProps {
  open: boolean;
  title?: ReactNode;
  subtitle?: string;
  onClose: () => void;
  children: ReactNode;
  footer?: ReactNode;
  size?: "sm" | "md" | "lg" | "xlg";
  className?: string;
  headerClassName?: string;
  footerClassName?: string;
  closeDisabled?: boolean;
}

const Modal: FC<ModalProps> = ({
  open,
  title,
  subtitle,
  onClose,
  children,
  footer,
  size = "md",
  className = "",
  headerClassName = "",
  footerClassName = "",
  closeDisabled = false,
}) => {
  const titleId = useId();
  const closeButtonRef = useRef<HTMLButtonElement>(null);
  const modalRef = useRef<HTMLDivElement>(null);
  const closeDisabledRef = useRef(closeDisabled);
  closeDisabledRef.current = closeDisabled;
  const onCloseRef = useRef(onClose);
  onCloseRef.current = onClose;

  useEffect(() => {
    if (!open) return;
    const previousOverflow = document.body.style.overflow;
    const previouslyFocused =
      document.activeElement instanceof HTMLElement
        ? document.activeElement
        : null;
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === "Escape" && !closeDisabledRef.current) onCloseRef.current();
      if (e.key === "Tab") {
        const elements = Array.from(
          modalRef.current?.querySelectorAll<HTMLElement>(
            'button:not(:disabled), input:not(:disabled), select:not(:disabled), textarea:not(:disabled), a[href], [tabindex="0"]',
          ) ?? [],
        ).filter((element) => element.getClientRects().length > 0);
        const first = elements[0],
          last = elements[elements.length - 1];
        if (!first) {
          e.preventDefault();
          modalRef.current?.focus();
          return;
        }
        if (
          first &&
          e.shiftKey &&
          (document.activeElement === first ||
            document.activeElement === modalRef.current ||
            !modalRef.current?.contains(document.activeElement))
        ) {
          e.preventDefault();
          last.focus();
        } else if (
          first &&
          !e.shiftKey &&
          (document.activeElement === last ||
            !modalRef.current?.contains(document.activeElement))
        ) {
          e.preventDefault();
          first.focus();
        }
      }
    };
    document.addEventListener("keydown", handleKey);
    document.body.style.overflow = "hidden";
    closeButtonRef.current?.focus();
    return () => {
      document.removeEventListener("keydown", handleKey);
      document.body.style.overflow = previousOverflow;
      previouslyFocused?.focus();
    };
  }, [open]);

  if (!open) return null;

  return createPortal(
    <div
      className={styles.overlay}
      onClick={(event) => {
        if (event.target === event.currentTarget && !closeDisabled) onClose();
      }}
    >
      <div
        ref={modalRef}
        tabIndex={-1}
        className={`${styles.modal} ${styles[size]} ${className}`}
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby={title ? titleId : undefined}
        aria-label={title ? undefined : "Dialog"}
      >
        <div className={`${styles.header} ${headerClassName}`}>
          <div>
            {title && (
              <h3 id={titleId} className={styles.title}>
                {title}
              </h3>
            )}
            {subtitle && <p className={styles.subtitle}>{subtitle}</p>}
          </div>
          <button
            ref={closeButtonRef}
            className={styles.closeBtn}
            onClick={onClose}
            disabled={closeDisabled}
            aria-label="Close modal"
            type="button"
          >
            <X size={18} strokeWidth={2} />
          </button>
        </div>
        <div className={styles.body}>{children}</div>
        {footer && (
          <div className={`${styles.footer} ${footerClassName}`}>{footer}</div>
        )}
      </div>
    </div>,
    document.body,
  );
};

export default Modal;
