import { useEffect, useId, useRef, useState } from "react";

export function useAuditFilterMenu(disabled: boolean) {
  const [open, setOpen] = useState(false);
  const root = useRef<HTMLDivElement>(null);
  const trigger = useRef<HTMLButtonElement>(null);
  const menuId = useId();
  useEffect(() => {
    if (disabled) setOpen(false);
  }, [disabled]);
  useEffect(() => {
    if (!open) return;
    function outside(event: PointerEvent) {
      if (event.target instanceof Node && !root.current?.contains(event.target))
        setOpen(false);
    }
    document.addEventListener("pointerdown", outside);
    root.current?.querySelector<HTMLInputElement>("input")?.focus();
    return () => document.removeEventListener("pointerdown", outside);
  }, [open]);
  return {
    open: open && !disabled,
    root,
    trigger,
    menuId,
    toggle: () => {
      if (!disabled) setOpen((current) => !current);
    },
    close: () => setOpen(false),
    escape() {
      setOpen(false);
      trigger.current?.focus();
    },
  };
}
