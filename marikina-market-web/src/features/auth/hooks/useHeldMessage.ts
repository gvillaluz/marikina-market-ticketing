import { useRef } from "react";

// Keeps the last words on screen while a message closes, and gives a new key
// each time it opens so a repeated message is announced again.
export function useHeldMessage(message: string) {
  const text = useRef(message);
  const wasOpen = useRef(false);
  const openKey = useRef(0);
  const open = Boolean(message);
  if (open) text.current = message;
  if (open && !wasOpen.current) openKey.current += 1;
  wasOpen.current = open;
  return { text: text.current, open, openKey: openKey.current };
}
