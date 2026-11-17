import { useState, type KeyboardEvent } from "react";

/** Tracks which password box is being typed in while Caps Lock is on. */
export function useCapsLock() {
  const [field, setField] = useState<string | null>(null);
  const bind = (id: string) => {
    const check = (event: Pick<KeyboardEvent, "getModifierState">) =>
      setField(event.getModifierState("CapsLock") ? id : null);
    return { onKeyDown: check, onKeyUp: check, onBlur: () => setField(null) };
  };
  return { field, bind };
}
